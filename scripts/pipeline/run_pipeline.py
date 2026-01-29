#!/usr/bin/env python3
"""
Universal Data Pipeline Runner
-------------------------------
Orchestrates data extraction, staging, and ETL for all external data sources.

Features:
- Auto-discovers pipelines from Pipeline_Metadata table
- Checks Next_Refresh_Date to run only due pipelines
- Audit trail for every run (extraction → staging → ETL)
- Interactive registration for new pipelines
- CLI interface for manual and scheduled runs

Usage:
    python run_pipeline.py --all                    # Run all due pipelines
    python run_pipeline.py --pipeline GP_Practices  # Run specific pipeline
    python run_pipeline.py --force --pipeline LSOA  # Force run even if not due
    python run_pipeline.py --register               # Register a new pipeline
    python run_pipeline.py --status                 # Show pipeline status

Author: Sridhar Peddi
Created: 2026-01-08
"""

import argparse
import sys
from datetime import datetime, timedelta
from pathlib import Path
import pyodbc
from typing import Optional, Dict, List
import logging

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent.parent))

from utils.db_connection import get_db_connection
from utils.logger import setup_logger

logger = setup_logger(__name__)


class PipelineRunner:
    """Orchestrates pipeline execution with full audit trail."""
    
    def __init__(self, connection_string: str):
        self.conn_string = connection_string
        self.conn = None
        
    def __enter__(self):
        self.conn = pyodbc.connect(self.conn_string)
        return self
        
    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.conn:
            self.conn.close()
    
    def get_due_pipelines(self, force: bool = False) -> List[Dict]:
        """Get list of pipelines that are due for refresh."""
        cursor = self.conn.cursor()
        
        if force:
            # Get all active pipelines
            query = """
            SELECT Pipeline_ID, Pipeline_Name, Source_URL, Target_Staging_Table,
                   Target_Dimension_Table, ETL_Procedure_Name, Refresh_Frequency
            FROM [Analytics].[Pipeline_Metadata]
            WHERE Is_Active = 1
            """
        else:
            # Get only overdue pipelines
            query = """
            SELECT Pipeline_ID, Pipeline_Name, Source_URL, Target_Staging_Table,
                   Target_Dimension_Table, ETL_Procedure_Name, Refresh_Frequency
            FROM [Analytics].[Pipeline_Metadata]
            WHERE Is_Active = 1
              AND Next_Refresh_Date <= CAST(GETDATE() AS DATE)
            """
        
        cursor.execute(query)
        columns = [column[0] for column in cursor.description]
        pipelines = [dict(zip(columns, row)) for row in cursor.fetchall()]
        cursor.close()
        
        return pipelines
    
    def get_pipeline_by_name(self, pipeline_name: str) -> Optional[Dict]:
        """Get pipeline configuration by name."""
        cursor = self.conn.cursor()
        query = """
        SELECT Pipeline_ID, Pipeline_Name, Source_Type, Source_URL, Target_Staging_Table,
               Target_Dimension_Table, ETL_Procedure_Name, Refresh_Frequency
        FROM [Analytics].[Pipeline_Metadata]
        WHERE Pipeline_Name = ? AND Is_Active = 1
        """
        cursor.execute(query, pipeline_name)
        
        if cursor.rowcount == 0:
            cursor.close()
            return None
            
        columns = [column[0] for column in cursor.description]
        result = dict(zip(columns, cursor.fetchone()))
        cursor.close()
        
        return result
    
    def start_run_audit(self, pipeline_id: int, triggered_by: str) -> int:
        """Create audit record for pipeline run. Returns Run_ID."""
        cursor = self.conn.cursor()
        cursor.execute("""
            INSERT INTO [Analytics].[Pipeline_Run_Audit]
                (Pipeline_ID, Run_Start_Time, Overall_Status, Triggered_By)
            VALUES (?, GETDATE(), 'RUNNING', ?)
        """, pipeline_id, triggered_by)
        self.conn.commit()
        
        cursor.execute("SELECT @@IDENTITY")
        run_id = cursor.fetchone()[0]
        cursor.close()
        
        return run_id
    
    def update_extraction_status(self, run_id: int, rows: int, status: str, error: str = None):
        """Update audit record with extraction phase results."""
        cursor = self.conn.cursor()
        cursor.execute("""
            UPDATE [Analytics].[Pipeline_Run_Audit]
            SET Rows_Extracted = ?,
                Extraction_Status = ?,
                Extraction_Error = ?
            WHERE Run_ID = ?
        """, rows, status, error, run_id)
        self.conn.commit()
        cursor.close()
    
    def update_staging_status(self, run_id: int, rows: int, status: str, error: str = None):
        """Update audit record with staging phase results."""
        cursor = self.conn.cursor()
        cursor.execute("""
            UPDATE [Analytics].[Pipeline_Run_Audit]
            SET Rows_Staged = ?,
                Staging_Status = ?,
                Staging_Error = ?
            WHERE Run_ID = ?
        """, rows, status, error, run_id)
        self.conn.commit()
        cursor.close()
    
    def update_etl_status(self, run_id: int, inserted: int, updated: int, deleted: int, 
                          status: str, error: str = None):
        """Update audit record with ETL phase results."""
        cursor = self.conn.cursor()
        cursor.execute("""
            UPDATE [Analytics].[Pipeline_Run_Audit]
            SET Rows_Inserted = ?,
                Rows_Updated = ?,
                Rows_Deleted = ?,
                ETL_Status = ?,
                ETL_Error = ?
            WHERE Run_ID = ?
        """, inserted, updated, deleted, status, error, run_id)
        self.conn.commit()
        cursor.close()
    
    def complete_run_audit(self, run_id: int, overall_status: str):
        """Mark run as complete."""
        cursor = self.conn.cursor()
        cursor.execute("""
            UPDATE [Analytics].[Pipeline_Run_Audit]
            SET Run_End_Time = GETDATE(),
                Overall_Status = ?
            WHERE Run_ID = ?
        """, overall_status, run_id)
        self.conn.commit()
        cursor.close()
    
    def update_pipeline_metadata(self, pipeline_id: int, status: str, refresh_frequency: str):
        """Update pipeline metadata after successful run."""
        cursor = self.conn.cursor()
        
        # Calculate next refresh date based on frequency
        if refresh_frequency == 'DAILY':
            next_refresh = datetime.now() + timedelta(days=1)
        elif refresh_frequency == 'WEEKLY':
            next_refresh = datetime.now() + timedelta(weeks=1)
        elif refresh_frequency == 'MONTHLY':
            next_refresh = datetime.now() + timedelta(days=30)
        elif refresh_frequency == 'QUARTERLY':
            next_refresh = datetime.now() + timedelta(days=90)
        else:  # MANUAL
            next_refresh = datetime.now() + timedelta(days=365*10)  # Far future
        
        cursor.execute("""
            UPDATE [Analytics].[Pipeline_Metadata]
            SET Last_Run_Date = GETDATE(),
                Last_Run_Status = ?,
                Next_Refresh_Date = ?,
                Updated_Date = GETDATE()
            WHERE Pipeline_ID = ?
        """, status, next_refresh.date(), pipeline_id)
        self.conn.commit()
        cursor.close()
    
    def run_extraction(self, pipeline: Dict, run_id: int) -> int:
        """
        Extract data from source.
        This method should be overridden by specific extractors.
        Returns number of rows extracted.
        """
        logger.info(f"Extracting from {pipeline['Source_URL']}...")
        
        # Import specific extractor based on source type
        source_type = pipeline.get('Source_Type', 'API')
        
        if source_type == 'API':
            from extractors.api_extractor import APIExtractor
            extractor = APIExtractor(pipeline['Source_URL'])
        elif source_type == 'CSV':
            from extractors.csv_extractor import CSVExtractor
            extractor = CSVExtractor(pipeline['Source_URL'])
        else:
            raise ValueError(f"Unsupported source type: {source_type}")
        
        try:
            data = extractor.extract()
            self.update_extraction_status(run_id, len(data), 'SUCCESS')
            return data
        except Exception as e:
            logger.error(f"Extraction failed: {str(e)}")
            self.update_extraction_status(run_id, 0, 'FAILED', str(e))
            raise
    
    def run_staging(self, pipeline: Dict, data: List[Dict], run_id: int) -> int:
        """
        Load extracted data into staging table.
        Returns number of rows staged.
        """
        logger.info(f"Loading {len(data)} rows into {pipeline['Target_Staging_Table']}...")
        
        try:
            # Truncate staging table
            cursor = self.conn.cursor()
            cursor.execute(f"TRUNCATE TABLE {pipeline['Target_Staging_Table']}")
            
            # Build INSERT statement dynamically
            if not data:
                self.update_staging_status(run_id, 0, 'SUCCESS')
                return 0
            
            columns = list(data[0].keys())
            placeholders = ','.join(['?' for _ in columns])
            insert_sql = f"INSERT INTO {pipeline['Target_Staging_Table']} ({','.join(columns)}) VALUES ({placeholders})"
            
            # Batch insert
            values = [tuple(row[col] for col in columns) for row in data]
            cursor.executemany(insert_sql, values)
            self.conn.commit()
            
            rows_staged = len(data)
            self.update_staging_status(run_id, rows_staged, 'SUCCESS')
            cursor.close()
            
            return rows_staged
            
        except Exception as e:
            logger.error(f"Staging failed: {str(e)}")
            self.update_staging_status(run_id, 0, 'FAILED', str(e))
            raise
    
    def run_etl(self, pipeline: Dict, run_id: int):
        """Execute ETL stored procedure to load dimension table."""
        logger.info(f"Running ETL procedure: {pipeline['ETL_Procedure_Name']}...")
        
        try:
            cursor = self.conn.cursor()
            cursor.execute(f"EXEC {pipeline['ETL_Procedure_Name']}")
            self.conn.commit()
            
            # Get rowcount from ETL_Logging table (assumes ETL proc logs there)
            cursor.execute("""
                SELECT TOP 1 Rows_Affected 
                FROM [Analytics].[tbl_ETL_Logging]
                WHERE Procedure_Name = ?
                ORDER BY Start_Time DESC
            """, pipeline['ETL_Procedure_Name'])
            
            result = cursor.fetchone()
            rows_affected = result[0] if result else 0
            
            self.update_etl_status(run_id, rows_affected, 0, 0, 'SUCCESS')
            cursor.close()
            
        except Exception as e:
            logger.error(f"ETL failed: {str(e)}")
            self.update_etl_status(run_id, 0, 0, 0, 'FAILED', str(e))
            raise
    
    def run_pipeline(self, pipeline_name: str, force: bool = False, triggered_by: str = 'MANUAL'):
        """Execute full pipeline: extract → stage → ETL."""
        pipeline = self.get_pipeline_by_name(pipeline_name)
        
        if not pipeline:
            logger.error(f"Pipeline '{pipeline_name}' not found or inactive")
            return False
        
        logger.info(f"Starting pipeline: {pipeline_name}")
        run_id = self.start_run_audit(pipeline['Pipeline_ID'], triggered_by)
        
        try:
            # Phase 1: Extraction
            data = self.run_extraction(pipeline, run_id)
            
            # Phase 2: Staging
            self.run_staging(pipeline, data, run_id)
            
            # Phase 3: ETL
            self.run_etl(pipeline, run_id)
            
            # Success - update metadata
            self.complete_run_audit(run_id, 'SUCCESS')
            self.update_pipeline_metadata(pipeline['Pipeline_ID'], 'SUCCESS', 
                                          pipeline['Refresh_Frequency'])
            
            logger.info(f"Pipeline '{pipeline_name}' completed successfully")
            return True
            
        except Exception as e:
            # Failure - log and update
            self.complete_run_audit(run_id, 'FAILED')
            self.update_pipeline_metadata(pipeline['Pipeline_ID'], 'FAILED', 
                                          pipeline['Refresh_Frequency'])
            logger.error(f"Pipeline '{pipeline_name}' failed: {str(e)}")
            return False


def register_pipeline():
    """Interactive CLI to register a new pipeline."""
    print("\n=== Register New Pipeline ===\n")
    
    pipeline_name = input("Pipeline Name (e.g., 'GP_Practices'): ").strip()
    description = input("Description: ").strip()
    source_type = input("Source Type (API/CSV/BULK_DOWNLOAD): ").strip().upper()
    source_url = input("Source URL: ").strip()
    staging_table = input("Staging Table (e.g., 'Analytics.Staging_Provider'): ").strip()
    dimension_table = input("Dimension Table (e.g., 'Analytics.tbl_Dim_Provider'): ").strip()
    etl_procedure = input("ETL Procedure (e.g., 'Analytics.sp_Load_Dim_Provider'): ").strip()
    
    print("\nRefresh Frequency Options:")
    print("  1. DAILY")
    print("  2. WEEKLY")
    print("  3. MONTHLY")
    print("  4. QUARTERLY")
    print("  5. MANUAL")
    freq_choice = input("Select frequency (1-5): ").strip()
    
    freq_map = {'1': 'DAILY', '2': 'WEEKLY', '3': 'MONTHLY', '4': 'QUARTERLY', '5': 'MANUAL'}
    refresh_frequency = freq_map.get(freq_choice, 'WEEKLY')
    
    # Calculate next refresh date
    if refresh_frequency == 'DAILY':
        next_refresh = datetime.now() + timedelta(days=1)
    elif refresh_frequency == 'WEEKLY':
        next_refresh = datetime.now() + timedelta(weeks=1)
    elif refresh_frequency == 'MONTHLY':
        next_refresh = datetime.now() + timedelta(days=30)
    elif refresh_frequency == 'QUARTERLY':
        next_refresh = datetime.now() + timedelta(days=90)
    else:
        next_refresh = datetime.now() + timedelta(days=365*10)
    
    # Insert into database
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("""
            INSERT INTO [Analytics].[Pipeline_Metadata]
                (Pipeline_Name, Pipeline_Description, Source_Type, Source_URL,
                 Target_Staging_Table, Target_Dimension_Table, ETL_Procedure_Name,
                 Refresh_Frequency, Next_Refresh_Date, Is_Active)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1)
        """, pipeline_name, description, source_type, source_url, staging_table,
             dimension_table, etl_procedure, refresh_frequency, next_refresh.date())
        conn.commit()
        print(f"\n✅ Pipeline '{pipeline_name}' registered successfully!")
        print(f"   Next refresh: {next_refresh.date()}")
    except Exception as e:
        print(f"\n❌ Failed to register pipeline: {str(e)}")
    finally:
        cursor.close()
        conn.close()


def show_status():
    """Display current pipeline status."""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute("SELECT * FROM [Analytics].[vw_Pipeline_Status] ORDER BY Is_Overdue DESC, Pipeline_Name")
    
    print("\n=== Pipeline Status ===\n")
    print(f"{'Pipeline':<20} {'Status':<10} {'Last Run':<12} {'Overdue':<8} {'Next Refresh':<15}")
    print("-" * 75)
    
    for row in cursor.fetchall():
        pipeline_name = row[1][:18]
        status = row[9] or 'NEVER RUN'
        last_run = row[7].strftime('%Y-%m-%d') if row[7] else 'Never'
        overdue = '⚠️ YES' if row[12] else 'No'
        next_refresh = row[6] strftime('%Y-%m-%d')
        
        print(f"{pipeline_name:<20} {status:<10} {last_run:<12} {overdue:<8} {next_refresh:<15}")
    
    cursor.close()
    conn.close()


def main():
    parser = argparse.ArgumentParser(description='Universal Data Pipeline Runner')
    parser.add_argument('--all', action='store_true', help='Run all due pipelines')
    parser.add_argument('--pipeline', type=str, help='Run specific pipeline by name')
    parser.add_argument('--force', action='store_true', help='Force run even if not due')
    parser.add_argument('--register', action='store_true', help='Register a new pipeline')
    parser.add_argument('--status', action='store_true', help='Show pipeline status')
    
    args = parser.parse_args()
    
    if args.register:
        register_pipeline()
        return
    
    if args.status:
        show_status()
        return
    
    conn_string = get_db_connection()
    
    with PipelineRunner(conn_string) as runner:
        if args.all:
            pipelines = runner.get_due_pipelines(force=args.force)
            logger.info(f"Found {len(pipelines)} due pipelines")
            
            for pipeline in pipelines:
                runner.run_pipeline(pipeline['Pipeline_Name'], args.force, 'SCHEDULED')
        
        elif args.pipeline:
            runner.run_pipeline(args.pipeline, args.force, 'MANUAL')
        
        else:
            parser.print_help()


if __name__ == '__main__':
    main()

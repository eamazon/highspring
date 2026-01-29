#!/usr/bin/env python3
"""
Complete NHS ODS Data Integration Helper
Orchestrates the full ETL workflow: Fetch → Stage → Load

This script automates the complete data integration:
1. Fetch data from NHS ODS API
2. Load to staging table
3. Execute ETL procedure to populate Dim_Commissioner  
4. Generate validation report

Database Agnostic: Works with SQL Server and Snowflake

Usage:
    python run_ods_integration.py --env prod --db-type sqlserver
    python run_ods_integration.py --dry-run  # Test without loading
"""

import argparse
import subprocess
import sys
from datetime import datetime


def print_header(title):
    """Print formatted section header"""
    print(f"\n{'='*80}")
    print(f"{title}")
    print(f"{'='*80}\n")


def run_fetch(db_type: str, dry_run: bool = False) -> bool:
    """Step 1: Fetch data from NHS ODS API"""
    print_header("Step 1: Fetching NHS ODS Data")
    
    cmd = [
        'python3',
        'scripts/data_integration/nhs_ods/fetch_all_commissioners.py',
        '--output', 'both' if not dry_run else 'json',
        '--db-type', db_type,
        '--status', 'All'  # Fetch both active and inactive
    ]
    
    if dry_run:
        cmd.append('--dry-run')
    
    print(f"Command: {' '.join(cmd)}\n")
    
    try:
        result = subprocess.run(cmd, check=True, capture_output=False)
        print("\n✓ Fetch completed successfully")
        return True
    except subprocess.CalledProcessError as e:
        print(f"\n✗ Fetch failed: {e}")
        return False


def run_sql_load(sql_file: str, db_type: str) -> bool:
    """Step 2: Load SQL file to staging table"""
    print_header("Step 2: Loading to Staging Table")
    
    if db_type == 'sqlserver':
        # SQL Server using sqlcmd
        cmd = [
            'sqlcmd',
            '-S', '${SQL_SERVER}',
            '-d', 'Data_Lab_SWL_Live',
            '-i', sql_file,
            '-E'  # Windows Authentication
        ]
    else:  # Snowflake
        # Snowflake using SnowSQL
        cmd = [
            'snowsql',
            '-a', '${SNOWFLAKE_ACCOUNT}',
            '-u', '${SNOWFLAKE_USER}',
            '-d', 'SWL_ANALYTICS',
            '-f', sql_file
        ]
    
    print(f"Loading SQL file: {sql_file}")
    print(f"Target: {db_type}\n")
    
    print("NOTE: Set environment variables for connection:")
    print(f"  SQL_SERVER, SNOWFLAKE_ACCOUNT, SNOWFLAKE_USER\n")
    
    # For now, just print instructions
    print("Manual Step: Execute the generated SQL file in your database client")
    print(f"  File: {sql_file}\n")
    
    return True


def run_etl_procedure(db_type: str) -> bool:
    """Step 3: Execute ETL procedure"""
    print_header("Step 3: Running ETL Procedure")
    
    print("Execute ETL procedure to load Dim_Commissioner from staging:\n")
    
    if db_type == 'sqlserver':
        print("  EXEC [Analytics].[sp_Load_Dim_Commissioner_From_ODS];")
    else:  # Snowflake
        print("  CALL ANALYTICS.sp_Load_Dim_Commissioner_From_ODS();")
    
    print("\nManual Step: Run the above procedure in your database client\n")
    
    return True


def generate_validation_report() -> bool:
    """Step 4: Generate data validation report"""
    print_header("Step 4: Validation Queries")
    
    queries = """
-- 1. Check staging table record count
SELECT 
    COUNT(*) AS Total_Records,
    SUM(CASE WHEN Status = 'Active' THEN 1 ELSE 0 END) AS Active,
    SUM(CASE WHEN Status != 'Active' THEN 1 ELSE 0 END) AS Inactive,
    SUM(CASE WHEN Is_Processed = 1 THEN 1 ELSE 0 END) AS Processed,
    SUM(CASE WHEN Validation_Status = 'Valid' THEN 1 ELSE 0 END) AS Valid
FROM [Analytics].[tbl_Staging_NHS_ODS_Commissioner];

-- 2. Check commissioner types
SELECT 
    Commissioner_Type,
    COUNT(*) AS Count,
    SUM(CASE WHEN Status = 'Active' THEN 1 ELSE 0 END) AS Active_Count
FROM [Analytics].[tbl_Staging_NHS_ODS_Commissioner]
GROUP BY Commissioner_Type
ORDER BY Count DESC;

-- 3. Verify SWL commissioners loaded
SELECT * 
FROM [Analytics].[Dim_Commissioner]
WHERE Commissioner_Code IN ('36L', '07V', '08J', '08P', '08R', '08T', '08X')
ORDER BY Commissioner_Code;

-- 4. Check for missing parent ICB names
SELECT Commissioner_Code, Parent_ICB_Code, Parent_ICB_Name
FROM [Analytics].[tbl_Staging_NHS_ODS_Commissioner]
WHERE Parent_ICB_Code IS NOT NULL 
  AND Parent_ICB_Name IS NULL;
"""
    
    print(queries)
    print("\nManual Step: Run validation queries in your database client\n")
    
    return True


def main():
    parser = argparse.ArgumentParser(description='Complete NHS ODS Integration Helper')
    parser.add_argument('--env', choices=['dev', 'prod'], default='dev',
                        help='Environment')
    parser.add_argument('--db-type', choices=['sqlserver', 'snowflake'], default='sqlserver',
                        help='Database type')
    parser.add_argument('--dry-run', action='store_true',
                        help='Test run without loading data')
    
    args = parser.parse_args()
    
    print_header(f"NHS ODS Complete Data Integration - {args.env.upper()}")
    print(f"Database Type: {args.db_type}")
    print(f"Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    # Step 1: Fetch
    if not run_fetch(args.db_type, args.dry_run):
        print("\n✗ Integration failed at fetch step")
        return 1
    
    if args.dry_run:
        print("\nDry run complete. Exiting.")
        return 0
    
    # Find generated SQL file
    import glob
    sql_files = glob.glob(f'scripts/data_integration/nhs_ods/nhs_ods_complete_{args.db_type}_*.sql')
    if not sql_files:
        print("\n✗ No SQL file generated")
        return 1
    
    latest_sql = max(sql_files)  # Get most recent
    
    # Step 2: Load to staging
    run_sql_load(latest_sql, args.db_type)
    
    # Step 3: ETL procedure
    run_etl_procedure(args.db_type)
    
    # Step 4: Validation
    generate_validation_report()
    
    print_header("Integration Complete")
    print("✓ NHS ODS data integration workflow finished")
    print(f"✓ Generated SQL file: {latest_sql}")
    print("\nNext Steps:")
    print("  1. Execute SQL file to load staging table")
    print("  2. Run ETL procedure to populate Dim_Commissioner")
    print("  3. Execute validation queries to verify data quality")
    print("  4. Schedule this script for weekly execution\n")
    
    return 0


if __name__ == "__main__":
    sys.exit(main())

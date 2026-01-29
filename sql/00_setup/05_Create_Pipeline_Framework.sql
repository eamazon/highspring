

USE [Data_Lab_SWL_Live];
GO

PRINT '========================================';
PRINT 'Creating Pipeline Framework Tables';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

-------------------------------------------------------------------------------
-- 1. Pipeline Metadata Table
-------------------------------------------------------------------------------
IF OBJECT_ID('[Analytics].[Pipeline_Metadata]', 'U') IS NOT NULL
BEGIN
    PRINT 'Table [Analytics].[Pipeline_Metadata] already exists. Dropping...';
    DROP TABLE [Analytics].[Pipeline_Metadata];
END
GO

/**
Script Name:   05_Create_Pipeline_Framework.sql
Description:   SQL object
Author:        Sridhar Peddi
Created:       2026-01-09

Change Log:
  2026-01-09  Sridhar Peddi    Initial creation
**/
CREATE TABLE [Analytics].[Pipeline_Metadata]
(
    Pipeline_ID INT IDENTITY(1,1) PRIMARY KEY,
    Pipeline_Name VARCHAR(100) NOT NULL UNIQUE,
    Pipeline_Description VARCHAR(500) NULL,
    
    -- Source Configuration
    Source_Type VARCHAR(50) NOT NULL,  -- 'API', 'CSV', 'BULK_DOWNLOAD'
    Source_URL VARCHAR(1000) NOT NULL,
    Source_Notes VARCHAR(500) NULL,
    
    -- Target Configuration
    Target_Staging_Table VARCHAR(200) NOT NULL,  -- 'Analytics.Staging_Provider'
    Target_Dimension_Table VARCHAR(200) NOT NULL,  -- 'Analytics.tbl_Dim_Provider'
    ETL_Procedure_Name VARCHAR(200) NOT NULL,  -- 'Analytics.sp_Load_Dim_Provider'
    
    -- Scheduling
    Refresh_Frequency VARCHAR(20) NOT NULL,  -- 'DAILY', 'WEEKLY', 'MONTHLY', 'QUARTERLY'
    Next_Refresh_Date DATE NOT NULL,
    Last_Run_Date DATETIME2 NULL,
    Last_Run_Status VARCHAR(20) NULL,  -- 'SUCCESS', 'FAILED', 'RUNNING'
    
    -- Control
    Is_Active BIT NOT NULL DEFAULT 1,
    Created_Date DATETIME2 NOT NULL DEFAULT GETDATE(),
    Updated_Date DATETIME2 NULL,
    
    CONSTRAINT CK_Refresh_Frequency CHECK (Refresh_Frequency IN ('DAILY', 'WEEKLY', 'MONTHLY', 'QUARTERLY', 'MANUAL')),
    CONSTRAINT CK_Source_Type CHECK (Source_Type IN ('API', 'CSV', 'BULK_DOWNLOAD', 'WEB_SCRAPE'))
);
GO

PRINT '[OK] Created Pipeline_Metadata table';
GO

-------------------------------------------------------------------------------
-- 2. Pipeline Audit Table
-------------------------------------------------------------------------------
IF OBJECT_ID('[Analytics].[Pipeline_Run_Audit]', 'U') IS NOT NULL
BEGIN
    PRINT 'Table [Analytics].[Pipeline_Run_Audit] already exists. Dropping...';
    DROP TABLE [Analytics].[Pipeline_Run_Audit];
END
GO

CREATE TABLE [Analytics].[Pipeline_Run_Audit]
(
    Run_ID INT IDENTITY(1,1) PRIMARY KEY,
    Pipeline_ID INT NOT NULL,
    
    -- Run Details
    Run_Start_Time DATETIME2 NOT NULL,
    Run_End_Time DATETIME2 NULL,
    Run_Duration_Seconds AS DATEDIFF(SECOND, Run_Start_Time, Run_End_Time),
    
    -- Extraction Phase
    Rows_Extracted INT NULL,
    Extraction_Status VARCHAR(20) NULL,  -- 'SUCCESS', 'FAILED', 'PARTIAL'
    Extraction_Error VARCHAR(MAX) NULL,
    
    -- Staging Phase
    Rows_Staged INT NULL,
    Staging_Status VARCHAR(20) NULL,
    Staging_Error VARCHAR(MAX) NULL,
    
    -- ETL Phase
    Rows_Inserted INT NULL,
    Rows_Updated INT NULL,
    Rows_Deleted INT NULL,
    ETL_Status VARCHAR(20) NULL,
    ETL_Error VARCHAR(MAX) NULL,
    
    -- Overall Status
    Overall_Status VARCHAR(20) NOT NULL,  -- 'SUCCESS', 'FAILED', 'PARTIAL'
    
    -- Metadata
    Triggered_By VARCHAR(100) NOT NULL,  -- 'SCHEDULED', 'MANUAL', 'CLI'
    Executed_By VARCHAR(100) NULL,  -- Username or system
    
    CONSTRAINT FK_Pipeline_Audit FOREIGN KEY (Pipeline_ID) 
        REFERENCES [Analytics].[Pipeline_Metadata](Pipeline_ID)
);
GO

PRINT '[OK] Created Pipeline_Run_Audit table';
GO

-- Create index on Pipeline_ID and Run_Start_Time for fast queries
CREATE NONCLUSTERED INDEX IX_Pipeline_Audit_Pipeline_Date 
    ON [Analytics].[Pipeline_Run_Audit](Pipeline_ID, Run_Start_Time DESC);
GO

PRINT '[OK] Created index on Pipeline_Run_Audit';
GO

-------------------------------------------------------------------------------
-- 3. Helper View: Pipeline Status Dashboard
-------------------------------------------------------------------------------
CREATE OR ALTER VIEW [Analytics].[vw_Pipeline_Status] AS
SELECT 
    pm.Pipeline_ID,
    pm.Pipeline_Name,
    pm.Pipeline_Description,
    pm.Source_Type,
    pm.Target_Dimension_Table,
    pm.Refresh_Frequency,
    pm.Next_Refresh_Date,
    pm.Last_Run_Date,
    pm.Last_Run_Status,
    pm.Is_Active,
    
    -- Days since last run
    DATEDIFF(DAY, pm.Last_Run_Date, GETDATE()) AS Days_Since_Last_Run,
    
    -- Is refresh overdue?
    CASE 
        WHEN pm.Next_Refresh_Date < CAST(GETDATE() AS DATE) THEN 1 
        ELSE 0 
    END AS Is_Overdue,
    
    -- Last run stats
    last_run.Rows_Extracted,
    last_run.Rows_Inserted,
    last_run.Rows_Updated,
    last_run.Run_Duration_Seconds,
    last_run.Overall_Status AS Last_Run_Overall_Status
    
FROM [Analytics].[Pipeline_Metadata] pm
LEFT JOIN (
    -- Get most recent run for each pipeline
    SELECT 
        Pipeline_ID,
        Rows_Extracted,
        Rows_Inserted,
        Rows_Updated,
        Run_Duration_Seconds,
        Overall_Status,
        ROW_NUMBER() OVER (PARTITION BY Pipeline_ID ORDER BY Run_Start_Time DESC) AS rn
    FROM [Analytics].[Pipeline_Run_Audit]
) last_run ON pm.Pipeline_ID = last_run.Pipeline_ID AND last_run.rn = 1;
GO

PRINT '[OK] Created vw_Pipeline_Status view';
GO

PRINT '';
PRINT '========================================';
PRINT 'Pipeline Framework Created Successfully';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
PRINT 'Next Steps:';
PRINT '  1. Register pipelines using Python CLI';
PRINT '  2. Run: python scripts/pipeline/run_pipeline.py --help';
GO

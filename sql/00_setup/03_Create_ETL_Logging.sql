

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating ETL Logging Infrastructure';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

-------------------------------------------------------------------------------
-- CLEANUP: Drop existing objects in reverse dependency order
-- (Must drop child tables with FKs before dropping parent Batch_Log)
-------------------------------------------------------------------------------

-- 1. Drop Stored Procedures
IF OBJECT_ID('[Analytics].[sp_Cleanup_Stale_Batches]', 'P') IS NOT NULL DROP PROCEDURE [Analytics].[sp_Cleanup_Stale_Batches];
IF OBJECT_ID('[Analytics].[sp_Log_Table_Load]', 'P') IS NOT NULL DROP PROCEDURE [Analytics].[sp_Log_Table_Load];
IF OBJECT_ID('[Analytics].[sp_End_ETL_Batch]', 'P') IS NOT NULL DROP PROCEDURE [Analytics].[sp_End_ETL_Batch];
IF OBJECT_ID('[Analytics].[sp_Start_ETL_Batch]', 'P') IS NOT NULL DROP PROCEDURE [Analytics].[sp_Start_ETL_Batch];

-- 2a. Drop Legacy Child Tables (pre tbl_ rename)
IF OBJECT_ID('[Analytics].[ETL_Performance_Metrics]', 'U') IS NOT NULL DROP TABLE [Analytics].[ETL_Performance_Metrics];
IF OBJECT_ID('[Analytics].[ETL_Error_Details]', 'U') IS NOT NULL DROP TABLE [Analytics].[ETL_Error_Details];
IF OBJECT_ID('[Analytics].[ETL_Table_Load_Log]', 'U') IS NOT NULL DROP TABLE [Analytics].[ETL_Table_Load_Log];

-- 2b. Drop Child Tables
IF OBJECT_ID('[Analytics].[tbl_ETL_Performance_Metrics]', 'U') IS NOT NULL DROP TABLE [Analytics].[tbl_ETL_Performance_Metrics];
IF OBJECT_ID('[Analytics].[tbl_ETL_Error_Details]', 'U') IS NOT NULL DROP TABLE [Analytics].[tbl_ETL_Error_Details];
IF OBJECT_ID('[Analytics].[tbl_ETL_Table_Load_Log]', 'U') IS NOT NULL DROP TABLE [Analytics].[tbl_ETL_Table_Load_Log];

-- 3a. Drop Legacy Parent Table (pre tbl_ rename)
IF OBJECT_ID('[Analytics].[ETL_Batch_Log]', 'U') IS NOT NULL 
BEGIN
    PRINT 'Dropping [Analytics].[ETL_Batch_Log] (legacy table)...';
    DROP TABLE [Analytics].[ETL_Batch_Log];
END

-- 3b. Drop Parent Table
IF OBJECT_ID('[Analytics].[tbl_ETL_Batch_Log]', 'U') IS NOT NULL 
BEGIN
    PRINT 'Dropping [Analytics].[tbl_ETL_Batch_Log] (and children)...';
    DROP TABLE [Analytics].[tbl_ETL_Batch_Log];
END
GO

-------------------------------------------------------------------------------
-- TABLE 1: ETL_Batch_Log
-- Purpose: Tracks each ETL job run (batch-level monitoring)
-------------------------------------------------------------------------------

/**
Script Name:   03_Create_ETL_Logging.sql
Description:   Production-grade ETL monitoring and error tracking infrastructure
Author:        Sridhar Peddi
Created:       2026-01-02

Change Log:
  2026-01-02  Sridhar Peddi    Initial creation
**/
CREATE TABLE [Analytics].[tbl_ETL_Batch_Log]
(
    Batch_ID INT IDENTITY(1,1) NOT NULL,
    Batch_Name VARCHAR(100) NOT NULL,
    Start_DateTime DATETIME2 NOT NULL DEFAULT GETDATE(),
    End_DateTime DATETIME2 NULL,
    Status VARCHAR(20) NOT NULL DEFAULT 'Running', 
        -- Values: 'Running', 'Success', 'Failed', 'Timeout', 'Cancelled'
    
    -- Row counts (how many rows were inserted/updated/deleted)
    Rows_Inserted INT NULL,
    Rows_Updated INT NULL,
    Rows_Deleted INT NULL,
    Rows_Failed INT NULL,  -- Rows that failed to load
    
    -- Performance metrics (automatically calculated via computed columns)
    Duration_Seconds AS DATEDIFF(SECOND, Start_DateTime, End_DateTime),
    Throughput_Rows_Per_Second AS 
        CASE 
            WHEN DATEDIFF(SECOND, Start_DateTime, End_DateTime) > 0 
            THEN (ISNULL(Rows_Inserted, 0) + ISNULL(Rows_Updated, 0) + ISNULL(Rows_Deleted, 0)) 
                 / DATEDIFF(SECOND, Start_DateTime, End_DateTime)
            ELSE NULL 
        END,
    
    -- Error handling (SQL Server error details)
    Error_Message NVARCHAR(4000) NULL,  -- Capped at 4000 chars for performance
    Error_Number INT NULL,              -- SQL error number (e.g., 2627 = duplicate key)
    Error_Severity INT NULL,            -- Error severity level (1-25)
    Error_State INT NULL,               -- Error state
    Error_Procedure VARCHAR(128) NULL,  -- Procedure where error occurred
    
    -- Audit columns (who ran the job, which server)
    Executed_By VARCHAR(128) DEFAULT SUSER_SNAME(),
    Server_Name VARCHAR(128) DEFAULT @@SERVERNAME,
    
    -- Retry tracking (for jobs that auto-retry on failure)
    Retry_Count INT DEFAULT 0,
    Parent_Batch_ID INT NULL,  -- References original batch if this is a retry
    
    CONSTRAINT PK_ETL_Batch_Log PRIMARY KEY CLUSTERED (Batch_ID),
    CONSTRAINT FK_ETL_Batch_Parent FOREIGN KEY (Parent_Batch_ID) 
        REFERENCES [Analytics].[tbl_ETL_Batch_Log](Batch_ID)
);
GO

PRINT '[OK] Created table: [Analytics].[tbl_ETL_Batch_Log]';
GO

-------------------------------------------------------------------------------
-- TABLE 2: ETL_Table_Load_Log
-- Purpose: Tracks individual table loads within a batch
-- Provides granular detail on which tables were updated
-------------------------------------------------------------------------------

IF OBJECT_ID('[Analytics].[tbl_ETL_Table_Load_Log]', 'U') IS NOT NULL
BEGIN
    PRINT 'Table [Analytics].[tbl_ETL_Table_Load_Log] already exists. Dropping...';
    DROP TABLE [Analytics].[tbl_ETL_Table_Load_Log];
END
GO

CREATE TABLE [Analytics].[tbl_ETL_Table_Load_Log]
(
    Load_ID INT IDENTITY(1,1) NOT NULL,
    Batch_ID INT NOT NULL,  -- Links to ETL_Batch_Log
    Table_Name VARCHAR(100) NOT NULL,  -- e.g., 'Fact_IP_Activity', 'Dim_Commissioner'
    Load_Type VARCHAR(20) NOT NULL,    -- 'Full', 'Incremental', 'Partition'
    Partition_ID INT NULL,              -- For partition-specific loads (e.g., partition 202401)
    
    -- Timing
    Start_DateTime DATETIME2 NOT NULL DEFAULT GETDATE(),
    End_DateTime DATETIME2 NULL,
    Duration_Seconds AS DATEDIFF(SECOND, Start_DateTime, End_DateTime),
    
    -- Row counts
    Rows_Affected INT NULL,  -- Rows inserted/updated/deleted
    Rows_Failed INT NULL,    -- Rows that failed for this specific table
    Status VARCHAR(20) NOT NULL DEFAULT 'In Progress',
        -- Values: 'In Progress', 'Success', 'Failed', 'Skipped'
    
    -- Error details
    Error_Message NVARCHAR(4000) NULL,
    
    CONSTRAINT PK_ETL_Table_Load_Log PRIMARY KEY CLUSTERED (Load_ID),
    CONSTRAINT FK_ETL_Batch FOREIGN KEY (Batch_ID) 
        REFERENCES [Analytics].[tbl_ETL_Batch_Log](Batch_ID)
);
GO

PRINT '[OK] Created table: [Analytics].[tbl_ETL_Table_Load_Log]';
GO

-------------------------------------------------------------------------------
-- TABLE 3: ETL_Error_Details
-- Purpose: Captures individual rows that failed to load
-- Useful for troubleshooting data quality issues
-------------------------------------------------------------------------------

IF OBJECT_ID('[Analytics].[tbl_ETL_Error_Details]', 'U') IS NOT NULL
BEGIN
    PRINT 'Table [Analytics].[tbl_ETL_Error_Details] already exists. Dropping...';
    DROP TABLE [Analytics].[tbl_ETL_Error_Details];
END
GO

CREATE TABLE [Analytics].[tbl_ETL_Error_Details]
(
    Error_ID BIGINT IDENTITY(1,1) NOT NULL,
    Batch_ID INT NOT NULL,
    Load_ID INT NULL,  -- Optional link to specific table load
    
    -- Error context
    Error_DateTime DATETIME2 NOT NULL DEFAULT GETDATE(),
    Source_Table VARCHAR(100) NULL,  -- Where the data came from
    Target_Table VARCHAR(100) NULL,  -- Where it was trying to go
    
    -- Failed row data (can store JSON or XML representation)
    Failed_Row_Data NVARCHAR(MAX) NULL,  -- e.g., '{"NHS_Number":"123456789","Name":"John Doe"}'
    Business_Key VARCHAR(255) NULL,       -- e.g., NHS_Number, Encounter_ID (for easy lookup)
    
    -- Error details
    Error_Message NVARCHAR(4000) NOT NULL,
    Error_Type VARCHAR(50) NULL,  -- 'Validation', 'Constraint', 'Conversion', 'Unknown'
    
    CONSTRAINT PK_ETL_Error_Details PRIMARY KEY CLUSTERED (Error_ID),
    CONSTRAINT FK_ETL_Error_Batch FOREIGN KEY (Batch_ID) 
        REFERENCES [Analytics].[tbl_ETL_Batch_Log](Batch_ID)
);
GO

-- Create index on Business_Key for fast lookups (e.g., "show all errors for Patient X")
CREATE NONCLUSTERED INDEX IX_ETL_Error_Details_BusinessKey 
    ON [Analytics].[tbl_ETL_Error_Details](Business_Key) 
    INCLUDE (Error_DateTime, Error_Message);
GO

PRINT '[OK] Created table: [Analytics].[tbl_ETL_Error_Details]';
GO

-------------------------------------------------------------------------------
-- TABLE 4: ETL_Performance_Metrics
-- Purpose: Tracks table sizes, compression, and load times over time
-- Helps identify performance degradation trends
-------------------------------------------------------------------------------

IF OBJECT_ID('[Analytics].[tbl_ETL_Performance_Metrics]', 'U') IS NOT NULL
BEGIN
    PRINT 'Table [Analytics].[tbl_ETL_Performance_Metrics] already exists. Dropping...';
    DROP TABLE [Analytics].[tbl_ETL_Performance_Metrics];
END
GO

CREATE TABLE [Analytics].[tbl_ETL_Performance_Metrics]
(
    Metric_ID BIGINT IDENTITY(1,1) NOT NULL,
    Batch_ID INT NOT NULL,
    Table_Name VARCHAR(100) NOT NULL,
    
    -- Size metrics (in megabytes)
    Table_Size_MB DECIMAL(18,2) NULL,
    Index_Size_MB DECIMAL(18,2) NULL,
    Rowgroup_Count INT NULL,           -- For columnstore indexes (aim for >1M rows per rowgroup)
    
    -- Compression metrics
    Compression_Type VARCHAR(50) NULL, -- 'Columnstore', 'Page', 'Row', 'None'
    Compression_Ratio DECIMAL(5,2) NULL,  -- e.g., 10.5 = 10.5:1 compression
    
    -- Timing
    Measurement_DateTime DATETIME2 NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT PK_ETL_Performance_Metrics PRIMARY KEY CLUSTERED (Metric_ID),
    CONSTRAINT FK_ETL_Perf_Batch FOREIGN KEY (Batch_ID) 
        REFERENCES [Analytics].[tbl_ETL_Batch_Log](Batch_ID)
);
GO

-- Create index for time-series queries (trending over time)
CREATE NONCLUSTERED INDEX IX_ETL_Performance_TableTime 
    ON [Analytics].[tbl_ETL_Performance_Metrics](Table_Name, Measurement_DateTime);
GO

PRINT '[OK] Created table: [Analytics].[tbl_ETL_Performance_Metrics]';
GO

PRINT '';
PRINT '========================================';
PRINT 'Creating Stored Procedures';
PRINT '========================================';
GO

-------------------------------------------------------------------------------
-- PROCEDURE 1: sp_Start_ETL_Batch
-- Purpose: Starts an ETL job and prevents duplicate concurrent runs
-- Uses SQL Server Application Locks (sp_getapplock)
-------------------------------------------------------------------------------

IF OBJECT_ID('[Analytics].[sp_Start_ETL_Batch]', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE [Analytics].[sp_Start_ETL_Batch];
END
GO

CREATE PROCEDURE [Analytics].[sp_Start_ETL_Batch]
    @BatchName VARCHAR(100),
    @BatchID INT OUTPUT,
    @TimeoutMinutes INT = 720  -- Default 12 hours
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Prevent concurrent batches with the same name using Application Lock
    DECLARE @LockResult INT;
    
    -- CHECK: Do we *already* hold the lock in this session? (Re-entrant)
    IF APPLOCK_MODE('public', @BatchName, 'Session') = 'Exclusive'
    BEGIN
        PRINT ' [INFO] Lock for "' + @BatchName + '" is already held by this session. Proceeding re-entrantly.';
        SET @LockResult = 0; -- Pretend we just got it
    END
    ELSE
    BEGIN
        -- Try to acquire new lock
        EXEC @LockResult = sp_getapplock 
            @Resource = @BatchName, 
            @LockMode = 'Exclusive', 
            @LockOwner = 'Session',
            @LockTimeout = 0;  -- Fail immediately if locked by ANTOHER session
    END
    
    -- Check if lock was acquired (or pre-held)
    IF @LockResult < 0
    BEGIN
        DECLARE @ErrorMsg VARCHAR(500) = 
            'Batch "' + @BatchName + '" is already running (Locked by another session). Cannot start duplicate.';
        RAISERROR(@ErrorMsg, 16, 1);
        RETURN -1;
    END
    
    -- Insert batch log record
    INSERT INTO [Analytics].[tbl_ETL_Batch_Log] 
        (Batch_Name, Start_DateTime, Status, Executed_By, Server_Name)
    VALUES 
        (@BatchName, GETDATE(), 'Running', SUSER_SNAME(), @@SERVERNAME);
    
    SET @BatchID = SCOPE_IDENTITY();
    
    -- Print confirmation
    PRINT '>>> Started Batch ID: ' + CAST(@BatchID AS VARCHAR) + ' (' + @BatchName + ')';
    PRINT ' Start Time: ' + CONVERT(VARCHAR, GETDATE(), 121);
    PRINT ' Lock acquired. Timeout set to ' + CAST(@TimeoutMinutes AS VARCHAR) + ' minutes.';
    PRINT '';
    
    RETURN 0;
END
GO

PRINT '[OK] Created procedure: [Analytics].[sp_Start_ETL_Batch]';
GO

-------------------------------------------------------------------------------
-- PROCEDURE 2: sp_End_ETL_Batch
-- Purpose: Marks batch as complete and releases the Application Lock
-------------------------------------------------------------------------------

IF OBJECT_ID('[Analytics].[sp_End_ETL_Batch]', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE [Analytics].[sp_End_ETL_Batch];
END
GO

CREATE PROCEDURE [Analytics].[sp_End_ETL_Batch]
    @BatchID INT,
    @Status VARCHAR(20),  -- 'Success' or 'Failed'
    @RowsInserted INT = NULL,
    @RowsUpdated INT = NULL,
    @RowsDeleted INT = NULL,
    @RowsFailed INT = NULL,
    @ErrorMessage NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Get batch name for lock release
    DECLARE @BatchName VARCHAR(100);
    SELECT @BatchName = Batch_Name 
    FROM [Analytics].[tbl_ETL_Batch_Log] 
    WHERE Batch_ID = @BatchID;
    
    -- Update batch log with final status
    UPDATE [Analytics].[tbl_ETL_Batch_Log]
    SET End_DateTime = GETDATE(),
        Status = @Status,
        Rows_Inserted = @RowsInserted,
        Rows_Updated = @RowsUpdated,
        Rows_Deleted = @RowsDeleted,
        Rows_Failed = @RowsFailed,
        Error_Message = LEFT(@ErrorMessage, 4000)  -- Cap at 4000 chars
    WHERE Batch_ID = @BatchID;
    
    -- If failed, capture SQL Server error details (if available in current context)
    IF @Status = 'Failed' AND @ErrorMessage IS NOT NULL
    BEGIN
        UPDATE [Analytics].[tbl_ETL_Batch_Log]
        SET Error_Number = ERROR_NUMBER(),
            Error_Severity = ERROR_SEVERITY(),
            Error_State = ERROR_STATE(),
            Error_Procedure = ERROR_PROCEDURE()
        WHERE Batch_ID = @BatchID;
    END
    
    -- Release application lock (Safely)
    IF @BatchName IS NOT NULL
    BEGIN
        -- Check if we actually hold the lock before trying to release it
        IF APPLOCK_MODE('public', @BatchName, 'Session') = 'Exclusive'
        BEGIN
            EXEC sp_releaseapplock @Resource = @BatchName, @LockOwner = 'Session';
            PRINT ' Released lock for batch: ' + @BatchName;
        END
        ELSE
        BEGIN
            PRINT ' [INFO] No lock held for batch: ' + @BatchName + ' (Already released or never acquired)';
        END
    END
    
    -- Print summary
    PRINT '';
    IF @Status = 'Failed'
    BEGIN
        PRINT '[FAIL] ETL FAILED - Batch ID: ' + CAST(@BatchID AS VARCHAR);
        PRINT '[WARNING]  Error: ' + ISNULL(LEFT(@ErrorMessage, 500), 'Unknown error');
        
        -- Future enhancement: Send email alert via Database Mail
        -- EXEC msdb.dbo.sp_send_dbmail @recipients='etl-alerts@example.com', ...
    END
    ELSE
    BEGIN
        PRINT '[OK] ETL SUCCESS - Batch ID: ' + CAST(@BatchID AS VARCHAR);
        PRINT ' Rows: +' + CAST(ISNULL(@RowsInserted, 0) AS VARCHAR) 
            + ' (inserted), ~' + CAST(ISNULL(@RowsUpdated, 0) AS VARCHAR) + ' (updated)'
            + ', -' + CAST(ISNULL(@RowsDeleted, 0) AS VARCHAR) + ' (deleted)';
        
        DECLARE @Duration INT;
        SELECT @Duration = Duration_Seconds 
        FROM [Analytics].[tbl_ETL_Batch_Log] 
        WHERE Batch_ID = @BatchID;
        
        IF @Duration IS NOT NULL
            PRINT '  Duration: ' + CAST(@Duration AS VARCHAR) + ' seconds';
    END
    PRINT '';
    
    RETURN 0;
END
GO

PRINT '[OK] Created procedure: [Analytics].[sp_End_ETL_Batch]';
GO

-------------------------------------------------------------------------------
-- PROCEDURE 3: sp_Log_Table_Load
-- Purpose: Logs individual table loads within a batch
-------------------------------------------------------------------------------

IF OBJECT_ID('[Analytics].[sp_Log_Table_Load]', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE [Analytics].[sp_Log_Table_Load];
END
GO

CREATE PROCEDURE [Analytics].[sp_Log_Table_Load]
    @BatchID INT,
    @TableName VARCHAR(100),
    @LoadType VARCHAR(20),  -- 'Full', 'Incremental', 'Partition'
    @RowsAffected INT = NULL,
    @RowsFailed INT = NULL,
    @Status VARCHAR(20) = 'Success',
    @ErrorMessage NVARCHAR(MAX) = NULL,
    @StartDateTime DATETIME2 = NULL,
    @EndDateTime DATETIME2 = NULL,
    @PartitionID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO [Analytics].[tbl_ETL_Table_Load_Log]
        (Batch_ID, Table_Name, Load_Type, Partition_ID, Start_DateTime, End_DateTime, 
         Rows_Affected, Rows_Failed, Status, Error_Message)
    VALUES
        (@BatchID, @TableName, @LoadType, @PartitionID,
         COALESCE(@StartDateTime, GETDATE()), COALESCE(@EndDateTime, GETDATE()),
         @RowsAffected, @RowsFailed, @Status, LEFT(@ErrorMessage, 4000));
    
    -- Print tree-style output for visual clarity
    DECLARE @StatusIcon VARCHAR(5) = CASE @Status 
        WHEN 'Success' THEN '[OK]' 
        WHEN 'Failed' THEN '[FAIL]' 
        ELSE '[WARNING] ' 
    END;
    
    PRINT '  |- ' + @StatusIcon + ' ' + @TableName + ': ' + @Status 
        + ' (' + CAST(ISNULL(@RowsAffected, 0) AS VARCHAR) + ' rows, ' + @LoadType + ')';
END
GO

PRINT '[OK] Created procedure: [Analytics].[sp_Log_Table_Load]';
GO

-------------------------------------------------------------------------------
-- PROCEDURE 4: sp_Cleanup_Stale_Batches
-- Purpose: Marks orphaned "Running" batches as "Timeout"
-- Schedule this to run daily via SQL Agent Job
-------------------------------------------------------------------------------

IF OBJECT_ID('[Analytics].[sp_Cleanup_Stale_Batches]', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE [Analytics].[sp_Cleanup_Stale_Batches];
END
GO

CREATE PROCEDURE [Analytics].[sp_Cleanup_Stale_Batches]
    @TimeoutHours INT = 24  -- Default: mark as timeout if running for 24+ hours
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Find and mark stale batches
    UPDATE [Analytics].[tbl_ETL_Batch_Log]
    SET Status = 'Timeout',
        End_DateTime = GETDATE(),
        Error_Message = 'Automatically marked as Timeout (no updates for ' 
                      + CAST(@TimeoutHours AS VARCHAR) + ' hours)'
    WHERE Status = 'Running'
      AND DATEDIFF(HOUR, Start_DateTime, GETDATE()) > @TimeoutHours;
    
    DECLARE @RowCount INT = @@ROWCOUNT;
    
    PRINT ' Cleanup Summary:';
    PRINT '   Stale batches marked as Timeout: ' + CAST(@RowCount AS VARCHAR);
    
    IF @RowCount > 0
    BEGIN
        PRINT '   [WARNING]  Review these batches - they may have failed without proper error logging.';
    END
    
    RETURN @RowCount;
END
GO

PRINT '[OK] Created procedure: [Analytics].[sp_Cleanup_Stale_Batches]';
GO

PRINT '';
PRINT '========================================';
PRINT 'ETL Logging Infrastructure Complete';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
PRINT 'Summary:';
PRINT '  [OK] 4 Tables created';
PRINT '  [OK] 4 Stored Procedures created';
PRINT '';
PRINT 'Next Steps:';
PRINT '  1. Test with: EXEC [Analytics].[sp_Start_ETL_Batch] ''Test_Batch'', @BatchID OUTPUT';
PRINT '  2. Create SQL Agent Job to run [Analytics].[sp_Cleanup_Stale_Batches] daily';
PRINT '  3. Integrate into your ETL procedures using TRY...CATCH pattern';
PRINT '';
GO

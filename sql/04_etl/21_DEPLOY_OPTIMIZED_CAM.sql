/*
===============================================================================
DEPLOY OPTIMIZED CAM ASSIGNMENT ACTIVE LOADER
===============================================================================
Purpose: Deploy and test optimized sp_Load_CAM_Assignment_Active
Expected Improvement: 28 minutes → 6-10 minutes (3-5x faster)

BEFORE RUNNING:
1. Review docs/operations/CAM_PERFORMANCE_OPTIMIZATION.md
2. Ensure you have tested in DEV/UAT first
3. Back up current procedure definition (see below)

===============================================================================
*/

USE [Data_Lab_SWL_Live];
GO

PRINT '===============================================================================';
PRINT 'DEPLOYING OPTIMIZED CAM ASSIGNMENT ACTIVE LOADER';
PRINT 'Started: ' + CONVERT(VARCHAR(30), GETDATE(), 121);
PRINT '===============================================================================';
PRINT '';

-- ===============================================================================
-- STEP 1: BACKUP CURRENT PROCEDURE (for rollback if needed)
-- ===============================================================================
PRINT 'STEP 1: Backing up current procedure...';
GO

IF OBJECT_ID('[Analytics].[sp_Load_CAM_Assignment_Active]', 'P') IS NOT NULL
BEGIN
    DECLARE @CurrentDefinition NVARCHAR(MAX);
    SET @CurrentDefinition = OBJECT_DEFINITION(OBJECT_ID('[Analytics].[sp_Load_CAM_Assignment_Active]'));

    PRINT '  Current procedure exists';
    PRINT '  Definition length: ' + CAST(LEN(@CurrentDefinition) AS VARCHAR(20)) + ' characters';
    PRINT '  [INFO] Backup stored in query results (execute separately if needed)';
    PRINT '';

    -- Uncomment below to save backup to a table (optional)
    /*
    IF OBJECT_ID('[Analytics].[tbl_SP_Backup]', 'U') IS NULL
    BEGIN
        CREATE TABLE [Analytics].[tbl_SP_Backup] (
            Backup_ID INT IDENTITY(1,1) PRIMARY KEY,
            Procedure_Name VARCHAR(200),
            Backup_DateTime DATETIME2 DEFAULT GETDATE(),
            Procedure_Definition NVARCHAR(MAX)
        );
    END

    INSERT INTO [Analytics].[tbl_SP_Backup] (Procedure_Name, Procedure_Definition)
    VALUES ('sp_Load_CAM_Assignment_Active', @CurrentDefinition);

    PRINT '  Backup saved to Analytics.tbl_SP_Backup';
    */
END
ELSE
BEGIN
    PRINT '  [WARNING] Current procedure not found (first deployment?)';
END
GO

PRINT '';
PRINT '-------------------------------------------------------------------------------';

-- ===============================================================================
-- STEP 2: DEPLOY OPTIMIZED VERSION
-- ===============================================================================
PRINT 'STEP 2: Deploying optimized procedure...';
PRINT '';
GO

:r ./21_sp_Load_CAM_Assignment_Active_OPTIMIZED.sql

PRINT '';
PRINT '  [OK] Optimized procedure deployed';
PRINT '';

-- ===============================================================================
-- STEP 3: VALIDATE DEPLOYMENT
-- ===============================================================================
PRINT '-------------------------------------------------------------------------------';
PRINT 'STEP 3: Validating deployment...';
GO

IF OBJECT_ID('[Analytics].[sp_Load_CAM_Assignment_Active]', 'P') IS NOT NULL
BEGIN
    PRINT '  [OK] Procedure exists';

    -- Check definition for optimization keywords
    DECLARE @NewDef NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('[Analytics].[sp_Load_CAM_Assignment_Active]'));

    IF @NewDef LIKE '%OPTIMIZATION%'
        PRINT '  [OK] Contains optimization markers';
    ELSE
        PRINT '  [WARNING] Optimization markers not found - may be wrong version';

    IF @NewDef LIKE '%CREATE CLUSTERED INDEX%'
        PRINT '  [OK] Contains temp table indexing';
    ELSE
        PRINT '  [WARNING] Temp table indexing not found';

    IF @NewDef LIKE '%OPTION (RECOMPILE)%'
        PRINT '  [OK] Contains query hints';
    ELSE
        PRINT '  [WARNING] Query hints not found';

    IF @NewDef LIKE '%WITH (TABLOCK)%'
        PRINT '  [OK] Contains TABLOCK hint';
    ELSE
        PRINT '  [WARNING] TABLOCK hint not found';
END
ELSE
BEGIN
    PRINT '  [ERROR] Procedure not found after deployment!';
    RAISERROR('Deployment failed - procedure not created', 16, 1);
END
GO

PRINT '';
PRINT '  [OK] Validation complete';
PRINT '';

-- ===============================================================================
-- STEP 4: READY TO TEST
-- ===============================================================================
PRINT '===============================================================================';
PRINT 'DEPLOYMENT COMPLETE';
PRINT '===============================================================================';
PRINT '';
PRINT 'Next Steps:';
PRINT '';
PRINT '  1. Test the optimized procedure:';
PRINT '     EXEC [Analytics].[sp_Load_CAM_Assignment_Active]';
PRINT '         @FinYearStart = ''2025'',';
PRINT '         @FinancialYear = ''2025/2026'';';
PRINT '';
PRINT '  2. Compare performance with baseline:';
PRINT '     SELECT TOP 2 * FROM [Analytics].[tbl_ETL_Batch_Log]';
PRINT '     WHERE Batch_Name = ''Load_CAM_Assignment_Active''';
PRINT '     ORDER BY Batch_ID DESC;';
PRINT '';
PRINT '  3. Validate data quality:';
PRINT '     SELECT COUNT(*), MIN(Activity_Date), MAX(Activity_Date)';
PRINT '     FROM [Analytics].[tbl_CAM_Assignment_Active];';
PRINT '';
PRINT 'Expected Performance:';
PRINT '  - Baseline: 1682 seconds (28 min) @ 3,069 rows/sec';
PRINT '  - Target:   400-600 seconds (6-10 min) @ 8,500-12,900 rows/sec';
PRINT '  - Expected speedup: 3-5x faster';
PRINT '';
PRINT 'Rollback (if needed):';
PRINT '  :r ./21_sp_Load_CAM_Assignment_Active.sql  -- Original version';
PRINT '';
PRINT '===============================================================================';
GO

-- ===============================================================================
-- OPTIONAL: RUN TEST IMMEDIATELY
-- ===============================================================================
-- Uncomment below to test immediately after deployment

/*
PRINT '';
PRINT '===============================================================================';
PRINT 'RUNNING TEST LOAD...';
PRINT '===============================================================================';
GO

DECLARE @TestStart DATETIME2 = GETDATE();

EXEC [Analytics].[sp_Load_CAM_Assignment_Active]
    @FinYearStart = '2025',
    @FinancialYear = '2025/2026';

DECLARE @TestEnd DATETIME2 = GETDATE();
DECLARE @TestDuration INT = DATEDIFF(SECOND, @TestStart, @TestEnd);

PRINT '';
PRINT '===============================================================================';
PRINT 'TEST COMPLETE';
PRINT '===============================================================================';
PRINT 'Duration: ' + CAST(@TestDuration AS VARCHAR(20)) + ' seconds';
PRINT 'Baseline: 1682 seconds';
PRINT 'Speedup: ' + CAST(CAST(1682.0 / NULLIF(@TestDuration, 0) AS DECIMAL(5,2)) AS VARCHAR(20)) + 'x';
PRINT '';
PRINT 'Performance Summary:';
SELECT TOP 2
    Batch_ID,
    Start_DateTime,
    Duration_Seconds,
    Rows_Inserted,
    Throughput_Rows_Per_Second,
    CASE
        WHEN LAG(Duration_Seconds) OVER (ORDER BY Batch_ID) IS NOT NULL
        THEN CAST((LAG(Duration_Seconds) OVER (ORDER BY Batch_ID) * 1.0 / NULLIF(Duration_Seconds, 0)) AS DECIMAL(5,2))
        ELSE NULL
    END AS Speedup_Factor
FROM Analytics.tbl_ETL_Batch_Log
WHERE Batch_Name = 'Load_CAM_Assignment_Active'
ORDER BY Batch_ID DESC;
GO
*/

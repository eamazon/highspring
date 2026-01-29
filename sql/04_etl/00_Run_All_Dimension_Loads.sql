/**
Script Name:   00_Run_All_Dimension_Loads.sql
Description:   Master orchestration script to load all dimensions in correct order
Author:        Sridhar Peddi
Created:       2026-01-02

Change Log:
  2026-01-02  Sridhar Peddi    Initial creation
  2026-01-15  Sridhar Peddi    Verify OpPlan measure view availability
**/

USE [Data_Lab_SWL_Live];
GO

SET NOCOUNT ON;
GO

PRINT '';
PRINT '==============================================================================';
PRINT 'DIMENSION ETL ORCHESTRATION';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '==============================================================================';
PRINT '';

DECLARE @OverallStartTime DATETIME2 = GETDATE();
DECLARE @StepStartTime DATETIME2;
DECLARE @StepDuration INT;
DECLARE @TotalErrors INT = 0;

-------------------------------------------------------------------------------
-- Step 1: Load Dim_POD (static reference data)
-------------------------------------------------------------------------------

PRINT '------------------------------------------------------------------------------';
PRINT 'Step 1: Loading Dim_POD (NHS Taxonomy)';
PRINT '------------------------------------------------------------------------------';

SET @StepStartTime = GETDATE();

BEGIN TRY
    -- Run the static INSERT script (05_Populate_Dim_POD.sql)
    -- Note: This should be converted to idempotent MERGE or DELETE/INSERT
    PRINT 'Executing: 05_Populate_Dim_POD.sql';
    PRINT '  [WARNING] Currently manual - convert to sp_Load_Dim_POD for automation';
    PRINT '';

        IF OBJECT_ID('[Analytics].[sp_Load_Dim_POD]', 'P') IS NOT NULL
           AND OBJECT_ID('[Analytics].[Staging_POD]', 'U') IS NOT NULL
        BEGIN
            PRINT 'Executing: [Analytics].[sp_Load_Dim_POD] (from [Analytics].[Staging_POD])';
            EXEC [Analytics].[sp_Load_Dim_POD];
        END
        ELSE
        BEGIN
            PRINT '[INFO] Skipping sp_Load_Dim_POD - procedure and/or [Analytics].[Staging_POD] not present.';
        END
    
END TRY
BEGIN CATCH
    SET @TotalErrors = @TotalErrors + 1;
    PRINT '[FAIL] Error loading Dim_POD: ' + ERROR_MESSAGE();
    PRINT '';
END CATCH

SET @StepDuration = DATEDIFF(SECOND, @StepStartTime, GETDATE());
PRINT '  Duration: ' + CAST(@StepDuration AS VARCHAR) + ' seconds';
PRINT '';

-------------------------------------------------------------------------------
-- Step 2: Load Dim_Commissioner
-------------------------------------------------------------------------------

PRINT '------------------------------------------------------------------------------';
PRINT 'Step 2: Loading Dim_Commissioner';
PRINT '------------------------------------------------------------------------------';

SET @StepStartTime = GETDATE();

BEGIN TRY
    EXEC [Analytics].[sp_Load_Dim_Commissioner];
END TRY
BEGIN CATCH
    SET @TotalErrors = @TotalErrors + 1;
    PRINT '[FAIL] Error loading Dim_Commissioner: ' + ERROR_MESSAGE();
    PRINT '';
END CATCH

SET @StepDuration = DATEDIFF(SECOND, @StepStartTime, GETDATE());
PRINT '  Duration: ' + CAST(@StepDuration AS VARCHAR) + ' seconds';
PRINT '';

-------------------------------------------------------------------------------
-- Step 3: Load Dim_GPPractice
-------------------------------------------------------------------------------

PRINT '------------------------------------------------------------------------------';
PRINT 'Step 3: Loading Dim_GPPractice';
PRINT '------------------------------------------------------------------------------';

SET @StepStartTime = GETDATE();

BEGIN TRY
    EXEC [Analytics].[sp_Load_Dim_GPPractice];
END TRY
BEGIN CATCH
    SET @TotalErrors = @TotalErrors + 1;
    PRINT '[FAIL] Error loading Dim_GPPractice: ' + ERROR_MESSAGE();
    PRINT '';
END CATCH

SET @StepDuration = DATEDIFF(SECOND, @StepStartTime, GETDATE());
PRINT '  Duration: ' + CAST(@StepDuration AS VARCHAR) + ' seconds';
PRINT '';

-------------------------------------------------------------------------------
-- Step 3.5: Load Dim_PCN (derived from Dim_GPPractice)
-------------------------------------------------------------------------------

PRINT '------------------------------------------------------------------------------';
PRINT 'Step 3.5: Loading Dim_PCN';
PRINT '------------------------------------------------------------------------------';

SET @StepStartTime = GETDATE();

BEGIN TRY
    EXEC [Analytics].[sp_Load_Dim_PCN];
END TRY
BEGIN CATCH
    SET @TotalErrors = @TotalErrors + 1;
    PRINT '[FAIL] Error loading Dim_PCN: ' + ERROR_MESSAGE();
    PRINT '';
END CATCH

SET @StepDuration = DATEDIFF(SECOND, @StepStartTime, GETDATE());
PRINT '  Duration: ' + CAST(@StepDuration AS VARCHAR) + ' seconds';
PRINT '';

-------------------------------------------------------------------------------
-- Step 4: Load Dim_LSOA
-------------------------------------------------------------------------------

PRINT '------------------------------------------------------------------------------';
PRINT 'Step 4: Loading Dim_LSOA';
PRINT '------------------------------------------------------------------------------';

SET @StepStartTime = GETDATE();

BEGIN TRY
    EXEC [Analytics].[sp_Load_Dim_LSOA];
END TRY
BEGIN CATCH
    SET @TotalErrors = @TotalErrors + 1;
    PRINT '[FAIL] Error loading Dim_LSOA: ' + ERROR_MESSAGE();
    PRINT '';
END CATCH

SET @StepDuration = DATEDIFF(SECOND, @StepStartTime, GETDATE());
PRINT '  Duration: ' + CAST(@StepDuration AS VARCHAR) + ' seconds';
PRINT '';

-------------------------------------------------------------------------------
-- Step 5: Load Dim_CAM_Service_Category
-------------------------------------------------------------------------------

PRINT '------------------------------------------------------------------------------';
PRINT 'Step 5: Loading Dim_CAM_Service_Category';
PRINT '------------------------------------------------------------------------------';

SET @StepStartTime = GETDATE();

BEGIN TRY
    EXEC [Analytics].[sp_Load_Dim_CAM_Service_Category];
END TRY
BEGIN CATCH
    SET @TotalErrors = @TotalErrors + 1;
    PRINT '[FAIL] Error loading Dim_CAM_Service_Category: ' + ERROR_MESSAGE();
    PRINT '';
END CATCH

SET @StepDuration = DATEDIFF(SECOND, @StepStartTime, GETDATE());
PRINT '  Duration: ' + CAST(@StepDuration AS VARCHAR) + ' seconds';
PRINT '';

-------------------------------------------------------------------------------
-- Step 6: Load Dim_CAM_Assignment_Reason
-------------------------------------------------------------------------------

PRINT '------------------------------------------------------------------------------';
PRINT 'Step 6: Loading Dim_CAM_Assignment_Reason';
PRINT '------------------------------------------------------------------------------';

SET @StepStartTime = GETDATE();

BEGIN TRY
    EXEC [Analytics].[sp_Load_Dim_CAM_Assignment_Reason];
END TRY
BEGIN CATCH
    SET @TotalErrors = @TotalErrors + 1;
    PRINT '[FAIL] Error loading Dim_CAM_Assignment_Reason: ' + ERROR_MESSAGE();
    PRINT '';
END CATCH

SET @StepDuration = DATEDIFF(SECOND, @StepStartTime, GETDATE());
PRINT '  Duration: ' + CAST(@StepDuration AS VARCHAR) + ' seconds';
PRINT '';

-- Step 7: Dim_Patient is opt-in (current snapshot only)
-- Run [Analytics].[sp_Load_Dim_Patient] explicitly if required.

-------------------------------------------------------------------------------
-- Step 8: Verify Dim_Measures_Catalogue (VIEW)
-------------------------------------------------------------------------------

PRINT '------------------------------------------------------------------------------';
PRINT 'Step 8: Verifying Dim_Measures_Catalogue (VIEW)';
PRINT '------------------------------------------------------------------------------';

BEGIN TRY
    DECLARE @MeasureCount INT;
    SELECT @MeasureCount = COUNT(*) FROM [Analytics].[vw_Dim_Measures_Catalogue];
    PRINT '  [OK] Dim_Measures_Catalogue accessible';
    PRINT '  Active measures: ' + CAST(@MeasureCount AS VARCHAR);
    PRINT '';
END TRY
BEGIN CATCH
    SET @TotalErrors = @TotalErrors + 1;
    PRINT '[FAIL] Error accessing Dim_Measures_Catalogue: ' + ERROR_MESSAGE();
    PRINT '';
END CATCH

-------------------------------------------------------------------------------
-- Step 8.1: Verify Dim_OpPlan_Measure (VIEW)
-------------------------------------------------------------------------------

PRINT '------------------------------------------------------------------------------';
PRINT 'Step 8.1: Verifying Dim_OpPlan_Measure (VIEW)';
PRINT '------------------------------------------------------------------------------';

BEGIN TRY
    DECLARE @OpPlanMeasureCount INT;
    SELECT @OpPlanMeasureCount = COUNT(*) FROM [Analytics].[vw_Dim_OpPlan_Measure];
    PRINT '  [OK] Dim_OpPlan_Measure accessible';
    PRINT '  Measures: ' + CAST(@OpPlanMeasureCount AS VARCHAR);
    PRINT '';
END TRY
BEGIN CATCH
    SET @TotalErrors = @TotalErrors + 1;
    PRINT '[FAIL] Error accessing Dim_OpPlan_Measure: ' + ERROR_MESSAGE();
    PRINT '';
END CATCH

-------------------------------------------------------------------------------
-- Summary
-------------------------------------------------------------------------------

DECLARE @TotalDuration INT = DATEDIFF(SECOND, @OverallStartTime, GETDATE());

PRINT '';
PRINT '==============================================================================';
PRINT 'DIMENSION ETL COMPLETE';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '==============================================================================';
PRINT '';
PRINT 'Summary:';
PRINT '  Total Duration: ' + CAST(@TotalDuration AS VARCHAR) + ' seconds';
PRINT '  Total Errors: ' + CAST(@TotalErrors AS VARCHAR);
PRINT '';

IF @TotalErrors = 0
BEGIN
    PRINT '[OK] All dimensions loaded successfully!';
    PRINT '';
    PRINT 'Dimension Row Counts:';
    SELECT 'Dim_POD' AS Dimension, COUNT(*) AS Row_Count FROM [Analytics].[tbl_Dim_POD]
    UNION ALL
    SELECT 'Dim_Commissioner', COUNT(*) FROM [Analytics].[tbl_Dim_Commissioner]
    UNION ALL
    SELECT 'Dim_PCN', COUNT(*) FROM [Analytics].[tbl_Dim_PCN]
    UNION ALL
    SELECT 'Dim_GPPractice', COUNT(*) FROM [Analytics].[tbl_Dim_GPPractice]
    UNION ALL
    SELECT 'Dim_LSOA', COUNT(*) FROM [Analytics].[tbl_Dim_LSOA]
    UNION ALL
    SELECT 'Dim_Measures_Catalogue', COUNT(*) FROM [Analytics].[vw_Dim_Measures_Catalogue]
    UNION ALL
    SELECT 'Dim_OpPlan_Measure', COUNT(*) FROM [Analytics].[vw_Dim_OpPlan_Measure]
    ORDER BY Dimension;
END
ELSE
BEGIN
    PRINT '[WARNING] ETL completed with ' + CAST(@TotalErrors AS VARCHAR) + ' error(s)';
    PRINT 'Review ETL_Batch_Log for details:';
    PRINT '';
    SELECT TOP 5 * 
    FROM [Analytics].[tbl_ETL_Batch_Log]
    WHERE Status = 'Failed'
    ORDER BY Start_DateTime DESC;
END

PRINT '';
PRINT 'Next Steps:';
PRINT '  1. Review ETL logs: SELECT * FROM [Analytics].[tbl_ETL_Batch_Log] ORDER BY Start_DateTime DESC';
PRINT '  2. Schedule this script via SQL Agent for weekly refresh';
PRINT '  3. Proceed to Week 2: Fact table creation';
PRINT '';
GO

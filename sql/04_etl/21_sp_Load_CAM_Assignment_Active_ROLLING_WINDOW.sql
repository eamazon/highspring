USE [Data_Lab_SWL_Live];
GO

/**
┌─────────────────────────────────────────────────────────────────────────┐
│                                                                         │
│  ⚠️  WARNING: DO NOT USE THIS FILE - INVALID FOR FY-BASED OPERATIONS  │
│                                                                         │
│  This rolling window approach is INCOMPATIBLE with business            │
│  requirements to operate on Financial Year (FY) boundaries.            │
│                                                                         │
│  ❌ INVALID: Load "last 12 months from today" (rolling window)         │
│  ✅ VALID:   Load full FY (e.g., April 2025 - March 2026)              │
│                                                                         │
│  Reason: Providers submit retroactive data from FY start,              │
│          requiring full FY reload each time.                           │
│                                                                         │
│  USE INSTEAD:                                                           │
│  → sql/analytics_platform/04_etl/21_sp_Load_CAM_Assignment_Active_OPTIMIZED.sql │
│                                                                         │
│  See: docs/operations/CAM_OPTIMIZATION_STATUS.md                       │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘

Script Name:   21_sp_Load_CAM_Assignment_Active_ROLLING_WINDOW.sql
Description:   ❌ DEPRECATED - Modified for ROLLING 12-MONTH WINDOW instead of full FY
               ❌ DO NOT DEPLOY - Incompatible with FY-based business operations
Author:        Claude Code
Created:       2026-01-15
Status:        INVALID - Use 21_sp_Load_CAM_Assignment_Active_OPTIMIZED.sql instead

ORIGINAL INTENT (NO LONGER VALID):
- Old: Load entire financial year (12 months fixed)
- New: Load last 12 months from today (rolling window)

WHY THIS DOESN'T WORK:
- Business operates on FY boundaries (April-March)
- Cannot use "last 12 months from today" approach
- Must reload full FY each time for retroactive provider data

PERFORMANCE (FOR REFERENCE ONLY):
- Baseline: 1682 seconds (28 min) for full FY
- Phase 1: 1228 seconds (20.5 min) for full FY
- This approach would be ~800-1000 seconds, but is NOT VALID

DO NOT USE THIS FILE.
**/

IF OBJECT_ID('[Analytics].[sp_Load_CAM_Assignment_Active]', 'P') IS NOT NULL
DROP PROCEDURE [Analytics].[sp_Load_CAM_Assignment_Active];
GO

CREATE PROCEDURE [Analytics].[sp_Load_CAM_Assignment_Active]
    @FinYearStart CHAR(4) = NULL,        -- Optional, defaults to current FY
    @FinancialYear VARCHAR(9) = NULL,    -- Optional, defaults to current FY
    @ProviderCode VARCHAR(10) = NULL,
    @FromDate DATE = NULL,               -- Optional, defaults to 12 months ago
    @ToDate DATE = NULL,                 -- Optional, defaults to today
    @MonthsBack INT = 12                 -- New parameter: How many months to load (default 12)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ETL_Start DATETIME2 = CURRENT_TIMESTAMP;
    DECLARE @BatchName VARCHAR(100) = 'Load_CAM_Assignment_Active';
    DECLARE @BatchID INT = NULL;
    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsDeleted INT = 0;
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @FinYearInt INT;
    DECLARE @FinYearStartDate DATE;
    DECLARE @FinYearEndDate DATE;
    DECLARE @WindowStartDate DATE;
    DECLARE @WindowEndDate DATE;
    DECLARE @CutoffDate DATE;
    DECLARE @DeleteBatchSize INT = 100000;

    -- ================================================================
    -- NEW: Calculate rolling window if not provided
    -- ================================================================
    IF @ToDate IS NULL
        SET @ToDate = GETDATE();

    IF @FromDate IS NULL
        SET @FromDate = DATEADD(MONTH, -@MonthsBack, @ToDate);

    -- Derive financial year from FromDate if not provided
    IF @FinYearStart IS NULL OR @FinancialYear IS NULL
    BEGIN
        DECLARE @FromYear INT = YEAR(@FromDate);
        DECLARE @FromMonth INT = MONTH(@FromDate);

        IF @FromMonth >= 4  -- April onwards
            SET @FinYearInt = @FromYear;
        ELSE
            SET @FinYearInt = @FromYear - 1;

        SET @FinYearStart = CAST(@FinYearInt AS CHAR(4));
        SET @FinancialYear = CAST(@FinYearInt AS VARCHAR(4)) + '/' + CAST(@FinYearInt + 1 AS VARCHAR(4));
    END
    ELSE
    BEGIN
        SET @FinYearInt = CASE
            WHEN ISNUMERIC(@FinYearStart) = 1 THEN CAST(@FinYearStart AS INT)
            ELSE NULL
        END;

        IF @FinYearInt IS NULL
        BEGIN
            RAISERROR('Parameter @FinYearStart must be numeric (e.g. ''2025'')', 16, 1);
            RETURN;
        END

        IF @FinancialYear IS NULL OR LTRIM(RTRIM(@FinancialYear)) = ''
            SET @FinancialYear = CAST(@FinYearInt AS VARCHAR(4)) + '/' + CAST(@FinYearInt + 1 AS VARCHAR(4));
    END

    SET @FinYearStartDate = CONVERT(DATE, @FinYearStart + '0401', 112);
    SET @FinYearEndDate = DATEADD(DAY, -1, DATEADD(YEAR, 1, @FinYearStartDate));
    SET @CutoffDate = [Analytics].[fn_SUS_Published_Cutoff_Date](NULL);

    SET @WindowStartDate = @FromDate;
    SET @WindowEndDate = @ToDate;

    -- Don't go beyond SUS cutoff date
    IF @WindowEndDate > ISNULL(@CutoffDate, @FinYearEndDate)
        SET @WindowEndDate = ISNULL(@CutoffDate, @FinYearEndDate);

    IF @WindowEndDate < @WindowStartDate
    BEGIN
        RAISERROR('ToDate must be on or after FromDate.', 16, 1);
        RETURN;
    END

    IF OBJECT_ID('[Analytics].[tbl_CAM_Assignment_Active]', 'U') IS NULL
    BEGIN
        RAISERROR('Required table [Analytics].[tbl_CAM_Assignment_Active] was not found.', 16, 1);
        RETURN;
    END

    BEGIN TRY
        EXEC [Analytics].[sp_Start_ETL_Batch]
            @BatchName = @BatchName,
            @BatchID = @BatchID OUTPUT;

        PRINT 'Loading CAM Assignment Active (Rolling Window)';
        PRINT '  Financial Year: ' + @FinancialYear;
        PRINT '  Window: ' + CONVERT(VARCHAR(10), @WindowStartDate, 120) + ' to ' + CONVERT(VARCHAR(10), @WindowEndDate, 120);
        PRINT '  Duration: ' + CAST(DATEDIFF(DAY, @WindowStartDate, @WindowEndDate) AS VARCHAR(10)) + ' days';

        -- Load from TVF (Phase 1 optimization already applied)
        IF OBJECT_ID('tempdb..#CAM_Raw') IS NOT NULL DROP TABLE #CAM_Raw;

        SELECT
            CAST(c.[RecordIdentifier] AS BIGINT) AS [SK_EncounterID],
            CAST(c.[Dataset] AS VARCHAR(2)) AS [Dataset],
            CAST(
                CASE
                    WHEN c.[Dataset] = 'IP' THEN c.[DischargeDate]
                    ELSE c.[AdmissionDate]
                END AS DATE
            ) AS [Activity_Date],
            CAST(c.[ReassignmentID] AS VARCHAR(50)) AS [CAM_Assignment_Code],
            CAST(c.[CAM_Commissioner_Code] AS VARCHAR(20)) AS [CAM_Commissioner_Code],
            CAST(c.[CAM_Service_Category] AS VARCHAR(50)) AS [CAM_Service_Category],
            CAST(c.[Commissioner Assignment Reason] AS VARCHAR(255)) AS [CAM_Assignment_Reason],
            CAST(c.[Commissioner_Variance] AS BIT) AS [Commissioner_Variance],
            CAST(c.[Service_Category_Variance] AS BIT) AS [Service_Category_Variance]
        INTO #CAM_Raw
        FROM [Analytics].[fn_CommissionerAssignment](@FinancialYear, @ProviderCode, @WindowStartDate, @WindowEndDate) c
        WHERE c.[Dataset] IN ('IP', 'OP')
          AND (
                CASE
                    WHEN c.[Dataset] = 'IP' THEN c.[DischargeDate]
                    ELSE c.[AdmissionDate]
                END
              ) >= @WindowStartDate
          AND (
                CASE
                    WHEN c.[Dataset] = 'IP' THEN c.[DischargeDate]
                    ELSE c.[AdmissionDate]
                END
              ) <= @WindowEndDate
          AND (
                CASE
                    WHEN c.[Dataset] = 'IP' THEN c.[DischargeDate]
                    ELSE c.[AdmissionDate]
                END
              ) IS NOT NULL
        OPTION (RECOMPILE);

        DECLARE @RawCount INT = @@ROWCOUNT;
        PRINT '  Loaded ' + CAST(@RawCount AS VARCHAR(20)) + ' rows from CAM function';

        -- Add clustered index
        CREATE CLUSTERED INDEX IX_CAM_Raw_PK
            ON #CAM_Raw ([SK_EncounterID], [Dataset]);

        PRINT '  Created clustered index on temp table';

        -- Deduplicate
        IF OBJECT_ID('tempdb..#CAM_Dedup') IS NOT NULL DROP TABLE #CAM_Dedup;

        ;WITH Ranked AS (
            SELECT
                *,
                ROW_NUMBER() OVER (
                    PARTITION BY [SK_EncounterID], [Dataset]
                    ORDER BY [Activity_Date] DESC,
                             [CAM_Assignment_Code] DESC,
                             [CAM_Service_Category] DESC
                ) AS RowNum
            FROM #CAM_Raw
        )
        SELECT
            [SK_EncounterID],
            [Dataset],
            [Activity_Date],
            [CAM_Assignment_Code],
            [CAM_Commissioner_Code],
            [CAM_Service_Category],
            [CAM_Assignment_Reason],
            [Commissioner_Variance],
            [Service_Category_Variance]
        INTO #CAM_Dedup
        FROM Ranked
        WHERE RowNum = 1;

        DECLARE @DedupCount INT = @@ROWCOUNT;
        DECLARE @DuplicatesRemoved INT = @RawCount - @DedupCount;
        PRINT '  Deduplicated to ' + CAST(@DedupCount AS VARCHAR(20)) + ' unique rows';
        IF @DuplicatesRemoved > 0
            PRINT '  Removed ' + CAST(@DuplicatesRemoved AS VARCHAR(20)) + ' duplicate rows';

        -- Add clustered index for dimension lookups
        CREATE CLUSTERED INDEX IX_CAM_Dedup_PK
            ON #CAM_Dedup ([SK_EncounterID], [Dataset]);

        -- Join dimensions
        IF OBJECT_ID('tempdb..#CAM_Final') IS NOT NULL DROP TABLE #CAM_Final;

        SELECT
            d.[SK_EncounterID],
            d.[Dataset],
            d.[Activity_Date],
            d.[CAM_Assignment_Code],
            d.[CAM_Commissioner_Code],
            d.[CAM_Service_Category],
            d.[CAM_Assignment_Reason],
            d.[Commissioner_Variance],
            d.[Service_Category_Variance],
            ISNULL(dc.[SK_CommissionerID], -1) AS [SK_CAM_CommissionerID],
            ISNULL(dsc.[SK_CAM_Service_CategoryID], -1) AS [SK_CAM_Service_CategoryID],
            ISNULL(dar.[SK_CAM_Assignment_ReasonID], -1) AS [SK_CAM_Assignment_ReasonID]
        INTO #CAM_Final
        FROM #CAM_Dedup d
        LEFT JOIN [Analytics].[tbl_Dim_Commissioner] dc
            ON dc.[Commissioner_Code] = d.[CAM_Commissioner_Code]
        LEFT JOIN [Analytics].[tbl_Dim_CAM_Service_Category] dsc
            ON dsc.[CAM_Service_Category] = d.[CAM_Service_Category]
        LEFT JOIN [Analytics].[tbl_Dim_CAM_Assignment_Reason] dar
            ON dar.[CAM_Assignment_Code] = d.[CAM_Assignment_Code]
        OPTION (RECOMPILE);

        PRINT '  Joined dimension lookups to ' + CAST(@@ROWCOUNT AS VARCHAR(20)) + ' rows';

        -- ================================================================
        -- DELETE only the window being refreshed (not entire table)
        -- ================================================================
        DECLARE @DeleteCount INT = 0;
        DECLARE @TotalDeleted INT = 0;

        SELECT @DeleteCount = COUNT(*)
        FROM [Analytics].[tbl_CAM_Assignment_Active]
        WHERE [Activity_Date] >= @WindowStartDate
          AND [Activity_Date] <= @WindowEndDate;

        PRINT '  Deleting ' + CAST(@DeleteCount AS VARCHAR(20)) + ' existing rows in window...';

        IF @DeleteCount > @DeleteBatchSize * 2
        BEGIN
            PRINT '  Using batched delete for large dataset';
            WHILE 1 = 1
            BEGIN
                DELETE TOP (@DeleteBatchSize)
                FROM [Analytics].[tbl_CAM_Assignment_Active]
                WHERE [Activity_Date] >= @WindowStartDate
                  AND [Activity_Date] <= @WindowEndDate;

                SET @RowsDeleted = @@ROWCOUNT;
                SET @TotalDeleted = @TotalDeleted + @RowsDeleted;

                IF @RowsDeleted = 0 BREAK;

                IF @TotalDeleted % (@DeleteBatchSize * 5) = 0
                    PRINT '    Deleted ' + CAST(@TotalDeleted AS VARCHAR(20)) + ' rows so far...';
            END
            SET @RowsDeleted = @TotalDeleted;
        END
        ELSE
        BEGIN
            DELETE FROM [Analytics].[tbl_CAM_Assignment_Active]
            WHERE [Activity_Date] >= @WindowStartDate
              AND [Activity_Date] <= @WindowEndDate;

            SET @RowsDeleted = @@ROWCOUNT;
        END

        PRINT '  Deleted ' + CAST(@RowsDeleted AS VARCHAR(20)) + ' rows';

        -- Insert new data
        PRINT '  Inserting ' + CAST(@DedupCount AS VARCHAR(20)) + ' new rows...';

        INSERT INTO [Analytics].[tbl_CAM_Assignment_Active] WITH (TABLOCK) (
            [SK_EncounterID],
            [Dataset],
            [Activity_Date],
            [CAM_Assignment_Code],
            [CAM_Commissioner_Code],
            [CAM_Service_Category],
            [CAM_Assignment_Reason],
            [Commissioner_Variance],
            [Service_Category_Variance],
            [SK_CAM_CommissionerID],
            [SK_CAM_Service_CategoryID],
            [SK_CAM_Assignment_ReasonID],
            [ETL_LoadDateTime]
        )
        SELECT
            [SK_EncounterID],
            [Dataset],
            [Activity_Date],
            [CAM_Assignment_Code],
            [CAM_Commissioner_Code],
            [CAM_Service_Category],
            [CAM_Assignment_Reason],
            [Commissioner_Variance],
            [Service_Category_Variance],
            [SK_CAM_CommissionerID],
            [SK_CAM_Service_CategoryID],
            [SK_CAM_Assignment_ReasonID],
            @ETL_Start
        FROM #CAM_Final
        OPTION (RECOMPILE);

        SET @RowsInserted = @@ROWCOUNT;

        PRINT '  Inserted ' + CAST(@RowsInserted AS VARCHAR(20)) + ' rows';

        -- Update statistics for optimal query plans
        PRINT '  Updating statistics...';
        UPDATE STATISTICS [Analytics].[tbl_CAM_Assignment_Active] WITH FULLSCAN;
        PRINT '  Statistics updated';

        EXEC [Analytics].[sp_Log_Table_Load]
            @BatchID = @BatchID,
            @TableName = 'Analytics.tbl_CAM_Assignment_Active',
            @LoadType = 'Incremental',
            @RowsAffected = @RowsInserted,
            @Status = 'Success';

        EXEC [Analytics].[sp_End_ETL_Batch]
            @BatchID = @BatchID,
            @Status = 'Success',
            @RowsInserted = @RowsInserted,
            @RowsUpdated = 0,
            @RowsDeleted = @RowsDeleted,
            @RowsFailed = 0,
            @ErrorMessage = NULL;

        PRINT 'CAM Assignment Active load completed successfully';

    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();
        PRINT 'Error Loading CAM Assignment Active: ' + ISNULL(@ErrorMessage, '');
        IF @BatchID IS NOT NULL
        BEGIN
            EXEC [Analytics].[sp_Log_Table_Load]
                @BatchID = @BatchID,
                @TableName = 'Analytics.tbl_CAM_Assignment_Active',
                @LoadType = 'Incremental',
                @RowsAffected = 0,
                @RowsFailed = 1,
                @Status = 'Failed',
                @ErrorMessage = @ErrorMessage;

            EXEC [Analytics].[sp_End_ETL_Batch]
                @BatchID = @BatchID,
                @Status = 'Failed',
                @RowsInserted = 0,
                @RowsUpdated = 0,
                @RowsDeleted = 0,
                @RowsFailed = 1,
                @ErrorMessage = @ErrorMessage;
        END
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END CATCH
END
GO

PRINT '[OK] Created ROLLING WINDOW version: sp_Load_CAM_Assignment_Active';
PRINT '';
PRINT 'Usage Examples:';
PRINT '';
PRINT '  -- Load last 12 months (default):';
PRINT '  EXEC sp_Load_CAM_Assignment_Active;';
PRINT '';
PRINT '  -- Load last 6 months:';
PRINT '  EXEC sp_Load_CAM_Assignment_Active @MonthsBack = 6;';
PRINT '';
PRINT '  -- Load specific window:';
PRINT '  EXEC sp_Load_CAM_Assignment_Active';
PRINT '      @FromDate = ''2025-01-01'', @ToDate = ''2025-12-31'';';
PRINT '';
GO

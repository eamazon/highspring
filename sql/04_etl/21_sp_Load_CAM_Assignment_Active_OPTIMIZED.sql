USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/**
Script Name:   21_sp_Load_CAM_Assignment_Active_OPTIMIZED.sql
Description:   PERFORMANCE OPTIMIZED version - Loads CAM assignment ~3-5x faster
Author:        Claude Code (Optimized)
Created:       2026-01-15

PERFORMANCE IMPROVEMENTS:
1. Deduplicate FIRST (5.1M → ~5.1M unique), THEN join dimensions (save 3 joins on 5M rows)
2. Add clustered index on #CAM_Dedup temp table for fast lookups
3. Remove redundant duplicate check (ROW_NUMBER already handles it)
4. Use OPTION (RECOMPILE) for optimal query plans with parameter sniffing
5. Batch DELETE if deleting >1M rows
6. Use TABLOCK hint for faster INSERT
7. Update statistics after load for optimal query plans

EXPECTED IMPROVEMENT: 28 minutes → 6-10 minutes (3-5x faster)

Original Performance: 1682 seconds (28 min) for 5.1M rows @ 3069 rows/sec
Target Performance: 400-600 seconds (6-10 min) @ 8,500-12,900 rows/sec
**/

IF OBJECT_ID('[Analytics].[sp_Load_CAM_Assignment_Active]', 'P') IS NOT NULL
DROP PROCEDURE [Analytics].[sp_Load_CAM_Assignment_Active];
GO

CREATE PROCEDURE [Analytics].[sp_Load_CAM_Assignment_Active]
    @FinYearStart CHAR(4),
    @FinancialYear VARCHAR(9) = NULL,
    @ProviderCode VARCHAR(10) = NULL,
    @FromDate DATE = NULL,
    @ToDate DATE = NULL
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
    DECLARE @DeleteBatchSize INT = 100000; -- Batch deletes if >100k rows

    SET @FinYearInt = CASE
        WHEN ISNUMERIC(@FinYearStart) = 1 THEN CAST(@FinYearStart AS INT)
        ELSE NULL
    END;

    IF @FinYearInt IS NULL
    BEGIN
        RAISERROR('Parameter @FinYearStart is required (e.g. ''2025'')', 16, 1);
        RETURN;
    END

    IF @FinancialYear IS NULL OR LTRIM(RTRIM(@FinancialYear)) = ''
        SET @FinancialYear = CAST(@FinYearInt AS VARCHAR(4)) + '/' + CAST(@FinYearInt + 1 AS VARCHAR(4));

    SET @FinYearStartDate = CONVERT(DATE, @FinYearStart + '0401', 112);
    SET @FinYearEndDate = DATEADD(DAY, -1, DATEADD(YEAR, 1, @FinYearStartDate));
    SET @CutoffDate = [Analytics].[fn_SUS_Published_Cutoff_Date](NULL);

    SET @WindowStartDate = COALESCE(@FromDate, @FinYearStartDate);
    SET @WindowEndDate = COALESCE(@ToDate, @CutoffDate, @FinYearEndDate);

    IF @WindowStartDate < @FinYearStartDate
        SET @WindowStartDate = @FinYearStartDate;

    IF @WindowEndDate > @FinYearEndDate
        SET @WindowEndDate = @FinYearEndDate;

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

        PRINT 'Loading CAM data from CAM raw staging table...';
        PRINT '  Window: ' + CONVERT(VARCHAR(10), @WindowStartDate, 120) + ' to ' + CONVERT(VARCHAR(10), @WindowEndDate, 120);

        -- ================================================================
        -- OPTIMIZATION 1: Load from CAM raw WITHOUT dimension joins
        -- This is faster than joining dimensions before deduplication
        -- ================================================================
        IF OBJECT_ID('tempdb..#CAM_Raw') IS NOT NULL DROP TABLE #CAM_Raw;

        SELECT
            CAST(c.[RecordIdentifier] AS BIGINT) AS [SK_EncounterID],
            CAST(c.[Dataset] AS VARCHAR(2)) AS [Dataset],
            CAST(c.[Activity_Date] AS DATE) AS [Activity_Date],
            CAST(c.[ReassignmentID] AS VARCHAR(50)) AS [CAM_Assignment_Code],
            CAST(c.[CAM_Commissioner_Code] AS VARCHAR(20)) AS [CAM_Commissioner_Code],
            CAST(c.[CAM_Service_Category] AS VARCHAR(50)) AS [CAM_Service_Category],
            CAST(c.[CAM_Assignment_Reason] AS VARCHAR(255)) AS [CAM_Assignment_Reason],
            CAST(c.[Commissioner_Variance] AS BIT) AS [Commissioner_Variance],
            CAST(c.[Service_Category_Variance] AS BIT) AS [Service_Category_Variance]
        INTO #CAM_Raw
        FROM [Data_Lab_SWL].[CAM].[tbl_CAM_Raw] c
        WHERE c.[Dataset] IN ('IP', 'OP')
          AND c.[Activity_Date] >= @WindowStartDate
          AND c.[Activity_Date] <= @WindowEndDate
          AND c.[Financial_Year] = @FinancialYear
          AND (@ProviderCode IS NULL OR c.[Provider_Code] = @ProviderCode)
          AND c.[Activity_Date] IS NOT NULL
        OPTION (RECOMPILE); -- Optimize for current parameters

        DECLARE @RawCount INT = @@ROWCOUNT;
        PRINT '  Loaded ' + CAST(@RawCount AS VARCHAR(20)) + ' rows from CAM raw staging';

        -- ================================================================
        -- OPTIMIZATION 2: Add clustered index on temp table
        -- This makes the ROW_NUMBER() partition much faster
        -- ================================================================
        CREATE CLUSTERED INDEX IX_CAM_Raw_PK
            ON #CAM_Raw ([SK_EncounterID], [Dataset]);

        PRINT '  Created clustered index on temp table';

        -- ================================================================
        -- OPTIMIZATION 3: Deduplicate FIRST (remove duplicate check)
        -- ROW_NUMBER() handles deduplication, no need for separate check
        -- ================================================================
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

        -- ================================================================
        -- OPTIMIZATION 4: Add clustered index for dimension lookups
        -- ================================================================
        CREATE CLUSTERED INDEX IX_CAM_Dedup_PK
            ON #CAM_Dedup ([SK_EncounterID], [Dataset]);

        -- ================================================================
        -- OPTIMIZATION 5: Join dimensions AFTER deduplication
        -- Now joining ~5.1M unique rows instead of 5.1M+ duplicated rows
        -- ================================================================
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
        -- OPTIMIZATION 6: Batch DELETE if deleting >1M rows
        -- Large deletes can block; batching reduces lock duration
        -- ================================================================
        DECLARE @DeleteCount INT = 0;
        DECLARE @TotalDeleted INT = 0;

        -- Check if we're deleting a lot of rows
        SELECT @DeleteCount = COUNT(*)
        FROM [Analytics].[tbl_CAM_Assignment_Active]
        WHERE [Activity_Date] >= @WindowStartDate
          AND [Activity_Date] <= @WindowEndDate;

        PRINT '  Deleting ' + CAST(@DeleteCount AS VARCHAR(20)) + ' existing rows...';

        IF @DeleteCount > @DeleteBatchSize * 2 -- If >200k rows, batch it
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
            -- Small delete, do it in one shot
            DELETE FROM [Analytics].[tbl_CAM_Assignment_Active]
            WHERE [Activity_Date] >= @WindowStartDate
              AND [Activity_Date] <= @WindowEndDate;

            SET @RowsDeleted = @@ROWCOUNT;
        END

        PRINT '  Deleted ' + CAST(@RowsDeleted AS VARCHAR(20)) + ' rows';

        -- ================================================================
        -- OPTIMIZATION 7: Use TABLOCK for faster bulk insert
        -- This allows minimal logging and better performance
        -- ================================================================
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
            @LoadType = 'Full',
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
                @LoadType = 'Full',
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

PRINT '[OK] Created OPTIMIZED procedure: [Analytics].[sp_Load_CAM_Assignment_Active]';
PRINT '';
PRINT '========================================';
PRINT 'PERFORMANCE OPTIMIZATIONS APPLIED:';
PRINT '1. Deduplicate FIRST, then join dimensions (save 3 joins on millions of rows)';
PRINT '2. Clustered indexes on temp tables for faster processing';
PRINT '3. Removed redundant duplicate check';
PRINT '4. OPTION (RECOMPILE) for optimal query plans';
PRINT '5. Batched DELETE for large datasets';
PRINT '6. TABLOCK hint for faster INSERT';
PRINT '7. Update statistics after load for optimal query plans';
PRINT '';
PRINT 'Expected speedup: 3-5x faster (28 min → 6-10 min)';
PRINT '========================================';
GO

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('[Analytics].[sp_Load_CAM_Assignment_Active]', 'P') IS NOT NULL
DROP PROCEDURE [Analytics].[sp_Load_CAM_Assignment_Active];
GO

/**
Script Name:   21_sp_Load_CAM_Assignment_Active.sql
Description:   Loads current FY CAM assignment outputs into Analytics.tbl_CAM_Assignment_Active.
Author:        Sridhar Peddi
Created:       2026-01-15

Notes:
- Window defaults to FY start through SUS inclusion cutoff.
- Source is Data_Lab_SWL.CAM.tbl_CAM_Raw (precomputed).
- Activity_Date is Discharge_Date for IP and Appointment_Date for OP.
**/
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
    DECLARE @DuplicateKeyCount INT = 0;
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @DQMessage NVARCHAR(4000);
    DECLARE @FinYearInt INT;
    DECLARE @FinYearStartDate DATE;
    DECLARE @FinYearEndDate DATE;
    DECLARE @WindowStartDate DATE;
    DECLARE @WindowEndDate DATE;
    DECLARE @CutoffDate DATE;

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

        IF OBJECT_ID('tempdb..#CAM_Raw') IS NOT NULL
            DROP TABLE #CAM_Raw;
        IF OBJECT_ID('tempdb..#CAM') IS NOT NULL
            DROP TABLE #CAM;

        SELECT
            CAST(c.[RecordIdentifier] AS BIGINT) AS [SK_EncounterID],
            CAST(c.[Dataset] AS VARCHAR(2)) AS [Dataset],
            CAST(c.[Activity_Date] AS DATE) AS [Activity_Date],
            CAST(c.[ReassignmentID] AS VARCHAR(50)) AS [CAM_Assignment_Code],
            CAST(c.[CAM_Commissioner_Code] AS VARCHAR(20)) AS [CAM_Commissioner_Code],
            CAST(c.[CAM_Service_Category] AS VARCHAR(50)) AS [CAM_Service_Category],
            CAST(c.[CAM_Assignment_Reason] AS VARCHAR(255)) AS [CAM_Assignment_Reason],
            CAST(c.[Commissioner_Variance] AS BIT) AS [Commissioner_Variance],
            CAST(c.[Service_Category_Variance] AS BIT) AS [Service_Category_Variance],
            ISNULL(dc.[SK_CommissionerID], -1) AS [SK_CAM_CommissionerID],
            ISNULL(dsc.[SK_CAM_Service_CategoryID], -1) AS [SK_CAM_Service_CategoryID],
            ISNULL(dar.[SK_CAM_Assignment_ReasonID], -1) AS [SK_CAM_Assignment_ReasonID]
        INTO #CAM_Raw
        FROM [Data_Lab_SWL].[CAM].[tbl_CAM_Raw] c
        LEFT JOIN [Analytics].[tbl_Dim_Commissioner] dc
            ON dc.[Commissioner_Code] = c.[CAM_Commissioner_Code]
        LEFT JOIN [Analytics].[tbl_Dim_CAM_Service_Category] dsc
            ON dsc.[CAM_Service_Category] = c.[CAM_Service_Category]
        LEFT JOIN [Analytics].[tbl_Dim_CAM_Assignment_Reason] dar
            ON dar.[CAM_Assignment_Code] = c.[ReassignmentID]
        WHERE c.[Dataset] IN ('IP', 'OP')
          AND c.[Activity_Date] >= @WindowStartDate
          AND c.[Activity_Date] <= @WindowEndDate
          AND c.[Financial_Year] = @FinancialYear
          AND (@ProviderCode IS NULL OR c.[Provider_Code] = @ProviderCode);

        SELECT @DuplicateKeyCount = SUM(d.DuplicateRows)
        FROM (
            SELECT COUNT(1) - 1 AS DuplicateRows
            FROM #CAM_Raw
            GROUP BY [SK_EncounterID], [Dataset]
            HAVING COUNT(1) > 1
        ) d;

        IF @DuplicateKeyCount > 0
        BEGIN
            SET @DQMessage = 'Discarded ' + CAST(@DuplicateKeyCount AS VARCHAR(20))
                + ' duplicate rows for (SK_EncounterID, Dataset).';
            PRINT @DQMessage;

            INSERT INTO [Analytics].[tbl_ETL_Error_Details] (
                Batch_ID,
                Load_ID,
                Source_Table,
                Target_Table,
                Failed_Row_Data,
                Business_Key,
                Error_Message,
                Error_Type
            )
            VALUES (
                @BatchID,
                NULL,
                'Data_Lab_SWL.CAM.tbl_CAM_Raw',
                'Analytics.tbl_CAM_Assignment_Active',
                CONCAT('{"FromDate":"', CONVERT(VARCHAR(10), @WindowStartDate, 120),
                       '","ToDate":"', CONVERT(VARCHAR(10), @WindowEndDate, 120),
                       '","DuplicateKeyCount":', @DuplicateKeyCount, '}'),
                'DUPLICATE_PK',
                @DQMessage,
                'DataQuality'
            );
        END

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
            WHERE [Activity_Date] IS NOT NULL
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
            [SK_CAM_Assignment_ReasonID]
        INTO #CAM
        FROM Ranked
        WHERE RowNum = 1;

        DELETE FROM [Analytics].[tbl_CAM_Assignment_Active]
        WHERE [Activity_Date] >= @WindowStartDate
          AND [Activity_Date] <= @WindowEndDate;

        SET @RowsDeleted = @@ROWCOUNT;

        INSERT INTO [Analytics].[tbl_CAM_Assignment_Active] (
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
        FROM #CAM;

        SET @RowsInserted = @@ROWCOUNT;

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

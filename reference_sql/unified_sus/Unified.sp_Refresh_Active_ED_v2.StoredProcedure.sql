USE [Data_Lab_SWL];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/*
Object Name:    Unified.sp_Refresh_Active_ED_v2
Description:    Refresh Unified.tbl_ED_EncounterDenormalised_Active_v2 from vw_ED_EncounterDenormalised_DateRange_v2
Author:         Sridhar Peddi (refactor: Codex)
Created Date:   2026-01-16 11:30 UTC
Parameters:
    @MonthsToRefresh INT = 12
*/
IF OBJECT_ID('[Unified].[sp_Refresh_Active_ED_v2]', 'P') IS NOT NULL
    DROP PROCEDURE [Unified].[sp_Refresh_Active_ED_v2];
GO

CREATE PROCEDURE [Unified].[sp_Refresh_Active_ED_v2]
    @MonthsToRefresh INT = 12
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LogID INT;
    DECLARE @AffectedRowsTotal INT = 0;
    DECLARE @CurrentDate DATE = CAST(GETDATE() AS DATE);
    DECLARE @LastInclusionDate DATE;
    DECLARE @RefreshStartDate DATE;
    DECLARE @SourceRowCount INT;
    DECLARE @HistoricalRowsInserted INT = 0;
    DECLARE @ExpectedTotalRows INT;
    DECLARE @NewTableRowCount INT;
    DECLARE @FinalRowCount INT;

    SELECT @LastInclusionDate = StartOfMonthDate
    FROM [SWL].[GetMaxFinPeriodBySUSDeliveryDate](@CurrentDate);

    SET @RefreshStartDate = DATEADD(MONTH, -@MonthsToRefresh, @LastInclusionDate);

    IF OBJECT_ID('[Unified].[tbl_ED_EncounterDenormalised_Active_v2]', 'U') IS NULL
    BEGIN
        SELECT TOP 0
            s.*,
            CAST('UnPublished' AS VARCHAR(20)) AS DataAtInclusionPoint,
            CAST(NULL AS INT) AS LogId
        INTO [Unified].[tbl_ED_EncounterDenormalised_Active_v2]
        FROM [Unified].[vw_ED_EncounterDenormalised_DateRange_v2] s;
    END

    INSERT INTO [Unified].[tbl_RefreshLog] ([ProcedureName], [TargetTable], [Status], [Message])
    VALUES (
        OBJECT_NAME(@@PROCID),
        'Unified.tbl_ED_EncounterDenormalised_Active_v2',
        'Running',
        'SWAP TABLE refresh: ' + CONVERT(VARCHAR, @RefreshStartDate, 23) + ' to ' + CONVERT(VARCHAR, @CurrentDate, 23)
    );

    SET @LogID = SCOPE_IDENTITY();

    BEGIN TRY
        SELECT @SourceRowCount = COUNT(*)
        FROM [Unified].[vw_ED_EncounterDenormalised_DateRange_v2] s
        WHERE CONVERT(DATE, s.[dv_Activity_Period_Date], 112) BETWEEN @RefreshStartDate AND @CurrentDate;

        IF @SourceRowCount = 0
        BEGIN
            RAISERROR('No source data available for refresh period. Aborting operation.', 16, 1);
        END

        IF OBJECT_ID('[Unified].[tbl_ED_EncounterDenormalised_Active_v2_New]', 'U') IS NOT NULL
            DROP TABLE [Unified].[tbl_ED_EncounterDenormalised_Active_v2_New];

        SELECT TOP 0
            s.*,
            CAST('UnPublished' AS VARCHAR(20)) AS DataAtInclusionPoint,
            CAST(NULL AS INT) AS LogId
        INTO [Unified].[tbl_ED_EncounterDenormalised_Active_v2_New]
        FROM [Unified].[vw_ED_EncounterDenormalised_DateRange_v2] s;

        INSERT INTO [Unified].[tbl_ED_EncounterDenormalised_Active_v2_New]
        SELECT *
        FROM [Unified].[tbl_ED_EncounterDenormalised_Active_v2]
        WHERE CONVERT(DATE, [dv_Activity_Period_Date], 112) NOT BETWEEN @RefreshStartDate AND @CurrentDate;

        SET @HistoricalRowsInserted = @@ROWCOUNT;

        INSERT INTO [Unified].[tbl_ED_EncounterDenormalised_Active_v2_New]
        SELECT
            s.*,
            CASE
                WHEN dt.SK_Date <= InclDate.SK_DATE THEN 'Published'
                ELSE 'UnPublished'
            END AS DataAtInclusionPoint,
            @LogID AS LogId
        FROM [Unified].[vw_ED_EncounterDenormalised_DateRange_v2] s
        INNER JOIN [Dictionary].[dbo].[Dates] dt WITH (NOLOCK)
            ON CONVERT(DATE, s.[dv_Activity_Period_Date], 112) = dt.FullDate
        CROSS APPLY [SWL].[GetMaxFinPeriodBySUSDeliveryDate](GETDATE()) InclDate
        WHERE CONVERT(DATE, s.[dv_Activity_Period_Date], 112) BETWEEN @RefreshStartDate AND @CurrentDate
        OPTION (OPTIMIZE FOR UNKNOWN, MAXDOP 4);

        SET @AffectedRowsTotal = @@ROWCOUNT;

        IF @AffectedRowsTotal = 0
        BEGIN
            RAISERROR('INSERT completed but no rows were inserted. Check source data and filter conditions.', 16, 1);
        END

        SET @ExpectedTotalRows = @HistoricalRowsInserted + @AffectedRowsTotal;

        SELECT @NewTableRowCount = COUNT(*)
        FROM [Unified].[tbl_ED_EncounterDenormalised_Active_v2_New];

        IF @NewTableRowCount <> @ExpectedTotalRows
        BEGIN
            RAISERROR(
                'Data validation failed: Expected %d rows (%d historical + %d fresh), found %d rows in new table.',
                16,
                1,
                @ExpectedTotalRows,
                @HistoricalRowsInserted,
                @AffectedRowsTotal,
                @NewTableRowCount
            );
        END

        IF OBJECT_ID('[Unified].[tbl_ED_EncounterDenormalised_Active_v2_Old]', 'U') IS NOT NULL
            DROP TABLE [Unified].[tbl_ED_EncounterDenormalised_Active_v2_Old];

        BEGIN TRANSACTION;
        EXEC sp_rename 'Unified.tbl_ED_EncounterDenormalised_Active_v2', 'tbl_ED_EncounterDenormalised_Active_v2_Old';
        EXEC sp_rename 'Unified.tbl_ED_EncounterDenormalised_Active_v2_New', 'tbl_ED_EncounterDenormalised_Active_v2';
        COMMIT TRANSACTION;

        SELECT @FinalRowCount = COUNT(*)
        FROM [Unified].[tbl_ED_EncounterDenormalised_Active_v2];

        IF @FinalRowCount <> @ExpectedTotalRows
        BEGIN
            RAISERROR('CRITICAL: Final validation failed. Row count mismatch after swap.', 16, 1);
        END

        UPDATE [Unified].[tbl_RefreshLog]
        SET [EndTime] = SYSDATETIME(),
            [Status] = 'Completed',
            [RecordsAffected] = @FinalRowCount,
            [Message] = 'SWAP TABLE refresh successful. Backup: tbl_ED_EncounterDenormalised_Active_v2_Old'
        WHERE [LogID] = @LogID;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();

        UPDATE [Unified].[tbl_RefreshLog]
        SET [EndTime] = SYSDATETIME(),
            [Status] = 'Failed',
            [Message] = @ErrorMessage
        WHERE [LogID] = @LogID;

        THROW;
    END CATCH
END;
GO

USE [Data_Lab_SWL];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/*
Object Name:    Unified.sp_Refresh_ED_FY_v2
Description:    Materialise Unified.vw_ED_EncounterDenormalised_DateRange_v2 into a FY-specific table.
Created Date:   2026-01-19 09:44 UTC
Parameters:
    @FinYear VARCHAR(9) -- Expected format: YYYY/YYYY (e.g., 2019/2020)
*/
IF OBJECT_ID('[Unified].[sp_Refresh_ED_FY_v2]', 'P') IS NOT NULL
    DROP PROCEDURE [Unified].[sp_Refresh_ED_FY_v2];
GO

CREATE PROCEDURE [Unified].[sp_Refresh_ED_FY_v2]
    @FinYear VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    IF @FinYear IS NULL OR @FinYear NOT LIKE '[0-9][0-9][0-9][0-9]/[0-9][0-9][0-9][0-9]'
    BEGIN
        RAISERROR('Invalid @FinYear. Expected format: YYYY/YYYY (e.g., 2019/2020).', 16, 1);
        RETURN;
    END

    DECLARE @StartYear INT = TRY_CONVERT(INT, LEFT(@FinYear, 4));
    DECLARE @EndYear INT = TRY_CONVERT(INT, RIGHT(@FinYear, 4));
    DECLARE @FromDate DATE;
    DECLARE @ToDate DATE;
    DECLARE @LogID INT;
    DECLARE @SourceRowCount INT;
    DECLARE @RowsInserted INT;
    DECLARE @TargetRowCount INT;
    DECLARE @TargetTableName SYSNAME = 'tbl_ED_EncounterDenormalised_FY_' + REPLACE(@FinYear, '/', '_');
    DECLARE @QualifiedTarget NVARCHAR(300) = QUOTENAME('Unified') + '.' + QUOTENAME(@TargetTableName);
    DECLARE @Sql NVARCHAR(MAX);

    IF @StartYear IS NULL OR @EndYear IS NULL OR @EndYear <> @StartYear + 1
    BEGIN
        RAISERROR('Invalid @FinYear. Expected contiguous years (e.g., 2019/2020).', 16, 1);
        RETURN;
    END

    SET @FromDate = DATEFROMPARTS(@StartYear, 4, 1);
    SET @ToDate = DATEFROMPARTS(@EndYear, 3, 31);

    INSERT INTO [Unified].[tbl_RefreshLog] ([ProcedureName], [TargetTable], [Status], [Message])
    VALUES (
        OBJECT_NAME(@@PROCID),
        @QualifiedTarget,
        'Running',
        'FY refresh: ' + @FinYear
    );

    SET @LogID = SCOPE_IDENTITY();

    BEGIN TRY
        SELECT @SourceRowCount = COUNT(*)
        FROM [Unified].[vw_ED_EncounterDenormalised_DateRange_v2] s
        WHERE s.dv_FinYear = @FinYear
          AND CONVERT(DATE, s.[dv_Activity_Period_Date], 112) >= @FromDate
          AND CONVERT(DATE, s.[dv_Activity_Period_Date], 112) <= @ToDate;

        IF @SourceRowCount = 0
        BEGIN
            RAISERROR('No source data available for the requested financial year.', 16, 1);
        END

        SET @Sql = N'
IF OBJECT_ID(N''' + @QualifiedTarget + ''', ''U'') IS NOT NULL
BEGIN
    DROP TABLE ' + @QualifiedTarget + ';
END;

SELECT TOP (0)
    s.*,
    CAST(
        CASE
            WHEN dt.SK_Date <= InclDate.SK_DATE THEN ''Published''
            ELSE ''UnPublished''
        END AS VARCHAR(20)
    ) AS DataAtInclusionPoint,
    CAST(@LogID AS INT) AS LogId
INTO ' + @QualifiedTarget + '
FROM [Unified].[vw_ED_EncounterDenormalised_DateRange_v2] s
INNER JOIN [Dictionary].[dbo].[Dates] dt WITH (NOLOCK)
    ON CONVERT(DATE, s.[dv_Activity_Period_Date], 112) = dt.FullDate
CROSS APPLY [SWL].[GetMaxFinPeriodBySUSDeliveryDate](GETDATE()) InclDate
WHERE s.dv_FinYear = @FinYear
  AND CONVERT(DATE, s.[dv_Activity_Period_Date], 112) >= @FromDate
  AND CONVERT(DATE, s.[dv_Activity_Period_Date], 112) <= @ToDate;

INSERT INTO ' + @QualifiedTarget + ' WITH (TABLOCK)
SELECT
    s.*,
    CAST(
        CASE
            WHEN dt.SK_Date <= InclDate.SK_DATE THEN ''Published''
            ELSE ''UnPublished''
        END AS VARCHAR(20)
    ) AS DataAtInclusionPoint,
    CAST(@LogID AS INT) AS LogId
FROM [Unified].[vw_ED_EncounterDenormalised_DateRange_v2] s
INNER JOIN [Dictionary].[dbo].[Dates] dt WITH (NOLOCK)
    ON CONVERT(DATE, s.[dv_Activity_Period_Date], 112) = dt.FullDate
CROSS APPLY [SWL].[GetMaxFinPeriodBySUSDeliveryDate](GETDATE()) InclDate
WHERE s.dv_FinYear = @FinYear
  AND CONVERT(DATE, s.[dv_Activity_Period_Date], 112) >= @FromDate
  AND CONVERT(DATE, s.[dv_Activity_Period_Date], 112) <= @ToDate;

SET @RowsInserted = @@ROWCOUNT;
SELECT @TargetRowCount = COUNT(*) FROM ' + @QualifiedTarget + ';';

        EXEC sp_executesql
            @Sql,
            N'@FinYear VARCHAR(9), @LogID INT, @FromDate DATE, @ToDate DATE, @RowsInserted INT OUTPUT, @TargetRowCount INT OUTPUT',
            @FinYear = @FinYear,
            @LogID = @LogID,
            @FromDate = @FromDate,
            @ToDate = @ToDate,
            @RowsInserted = @RowsInserted OUTPUT,
            @TargetRowCount = @TargetRowCount OUTPUT;

        IF @RowsInserted = 0
        BEGIN
            RAISERROR('Insert completed but no rows were inserted.', 16, 1);
        END

        IF @TargetRowCount <> @RowsInserted
        BEGIN
            RAISERROR('Row count mismatch after insert. Expected %d, found %d.', 16, 1, @RowsInserted, @TargetRowCount);
        END

        UPDATE [Unified].[tbl_RefreshLog]
        SET [EndTime] = SYSDATETIME(),
            [Status] = 'Completed',
            [RecordsAffected] = @TargetRowCount,
            [Message] = 'FY refresh successful: ' + @FinYear
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

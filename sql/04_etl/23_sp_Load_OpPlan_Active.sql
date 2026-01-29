USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('[Analytics].[sp_Load_OpPlan_Active]', 'P') IS NOT NULL
DROP PROCEDURE [Analytics].[sp_Load_OpPlan_Active];
GO

/**
Script Name:   23_sp_Load_OpPlan_Active.sql
Description:   Loads Operating Plan encounter measure sets into Analytics.tbl_OpPlan_Active.
Author:        Sridhar Peddi
Created:       2026-01-15

Notes:
- Current FY by default; explicit @FinYearStart allows prior years.
- Uses OpPlan TVFs (no LogId dependency).
- Activity_Date uses Discharge (IP), Appointment (OP), Arrival (ED).
Flow (summary):
1) Read MeasureId per encounter from OpPlan TVFs (IP/OP/ED).
2) Attach activity dates from Unified materialised tables.
3) Build distinct measure-sets per encounter (sorted MeasureIds + hash).
4) Upsert measure-set dimension and bridge, then load tbl_OpPlan_Active.
**/
CREATE PROCEDURE [Analytics].[sp_Load_OpPlan_Active]
    @FinYearStart CHAR(4),
    @FromDate DATE = NULL,
    @ToDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ETL_Start DATETIME2 = CURRENT_TIMESTAMP;
    DECLARE @BatchName VARCHAR(100) = 'Load_OpPlan_Active';
    DECLARE @BatchID INT = NULL;
    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsDeleted INT = 0;
    DECLARE @RowsDim INT = 0;
    DECLARE @RowsBridge INT = 0;
    DECLARE @ErrorMessage NVARCHAR(4000);
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

    IF (@FromDate IS NULL AND @ToDate IS NOT NULL)
        OR (@FromDate IS NOT NULL AND @ToDate IS NULL)
    BEGIN
        RAISERROR('Both @FromDate and @ToDate must be provided together.', 16, 1);
        RETURN;
    END

    IF @FromDate IS NOT NULL AND @ToDate < @FromDate
    BEGIN
        RAISERROR('ToDate must be on or after FromDate.', 16, 1);
        RETURN;
    END

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

    IF OBJECT_ID('[Analytics].[tbl_OpPlan_Active]', 'U') IS NULL
    BEGIN
        RAISERROR('Required table [Analytics].[tbl_OpPlan_Active] was not found.', 16, 1);
        RETURN;
    END

    BEGIN TRY
        EXEC [Analytics].[sp_Start_ETL_Batch]
            @BatchName = @BatchName,
            @BatchID = @BatchID OUTPUT;

        IF OBJECT_ID('tempdb..#OpPlanRaw') IS NOT NULL
            DROP TABLE #OpPlanRaw;
        IF OBJECT_ID('tempdb..#OpPlanActivity') IS NOT NULL
            DROP TABLE #OpPlanActivity;
        IF OBJECT_ID('tempdb..#EncounterMeasureSet') IS NOT NULL
            DROP TABLE #EncounterMeasureSet;
        IF OBJECT_ID('tempdb..#OpPlanActive') IS NOT NULL
            DROP TABLE #OpPlanActive;

        SELECT
            o.SK_EncounterID,
            o.MeasureId,
            CAST('Inpatient' AS VARCHAR(20)) AS Dataset
        INTO #OpPlanRaw
        FROM [Data_Lab_SWL].[PLNG].[Get_OpPlan_ActivityBridge_IP_UfS](@FinYearStart) o
        UNION ALL
        SELECT
            o.SK_EncounterID,
            o.MeasureId,
            CAST('Outpatient' AS VARCHAR(20)) AS Dataset
        FROM [Data_Lab_SWL].[PLNG].[Get_OpPlan_ActivityBridge_OP_UfS](@FinYearStart) o
        UNION ALL
        SELECT
            o.SK_EncounterID,
            o.MeasureId,
            CAST('ED' AS VARCHAR(20)) AS Dataset
        FROM [Data_Lab_SWL].[PLNG].[Get_OpPlan_ActivityBridge_ED_UfS](@FinYearStart) o;

        SELECT
            r.SK_EncounterID,
            r.MeasureId,
            r.Dataset,
            CAST(ip.End_Date_Hospital_Provider_Spell AS DATE) AS Activity_Date
        INTO #OpPlanActivity
        FROM #OpPlanRaw r
        INNER JOIN [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active] ip
            ON r.SK_EncounterID = ip.SK_EncounterID
        WHERE r.Dataset = 'Inpatient'
          AND ip.End_Date_Hospital_Provider_Spell >= @WindowStartDate
          AND ip.End_Date_Hospital_Provider_Spell < DATEADD(DAY, 1, @WindowEndDate)

        UNION ALL
        SELECT
            r.SK_EncounterID,
            r.MeasureId,
            r.Dataset,
            CAST(op.Appointment_Date AS DATE) AS Activity_Date
        FROM #OpPlanRaw r
        INNER JOIN [Data_Lab_SWL].[Unified].[tbl_OP_EncounterDenormalised_Active] op
            ON r.SK_EncounterID = op.SK_EncounterID
        WHERE r.Dataset = 'Outpatient'
          AND op.Appointment_Date >= @WindowStartDate
          AND op.Appointment_Date < DATEADD(DAY, 1, @WindowEndDate)

        UNION ALL
        SELECT
            r.SK_EncounterID,
            r.MeasureId,
            r.Dataset,
            CAST(ed.Arrival_Date AS DATE) AS Activity_Date
        FROM #OpPlanRaw r
        INNER JOIN [Data_Lab_SWL].[Unified].[tbl_ED_EncounterDenormalised_Active] ed
            ON r.SK_EncounterID = ed.SK_EncounterID
        WHERE r.Dataset = 'ED'
          AND ed.Arrival_Date >= @WindowStartDate
          AND ed.Arrival_Date < DATEADD(DAY, 1, @WindowEndDate);

        ;WITH DistinctMeasures AS (
            SELECT DISTINCT SK_EncounterID, Dataset, MeasureId, Activity_Date
            FROM #OpPlanActivity
        ),
        MeasureSets AS (
            SELECT
                d.SK_EncounterID,
                d.Dataset,
                MAX(d.Activity_Date) AS Activity_Date,
                COUNT(*) AS MeasureCount,
                STUFF((
                    SELECT ',' + CONVERT(VARCHAR(20), d2.MeasureId)
                    FROM DistinctMeasures d2
                    WHERE d2.SK_EncounterID = d.SK_EncounterID
                      AND d2.Dataset = d.Dataset
                    ORDER BY d2.MeasureId
                    FOR XML PATH(''), TYPE
                ).value('.', 'VARCHAR(MAX)'), 1, 1, '') AS MeasureIds
            FROM DistinctMeasures d
            GROUP BY d.SK_EncounterID, d.Dataset
        )
        SELECT
            SK_EncounterID,
            Dataset,
            Activity_Date,
            MeasureCount,
            MeasureIds,
            HASHBYTES('SHA2_256', MeasureIds) AS SetHash
        INTO #EncounterMeasureSet
        FROM MeasureSets;

        INSERT INTO [Analytics].[tbl_Dim_OpPlan_MeasureSet] (
            [MeasureIds],
            [MeasureCount],
            [SetHash],
            [Is_Active],
            [Created_Date]
        )
        SELECT DISTINCT
            ms.MeasureIds,
            ms.MeasureCount,
            ms.SetHash,
            1,
            CURRENT_TIMESTAMP
        FROM #EncounterMeasureSet ms
        LEFT JOIN [Analytics].[tbl_Dim_OpPlan_MeasureSet] d
            ON d.SetHash = ms.SetHash
           AND d.MeasureIds = ms.MeasureIds
        WHERE d.SK_OpPlan_MeasureSet IS NULL;

        SET @RowsDim = @@ROWCOUNT;

        ;WITH DistinctSets AS (
            SELECT DISTINCT MeasureIds, SetHash
            FROM #EncounterMeasureSet
        )
        INSERT INTO [Analytics].[tbl_Bridge_OpPlan_MeasureSet] (
            [SK_OpPlan_MeasureSet],
            [MeasureID],
            [ETL_LoadDateTime]
        )
        SELECT
            d.SK_OpPlan_MeasureSet,
            LTRIM(RTRIM(m.n.value('.', 'VARCHAR(20)'))) AS MeasureID,
            @ETL_Start
        FROM DistinctSets s
        INNER JOIN [Analytics].[tbl_Dim_OpPlan_MeasureSet] d
            ON d.SetHash = s.SetHash
           AND d.MeasureIds = s.MeasureIds
        CROSS APPLY (
            SELECT CAST('<x>' + REPLACE(s.MeasureIds, ',', '</x><x>') + '</x>' AS XML) AS MeasureXml
        ) x
        CROSS APPLY x.MeasureXml.nodes('/x') AS m(n)
        LEFT JOIN [Analytics].[tbl_Bridge_OpPlan_MeasureSet] b
            ON b.SK_OpPlan_MeasureSet = d.SK_OpPlan_MeasureSet
           AND b.MeasureID = LTRIM(RTRIM(m.n.value('.', 'VARCHAR(20)')))
        WHERE d.SK_OpPlan_MeasureSet <> -1
          AND b.SK_OpPlan_MeasureSet IS NULL;

        SET @RowsBridge = @@ROWCOUNT;

        SELECT
            e.SK_EncounterID,
            e.Dataset,
            e.Activity_Date,
            e.MeasureIds,
            e.MeasureCount,
            e.SetHash,
            d.SK_OpPlan_MeasureSet,
            CAST(NULL AS INT) AS LogId
        INTO #OpPlanActive
        FROM #EncounterMeasureSet e
        INNER JOIN [Analytics].[tbl_Dim_OpPlan_MeasureSet] d
            ON d.SetHash = e.SetHash
           AND d.MeasureIds = e.MeasureIds;

        DELETE FROM [Analytics].[tbl_OpPlan_Active]
        WHERE [Activity_Date] >= @WindowStartDate
          AND [Activity_Date] <= @WindowEndDate;

        SET @RowsDeleted = @@ROWCOUNT;

        INSERT INTO [Analytics].[tbl_OpPlan_Active] (
            [SK_EncounterID],
            [Dataset],
            [Activity_Date],
            [MeasureIds],
            [MeasureCount],
            [SetHash],
            [SK_OpPlan_MeasureSet],
            [LogId],
            [ETL_LoadDateTime]
        )
        SELECT
            [SK_EncounterID],
            [Dataset],
            [Activity_Date],
            [MeasureIds],
            [MeasureCount],
            [SetHash],
            [SK_OpPlan_MeasureSet],
            [LogId],
            @ETL_Start
        FROM #OpPlanActive;

        SET @RowsInserted = @@ROWCOUNT;

        EXEC [Analytics].[sp_Log_Table_Load]
            @BatchID = @BatchID,
            @TableName = 'Analytics.tbl_Dim_OpPlan_MeasureSet',
            @LoadType = 'Upsert',
            @RowsAffected = @RowsDim,
            @Status = 'Success';

        EXEC [Analytics].[sp_Log_Table_Load]
            @BatchID = @BatchID,
            @TableName = 'Analytics.tbl_Bridge_OpPlan_MeasureSet',
            @LoadType = 'Upsert',
            @RowsAffected = @RowsBridge,
            @Status = 'Success';

        EXEC [Analytics].[sp_Log_Table_Load]
            @BatchID = @BatchID,
            @TableName = 'Analytics.tbl_OpPlan_Active',
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
        PRINT 'Error Loading OpPlan Active: ' + ISNULL(@ErrorMessage, '');
        IF @BatchID IS NOT NULL
        BEGIN
            EXEC [Analytics].[sp_Log_Table_Load]
                @BatchID = @BatchID,
                @TableName = 'Analytics.tbl_OpPlan_Active',
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


USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('[Analytics].[sp_Enrich_Facts_Operating_Plan]', 'P') IS NOT NULL
DROP PROCEDURE [Analytics].[sp_Enrich_Facts_Operating_Plan];
GO

/**
Script Name:   19_sp_Enrich_Facts_Operating_Plan.sql
Description:   Update Is_Operating_Plan and SK_OpPlan_MeasureSet on IP/OP/AE facts.
Author:        Sridhar Peddi
Created:       2026-01-13
Change Log:
  2026-01-13  Sridhar Peddi    Initial creation
  2026-01-26  Sridhar Peddi    Add table-level timings and temp index
Notes:
  - Uses Analytics.tbl_OpPlan_Active (precomputed from OpPlan TVFs).
  - @FromDate/@ToDate optionally constrain the fact update window.
*/
CREATE PROCEDURE [Analytics].[sp_Enrich_Facts_Operating_Plan]
    @FinYearStart CHAR(4),
    @FromDate DATE = NULL,
    @ToDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @BatchName VARCHAR(100) = 'Enrich_Facts_Operating_Plan';
    DECLARE @BatchID INT = NULL;
    DECLARE @RowsIP INT = 0;
    DECLARE @RowsOP INT = 0;
    DECLARE @RowsAE INT = 0;
    DECLARE @RowsUpdated INT = 0;
    DECLARE @FinYearInt INT;
    DECLARE @FinYearStartDate DATE;
    DECLARE @FinYearEndDate DATE;
    DECLARE @WindowStartDate DATE;
    DECLARE @WindowEndDate DATE;
    DECLARE @IP_StartTime DATETIME2;
    DECLARE @IP_EndTime DATETIME2;
    DECLARE @OP_StartTime DATETIME2;
    DECLARE @OP_EndTime DATETIME2;
    DECLARE @AE_StartTime DATETIME2;
    DECLARE @AE_EndTime DATETIME2;

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

    SET @FinYearStartDate = CONVERT(DATE, CONCAT(@FinYearStart, '0401'), 112);
    SET @FinYearEndDate = DATEADD(DAY, -1, DATEADD(YEAR, 1, @FinYearStartDate));
    SET @WindowStartDate = COALESCE(@FromDate, @FinYearStartDate);
    SET @WindowEndDate = COALESCE(@ToDate, @FinYearEndDate);

    IF OBJECT_ID('[Analytics].[tbl_OpPlan_Active]', 'U') IS NULL
    BEGIN
        RAISERROR('Required table [Analytics].[tbl_OpPlan_Active] was not found.', 16, 1);
        RETURN;
    END

    BEGIN TRY
        EXEC [Analytics].[sp_Start_ETL_Batch]
            @BatchName = @BatchName,
            @BatchID = @BatchID OUTPUT;

        IF OBJECT_ID('tempdb..#OpPlanActive') IS NOT NULL
            DROP TABLE #OpPlanActive;

        SELECT
            a.SK_EncounterID,
            a.Dataset,
            a.SK_OpPlan_MeasureSet
        INTO #OpPlanActive
        FROM [Analytics].[tbl_OpPlan_Active] a
        WHERE a.Activity_Date >= @WindowStartDate
          AND a.Activity_Date <= @WindowEndDate;

        CREATE INDEX [IX_OpPlanActive_Dataset_Encounter]
            ON #OpPlanActive ([Dataset], [SK_EncounterID]);

        IF NOT EXISTS (SELECT 1 FROM #OpPlanActive)
            AND (
                EXISTS (
                    SELECT 1
                    FROM [Analytics].[tbl_Fact_IP_Activity] f
                    WHERE f.Discharge_Date >= @WindowStartDate
                      AND f.Discharge_Date <= @WindowEndDate
                )
                OR EXISTS (
                    SELECT 1
                    FROM [Analytics].[tbl_Fact_OP_Activity] f
                    WHERE f.Appointment_Date >= @WindowStartDate
                      AND f.Appointment_Date <= @WindowEndDate
                )
                OR EXISTS (
                    SELECT 1
                    FROM [Analytics].[tbl_Fact_AE_Activity] f
                    WHERE f.Arrival_Date >= @WindowStartDate
                      AND f.Arrival_Date <= @WindowEndDate
                )
            )
        BEGIN
            RAISERROR('No OpPlan active rows found in Analytics.tbl_OpPlan_Active for the requested window.', 16, 1);
        END

        SET @IP_StartTime = SYSDATETIME();
        UPDATE f
        SET f.Is_Operating_Plan = CASE WHEN o.SK_EncounterID IS NULL THEN 0 ELSE 1 END,
            f.SK_OpPlan_MeasureSet = COALESCE(o.SK_OpPlan_MeasureSet, -1)
        FROM [Analytics].[tbl_Fact_IP_Activity] f
        LEFT JOIN #OpPlanActive o
            ON f.SK_EncounterID = o.SK_EncounterID
           AND o.Dataset = 'Inpatient'
        WHERE f.Discharge_Date >= @WindowStartDate
          AND f.Discharge_Date <= @WindowEndDate
          AND (
                (o.SK_EncounterID IS NULL AND (f.Is_Operating_Plan <> 0 OR f.SK_OpPlan_MeasureSet <> -1))
             OR (o.SK_EncounterID IS NOT NULL AND (f.Is_Operating_Plan <> 1 OR f.SK_OpPlan_MeasureSet <> o.SK_OpPlan_MeasureSet))
          );

        SET @RowsIP = @@ROWCOUNT;
        SET @IP_EndTime = SYSDATETIME();

        SET @OP_StartTime = SYSDATETIME();
        UPDATE f
        SET f.Is_Operating_Plan = CASE WHEN o.SK_EncounterID IS NULL THEN 0 ELSE 1 END,
            f.SK_OpPlan_MeasureSet = COALESCE(o.SK_OpPlan_MeasureSet, -1)
        FROM [Analytics].[tbl_Fact_OP_Activity] f
        LEFT JOIN #OpPlanActive o
            ON f.SK_EncounterID = o.SK_EncounterID
           AND o.Dataset = 'Outpatient'
        WHERE f.Appointment_Date >= @WindowStartDate
          AND f.Appointment_Date <= @WindowEndDate
          AND (
                (o.SK_EncounterID IS NULL AND (f.Is_Operating_Plan <> 0 OR f.SK_OpPlan_MeasureSet <> -1))
             OR (o.SK_EncounterID IS NOT NULL AND (f.Is_Operating_Plan <> 1 OR f.SK_OpPlan_MeasureSet <> o.SK_OpPlan_MeasureSet))
          );

        SET @RowsOP = @@ROWCOUNT;
        SET @OP_EndTime = SYSDATETIME();

        SET @AE_StartTime = SYSDATETIME();
        UPDATE f
        SET f.Is_Operating_Plan = CASE WHEN o.SK_EncounterID IS NULL THEN 0 ELSE 1 END,
            f.SK_OpPlan_MeasureSet = COALESCE(o.SK_OpPlan_MeasureSet, -1)
        FROM [Analytics].[tbl_Fact_AE_Activity] f
        LEFT JOIN #OpPlanActive o
            ON f.SK_EncounterID = o.SK_EncounterID
           AND o.Dataset = 'ED'
        WHERE f.Arrival_Date >= @WindowStartDate
          AND f.Arrival_Date <= @WindowEndDate
          AND (
                (o.SK_EncounterID IS NULL AND (f.Is_Operating_Plan <> 0 OR f.SK_OpPlan_MeasureSet <> -1))
             OR (o.SK_EncounterID IS NOT NULL AND (f.Is_Operating_Plan <> 1 OR f.SK_OpPlan_MeasureSet <> o.SK_OpPlan_MeasureSet))
          );

        SET @RowsAE = @@ROWCOUNT;
        SET @AE_EndTime = SYSDATETIME();

        SELECT @RowsUpdated = SUM(v)
        FROM (VALUES (@RowsIP), (@RowsOP), (@RowsAE)) AS x(v);

        EXEC [Analytics].[sp_Log_Table_Load]
            @BatchID = @BatchID,
            @TableName = 'Analytics.tbl_Fact_IP_Activity',
            @LoadType = 'Update',
            @RowsAffected = @RowsIP,
            @Status = 'Success',
            @StartDateTime = @IP_StartTime,
            @EndDateTime = @IP_EndTime;

        EXEC [Analytics].[sp_Log_Table_Load]
            @BatchID = @BatchID,
            @TableName = 'Analytics.tbl_Fact_OP_Activity',
            @LoadType = 'Update',
            @RowsAffected = @RowsOP,
            @Status = 'Success',
            @StartDateTime = @OP_StartTime,
            @EndDateTime = @OP_EndTime;

        EXEC [Analytics].[sp_Log_Table_Load]
            @BatchID = @BatchID,
            @TableName = 'Analytics.tbl_Fact_AE_Activity',
            @LoadType = 'Update',
            @RowsAffected = @RowsAE,
            @Status = 'Success',
            @StartDateTime = @AE_StartTime,
            @EndDateTime = @AE_EndTime;

        EXEC [Analytics].[sp_End_ETL_Batch]
            @BatchID = @BatchID,
            @Status = 'Success',
            @RowsInserted = 0,
            @RowsUpdated = @RowsUpdated,
            @RowsDeleted = 0,
            @RowsFailed = 0,
            @ErrorMessage = NULL;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        PRINT CONCAT('ErrorNumber:', ERROR_NUMBER(), ' ErrorMessage:', ISNULL(@ErrorMessage, ''));
        IF @BatchID IS NOT NULL
        BEGIN
            EXEC [Analytics].[sp_Log_Table_Load]
                @BatchID = @BatchID,
                @TableName = 'Analytics.tbl_Fact_*_Activity',
                @LoadType = 'Update',
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

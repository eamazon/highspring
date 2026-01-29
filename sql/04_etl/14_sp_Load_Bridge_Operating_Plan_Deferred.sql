
USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('[Analytics].[sp_Load_Bridge_Operating_Plan_Deferred]', 'P') IS NOT NULL
DROP PROCEDURE [Analytics].[sp_Load_Bridge_Operating_Plan_Deferred];
GO

/**
Script Name:   14_sp_Load_Bridge_Operating_Plan_Deferred.sql
Description:   ETL Procedure to load encounter-level Operating Plan bridge (deferred/Phase 2 table).
               Uses PLNG activity-bridge TVFs (IP/OP/ED) to map encounters -> MeasureId.
Author:        Sridhar Peddi
Created:       2026-01-09

Notes:
- Sources are expected in [Data_Lab_SWL] database:
    - [PLNG].[Get_OpPlan_ActivityBridge_IP_UfS]
    - [PLNG].[Get_OpPlan_ActivityBridge_OP_UfS]
    - [PLNG].[Get_OpPlan_ActivityBridge_ED_UfS]
- Metric metadata is optionally pulled from [Data_Lab_SWL].[IM].[tbl_Metrics_Catalogue] using NHSEMetricId.
- Designed for Phase 1 truncate/reload.
- This loader intentionally restricts to encounters present in the Analytics fact tables,
  so the bridge stays aligned to the currently loaded fact window (e.g., rolling 6 months).
*/
CREATE PROCEDURE [Analytics].[sp_Load_Bridge_Operating_Plan_Deferred]
    @FinYearStart CHAR(4)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PlanningYear VARCHAR(7) = CONCAT(@FinYearStart, '/', RIGHT(CAST(CAST(@FinYearStart AS INT) + 1 AS VARCHAR(4)), 2));
    DECLARE @RowsInserted INT = 0;
    DECLARE @BatchName VARCHAR(100) = 'Bridge_Operating_Plan_Deferred';
    DECLARE @BatchID INT = NULL;

    BEGIN TRY
        EXEC [Analytics].[sp_Start_ETL_Batch]
            @BatchName = @BatchName,
            @BatchID = @BatchID OUTPUT;

        PRINT 'Starting Load: [Analytics].[tbl_Bridge_Operating_Plan_Deferred]';

        TRUNCATE TABLE [Analytics].[tbl_Bridge_Operating_Plan_Deferred];

        ;WITH OPPLAN AS (
            SELECT SK_EncounterID, MeasureId, Dataset
            FROM [Data_Lab_SWL].[PLNG].[Get_OpPlan_ActivityBridge_IP_UfS](@FinYearStart)

            UNION ALL
            SELECT SK_EncounterID, MeasureId, Dataset
            FROM [Data_Lab_SWL].[PLNG].[Get_OpPlan_ActivityBridge_OP_UfS](@FinYearStart)

            UNION ALL
            SELECT SK_EncounterID, MeasureId, Dataset
            FROM [Data_Lab_SWL].[PLNG].[Get_OpPlan_ActivityBridge_ED_UfS](@FinYearStart)
        )
        INSERT INTO [Analytics].[tbl_Bridge_Operating_Plan_Deferred] (
            [SK_EncounterID],
            [POD],
            [MeasureID],
            [Measure_Category],
            [Is_Baseline_Activity],
            [Is_Recovery_Target],
            [Planning_Year],
            [ETL_LoadDateTime]
        )
        SELECT
            b.SK_EncounterID,
            CASE
                WHEN b.Dataset = 'Inpatient' THEN 'IP'
                WHEN b.Dataset = 'Outpatient' THEN 'OP'
                WHEN b.Dataset = 'ED' THEN 'AE'
                ELSE 'NA'
            END AS POD,
            CAST(b.MeasureId AS VARCHAR(20)) AS MeasureID,
            mc.Category AS Measure_Category,
            CAST(0 AS BIT) AS Is_Baseline_Activity,
            CAST(0 AS BIT) AS Is_Recovery_Target,
            @PlanningYear AS Planning_Year,
            CURRENT_TIMESTAMP
        FROM OPPLAN b
        LEFT JOIN [Data_Lab_SWL].[IM].[tbl_Metrics_Catalogue] mc
            ON mc.NHSEMetricId = b.MeasureId
        WHERE
            (b.Dataset = 'Inpatient' AND EXISTS (SELECT 1 FROM [Analytics].[tbl_Fact_IP_Activity] f WHERE f.SK_EncounterID = b.SK_EncounterID))
            OR
            (b.Dataset = 'Outpatient' AND EXISTS (SELECT 1 FROM [Analytics].[tbl_Fact_OP_Activity] f WHERE f.SK_EncounterID = b.SK_EncounterID))
            OR
            (b.Dataset = 'ED' AND EXISTS (SELECT 1 FROM [Analytics].[tbl_Fact_AE_Activity] f WHERE f.SK_EncounterID = b.SK_EncounterID));

        SET @RowsInserted = @@ROWCOUNT;
        PRINT 'Completed Load: [Analytics].[tbl_Bridge_Operating_Plan_Deferred]';

        EXEC [Analytics].[sp_Log_Table_Load]
            @BatchID = @BatchID,
            @TableName = 'Analytics.tbl_Bridge_Operating_Plan_Deferred',
            @LoadType = 'Full',
            @RowsAffected = @RowsInserted,
            @Status = 'Success';

        EXEC [Analytics].[sp_End_ETL_Batch]
            @BatchID = @BatchID,
            @Status = 'Success',
            @RowsInserted = @RowsInserted,
            @RowsUpdated = 0,
            @RowsDeleted = 0,
            @RowsFailed = 0,
            @ErrorMessage = NULL;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        PRINT(CONCAT('ErrorNumber:', ERROR_NUMBER(), ' ErrorMessage:', @ErrorMessage));
        IF @BatchID IS NOT NULL
        BEGIN
            EXEC [Analytics].[sp_Log_Table_Load]
                @BatchID = @BatchID,
                @TableName = 'Analytics.tbl_Bridge_Operating_Plan_Deferred',
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

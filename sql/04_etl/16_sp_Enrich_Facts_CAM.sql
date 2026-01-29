
USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('[Analytics].[sp_Enrich_Facts_CAM]', 'P') IS NOT NULL
DROP PROCEDURE [Analytics].[sp_Enrich_Facts_CAM];
GO

/**
Script Name:   16_sp_Enrich_Facts_CAM.sql
Description:   Enriches Analytics IP/OP facts with CAM (Commissioning Allocation Method) attribution.
               Stores CAM outputs as columns on facts (no bridge table) because CAM is effectively
               a 1:1 encounter-level reassignment for "who pays".
Author:        Sridhar Peddi
Created:       2026-01-09

Notes:
- Uses precomputed CAM outputs from [Analytics].[tbl_CAM_Assignment_Active].
- [Analytics].[fn_CommissionerAssignment] remains the upstream source for CAM precompute.
    RecordIdentifier, Dataset, CAM_Commissioner_Code, CAM_Service_Category,
    [Commissioner Assignment Reason], Commissioner_Variance, Service_Category_Variance
-- The CAM function currently sources [Analytics].[vw_SUS_CAM] which is financial-year scoped.
-- Populates CAM dimension keys on facts (commissioner, service category, assignment reason).
-- Designed as an explicit post-load enrichment step (deploy now; run later).

Parameters:
- @FinancialYear: 'YYYY/YYYY' e.g. '2025/2026'
- @ProviderCode: optional provider filter passed to CAM function
-- @FromDate/@ToDate: optional discharge/appointment date window passed to CAM function

Change Log:
  2026-01-12  Sridhar Peddi    Add ETL batch/table logging
  2026-01-26  Sridhar Peddi    Add table-level timings for logging
*/
CREATE PROCEDURE [Analytics].[sp_Enrich_Facts_CAM]
    @FinancialYear VARCHAR(9),
    @ProviderCode VARCHAR(10) = NULL,
    @FromDate DATE = NULL,
    @ToDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @BatchName VARCHAR(100) = 'Enrich_Facts_CAM';
    DECLARE @BatchID INT = NULL;
    DECLARE @RowsUpdatedIP INT = 0;
    DECLARE @RowsUpdatedOP INT = 0;
    DECLARE @RowsUpdatedTotal INT = 0;
    DECLARE @LoggedIP BIT = 0;
    DECLARE @LoggedOP BIT = 0;
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @FromDateActual DATE = @FromDate;
    DECLARE @ToDateActual DATE = @ToDate;
    DECLARE @IP_StartTime DATETIME2;
    DECLARE @IP_EndTime DATETIME2;
    DECLARE @OP_StartTime DATETIME2;
    DECLARE @OP_EndTime DATETIME2;

    IF @FinancialYear IS NULL OR LTRIM(RTRIM(@FinancialYear)) = ''
    BEGIN
        RAISERROR('Parameter @FinancialYear is required (e.g. ''2025/2026'')', 16, 1);
        RETURN;
    END

    BEGIN TRY
        EXEC [Analytics].[sp_Start_ETL_Batch]
            @BatchName = @BatchName,
            @BatchID = @BatchID OUTPUT;

        PRINT 'Batch ID: ' + CAST(@BatchID AS VARCHAR);
        PRINT 'Starting CAM enrichment for Analytics facts';

        IF OBJECT_ID('[Analytics].[tbl_CAM_Assignment_Active]', 'U') IS NULL
        BEGIN
            RAISERROR('Required table [Analytics].[tbl_CAM_Assignment_Active] was not found.', 16, 1);
            RETURN;
        END

        -- Materialise CAM outputs once for efficient joins
        IF OBJECT_ID('tempdb..#CAM') IS NOT NULL
            DROP TABLE #CAM;

        SELECT
            c.[SK_EncounterID],
            c.[Dataset],
            c.[CAM_Assignment_Code],
            c.[CAM_Commissioner_Code],
            c.[CAM_Service_Category],
            c.[CAM_Assignment_Reason],
            c.[Commissioner_Variance],
            c.[Service_Category_Variance],
            c.[SK_CAM_CommissionerID],
            c.[SK_CAM_Service_CategoryID],
            c.[SK_CAM_Assignment_ReasonID]
        INTO #CAM
        FROM [Analytics].[tbl_CAM_Assignment_Active] c
        WHERE (@FromDateActual IS NULL OR c.[Activity_Date] >= @FromDateActual)
          AND (@ToDateActual IS NULL OR c.[Activity_Date] <= @ToDateActual);

        IF NOT EXISTS (SELECT 1 FROM #CAM)
            AND (
                EXISTS (
                    SELECT 1
                    FROM [Analytics].[tbl_Fact_IP_Activity] f
                    WHERE (@FromDateActual IS NULL OR f.[Discharge_Date] >= @FromDateActual)
                      AND (@ToDateActual IS NULL OR f.[Discharge_Date] <= @ToDateActual)
                )
                OR EXISTS (
                    SELECT 1
                    FROM [Analytics].[tbl_Fact_OP_Activity] f
                    WHERE (@FromDateActual IS NULL OR f.[Appointment_Date] >= @FromDateActual)
                      AND (@ToDateActual IS NULL OR f.[Appointment_Date] <= @ToDateActual)
                )
            )
        BEGIN
            RAISERROR('No CAM assignment rows found in Analytics.tbl_CAM_Assignment_Active for the requested window.', 16, 1);
            RETURN;
        END

        CREATE INDEX IX_CAM_Dataset_Encounter ON #CAM ([Dataset], [SK_EncounterID]);

        -- IP enrichment
        SET @IP_StartTime = SYSDATETIME();
        UPDATE f
        SET
            f.[SK_CAM_CommissionerID] = c.[SK_CAM_CommissionerID],
            f.[SK_CAM_Service_CategoryID] = c.[SK_CAM_Service_CategoryID],
            f.[SK_CAM_Assignment_ReasonID] = c.[SK_CAM_Assignment_ReasonID],
            f.[CAM_Commissioner_Code] = c.[CAM_Commissioner_Code],
            f.[CAM_Service_Category] = c.[CAM_Service_Category],
            f.[CAM_Assignment_Reason] = c.[CAM_Assignment_Reason],
            f.[Commissioner_Variance] = c.[Commissioner_Variance],
            f.[Service_Category_Variance] = c.[Service_Category_Variance],
            f.[ETL_UpdateDateTime] = CURRENT_TIMESTAMP
        FROM [Analytics].[tbl_Fact_IP_Activity] f
        INNER JOIN #CAM c
            ON c.[Dataset] = 'IP'
            AND c.[SK_EncounterID] = f.[SK_EncounterID]
        WHERE (@FromDateActual IS NULL OR f.[Discharge_Date] >= @FromDateActual)
          AND (@ToDateActual IS NULL OR f.[Discharge_Date] <= @ToDateActual)
          AND (
                ISNULL(f.[SK_CAM_CommissionerID], -1) <> c.[SK_CAM_CommissionerID]
             OR ISNULL(f.[SK_CAM_Service_CategoryID], -1) <> c.[SK_CAM_Service_CategoryID]
             OR ISNULL(f.[SK_CAM_Assignment_ReasonID], -1) <> c.[SK_CAM_Assignment_ReasonID]
             OR ISNULL(f.[CAM_Commissioner_Code], '') <> ISNULL(c.[CAM_Commissioner_Code], '')
             OR ISNULL(f.[CAM_Service_Category], '') <> ISNULL(c.[CAM_Service_Category], '')
             OR ISNULL(f.[CAM_Assignment_Reason], '') <> ISNULL(c.[CAM_Assignment_Reason], '')
             OR ISNULL(f.[Commissioner_Variance], 0) <> ISNULL(c.[Commissioner_Variance], 0)
             OR ISNULL(f.[Service_Category_Variance], 0) <> ISNULL(c.[Service_Category_Variance], 0)
          );

        SET @RowsUpdatedIP = @@ROWCOUNT;
        SET @IP_EndTime = SYSDATETIME();

        EXEC [Analytics].[sp_Log_Table_Load]
            @BatchID = @BatchID,
            @TableName = 'Analytics.tbl_Fact_IP_Activity',
            @LoadType = 'Update',
            @RowsAffected = @RowsUpdatedIP,
            @Status = 'Success',
            @StartDateTime = @IP_StartTime,
            @EndDateTime = @IP_EndTime;

        SET @LoggedIP = 1;

        -- OP enrichment
        SET @OP_StartTime = SYSDATETIME();
        UPDATE f
        SET
            f.[SK_CAM_CommissionerID] = c.[SK_CAM_CommissionerID],
            f.[SK_CAM_Service_CategoryID] = c.[SK_CAM_Service_CategoryID],
            f.[SK_CAM_Assignment_ReasonID] = c.[SK_CAM_Assignment_ReasonID],
            f.[CAM_Commissioner_Code] = c.[CAM_Commissioner_Code],
            f.[CAM_Service_Category] = c.[CAM_Service_Category],
            f.[CAM_Assignment_Reason] = c.[CAM_Assignment_Reason],
            f.[Commissioner_Variance] = c.[Commissioner_Variance],
            f.[Service_Category_Variance] = c.[Service_Category_Variance],
            f.[ETL_UpdateDateTime] = CURRENT_TIMESTAMP
        FROM [Analytics].[tbl_Fact_OP_Activity] f
        INNER JOIN #CAM c
            ON c.[Dataset] = 'OP'
            AND c.[SK_EncounterID] = f.[SK_EncounterID]
        WHERE (@FromDateActual IS NULL OR f.[Appointment_Date] >= @FromDateActual)
          AND (@ToDateActual IS NULL OR f.[Appointment_Date] <= @ToDateActual)
          AND (
                ISNULL(f.[SK_CAM_CommissionerID], -1) <> c.[SK_CAM_CommissionerID]
             OR ISNULL(f.[SK_CAM_Service_CategoryID], -1) <> c.[SK_CAM_Service_CategoryID]
             OR ISNULL(f.[SK_CAM_Assignment_ReasonID], -1) <> c.[SK_CAM_Assignment_ReasonID]
             OR ISNULL(f.[CAM_Commissioner_Code], '') <> ISNULL(c.[CAM_Commissioner_Code], '')
             OR ISNULL(f.[CAM_Service_Category], '') <> ISNULL(c.[CAM_Service_Category], '')
             OR ISNULL(f.[CAM_Assignment_Reason], '') <> ISNULL(c.[CAM_Assignment_Reason], '')
             OR ISNULL(f.[Commissioner_Variance], 0) <> ISNULL(c.[Commissioner_Variance], 0)
             OR ISNULL(f.[Service_Category_Variance], 0) <> ISNULL(c.[Service_Category_Variance], 0)
          );

        SET @RowsUpdatedOP = @@ROWCOUNT;
        SET @OP_EndTime = SYSDATETIME();

        EXEC [Analytics].[sp_Log_Table_Load]
            @BatchID = @BatchID,
            @TableName = 'Analytics.tbl_Fact_OP_Activity',
            @LoadType = 'Update',
            @RowsAffected = @RowsUpdatedOP,
            @Status = 'Success',
            @StartDateTime = @OP_StartTime,
            @EndDateTime = @OP_EndTime;

        SET @LoggedOP = 1;

        SELECT @RowsUpdatedTotal = SUM(v)
        FROM (VALUES (ISNULL(@RowsUpdatedIP, 0)), (ISNULL(@RowsUpdatedOP, 0))) AS x(v);

        EXEC [Analytics].[sp_End_ETL_Batch]
            @BatchID = @BatchID,
            @Status = 'Success',
            @RowsInserted = 0,
            @RowsUpdated = @RowsUpdatedTotal,
            @RowsDeleted = 0,
            @RowsFailed = 0,
            @ErrorMessage = NULL;

        PRINT 'Completed CAM enrichment for Analytics facts';
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();
        PRINT(CONCAT('ErrorNumber:', ERROR_NUMBER(), ' ErrorMessage:', @ErrorMessage));
        IF @BatchID IS NOT NULL
        BEGIN
            IF @LoggedIP = 0
            BEGIN
                EXEC [Analytics].[sp_Log_Table_Load]
                    @BatchID = @BatchID,
                    @TableName = 'Analytics.tbl_Fact_IP_Activity',
                    @LoadType = 'Update',
                    @RowsAffected = 0,
                    @RowsFailed = 1,
                    @Status = 'Failed',
                    @ErrorMessage = @ErrorMessage;
            END

            IF @LoggedOP = 0
            BEGIN
                EXEC [Analytics].[sp_Log_Table_Load]
                    @BatchID = @BatchID,
                    @TableName = 'Analytics.tbl_Fact_OP_Activity',
                    @LoadType = 'Update',
                    @RowsAffected = 0,
                    @RowsFailed = 1,
                    @Status = 'Failed',
                    @ErrorMessage = @ErrorMessage;
            END

            SELECT @RowsUpdatedTotal = SUM(v)
            FROM (VALUES (ISNULL(@RowsUpdatedIP, 0)), (ISNULL(@RowsUpdatedOP, 0))) AS x(v);

            EXEC [Analytics].[sp_End_ETL_Batch]
                @BatchID = @BatchID,
                @Status = 'Failed',
                @RowsInserted = 0,
                @RowsUpdated = @RowsUpdatedTotal,
                @RowsDeleted = 0,
                @RowsFailed = 1,
                @ErrorMessage = @ErrorMessage;
        END
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END CATCH
END
GO

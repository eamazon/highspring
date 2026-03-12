
USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('[Analytics].[sp_Enrich_Facts_ERF]', 'P') IS NOT NULL
DROP PROCEDURE [Analytics].[sp_Enrich_Facts_ERF];
GO

/**
Script Name:   20_sp_Enrich_Facts_ERF.sql
Description:   Enriches IP/OP facts with ERF eligibility and repriced cost fields.
Author:        Sridhar Peddi
Created:       2026-01-14

Change Log:
  2026-01-14  Sridhar Peddi    Initial creation
  2026-01-26  Sridhar Peddi    Add table-level timings and #ERF index

Notes:
- Uses Analytics.tbl_ERF_Repriced_Active as the eligibility source (precomputed).
- Updates only the requested date window (Admission/Appointment date).
- If @FinYearStart is supplied, it also filters ERF view rows by dv_FinYear.

Parameters:
- @FinYearStart: Optional 4-char year filter, e.g. '2025' (matches LEFT(dv_FinYear,4)).
- @FromDate/@ToDate: Optional date window for fact updates (must be supplied together).
*/
CREATE PROCEDURE [Analytics].[sp_Enrich_Facts_ERF]
    @FinYearStart CHAR(4) = NULL,
    @FromDate DATE = NULL,
    @ToDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @BatchName VARCHAR(100) = 'Enrich_Facts_ERF';
    DECLARE @BatchID INT = NULL;
    DECLARE @RowsUpdatedIP INT = 0;
    DECLARE @RowsUpdatedOP INT = 0;
    DECLARE @RowsUpdatedTotal INT = 0;
    DECLARE @FinYearInt INT = NULL;
    DECLARE @WindowStartDate DATE;
    DECLARE @WindowEndDate DATE;
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @IP_StartTime DATETIME2;
    DECLARE @IP_EndTime DATETIME2;
    DECLARE @OP_StartTime DATETIME2;
    DECLARE @OP_EndTime DATETIME2;

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

    IF @FinYearStart IS NOT NULL AND LTRIM(RTRIM(@FinYearStart)) <> ''
    BEGIN
        SET @FinYearInt = CASE
            WHEN ISNUMERIC(@FinYearStart) = 1 THEN CAST(@FinYearStart AS INT)
            ELSE NULL
        END;

        IF @FinYearInt IS NULL
        BEGIN
            RAISERROR('Parameter @FinYearStart must be a 4-digit year (e.g. ''2025'')', 16, 1);
            RETURN;
        END
    END

    IF @FromDate IS NOT NULL
    BEGIN
        SET @WindowStartDate = @FromDate;
        SET @WindowEndDate = @ToDate;
    END
    ELSE IF @FinYearInt IS NOT NULL
    BEGIN
        SET @WindowStartDate = CONVERT(DATE, @FinYearStart + '0401', 112);
        SET @WindowEndDate = DATEADD(DAY, -1, DATEADD(YEAR, 1, @WindowStartDate));
    END
    ELSE
    BEGIN
        SET @WindowStartDate = CAST('1900-01-01' AS DATE);
        SET @WindowEndDate = CAST('9999-12-31' AS DATE);
    END

    BEGIN TRY
        EXEC [Analytics].[sp_Start_ETL_Batch]
            @BatchName = @BatchName,
            @BatchID = @BatchID OUTPUT;

        IF OBJECT_ID('[Analytics].[tbl_ERF_Repriced_Active]', 'U') IS NULL
        BEGIN
            RAISERROR('Required table [Analytics].[tbl_ERF_Repriced_Active] was not found.', 16, 1);
            RETURN;
        END

        IF OBJECT_ID('tempdb..#ERF') IS NOT NULL
            DROP TABLE #ERF;

        CREATE TABLE #ERF (
            [SK_EncounterID] BIGINT NOT NULL,
            [POD] VARCHAR(2) NOT NULL,
            [ERF_MFF_Applied] DECIMAL(12,2) NULL,
            [ERF_Total_Cost_Incl_MFF] DECIMAL(12,2) NULL
        );

        INSERT INTO #ERF (
            [SK_EncounterID],
            [POD],
            [ERF_MFF_Applied],
            [ERF_Total_Cost_Incl_MFF]
        )
        SELECT
            v.SK_EncounterID,
            'IP' AS POD,
            CAST(v.ERF_MFF_Applied AS DECIMAL(12,2)) AS ERF_MFF_Applied,
            CAST(v.ERF_Total_Cost_Incl_MFF AS DECIMAL(12,2)) AS ERF_Total_Cost_Incl_MFF
        FROM [Analytics].[tbl_ERF_Repriced_Active] v
        INNER JOIN [Analytics].[tbl_Fact_IP_Activity] f
            ON f.SK_EncounterID = v.SK_EncounterID
        WHERE v.POD = 'IP'
          AND f.Discharge_Date >= @WindowStartDate
          AND f.Discharge_Date <= @WindowEndDate
          AND (@FinYearStart IS NULL OR LEFT(v.dv_FinYear, 4) = @FinYearStart)
        UNION ALL
        SELECT
            v.SK_EncounterID,
            'OP' AS POD,
            CAST(v.ERF_MFF_Applied AS DECIMAL(12,2)) AS ERF_MFF_Applied,
            CAST(v.ERF_Total_Cost_Incl_MFF AS DECIMAL(12,2)) AS ERF_Total_Cost_Incl_MFF
        FROM [Analytics].[tbl_ERF_Repriced_Active] v
        INNER JOIN [Analytics].[tbl_Fact_OP_Activity] f
            ON f.SK_EncounterID = v.SK_EncounterID
        WHERE v.POD = 'OP'
          AND f.Appointment_Date >= @WindowStartDate
          AND f.Appointment_Date <= @WindowEndDate
          AND (@FinYearStart IS NULL OR LEFT(v.dv_FinYear, 4) = @FinYearStart);

        ;WITH Dedup AS (
            SELECT
                *,
                ROW_NUMBER() OVER (
                    PARTITION BY POD, SK_EncounterID
                    ORDER BY SK_EncounterID
                ) AS rn
            FROM #ERF
        )
        DELETE FROM Dedup
        WHERE rn > 1;

        IF NOT EXISTS (SELECT 1 FROM #ERF)
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
            )
        BEGIN
            RAISERROR('No ERF repriced rows found in Analytics.tbl_ERF_Repriced_Active for the requested window.', 16, 1);
            RETURN;
        END

        CREATE CLUSTERED INDEX [CX_ERF_POD_Encounter]
            ON #ERF ([POD], [SK_EncounterID]);

        SET @IP_StartTime = SYSDATETIME();
        UPDATE f
        SET f.Is_ERF_Eligible = CASE WHEN e.SK_EncounterID IS NULL THEN 0 ELSE 1 END,
            f.ERF_MFF_Applied = e.ERF_MFF_Applied,
            f.ERF_Total_Cost_Incl_MFF = e.ERF_Total_Cost_Incl_MFF,
            f.ETL_UpdateDateTime = CURRENT_TIMESTAMP
        FROM [Analytics].[tbl_Fact_IP_Activity] f
        LEFT JOIN #ERF e
            ON e.POD = 'IP'
           AND e.SK_EncounterID = f.SK_EncounterID
        WHERE f.Discharge_Date >= @WindowStartDate
          AND f.Discharge_Date <= @WindowEndDate
          AND (
                ISNULL(f.Is_ERF_Eligible, 0) <> CASE WHEN e.SK_EncounterID IS NULL THEN 0 ELSE 1 END
             OR ISNULL(f.ERF_MFF_Applied, -1.00) <> ISNULL(e.ERF_MFF_Applied, -1.00)
             OR ISNULL(f.ERF_Total_Cost_Incl_MFF, -1.00) <> ISNULL(e.ERF_Total_Cost_Incl_MFF, -1.00)
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

        SET @OP_StartTime = SYSDATETIME();
        UPDATE f
        SET f.Is_ERF_Eligible = CASE WHEN e.SK_EncounterID IS NULL THEN 0 ELSE 1 END,
            f.ERF_MFF_Applied = e.ERF_MFF_Applied,
            f.ERF_Total_Cost_Incl_MFF = e.ERF_Total_Cost_Incl_MFF,
            f.ETL_UpdateDateTime = CURRENT_TIMESTAMP
        FROM [Analytics].[tbl_Fact_OP_Activity] f
        LEFT JOIN #ERF e
            ON e.POD = 'OP'
           AND e.SK_EncounterID = f.SK_EncounterID
        WHERE f.Appointment_Date >= @WindowStartDate
          AND f.Appointment_Date <= @WindowEndDate
          AND (
                ISNULL(f.Is_ERF_Eligible, 0) <> CASE WHEN e.SK_EncounterID IS NULL THEN 0 ELSE 1 END
             OR ISNULL(f.ERF_MFF_Applied, -1.00) <> ISNULL(e.ERF_MFF_Applied, -1.00)
             OR ISNULL(f.ERF_Total_Cost_Incl_MFF, -1.00) <> ISNULL(e.ERF_Total_Cost_Incl_MFF, -1.00)
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
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();
        PRINT 'ErrorNumber:' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' ErrorMessage:' + ISNULL(@ErrorMessage, '');
        IF @BatchID IS NOT NULL
        BEGIN
            EXEC [Analytics].[sp_Log_Table_Load]
                @BatchID = @BatchID,
                @TableName = 'Analytics.tbl_Fact_IP_Activity',
                @LoadType = 'Update',
                @RowsAffected = 0,
                @RowsFailed = 1,
                @Status = 'Failed',
                @ErrorMessage = @ErrorMessage;

            EXEC [Analytics].[sp_Log_Table_Load]
                @BatchID = @BatchID,
                @TableName = 'Analytics.tbl_Fact_OP_Activity',
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

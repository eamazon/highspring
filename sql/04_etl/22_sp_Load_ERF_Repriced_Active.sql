USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('[Analytics].[sp_Load_ERF_Repriced_Active]', 'P') IS NOT NULL
DROP PROCEDURE [Analytics].[sp_Load_ERF_Repriced_Active];
GO

/**
Script Name:   22_sp_Load_ERF_Repriced_Active.sql
Description:   Loads current FY ERF repriced outputs into Analytics.tbl_ERF_Repriced_Active.
Author:        Sridhar Peddi
Created:       2026-01-15

Notes:
- Window defaults to FY start through SUS inclusion cutoff.
- Current FY only.
**/
CREATE PROCEDURE [Analytics].[sp_Load_ERF_Repriced_Active]
    @FinYearStart CHAR(4),
    @FromDate DATE = NULL,
    @ToDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ETL_Start DATETIME2 = CURRENT_TIMESTAMP;
    DECLARE @BatchName VARCHAR(100) = 'Load_ERF_Repriced_Active';
    DECLARE @BatchID INT = NULL;
    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsDeleted INT = 0;
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @FinYearInt INT;
    DECLARE @FinancialYear VARCHAR(9);
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

    IF OBJECT_ID('[Analytics].[tbl_ERF_Repriced_Active]', 'U') IS NULL
    BEGIN
        RAISERROR('Required table [Analytics].[tbl_ERF_Repriced_Active] was not found.', 16, 1);
        RETURN;
    END
    IF COL_LENGTH('[Analytics].[tbl_ERF_Repriced_Active]', 'dv_FinYear') < 9
    BEGIN
        RAISERROR('Column [dv_FinYear] in [Analytics].[tbl_ERF_Repriced_Active] must be VARCHAR(9). Run the DDL script to apply the change.', 16, 1);
        RETURN;
    END

    BEGIN TRY
        EXEC [Analytics].[sp_Start_ETL_Batch]
            @BatchName = @BatchName,
            @BatchID = @BatchID OUTPUT;

        IF OBJECT_ID('tempdb..#ERF_WindowKeys') IS NOT NULL
            DROP TABLE #ERF_WindowKeys;

        SELECT DISTINCT
            src.SK_EncounterID,
            CAST('IP' AS VARCHAR(2)) AS POD
        INTO #ERF_WindowKeys
        FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active] src
        WHERE src.End_Date_Hospital_Provider_Spell >= @WindowStartDate
          AND src.End_Date_Hospital_Provider_Spell < DATEADD(DAY, 1, @WindowEndDate)
          AND src.dv_FinYear = @FinancialYear;

        INSERT INTO #ERF_WindowKeys (SK_EncounterID, POD)
        SELECT DISTINCT
            src.SK_EncounterID,
            CAST('OP' AS VARCHAR(2)) AS POD
        FROM [Data_Lab_SWL].[Unified].[tbl_OP_EncounterDenormalised_Active] src
        WHERE src.Appointment_Date >= @WindowStartDate
          AND src.Appointment_Date < DATEADD(DAY, 1, @WindowEndDate)
          AND src.dv_FinYear = @FinancialYear;

        DELETE t
        FROM [Analytics].[tbl_ERF_Repriced_Active] t
        INNER JOIN #ERF_WindowKeys w
            ON w.SK_EncounterID = t.SK_EncounterID
           AND w.POD = t.POD;

        SET @RowsDeleted = @@ROWCOUNT;

        INSERT INTO [Analytics].[tbl_ERF_Repriced_Active] (
            [SK_EncounterID],
            [POD],
            [dv_FinYear],
            [ERF_National_Price],
            [ERF_MFF_Applied],
            [ERF_Total_Cost_Incl_MFF],
            [ERF_Tariff_Used],
            [ETL_LoadDateTime]
        )
        SELECT
            v.SK_EncounterID,
            'IP' AS POD,
            v.dv_FinYear,
            CAST(v.Price AS DECIMAL(12,2)) AS ERF_National_Price,
            CAST(v.MFF_Applied AS DECIMAL(12,6)) AS ERF_MFF_Applied,
            CAST(v.TotalCostInclMFF AS DECIMAL(12,2)) AS ERF_Total_Cost_Incl_MFF,
            CAST(v.Tariff_Used AS VARCHAR(50)) AS ERF_Tariff_Used,
            @ETL_Start
        FROM [Analytics].[vw_IP_ERF] v
        INNER JOIN [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active] src
            ON src.SK_EncounterID = v.SK_EncounterID
        WHERE v.dv_FinYear = @FinancialYear
          AND src.End_Date_Hospital_Provider_Spell >= @WindowStartDate
          AND src.End_Date_Hospital_Provider_Spell < DATEADD(DAY, 1, @WindowEndDate)
        UNION ALL
        SELECT
            v.SK_EncounterID,
            'OP' AS POD,
            v.dv_FinYear,
            CAST(v.National_Price AS DECIMAL(12,2)) AS ERF_National_Price,
            CAST(v.MFF AS DECIMAL(12,6)) AS ERF_MFF_Applied,
            CAST(v.TotalCostInclMFF AS DECIMAL(12,2)) AS ERF_Total_Cost_Incl_MFF,
            CAST(v.Tariff_Used AS VARCHAR(50)) AS ERF_Tariff_Used,
            @ETL_Start
        FROM [Analytics].[vw_OP_ERF] v
        INNER JOIN [Data_Lab_SWL].[Unified].[tbl_OP_EncounterDenormalised_Active] src
            ON src.SK_EncounterID = v.SK_EncounterID
        WHERE v.dv_FinYear = @FinancialYear
          AND src.Appointment_Date >= @WindowStartDate
          AND src.Appointment_Date < DATEADD(DAY, 1, @WindowEndDate);

        SET @RowsInserted = @@ROWCOUNT;

        EXEC [Analytics].[sp_Log_Table_Load]
            @BatchID = @BatchID,
            @TableName = 'Analytics.tbl_ERF_Repriced_Active',
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
        PRINT 'Error Loading ERF Repriced Active: ' + ISNULL(@ErrorMessage, '');
        IF @BatchID IS NOT NULL
        BEGIN
            EXEC [Analytics].[sp_Log_Table_Load]
                @BatchID = @BatchID,
                @TableName = 'Analytics.tbl_ERF_Repriced_Active',
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

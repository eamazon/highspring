
USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('[Analytics].[sp_Load_Bridge_ERF_Activity]', 'P') IS NOT NULL
DROP PROCEDURE [Analytics].[sp_Load_Bridge_ERF_Activity];
GO

/**
Script Name:   13_sp_Load_Bridge_ERF_Activity.sql
Description:   ETL Procedure to load ERF bridge table for encounters present in Analytics facts.
              Sources Analytics ERF repriced views (25/26) and restricts to current fact window.
Author:        Sridhar Peddi
Created:       2026-01-09

Notes:
-- Reads from [Analytics].[vw_IP_ERF] and [Analytics].[vw_OP_ERF].
- Requires ERF views + dependencies to be deployed in Data_Lab_SWL.
- Designed for Phase 1 truncate/reload.

Parameters:
- @FinYearStart: Optional 4-char year filter, e.g. '2025' (matches LEFT(dv_FinYear,4)).
*/
CREATE PROCEDURE [Analytics].[sp_Load_Bridge_ERF_Activity]
    @FinYearStart CHAR(4) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ETL_Start DATETIME2 = CURRENT_TIMESTAMP;
    DECLARE @RowsInserted INT = 0;
    DECLARE @BatchName VARCHAR(100) = 'Bridge_ERF_Activity';
    DECLARE @BatchID INT = NULL;

    BEGIN TRY
        EXEC [Analytics].[sp_Start_ETL_Batch]
            @BatchName = @BatchName,
            @BatchID = @BatchID OUTPUT;

        PRINT 'Starting Load: [Analytics].[tbl_Bridge_ERF_Activity]';

        TRUNCATE TABLE [Analytics].[tbl_Bridge_ERF_Activity];

        ;WITH IP_SRC AS (
            SELECT
                v.SK_EncounterID,
                CAST('IP' AS VARCHAR(2)) AS POD,
                CAST(v.Price AS DECIMAL(12,2)) AS ERF_National_Price,
                CAST(v.MFF_Applied AS DECIMAL(12,2)) AS ERF_MFF_Applied,
                CAST(v.TotalCostInclMFF AS DECIMAL(12,2)) AS ERF_Total_Cost_Incl_MFF,
                CAST(v.Tariff_Used AS VARCHAR(50)) AS Tariff_Used,
                CAST(v.dv_FinYear AS VARCHAR(7)) AS ERF_Financial_Year
            FROM [Analytics].[vw_IP_ERF] v
            INNER JOIN [Analytics].[tbl_Fact_IP_Activity] f
                ON f.SK_EncounterID = v.SK_EncounterID
            WHERE (@FinYearStart IS NULL OR LEFT(v.dv_FinYear, 4) = @FinYearStart)
        ),
        OP_SRC AS (
            SELECT
                v.SK_EncounterID,
                CAST('OP' AS VARCHAR(2)) AS POD,
                CAST(v.National_Price AS DECIMAL(12,2)) AS ERF_National_Price,
                CAST(v.MFF AS DECIMAL(12,2)) AS ERF_MFF_Applied,
                CAST(v.TotalCostInclMFF AS DECIMAL(12,2)) AS ERF_Total_Cost_Incl_MFF,
                CAST(v.Tariff_Used AS VARCHAR(50)) AS Tariff_Used,
                CAST(v.dv_FinYear AS VARCHAR(7)) AS ERF_Financial_Year
            FROM [Analytics].[vw_OP_ERF] v
            INNER JOIN [Analytics].[tbl_Fact_OP_Activity] f
                ON f.SK_EncounterID = v.SK_EncounterID
            WHERE (@FinYearStart IS NULL OR LEFT(v.dv_FinYear, 4) = @FinYearStart)
        )
        INSERT INTO [Analytics].[tbl_Bridge_ERF_Activity] (
            [SK_EncounterID],
            [POD],
            [ERF_National_Price],
            [ERF_MFF_Applied],
            [ERF_Total_Cost_Incl_MFF],
            [Tariff_Used],
            [ERF_Financial_Year],
            [Is_ERF_Eligible],
            [ETL_LoadDateTime]
        )
        SELECT
            s.SK_EncounterID,
            s.POD,
            s.ERF_National_Price,
            s.ERF_MFF_Applied,
            s.ERF_Total_Cost_Incl_MFF,
            s.Tariff_Used,
            s.ERF_Financial_Year,
            CAST(1 AS BIT) AS Is_ERF_Eligible,
            CURRENT_TIMESTAMP
        FROM (
            SELECT * FROM IP_SRC
            UNION ALL
            SELECT * FROM OP_SRC
        ) s;

        SET @RowsInserted = @@ROWCOUNT;
        PRINT 'Completed Load: [Analytics].[tbl_Bridge_ERF_Activity]';

        EXEC [Analytics].[sp_Log_Table_Load]
            @BatchID = @BatchID,
            @TableName = 'Analytics.tbl_Bridge_ERF_Activity',
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
                @TableName = 'Analytics.tbl_Bridge_ERF_Activity',
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

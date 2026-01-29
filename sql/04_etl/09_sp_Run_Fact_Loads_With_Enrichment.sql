
USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('[Analytics].[sp_Run_Fact_Loads_With_Enrichment]', 'P') IS NOT NULL
DROP PROCEDURE [Analytics].[sp_Run_Fact_Loads_With_Enrichment];
GO

/**
Script Name:   09_sp_Run_Fact_Loads_With_Enrichment.sql
Description:   Orchestrates fact loads and enrichment in a single call to avoid omissions.
Author:        Sridhar Peddi
Created:       2026-01-13

Notes:
- CAM/ERF/OpPlan enrichments assume precompute tables are populated.
- AE fact load is currently disabled (do not run).

Parameters:
- @FromDate/@ToDate: optional window (passed to fact loads and enrichments)
- @FinYearStart: required for Operating Plan + ERF enrichment
- @FinancialYear: required for CAM enrichment
- @ProviderCode: optional CAM filter
*/
CREATE PROCEDURE [Analytics].[sp_Run_Fact_Loads_With_Enrichment]
    @FromDate DATE = NULL,
    @ToDate DATE = NULL,
    @FinYearStart CHAR(4),
    @FinancialYear VARCHAR(9),
    @ProviderCode VARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @FinYearStart IS NULL OR LTRIM(RTRIM(@FinYearStart)) = ''
    BEGIN
        RAISERROR('Parameter @FinYearStart is required (e.g. ''2025'')', 16, 1);
        RETURN;
    END

    IF @FinancialYear IS NULL OR LTRIM(RTRIM(@FinancialYear)) = ''
    BEGIN
        RAISERROR('Parameter @FinancialYear is required (e.g. ''2025/2026'')', 16, 1);
        RETURN;
    END

    EXEC [Analytics].[sp_Load_Fact_IP_Activity]
        @FromDate = @FromDate,
        @ToDate = @ToDate;

    EXEC [Analytics].[sp_Load_Fact_OP_Activity]
        @FromDate = @FromDate,
        @ToDate = @ToDate;

    -- AE fact load is currently disabled (do not run)
    -- EXEC [Analytics].[sp_Load_Fact_AE_Activity]
    --     @FromDate = @FromDate,
    --     @ToDate = @ToDate;

    EXEC [Analytics].[sp_Enrich_Facts_Operating_Plan]
        @FinYearStart = @FinYearStart,
        @FromDate = @FromDate,
        @ToDate = @ToDate;

    EXEC [Analytics].[sp_Enrich_Facts_ERF]
        @FinYearStart = @FinYearStart,
        @FromDate = @FromDate,
        @ToDate = @ToDate;

    EXEC [Analytics].[sp_Enrich_Facts_CAM]
        @FinancialYear = @FinancialYear,
        @ProviderCode = @ProviderCode,
        @FromDate = @FromDate,
        @ToDate = @ToDate;
END
GO

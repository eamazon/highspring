
USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('[Analytics].[sp_Validate_Fact_Data]', 'P') IS NOT NULL
    DROP PROCEDURE [Analytics].[sp_Validate_Fact_Data];
GO

/**
Script Name:   01_sp_Validate_Fact_Data.sql
Description:   Comprehensive automated validation comparing Analytics facts vs Unified source.
               Uses EXACT same column mappings as the fact loader procedures.
               Returns PASS/FAIL for each test with variance details.

               v2.0 - Enhanced distribution validation with health scores and materiality filtering

Author:        Sridhar Peddi
Created:       2026-01-28
Updated:       2026-01-29

Usage:
    EXEC [Analytics].[sp_Validate_Fact_Data]
        @FromDate = '2025-04-01',
        @ToDate = '2025-12-31',
        @VarianceThresholdPct = 1.0,
        @UnknownThresholdPct = 5.0,
        @MaterialityThreshold = 100;

Source Tables (same as fact loaders):
    IP: [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active]
    OP: [Data_Lab_SWL].[Unified].[tbl_OP_EncounterDenormalised_Active]
**/
CREATE PROCEDURE [Analytics].[sp_Validate_Fact_Data]
    @FromDate DATE = '2025-04-01',
    @ToDate DATE = '2025-12-31',
    @VarianceThresholdPct DECIMAL(5,2) = 1.0,
    @UnknownThresholdPct DECIMAL(5,2) = 5.0,
    @MaterialityThreshold INT = 100,  -- Minimum records for a code to be flagged
    @FailOnError BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    -- Results table
    CREATE TABLE #ValidationResults (
        Test_ID INT IDENTITY(1,1),
        Domain VARCHAR(10),
        Test_Category VARCHAR(50),
        Test_Name VARCHAR(100),
        Source_Value BIGINT,
        Target_Value BIGINT,
        Variance_Pct DECIMAL(10,4),
        Threshold_Pct DECIMAL(5,2),
        Status VARCHAR(10),
        Details VARCHAR(500)
    );

    -- Distribution detail table (for Section 3)
    CREATE TABLE #DistributionDetail (
        Domain VARCHAR(10),
        Dimension_Name VARCHAR(50),
        Code VARCHAR(100),
        Source_Count BIGINT,
        Target_Count BIGINT,
        Difference BIGINT,
        Variance_Pct DECIMAL(10,4),
        Is_Material BIT,
        Exceeds_Threshold BIT
    );

    -- Distribution health summary table
    CREATE TABLE #DistributionHealth (
        Domain VARCHAR(10),
        Dimension_Name VARCHAR(50),
        Total_Codes INT,
        Codes_Matched INT,
        Codes_Mismatched INT,
        Total_Source_Records BIGINT,
        Total_Target_Records BIGINT,
        Total_Record_Discrepancy BIGINT,
        Match_Rate_Pct DECIMAL(5,2),
        Health_Status VARCHAR(20)
    );

    DECLARE @SourceCount BIGINT, @TargetCount BIGINT, @Variance DECIMAL(10,4);
    DECLARE @TotalCount BIGINT, @UnknownCount BIGINT, @UnknownPct DECIMAL(10,4);
    DECLARE @OrphanCount BIGINT;

    PRINT '================================================================';
    PRINT 'COMPREHENSIVE FACT VALIDATION - USING EXACT LOADER MAPPINGS';
    PRINT 'Date Range: ' + CAST(@FromDate AS VARCHAR) + ' to ' + CAST(@ToDate AS VARCHAR);
    PRINT 'Row Count Variance Threshold: ' + CAST(@VarianceThresholdPct AS VARCHAR) + '%';
    PRINT 'Unknown Rate Threshold: ' + CAST(@UnknownThresholdPct AS VARCHAR) + '%';
    PRINT 'Materiality Threshold: ' + CAST(@MaterialityThreshold AS VARCHAR) + ' records';
    PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
    PRINT '================================================================';
    PRINT '';

    -- ==========================================================================
    -- SECTION 1: ROW COUNT VALIDATION
    -- ==========================================================================
    PRINT '>>> Section 1: Row Count Validation';

    -- IP Total Row Count (same source as loader: tbl_IP_EncounterDenormalised_Active)
    SELECT @TargetCount = COUNT(*)
    FROM [Analytics].[tbl_Fact_IP_Activity]
    WHERE Discharge_Date BETWEEN @FromDate AND @ToDate;

    SELECT @SourceCount = COUNT(*)
    FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active]
    WHERE End_Date_Hospital_Provider_Spell BETWEEN @FromDate AND @ToDate;

    SET @Variance = CASE WHEN @SourceCount = 0 THEN 0 ELSE ABS(@TargetCount - @SourceCount) * 100.0 / @SourceCount END;

    INSERT INTO #ValidationResults VALUES ('IP', 'Row Count', 'Total Records', @SourceCount, @TargetCount, @Variance, @VarianceThresholdPct,
        CASE WHEN @Variance <= @VarianceThresholdPct THEN 'PASS' ELSE 'FAIL' END,
        'Source: ' + FORMAT(@SourceCount, 'N0') + ' | Target: ' + FORMAT(@TargetCount, 'N0'));

    -- OP Total Row Count (same source as loader: tbl_OP_EncounterDenormalised_Active)
    SELECT @TargetCount = COUNT(*)
    FROM [Analytics].[tbl_Fact_OP_Activity]
    WHERE Appointment_Date BETWEEN @FromDate AND @ToDate;

    SELECT @SourceCount = COUNT(*)
    FROM [Data_Lab_SWL].[Unified].[tbl_OP_EncounterDenormalised_Active]
    WHERE Appointment_Date BETWEEN @FromDate AND @ToDate;

    SET @Variance = CASE WHEN @SourceCount = 0 THEN 0 ELSE ABS(@TargetCount - @SourceCount) * 100.0 / @SourceCount END;

    INSERT INTO #ValidationResults VALUES ('OP', 'Row Count', 'Total Records', @SourceCount, @TargetCount, @Variance, @VarianceThresholdPct,
        CASE WHEN @Variance <= @VarianceThresholdPct THEN 'PASS' ELSE 'FAIL' END,
        'Source: ' + FORMAT(@SourceCount, 'N0') + ' | Target: ' + FORMAT(@TargetCount, 'N0'));

    -- ==========================================================================
    -- SECTION 2: MONTHLY DISTRIBUTION VALIDATION
    -- ==========================================================================
    PRINT '>>> Section 2: Monthly Distribution';

    -- IP Monthly
    ;WITH SourceMonthly AS (
        SELECT FORMAT(End_Date_Hospital_Provider_Spell, 'yyyy-MM') AS Month, COUNT(*) AS Cnt
        FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active]
        WHERE End_Date_Hospital_Provider_Spell BETWEEN @FromDate AND @ToDate
        GROUP BY FORMAT(End_Date_Hospital_Provider_Spell, 'yyyy-MM')
    ),
    TargetMonthly AS (
        SELECT FORMAT(Discharge_Date, 'yyyy-MM') AS Month, COUNT(*) AS Cnt
        FROM [Analytics].[tbl_Fact_IP_Activity]
        WHERE Discharge_Date BETWEEN @FromDate AND @ToDate
        GROUP BY FORMAT(Discharge_Date, 'yyyy-MM')
    )
    INSERT INTO #ValidationResults
    SELECT 'IP', 'Monthly', 'Month: ' + COALESCE(s.Month, t.Month),
           ISNULL(s.Cnt, 0), ISNULL(t.Cnt, 0),
           CASE WHEN ISNULL(s.Cnt, 0) = 0 THEN 100.0 ELSE ABS(ISNULL(t.Cnt, 0) - s.Cnt) * 100.0 / s.Cnt END,
           @VarianceThresholdPct,
           CASE WHEN CASE WHEN ISNULL(s.Cnt, 0) = 0 THEN 100.0 ELSE ABS(ISNULL(t.Cnt, 0) - s.Cnt) * 100.0 / s.Cnt END <= @VarianceThresholdPct THEN 'PASS' ELSE 'FAIL' END,
           'Source: ' + FORMAT(ISNULL(s.Cnt, 0), 'N0') + ' | Target: ' + FORMAT(ISNULL(t.Cnt, 0), 'N0')
    FROM SourceMonthly s FULL OUTER JOIN TargetMonthly t ON s.Month = t.Month;

    -- OP Monthly
    ;WITH SourceMonthly AS (
        SELECT FORMAT(Appointment_Date, 'yyyy-MM') AS Month, COUNT(*) AS Cnt
        FROM [Data_Lab_SWL].[Unified].[tbl_OP_EncounterDenormalised_Active]
        WHERE Appointment_Date BETWEEN @FromDate AND @ToDate
        GROUP BY FORMAT(Appointment_Date, 'yyyy-MM')
    ),
    TargetMonthly AS (
        SELECT FORMAT(Appointment_Date, 'yyyy-MM') AS Month, COUNT(*) AS Cnt
        FROM [Analytics].[tbl_Fact_OP_Activity]
        WHERE Appointment_Date BETWEEN @FromDate AND @ToDate
        GROUP BY FORMAT(Appointment_Date, 'yyyy-MM')
    )
    INSERT INTO #ValidationResults
    SELECT 'OP', 'Monthly', 'Month: ' + COALESCE(s.Month, t.Month),
           ISNULL(s.Cnt, 0), ISNULL(t.Cnt, 0),
           CASE WHEN ISNULL(s.Cnt, 0) = 0 THEN 100.0 ELSE ABS(ISNULL(t.Cnt, 0) - s.Cnt) * 100.0 / s.Cnt END,
           @VarianceThresholdPct,
           CASE WHEN CASE WHEN ISNULL(s.Cnt, 0) = 0 THEN 100.0 ELSE ABS(ISNULL(t.Cnt, 0) - s.Cnt) * 100.0 / s.Cnt END <= @VarianceThresholdPct THEN 'PASS' ELSE 'FAIL' END,
           'Source: ' + FORMAT(ISNULL(s.Cnt, 0), 'N0') + ' | Target: ' + FORMAT(ISNULL(t.Cnt, 0), 'N0')
    FROM SourceMonthly s FULL OUTER JOIN TargetMonthly t ON s.Month = t.Month;

    -- ==========================================================================
    -- SECTION 3: DIMENSION DISTRIBUTION VALIDATION (Enhanced with Health Scores)
    -- Collects ALL codes, calculates health metrics, flags material issues
    -- ==========================================================================
    PRINT '>>> Section 3: Dimension Distribution (Source vs Target)';

    -- ----- IP COMMISSIONER -----
    ;WITH SourceDist AS (
        SELECT
            CASE WHEN RIGHT(Organisation_Code_Code_of_Commissioner, 2) = '00'
                 THEN LEFT(Organisation_Code_Code_of_Commissioner, 3)
                 ELSE Organisation_Code_Code_of_Commissioner END AS Code,
            COUNT(*) AS Cnt
        FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active]
        WHERE End_Date_Hospital_Provider_Spell BETWEEN @FromDate AND @ToDate
        GROUP BY CASE WHEN RIGHT(Organisation_Code_Code_of_Commissioner, 2) = '00'
                      THEN LEFT(Organisation_Code_Code_of_Commissioner, 3)
                      ELSE Organisation_Code_Code_of_Commissioner END
    ),
    TargetDist AS (
        SELECT d.Commissioner_Code AS Code, COUNT(*) AS Cnt
        FROM [Analytics].[tbl_Fact_IP_Activity] f
        JOIN [Analytics].[tbl_Dim_Commissioner] d ON f.SK_CommissionerID = d.SK_CommissionerID
        WHERE f.Discharge_Date BETWEEN @FromDate AND @ToDate
        GROUP BY d.Commissioner_Code
    )
    INSERT INTO #DistributionDetail
    SELECT 'IP', 'Commissioner', ISNULL(COALESCE(s.Code, t.Code), 'NULL'),
           ISNULL(s.Cnt, 0), ISNULL(t.Cnt, 0),
           ISNULL(t.Cnt, 0) - ISNULL(s.Cnt, 0),
           CASE WHEN ISNULL(s.Cnt, 0) = 0 THEN 100.0 ELSE ABS(ISNULL(t.Cnt, 0) - s.Cnt) * 100.0 / s.Cnt END,
           CASE WHEN ISNULL(s.Cnt, 0) >= @MaterialityThreshold OR ISNULL(t.Cnt, 0) >= @MaterialityThreshold THEN 1 ELSE 0 END,
           CASE WHEN CASE WHEN ISNULL(s.Cnt, 0) = 0 THEN 100.0 ELSE ABS(ISNULL(t.Cnt, 0) - s.Cnt) * 100.0 / s.Cnt END > @VarianceThresholdPct THEN 1 ELSE 0 END
    FROM SourceDist s FULL OUTER JOIN TargetDist t ON s.Code = t.Code;

    -- ----- IP PROVIDER -----
    ;WITH SourceDist AS (
        SELECT
            CASE WHEN RIGHT(Organisation_Code_Code_of_Provider, 2) = '00'
                 THEN LEFT(Organisation_Code_Code_of_Provider, 3)
                 ELSE Organisation_Code_Code_of_Provider END AS Code,
            COUNT(*) AS Cnt
        FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active]
        WHERE End_Date_Hospital_Provider_Spell BETWEEN @FromDate AND @ToDate
        GROUP BY CASE WHEN RIGHT(Organisation_Code_Code_of_Provider, 2) = '00'
                      THEN LEFT(Organisation_Code_Code_of_Provider, 3)
                      ELSE Organisation_Code_Code_of_Provider END
    ),
    TargetDist AS (
        SELECT d.Provider_Code AS Code, COUNT(*) AS Cnt
        FROM [Analytics].[tbl_Fact_IP_Activity] f
        JOIN [Analytics].[vw_Dim_Provider] d ON f.SK_ProviderID = d.SK_ProviderID
        WHERE f.Discharge_Date BETWEEN @FromDate AND @ToDate
        GROUP BY d.Provider_Code
    )
    INSERT INTO #DistributionDetail
    SELECT 'IP', 'Provider', ISNULL(COALESCE(s.Code, t.Code), 'NULL'),
           ISNULL(s.Cnt, 0), ISNULL(t.Cnt, 0),
           ISNULL(t.Cnt, 0) - ISNULL(s.Cnt, 0),
           CASE WHEN ISNULL(s.Cnt, 0) = 0 THEN 100.0 ELSE ABS(ISNULL(t.Cnt, 0) - s.Cnt) * 100.0 / s.Cnt END,
           CASE WHEN ISNULL(s.Cnt, 0) >= @MaterialityThreshold OR ISNULL(t.Cnt, 0) >= @MaterialityThreshold THEN 1 ELSE 0 END,
           CASE WHEN CASE WHEN ISNULL(s.Cnt, 0) = 0 THEN 100.0 ELSE ABS(ISNULL(t.Cnt, 0) - s.Cnt) * 100.0 / s.Cnt END > @VarianceThresholdPct THEN 1 ELSE 0 END
    FROM SourceDist s FULL OUTER JOIN TargetDist t ON s.Code = t.Code;

    -- ----- IP SPECIALTY -----
    ;WITH SourceDist AS (
        SELECT Treatment_Function_Code AS Code, COUNT(*) AS Cnt
        FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active]
        WHERE End_Date_Hospital_Provider_Spell BETWEEN @FromDate AND @ToDate
        GROUP BY Treatment_Function_Code
    ),
    TargetDist AS (
        SELECT d.BK_SpecialtyCode AS Code, COUNT(*) AS Cnt
        FROM [Analytics].[tbl_Fact_IP_Activity] f
        JOIN [Analytics].[vw_Dim_Specialty] d ON f.SK_SpecialtyID = d.SK_SpecialtyID
        WHERE f.Discharge_Date BETWEEN @FromDate AND @ToDate
        GROUP BY d.BK_SpecialtyCode
    )
    INSERT INTO #DistributionDetail
    SELECT 'IP', 'Specialty', ISNULL(COALESCE(s.Code, t.Code), 'NULL'),
           ISNULL(s.Cnt, 0), ISNULL(t.Cnt, 0),
           ISNULL(t.Cnt, 0) - ISNULL(s.Cnt, 0),
           CASE WHEN ISNULL(s.Cnt, 0) = 0 THEN 100.0 ELSE ABS(ISNULL(t.Cnt, 0) - s.Cnt) * 100.0 / s.Cnt END,
           CASE WHEN ISNULL(s.Cnt, 0) >= @MaterialityThreshold OR ISNULL(t.Cnt, 0) >= @MaterialityThreshold THEN 1 ELSE 0 END,
           CASE WHEN CASE WHEN ISNULL(s.Cnt, 0) = 0 THEN 100.0 ELSE ABS(ISNULL(t.Cnt, 0) - s.Cnt) * 100.0 / s.Cnt END > @VarianceThresholdPct THEN 1 ELSE 0 END
    FROM SourceDist s FULL OUTER JOIN TargetDist t ON s.Code = t.Code;

    -- ----- IP GENDER -----
    ;WITH SourceDist AS (
        SELECT Gender_Code AS Code, COUNT(*) AS Cnt
        FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active]
        WHERE End_Date_Hospital_Provider_Spell BETWEEN @FromDate AND @ToDate
        GROUP BY Gender_Code
    ),
    TargetDist AS (
        SELECT d.GenderCode AS Code, COUNT(*) AS Cnt
        FROM [Analytics].[tbl_Fact_IP_Activity] f
        JOIN [Analytics].[vw_Dim_Gender] d ON f.SK_GenderID = d.SK_GenderID
        WHERE f.Discharge_Date BETWEEN @FromDate AND @ToDate
        GROUP BY d.GenderCode
    )
    INSERT INTO #DistributionDetail
    SELECT 'IP', 'Gender', ISNULL(COALESCE(s.Code, t.Code), 'NULL'),
           ISNULL(s.Cnt, 0), ISNULL(t.Cnt, 0),
           ISNULL(t.Cnt, 0) - ISNULL(s.Cnt, 0),
           CASE WHEN ISNULL(s.Cnt, 0) = 0 THEN 100.0 ELSE ABS(ISNULL(t.Cnt, 0) - s.Cnt) * 100.0 / s.Cnt END,
           CASE WHEN ISNULL(s.Cnt, 0) >= @MaterialityThreshold OR ISNULL(t.Cnt, 0) >= @MaterialityThreshold THEN 1 ELSE 0 END,
           CASE WHEN CASE WHEN ISNULL(s.Cnt, 0) = 0 THEN 100.0 ELSE ABS(ISNULL(t.Cnt, 0) - s.Cnt) * 100.0 / s.Cnt END > @VarianceThresholdPct THEN 1 ELSE 0 END
    FROM SourceDist s FULL OUTER JOIN TargetDist t ON s.Code = t.Code;

    -- ----- IP ADMISSION METHOD -----
    ;WITH SourceDist AS (
        SELECT Admission_Method_Hospital_Provider_Spell AS Code, COUNT(*) AS Cnt
        FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active]
        WHERE End_Date_Hospital_Provider_Spell BETWEEN @FromDate AND @ToDate
        GROUP BY Admission_Method_Hospital_Provider_Spell
    ),
    TargetDist AS (
        SELECT d.Admission_Method_Code AS Code, COUNT(*) AS Cnt
        FROM [Analytics].[tbl_Fact_IP_Activity] f
        JOIN [Analytics].[vw_Dim_Admission_Method] d ON f.SK_Admission_MethodID = d.SK_AdmissionMethodID
        WHERE f.Discharge_Date BETWEEN @FromDate AND @ToDate
        GROUP BY d.Admission_Method_Code
    )
    INSERT INTO #DistributionDetail
    SELECT 'IP', 'Admission Method', ISNULL(COALESCE(s.Code, t.Code), 'NULL'),
           ISNULL(s.Cnt, 0), ISNULL(t.Cnt, 0),
           ISNULL(t.Cnt, 0) - ISNULL(s.Cnt, 0),
           CASE WHEN ISNULL(s.Cnt, 0) = 0 THEN 100.0 ELSE ABS(ISNULL(t.Cnt, 0) - s.Cnt) * 100.0 / s.Cnt END,
           CASE WHEN ISNULL(s.Cnt, 0) >= @MaterialityThreshold OR ISNULL(t.Cnt, 0) >= @MaterialityThreshold THEN 1 ELSE 0 END,
           CASE WHEN CASE WHEN ISNULL(s.Cnt, 0) = 0 THEN 100.0 ELSE ABS(ISNULL(t.Cnt, 0) - s.Cnt) * 100.0 / s.Cnt END > @VarianceThresholdPct THEN 1 ELSE 0 END
    FROM SourceDist s FULL OUTER JOIN TargetDist t ON s.Code = t.Code;

    -- ----- IP DISCHARGE METHOD -----
    ;WITH SourceDist AS (
        SELECT Discharge_Method_Hospital_Provider_Spell AS Code, COUNT(*) AS Cnt
        FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active]
        WHERE End_Date_Hospital_Provider_Spell BETWEEN @FromDate AND @ToDate
        GROUP BY Discharge_Method_Hospital_Provider_Spell
    ),
    TargetDist AS (
        SELECT d.Discharge_Method_Code AS Code, COUNT(*) AS Cnt
        FROM [Analytics].[tbl_Fact_IP_Activity] f
        JOIN [Analytics].[vw_Dim_Discharge_Method] d ON f.SK_Discharge_MethodID = d.SK_DischargeMethodID
        WHERE f.Discharge_Date BETWEEN @FromDate AND @ToDate
        GROUP BY d.Discharge_Method_Code
    )
    INSERT INTO #DistributionDetail
    SELECT 'IP', 'Discharge Method', ISNULL(COALESCE(s.Code, t.Code), 'NULL'),
           ISNULL(s.Cnt, 0), ISNULL(t.Cnt, 0),
           ISNULL(t.Cnt, 0) - ISNULL(s.Cnt, 0),
           CASE WHEN ISNULL(s.Cnt, 0) = 0 THEN 100.0 ELSE ABS(ISNULL(t.Cnt, 0) - s.Cnt) * 100.0 / s.Cnt END,
           CASE WHEN ISNULL(s.Cnt, 0) >= @MaterialityThreshold OR ISNULL(t.Cnt, 0) >= @MaterialityThreshold THEN 1 ELSE 0 END,
           CASE WHEN CASE WHEN ISNULL(s.Cnt, 0) = 0 THEN 100.0 ELSE ABS(ISNULL(t.Cnt, 0) - s.Cnt) * 100.0 / s.Cnt END > @VarianceThresholdPct THEN 1 ELSE 0 END
    FROM SourceDist s FULL OUTER JOIN TargetDist t ON s.Code = t.Code;

    -- ----- IP GP PRACTICE -----
    ;WITH SourceDist AS (
        SELECT GP_Practice_Code_Original_Data AS Code, COUNT(*) AS Cnt
        FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active]
        WHERE End_Date_Hospital_Provider_Spell BETWEEN @FromDate AND @ToDate
        GROUP BY GP_Practice_Code_Original_Data
    ),
    TargetDist AS (
        SELECT d.GPPractice_Code AS Code, COUNT(*) AS Cnt
        FROM [Analytics].[tbl_Fact_IP_Activity] f
        JOIN [Analytics].[tbl_Dim_GPPractice] d ON f.SK_GPPracticeID = d.SK_GPPracticeID
        WHERE f.Discharge_Date BETWEEN @FromDate AND @ToDate
        GROUP BY d.GPPractice_Code
    )
    INSERT INTO #DistributionDetail
    SELECT 'IP', 'GP Practice', ISNULL(COALESCE(s.Code, t.Code), 'NULL'),
           ISNULL(s.Cnt, 0), ISNULL(t.Cnt, 0),
           ISNULL(t.Cnt, 0) - ISNULL(s.Cnt, 0),
           CASE WHEN ISNULL(s.Cnt, 0) = 0 THEN 100.0 ELSE ABS(ISNULL(t.Cnt, 0) - s.Cnt) * 100.0 / s.Cnt END,
           CASE WHEN ISNULL(s.Cnt, 0) >= @MaterialityThreshold OR ISNULL(t.Cnt, 0) >= @MaterialityThreshold THEN 1 ELSE 0 END,
           CASE WHEN CASE WHEN ISNULL(s.Cnt, 0) = 0 THEN 100.0 ELSE ABS(ISNULL(t.Cnt, 0) - s.Cnt) * 100.0 / s.Cnt END > @VarianceThresholdPct THEN 1 ELSE 0 END
    FROM SourceDist s FULL OUTER JOIN TargetDist t ON s.Code = t.Code;

    -- ----- OP COMMISSIONER -----
    ;WITH SourceDist AS (
        SELECT
            CASE WHEN RIGHT(Organisation_Code_Code_of_Commissioner, 2) = '00'
                 THEN LEFT(Organisation_Code_Code_of_Commissioner, 3)
                 ELSE Organisation_Code_Code_of_Commissioner END AS Code,
            COUNT(*) AS Cnt
        FROM [Data_Lab_SWL].[Unified].[tbl_OP_EncounterDenormalised_Active]
        WHERE Appointment_Date BETWEEN @FromDate AND @ToDate
        GROUP BY CASE WHEN RIGHT(Organisation_Code_Code_of_Commissioner, 2) = '00'
                      THEN LEFT(Organisation_Code_Code_of_Commissioner, 3)
                      ELSE Organisation_Code_Code_of_Commissioner END
    ),
    TargetDist AS (
        SELECT d.Commissioner_Code AS Code, COUNT(*) AS Cnt
        FROM [Analytics].[tbl_Fact_OP_Activity] f
        JOIN [Analytics].[tbl_Dim_Commissioner] d ON f.SK_CommissionerID = d.SK_CommissionerID
        WHERE f.Appointment_Date BETWEEN @FromDate AND @ToDate
        GROUP BY d.Commissioner_Code
    )
    INSERT INTO #DistributionDetail
    SELECT 'OP', 'Commissioner', ISNULL(COALESCE(s.Code, t.Code), 'NULL'),
           ISNULL(s.Cnt, 0), ISNULL(t.Cnt, 0),
           ISNULL(t.Cnt, 0) - ISNULL(s.Cnt, 0),
           CASE WHEN ISNULL(s.Cnt, 0) = 0 THEN 100.0 ELSE ABS(ISNULL(t.Cnt, 0) - s.Cnt) * 100.0 / s.Cnt END,
           CASE WHEN ISNULL(s.Cnt, 0) >= @MaterialityThreshold OR ISNULL(t.Cnt, 0) >= @MaterialityThreshold THEN 1 ELSE 0 END,
           CASE WHEN CASE WHEN ISNULL(s.Cnt, 0) = 0 THEN 100.0 ELSE ABS(ISNULL(t.Cnt, 0) - s.Cnt) * 100.0 / s.Cnt END > @VarianceThresholdPct THEN 1 ELSE 0 END
    FROM SourceDist s FULL OUTER JOIN TargetDist t ON s.Code = t.Code;

    -- ----- OP PROVIDER -----
    ;WITH SourceDist AS (
        SELECT
            CASE WHEN RIGHT(Organisation_Code_Code_of_Provider, 2) = '00'
                 THEN LEFT(Organisation_Code_Code_of_Provider, 3)
                 ELSE Organisation_Code_Code_of_Provider END AS Code,
            COUNT(*) AS Cnt
        FROM [Data_Lab_SWL].[Unified].[tbl_OP_EncounterDenormalised_Active]
        WHERE Appointment_Date BETWEEN @FromDate AND @ToDate
        GROUP BY CASE WHEN RIGHT(Organisation_Code_Code_of_Provider, 2) = '00'
                      THEN LEFT(Organisation_Code_Code_of_Provider, 3)
                      ELSE Organisation_Code_Code_of_Provider END
    ),
    TargetDist AS (
        SELECT d.Provider_Code AS Code, COUNT(*) AS Cnt
        FROM [Analytics].[tbl_Fact_OP_Activity] f
        JOIN [Analytics].[vw_Dim_Provider] d ON f.SK_ProviderID = d.SK_ProviderID
        WHERE f.Appointment_Date BETWEEN @FromDate AND @ToDate
        GROUP BY d.Provider_Code
    )
    INSERT INTO #DistributionDetail
    SELECT 'OP', 'Provider', ISNULL(COALESCE(s.Code, t.Code), 'NULL'),
           ISNULL(s.Cnt, 0), ISNULL(t.Cnt, 0),
           ISNULL(t.Cnt, 0) - ISNULL(s.Cnt, 0),
           CASE WHEN ISNULL(s.Cnt, 0) = 0 THEN 100.0 ELSE ABS(ISNULL(t.Cnt, 0) - s.Cnt) * 100.0 / s.Cnt END,
           CASE WHEN ISNULL(s.Cnt, 0) >= @MaterialityThreshold OR ISNULL(t.Cnt, 0) >= @MaterialityThreshold THEN 1 ELSE 0 END,
           CASE WHEN CASE WHEN ISNULL(s.Cnt, 0) = 0 THEN 100.0 ELSE ABS(ISNULL(t.Cnt, 0) - s.Cnt) * 100.0 / s.Cnt END > @VarianceThresholdPct THEN 1 ELSE 0 END
    FROM SourceDist s FULL OUTER JOIN TargetDist t ON s.Code = t.Code;

    -- ----- OP SPECIALTY -----
    ;WITH SourceDist AS (
        SELECT Treatment_Function_Code AS Code, COUNT(*) AS Cnt
        FROM [Data_Lab_SWL].[Unified].[tbl_OP_EncounterDenormalised_Active]
        WHERE Appointment_Date BETWEEN @FromDate AND @ToDate
        GROUP BY Treatment_Function_Code
    ),
    TargetDist AS (
        SELECT d.BK_SpecialtyCode AS Code, COUNT(*) AS Cnt
        FROM [Analytics].[tbl_Fact_OP_Activity] f
        JOIN [Analytics].[vw_Dim_Specialty] d ON f.SK_SpecialtyID = d.SK_SpecialtyID
        WHERE f.Appointment_Date BETWEEN @FromDate AND @ToDate
        GROUP BY d.BK_SpecialtyCode
    )
    INSERT INTO #DistributionDetail
    SELECT 'OP', 'Specialty', ISNULL(COALESCE(s.Code, t.Code), 'NULL'),
           ISNULL(s.Cnt, 0), ISNULL(t.Cnt, 0),
           ISNULL(t.Cnt, 0) - ISNULL(s.Cnt, 0),
           CASE WHEN ISNULL(s.Cnt, 0) = 0 THEN 100.0 ELSE ABS(ISNULL(t.Cnt, 0) - s.Cnt) * 100.0 / s.Cnt END,
           CASE WHEN ISNULL(s.Cnt, 0) >= @MaterialityThreshold OR ISNULL(t.Cnt, 0) >= @MaterialityThreshold THEN 1 ELSE 0 END,
           CASE WHEN CASE WHEN ISNULL(s.Cnt, 0) = 0 THEN 100.0 ELSE ABS(ISNULL(t.Cnt, 0) - s.Cnt) * 100.0 / s.Cnt END > @VarianceThresholdPct THEN 1 ELSE 0 END
    FROM SourceDist s FULL OUTER JOIN TargetDist t ON s.Code = t.Code;

    -- ----- OP ATTENDANCE STATUS -----
    ;WITH SourceDist AS (
        SELECT NULLIF(LTRIM(RTRIM(Attended_Or_Did_Not_Attend)), '') AS Code, COUNT(*) AS Cnt
        FROM [Data_Lab_SWL].[Unified].[tbl_OP_EncounterDenormalised_Active]
        WHERE Appointment_Date BETWEEN @FromDate AND @ToDate
        GROUP BY NULLIF(LTRIM(RTRIM(Attended_Or_Did_Not_Attend)), '')
    ),
    TargetDist AS (
        SELECT LTRIM(RTRIM(d.Attendance_Status_Code)) AS Code, COUNT(*) AS Cnt
        FROM [Analytics].[tbl_Fact_OP_Activity] f
        JOIN [Analytics].[vw_Dim_Attendance_Status] d ON f.SK_Attendance_StatusID = d.SK_AttendanceStatusID
        WHERE f.Appointment_Date BETWEEN @FromDate AND @ToDate
        GROUP BY LTRIM(RTRIM(d.Attendance_Status_Code))
    )
    INSERT INTO #DistributionDetail
    SELECT 'OP', 'Attendance Status', ISNULL(COALESCE(s.Code, t.Code), 'NULL'),
           ISNULL(s.Cnt, 0), ISNULL(t.Cnt, 0),
           ISNULL(t.Cnt, 0) - ISNULL(s.Cnt, 0),
           CASE WHEN ISNULL(s.Cnt, 0) = 0 THEN 100.0 ELSE ABS(ISNULL(t.Cnt, 0) - s.Cnt) * 100.0 / s.Cnt END,
           CASE WHEN ISNULL(s.Cnt, 0) >= @MaterialityThreshold OR ISNULL(t.Cnt, 0) >= @MaterialityThreshold THEN 1 ELSE 0 END,
           CASE WHEN CASE WHEN ISNULL(s.Cnt, 0) = 0 THEN 100.0 ELSE ABS(ISNULL(t.Cnt, 0) - s.Cnt) * 100.0 / s.Cnt END > @VarianceThresholdPct THEN 1 ELSE 0 END
    FROM SourceDist s FULL OUTER JOIN TargetDist t ON s.Code = t.Code;

    -- ----- OP GP PRACTICE -----
    ;WITH SourceDist AS (
        SELECT GP_Practice_Code_Original_Data AS Code, COUNT(*) AS Cnt
        FROM [Data_Lab_SWL].[Unified].[tbl_OP_EncounterDenormalised_Active]
        WHERE Appointment_Date BETWEEN @FromDate AND @ToDate
        GROUP BY GP_Practice_Code_Original_Data
    ),
    TargetDist AS (
        SELECT d.GPPractice_Code AS Code, COUNT(*) AS Cnt
        FROM [Analytics].[tbl_Fact_OP_Activity] f
        JOIN [Analytics].[tbl_Dim_GPPractice] d ON f.SK_GPPracticeID = d.SK_GPPracticeID
        WHERE f.Appointment_Date BETWEEN @FromDate AND @ToDate
        GROUP BY d.GPPractice_Code
    )
    INSERT INTO #DistributionDetail
    SELECT 'OP', 'GP Practice', ISNULL(COALESCE(s.Code, t.Code), 'NULL'),
           ISNULL(s.Cnt, 0), ISNULL(t.Cnt, 0),
           ISNULL(t.Cnt, 0) - ISNULL(s.Cnt, 0),
           CASE WHEN ISNULL(s.Cnt, 0) = 0 THEN 100.0 ELSE ABS(ISNULL(t.Cnt, 0) - s.Cnt) * 100.0 / s.Cnt END,
           CASE WHEN ISNULL(s.Cnt, 0) >= @MaterialityThreshold OR ISNULL(t.Cnt, 0) >= @MaterialityThreshold THEN 1 ELSE 0 END,
           CASE WHEN CASE WHEN ISNULL(s.Cnt, 0) = 0 THEN 100.0 ELSE ABS(ISNULL(t.Cnt, 0) - s.Cnt) * 100.0 / s.Cnt END > @VarianceThresholdPct THEN 1 ELSE 0 END
    FROM SourceDist s FULL OUTER JOIN TargetDist t ON s.Code = t.Code;

    -- Calculate Distribution Health Summary
    INSERT INTO #DistributionHealth
    SELECT
        Domain,
        Dimension_Name,
        COUNT(*) AS Total_Codes,
        SUM(CASE WHEN Exceeds_Threshold = 0 THEN 1 ELSE 0 END) AS Codes_Matched,
        SUM(CASE WHEN Exceeds_Threshold = 1 THEN 1 ELSE 0 END) AS Codes_Mismatched,
        SUM(Source_Count) AS Total_Source_Records,
        SUM(Target_Count) AS Total_Target_Records,
        SUM(ABS(Difference)) AS Total_Record_Discrepancy,
        CAST(100.0 * SUM(CASE WHEN Exceeds_Threshold = 0 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS Match_Rate_Pct,
        CASE
            WHEN CAST(100.0 * SUM(CASE WHEN Exceeds_Threshold = 0 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) >= 99.0 THEN 'EXCELLENT'
            WHEN CAST(100.0 * SUM(CASE WHEN Exceeds_Threshold = 0 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) >= 95.0 THEN 'GOOD'
            WHEN CAST(100.0 * SUM(CASE WHEN Exceeds_Threshold = 0 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) >= 90.0 THEN 'ACCEPTABLE'
            ELSE 'NEEDS ATTENTION'
        END AS Health_Status
    FROM #DistributionDetail
    GROUP BY Domain, Dimension_Name;

    -- Add summary results to validation results
    INSERT INTO #ValidationResults
    SELECT
        Domain,
        'Distribution',
        Dimension_Name + ' Health',
        Total_Source_Records,
        Total_Target_Records,
        CASE WHEN Total_Source_Records = 0 THEN 0 ELSE ABS(Total_Target_Records - Total_Source_Records) * 100.0 / Total_Source_Records END,
        @VarianceThresholdPct,
        CASE WHEN Health_Status IN ('EXCELLENT', 'GOOD') THEN 'PASS' ELSE 'FAIL' END,
        Health_Status + ' (' + CAST(Match_Rate_Pct AS VARCHAR) + '% codes match) | ' +
        CAST(Codes_Mismatched AS VARCHAR) + ' of ' + CAST(Total_Codes AS VARCHAR) + ' codes with variance | ' +
        FORMAT(Total_Record_Discrepancy, 'N0') + ' total record discrepancy'
    FROM #DistributionHealth;

    -- ==========================================================================
    -- SECTION 4: REFERENTIAL INTEGRITY (Orphan Detection)
    -- ==========================================================================
    PRINT '>>> Section 4: Referential Integrity (Orphan Detection)';

    -- IP Orphan checks
    SELECT @OrphanCount = COUNT(*) FROM [Analytics].[tbl_Fact_IP_Activity] f
    LEFT JOIN [Analytics].[tbl_Dim_Commissioner] d ON f.SK_CommissionerID = d.SK_CommissionerID WHERE d.SK_CommissionerID IS NULL;
    INSERT INTO #ValidationResults VALUES ('IP', 'Referential Integrity', 'Commissioner Orphans', 0, @OrphanCount, CASE WHEN @OrphanCount = 0 THEN 0 ELSE 100 END, 0,
        CASE WHEN @OrphanCount = 0 THEN 'PASS' ELSE 'FAIL' END, FORMAT(@OrphanCount, 'N0') + ' orphan records');

    SELECT @OrphanCount = COUNT(*) FROM [Analytics].[tbl_Fact_IP_Activity] f
    LEFT JOIN [Analytics].[tbl_Dim_GPPractice] d ON f.SK_GPPracticeID = d.SK_GPPracticeID WHERE d.SK_GPPracticeID IS NULL AND f.SK_GPPracticeID IS NOT NULL;
    INSERT INTO #ValidationResults VALUES ('IP', 'Referential Integrity', 'GP Practice Orphans', 0, @OrphanCount, CASE WHEN @OrphanCount = 0 THEN 0 ELSE 100 END, 0,
        CASE WHEN @OrphanCount = 0 THEN 'PASS' ELSE 'FAIL' END, FORMAT(@OrphanCount, 'N0') + ' orphan records');

    SELECT @OrphanCount = COUNT(*) FROM [Analytics].[tbl_Fact_IP_Activity] f
    LEFT JOIN [Analytics].[vw_Dim_Provider] d ON f.SK_ProviderID = d.SK_ProviderID WHERE d.SK_ProviderID IS NULL;
    INSERT INTO #ValidationResults VALUES ('IP', 'Referential Integrity', 'Provider Orphans', 0, @OrphanCount, CASE WHEN @OrphanCount = 0 THEN 0 ELSE 100 END, 0,
        CASE WHEN @OrphanCount = 0 THEN 'PASS' ELSE 'FAIL' END, FORMAT(@OrphanCount, 'N0') + ' orphan records');

    SELECT @OrphanCount = COUNT(*) FROM [Analytics].[tbl_Fact_IP_Activity] f
    LEFT JOIN [Analytics].[vw_Dim_Specialty] d ON f.SK_SpecialtyID = d.SK_SpecialtyID WHERE d.SK_SpecialtyID IS NULL AND f.SK_SpecialtyID IS NOT NULL;
    INSERT INTO #ValidationResults VALUES ('IP', 'Referential Integrity', 'Specialty Orphans', 0, @OrphanCount, CASE WHEN @OrphanCount = 0 THEN 0 ELSE 100 END, 0,
        CASE WHEN @OrphanCount = 0 THEN 'PASS' ELSE 'FAIL' END, FORMAT(@OrphanCount, 'N0') + ' orphan records');

    -- OP Orphan checks
    SELECT @OrphanCount = COUNT(*) FROM [Analytics].[tbl_Fact_OP_Activity] f
    LEFT JOIN [Analytics].[tbl_Dim_Commissioner] d ON f.SK_CommissionerID = d.SK_CommissionerID WHERE d.SK_CommissionerID IS NULL;
    INSERT INTO #ValidationResults VALUES ('OP', 'Referential Integrity', 'Commissioner Orphans', 0, @OrphanCount, CASE WHEN @OrphanCount = 0 THEN 0 ELSE 100 END, 0,
        CASE WHEN @OrphanCount = 0 THEN 'PASS' ELSE 'FAIL' END, FORMAT(@OrphanCount, 'N0') + ' orphan records');

    SELECT @OrphanCount = COUNT(*) FROM [Analytics].[tbl_Fact_OP_Activity] f
    LEFT JOIN [Analytics].[tbl_Dim_GPPractice] d ON f.SK_GPPracticeID = d.SK_GPPracticeID WHERE d.SK_GPPracticeID IS NULL AND f.SK_GPPracticeID IS NOT NULL;
    INSERT INTO #ValidationResults VALUES ('OP', 'Referential Integrity', 'GP Practice Orphans', 0, @OrphanCount, CASE WHEN @OrphanCount = 0 THEN 0 ELSE 100 END, 0,
        CASE WHEN @OrphanCount = 0 THEN 'PASS' ELSE 'FAIL' END, FORMAT(@OrphanCount, 'N0') + ' orphan records');

    SELECT @OrphanCount = COUNT(*) FROM [Analytics].[tbl_Fact_OP_Activity] f
    LEFT JOIN [Analytics].[vw_Dim_Provider] d ON f.SK_ProviderID = d.SK_ProviderID WHERE d.SK_ProviderID IS NULL;
    INSERT INTO #ValidationResults VALUES ('OP', 'Referential Integrity', 'Provider Orphans', 0, @OrphanCount, CASE WHEN @OrphanCount = 0 THEN 0 ELSE 100 END, 0,
        CASE WHEN @OrphanCount = 0 THEN 'PASS' ELSE 'FAIL' END, FORMAT(@OrphanCount, 'N0') + ' orphan records');

    SELECT @OrphanCount = COUNT(*) FROM [Analytics].[tbl_Fact_OP_Activity] f
    LEFT JOIN [Analytics].[vw_Dim_Specialty] d ON f.SK_SpecialtyID = d.SK_SpecialtyID WHERE d.SK_SpecialtyID IS NULL AND f.SK_SpecialtyID IS NOT NULL;
    INSERT INTO #ValidationResults VALUES ('OP', 'Referential Integrity', 'Specialty Orphans', 0, @OrphanCount, CASE WHEN @OrphanCount = 0 THEN 0 ELSE 100 END, 0,
        CASE WHEN @OrphanCount = 0 THEN 'PASS' ELSE 'FAIL' END, FORMAT(@OrphanCount, 'N0') + ' orphan records');

    -- ==========================================================================
    -- SECTION 5: UNKNOWN/DEFAULT MEMBER RATES
    -- ==========================================================================
    PRINT '>>> Section 5: Unknown/Default Member Rates';

    -- IP Unknown rates
    SELECT @TotalCount = COUNT(*), @UnknownCount = SUM(CASE WHEN SK_CommissionerID = -1 THEN 1 ELSE 0 END)
    FROM [Analytics].[tbl_Fact_IP_Activity] WHERE Discharge_Date BETWEEN @FromDate AND @ToDate;
    SET @UnknownPct = CASE WHEN @TotalCount = 0 THEN 0 ELSE @UnknownCount * 100.0 / @TotalCount END;
    INSERT INTO #ValidationResults VALUES ('IP', 'Data Quality', 'Unknown Commissioner Rate', @TotalCount, @UnknownCount, @UnknownPct, @UnknownThresholdPct,
        CASE WHEN @UnknownPct <= @UnknownThresholdPct THEN 'PASS' ELSE 'FAIL' END,
        FORMAT(@UnknownPct, 'N2') + '% (' + FORMAT(@UnknownCount, 'N0') + ' of ' + FORMAT(@TotalCount, 'N0') + ')');

    SELECT @TotalCount = COUNT(*), @UnknownCount = SUM(CASE WHEN SK_GPPracticeID = -1 THEN 1 ELSE 0 END)
    FROM [Analytics].[tbl_Fact_IP_Activity] WHERE Discharge_Date BETWEEN @FromDate AND @ToDate;
    SET @UnknownPct = CASE WHEN @TotalCount = 0 THEN 0 ELSE @UnknownCount * 100.0 / @TotalCount END;
    INSERT INTO #ValidationResults VALUES ('IP', 'Data Quality', 'Unknown GP Practice Rate', @TotalCount, @UnknownCount, @UnknownPct, @UnknownThresholdPct,
        CASE WHEN @UnknownPct <= @UnknownThresholdPct THEN 'PASS' ELSE 'FAIL' END,
        FORMAT(@UnknownPct, 'N2') + '% (' + FORMAT(@UnknownCount, 'N0') + ' of ' + FORMAT(@TotalCount, 'N0') + ')');

    SELECT @TotalCount = COUNT(*), @UnknownCount = SUM(CASE WHEN SK_ProviderID = -1 THEN 1 ELSE 0 END)
    FROM [Analytics].[tbl_Fact_IP_Activity] WHERE Discharge_Date BETWEEN @FromDate AND @ToDate;
    SET @UnknownPct = CASE WHEN @TotalCount = 0 THEN 0 ELSE @UnknownCount * 100.0 / @TotalCount END;
    INSERT INTO #ValidationResults VALUES ('IP', 'Data Quality', 'Unknown Provider Rate', @TotalCount, @UnknownCount, @UnknownPct, @UnknownThresholdPct,
        CASE WHEN @UnknownPct <= @UnknownThresholdPct THEN 'PASS' ELSE 'FAIL' END,
        FORMAT(@UnknownPct, 'N2') + '% (' + FORMAT(@UnknownCount, 'N0') + ' of ' + FORMAT(@TotalCount, 'N0') + ')');

    SELECT @TotalCount = COUNT(*), @UnknownCount = SUM(CASE WHEN SK_SpecialtyID = -1 THEN 1 ELSE 0 END)
    FROM [Analytics].[tbl_Fact_IP_Activity] WHERE Discharge_Date BETWEEN @FromDate AND @ToDate;
    SET @UnknownPct = CASE WHEN @TotalCount = 0 THEN 0 ELSE @UnknownCount * 100.0 / @TotalCount END;
    INSERT INTO #ValidationResults VALUES ('IP', 'Data Quality', 'Unknown Specialty Rate', @TotalCount, @UnknownCount, @UnknownPct, @UnknownThresholdPct,
        CASE WHEN @UnknownPct <= @UnknownThresholdPct THEN 'PASS' ELSE 'FAIL' END,
        FORMAT(@UnknownPct, 'N2') + '% (' + FORMAT(@UnknownCount, 'N0') + ' of ' + FORMAT(@TotalCount, 'N0') + ')');

    -- OP Unknown rates
    SELECT @TotalCount = COUNT(*), @UnknownCount = SUM(CASE WHEN SK_CommissionerID = -1 THEN 1 ELSE 0 END)
    FROM [Analytics].[tbl_Fact_OP_Activity] WHERE Appointment_Date BETWEEN @FromDate AND @ToDate;
    SET @UnknownPct = CASE WHEN @TotalCount = 0 THEN 0 ELSE @UnknownCount * 100.0 / @TotalCount END;
    INSERT INTO #ValidationResults VALUES ('OP', 'Data Quality', 'Unknown Commissioner Rate', @TotalCount, @UnknownCount, @UnknownPct, @UnknownThresholdPct,
        CASE WHEN @UnknownPct <= @UnknownThresholdPct THEN 'PASS' ELSE 'FAIL' END,
        FORMAT(@UnknownPct, 'N2') + '% (' + FORMAT(@UnknownCount, 'N0') + ' of ' + FORMAT(@TotalCount, 'N0') + ')');

    SELECT @TotalCount = COUNT(*), @UnknownCount = SUM(CASE WHEN SK_GPPracticeID = -1 THEN 1 ELSE 0 END)
    FROM [Analytics].[tbl_Fact_OP_Activity] WHERE Appointment_Date BETWEEN @FromDate AND @ToDate;
    SET @UnknownPct = CASE WHEN @TotalCount = 0 THEN 0 ELSE @UnknownCount * 100.0 / @TotalCount END;
    INSERT INTO #ValidationResults VALUES ('OP', 'Data Quality', 'Unknown GP Practice Rate', @TotalCount, @UnknownCount, @UnknownPct, @UnknownThresholdPct,
        CASE WHEN @UnknownPct <= @UnknownThresholdPct THEN 'PASS' ELSE 'FAIL' END,
        FORMAT(@UnknownPct, 'N2') + '% (' + FORMAT(@UnknownCount, 'N0') + ' of ' + FORMAT(@TotalCount, 'N0') + ')');

    SELECT @TotalCount = COUNT(*), @UnknownCount = SUM(CASE WHEN SK_ProviderID = -1 THEN 1 ELSE 0 END)
    FROM [Analytics].[tbl_Fact_OP_Activity] WHERE Appointment_Date BETWEEN @FromDate AND @ToDate;
    SET @UnknownPct = CASE WHEN @TotalCount = 0 THEN 0 ELSE @UnknownCount * 100.0 / @TotalCount END;
    INSERT INTO #ValidationResults VALUES ('OP', 'Data Quality', 'Unknown Provider Rate', @TotalCount, @UnknownCount, @UnknownPct, @UnknownThresholdPct,
        CASE WHEN @UnknownPct <= @UnknownThresholdPct THEN 'PASS' ELSE 'FAIL' END,
        FORMAT(@UnknownPct, 'N2') + '% (' + FORMAT(@UnknownCount, 'N0') + ' of ' + FORMAT(@TotalCount, 'N0') + ')');

    SELECT @TotalCount = COUNT(*), @UnknownCount = SUM(CASE WHEN SK_SpecialtyID = -1 THEN 1 ELSE 0 END)
    FROM [Analytics].[tbl_Fact_OP_Activity] WHERE Appointment_Date BETWEEN @FromDate AND @ToDate;
    SET @UnknownPct = CASE WHEN @TotalCount = 0 THEN 0 ELSE @UnknownCount * 100.0 / @TotalCount END;
    INSERT INTO #ValidationResults VALUES ('OP', 'Data Quality', 'Unknown Specialty Rate', @TotalCount, @UnknownCount, @UnknownPct, @UnknownThresholdPct,
        CASE WHEN @UnknownPct <= @UnknownThresholdPct THEN 'PASS' ELSE 'FAIL' END,
        FORMAT(@UnknownPct, 'N2') + '% (' + FORMAT(@UnknownCount, 'N0') + ' of ' + FORMAT(@TotalCount, 'N0') + ')');

    -- ==========================================================================
    -- SECTION 6: MISSING DIMENSION MEMBERS
    -- Shows source codes that don't exist in dimension tables
    -- ==========================================================================
    PRINT '>>> Section 6: Missing Dimension Members';

    -- Temp table for missing members
    CREATE TABLE #MissingMembers (
        Domain VARCHAR(10),
        Dimension_Name VARCHAR(50),
        Missing_Code VARCHAR(50),
        Source_Record_Count BIGINT
    );

    -- IP Missing Commissioners
    INSERT INTO #MissingMembers
    SELECT 'IP', 'Commissioner',
        CASE WHEN RIGHT(s.Organisation_Code_Code_of_Commissioner, 2) = '00'
             THEN LEFT(s.Organisation_Code_Code_of_Commissioner, 3)
             ELSE s.Organisation_Code_Code_of_Commissioner END,
        COUNT(*)
    FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active] s
    WHERE s.End_Date_Hospital_Provider_Spell BETWEEN @FromDate AND @ToDate
    GROUP BY CASE WHEN RIGHT(s.Organisation_Code_Code_of_Commissioner, 2) = '00'
                  THEN LEFT(s.Organisation_Code_Code_of_Commissioner, 3)
                  ELSE s.Organisation_Code_Code_of_Commissioner END
    HAVING NOT EXISTS (
        SELECT 1 FROM [Analytics].[tbl_Dim_Commissioner] d
        WHERE d.Commissioner_Code = CASE WHEN RIGHT(s.Organisation_Code_Code_of_Commissioner, 2) = '00'
                                         THEN LEFT(s.Organisation_Code_Code_of_Commissioner, 3)
                                         ELSE s.Organisation_Code_Code_of_Commissioner END
    );

    -- IP Missing Providers
    INSERT INTO #MissingMembers
    SELECT 'IP', 'Provider',
        CASE WHEN RIGHT(s.Organisation_Code_Code_of_Provider, 2) = '00'
             THEN LEFT(s.Organisation_Code_Code_of_Provider, 3)
             ELSE s.Organisation_Code_Code_of_Provider END,
        COUNT(*)
    FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active] s
    WHERE s.End_Date_Hospital_Provider_Spell BETWEEN @FromDate AND @ToDate
    GROUP BY CASE WHEN RIGHT(s.Organisation_Code_Code_of_Provider, 2) = '00'
                  THEN LEFT(s.Organisation_Code_Code_of_Provider, 3)
                  ELSE s.Organisation_Code_Code_of_Provider END
    HAVING NOT EXISTS (
        SELECT 1 FROM [Analytics].[vw_Dim_Provider] d
        WHERE d.Provider_Code = CASE WHEN RIGHT(s.Organisation_Code_Code_of_Provider, 2) = '00'
                                     THEN LEFT(s.Organisation_Code_Code_of_Provider, 3)
                                     ELSE s.Organisation_Code_Code_of_Provider END
    );

    -- IP Missing Specialties
    INSERT INTO #MissingMembers
    SELECT 'IP', 'Specialty', s.Treatment_Function_Code, COUNT(*)
    FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active] s
    WHERE s.End_Date_Hospital_Provider_Spell BETWEEN @FromDate AND @ToDate
      AND s.Treatment_Function_Code IS NOT NULL
    GROUP BY s.Treatment_Function_Code
    HAVING NOT EXISTS (
        SELECT 1 FROM [Analytics].[vw_Dim_Specialty] d
        WHERE d.BK_SpecialtyCode = s.Treatment_Function_Code
    );

    -- IP Missing Admission Methods
    INSERT INTO #MissingMembers
    SELECT 'IP', 'Admission Method', s.Admission_Method_Hospital_Provider_Spell, COUNT(*)
    FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active] s
    WHERE s.End_Date_Hospital_Provider_Spell BETWEEN @FromDate AND @ToDate
      AND s.Admission_Method_Hospital_Provider_Spell IS NOT NULL
    GROUP BY s.Admission_Method_Hospital_Provider_Spell
    HAVING NOT EXISTS (
        SELECT 1 FROM [Analytics].[vw_Dim_Admission_Method] d
        WHERE d.Admission_Method_Code = s.Admission_Method_Hospital_Provider_Spell
    );

    -- IP Missing Discharge Methods
    INSERT INTO #MissingMembers
    SELECT 'IP', 'Discharge Method', s.Discharge_Method_Hospital_Provider_Spell, COUNT(*)
    FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active] s
    WHERE s.End_Date_Hospital_Provider_Spell BETWEEN @FromDate AND @ToDate
      AND s.Discharge_Method_Hospital_Provider_Spell IS NOT NULL
    GROUP BY s.Discharge_Method_Hospital_Provider_Spell
    HAVING NOT EXISTS (
        SELECT 1 FROM [Analytics].[vw_Dim_Discharge_Method] d
        WHERE d.Discharge_Method_Code = s.Discharge_Method_Hospital_Provider_Spell
    );

    -- IP Missing GP Practices
    INSERT INTO #MissingMembers
    SELECT 'IP', 'GP Practice', s.GP_Practice_Code_Original_Data, COUNT(*)
    FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active] s
    WHERE s.End_Date_Hospital_Provider_Spell BETWEEN @FromDate AND @ToDate
      AND s.GP_Practice_Code_Original_Data IS NOT NULL
    GROUP BY s.GP_Practice_Code_Original_Data
    HAVING NOT EXISTS (
        SELECT 1 FROM [Analytics].[tbl_Dim_GPPractice] d
        WHERE d.GPPractice_Code = s.GP_Practice_Code_Original_Data
    );

    -- OP Missing Commissioners
    INSERT INTO #MissingMembers
    SELECT 'OP', 'Commissioner',
        CASE WHEN RIGHT(s.Organisation_Code_Code_of_Commissioner, 2) = '00'
             THEN LEFT(s.Organisation_Code_Code_of_Commissioner, 3)
             ELSE s.Organisation_Code_Code_of_Commissioner END,
        COUNT(*)
    FROM [Data_Lab_SWL].[Unified].[tbl_OP_EncounterDenormalised_Active] s
    WHERE s.Appointment_Date BETWEEN @FromDate AND @ToDate
    GROUP BY CASE WHEN RIGHT(s.Organisation_Code_Code_of_Commissioner, 2) = '00'
                  THEN LEFT(s.Organisation_Code_Code_of_Commissioner, 3)
                  ELSE s.Organisation_Code_Code_of_Commissioner END
    HAVING NOT EXISTS (
        SELECT 1 FROM [Analytics].[tbl_Dim_Commissioner] d
        WHERE d.Commissioner_Code = CASE WHEN RIGHT(s.Organisation_Code_Code_of_Commissioner, 2) = '00'
                                         THEN LEFT(s.Organisation_Code_Code_of_Commissioner, 3)
                                         ELSE s.Organisation_Code_Code_of_Commissioner END
    );

    -- OP Missing Providers
    INSERT INTO #MissingMembers
    SELECT 'OP', 'Provider',
        CASE WHEN RIGHT(s.Organisation_Code_Code_of_Provider, 2) = '00'
             THEN LEFT(s.Organisation_Code_Code_of_Provider, 3)
             ELSE s.Organisation_Code_Code_of_Provider END,
        COUNT(*)
    FROM [Data_Lab_SWL].[Unified].[tbl_OP_EncounterDenormalised_Active] s
    WHERE s.Appointment_Date BETWEEN @FromDate AND @ToDate
    GROUP BY CASE WHEN RIGHT(s.Organisation_Code_Code_of_Provider, 2) = '00'
                  THEN LEFT(s.Organisation_Code_Code_of_Provider, 3)
                  ELSE s.Organisation_Code_Code_of_Provider END
    HAVING NOT EXISTS (
        SELECT 1 FROM [Analytics].[vw_Dim_Provider] d
        WHERE d.Provider_Code = CASE WHEN RIGHT(s.Organisation_Code_Code_of_Provider, 2) = '00'
                                     THEN LEFT(s.Organisation_Code_Code_of_Provider, 3)
                                     ELSE s.Organisation_Code_Code_of_Provider END
    );

    -- OP Missing Specialties
    INSERT INTO #MissingMembers
    SELECT 'OP', 'Specialty', s.Treatment_Function_Code, COUNT(*)
    FROM [Data_Lab_SWL].[Unified].[tbl_OP_EncounterDenormalised_Active] s
    WHERE s.Appointment_Date BETWEEN @FromDate AND @ToDate
      AND s.Treatment_Function_Code IS NOT NULL
    GROUP BY s.Treatment_Function_Code
    HAVING NOT EXISTS (
        SELECT 1 FROM [Analytics].[vw_Dim_Specialty] d
        WHERE d.BK_SpecialtyCode = s.Treatment_Function_Code
    );

    -- OP Missing Attendance Statuses
    INSERT INTO #MissingMembers
    SELECT 'OP', 'Attendance Status', NULLIF(LTRIM(RTRIM(s.Attended_Or_Did_Not_Attend)), ''), COUNT(*)
    FROM [Data_Lab_SWL].[Unified].[tbl_OP_EncounterDenormalised_Active] s
    WHERE s.Appointment_Date BETWEEN @FromDate AND @ToDate
      AND NULLIF(LTRIM(RTRIM(s.Attended_Or_Did_Not_Attend)), '') IS NOT NULL
    GROUP BY NULLIF(LTRIM(RTRIM(s.Attended_Or_Did_Not_Attend)), '')
    HAVING NOT EXISTS (
        SELECT 1 FROM [Analytics].[vw_Dim_Attendance_Status] d
        WHERE LTRIM(RTRIM(d.Attendance_Status_Code)) = NULLIF(LTRIM(RTRIM(s.Attended_Or_Did_Not_Attend)), '')
    );

    -- OP Missing GP Practices
    INSERT INTO #MissingMembers
    SELECT 'OP', 'GP Practice', s.GP_Practice_Code_Original_Data, COUNT(*)
    FROM [Data_Lab_SWL].[Unified].[tbl_OP_EncounterDenormalised_Active] s
    WHERE s.Appointment_Date BETWEEN @FromDate AND @ToDate
      AND s.GP_Practice_Code_Original_Data IS NOT NULL
    GROUP BY s.GP_Practice_Code_Original_Data
    HAVING NOT EXISTS (
        SELECT 1 FROM [Analytics].[tbl_Dim_GPPractice] d
        WHERE d.GPPractice_Code = s.GP_Practice_Code_Original_Data
    );

    -- ==========================================================================
    -- SECTION 7: DICTIONARY VALIDATION
    -- Compare source codes against NHS Data Dictionary (authoritative reference)
    -- ==========================================================================
    PRINT '>>> Section 7: Dictionary Validation';

    -- Temp table for dictionary comparison
    CREATE TABLE #DictionaryValidation (
        Domain VARCHAR(10),
        Dimension_Name VARCHAR(50),
        Code VARCHAR(50),
        Source_Record_Count BIGINT,
        In_Dictionary BIT,
        In_Dimension BIT,
        Action_Required VARCHAR(100)
    );

    -- IP Discharge Methods - Compare against Dictionary
    INSERT INTO #DictionaryValidation
    SELECT 'IP', 'Discharge Method',
           s.Discharge_Method_Hospital_Provider_Spell,
           COUNT(*),
           MAX(CASE WHEN dict.BK_DischargeMethodCode IS NOT NULL THEN 1 ELSE 0 END),
           MAX(CASE WHEN dim.Discharge_Method_Code IS NOT NULL THEN 1 ELSE 0 END),
           MAX(CASE
               WHEN dict.BK_DischargeMethodCode IS NOT NULL AND dim.Discharge_Method_Code IS NULL
                   THEN 'Add to Dimension (valid NHS code)'
               WHEN dict.BK_DischargeMethodCode IS NULL
                   THEN 'Invalid code (not in NHS Dictionary)'
               ELSE 'OK'
           END)
    FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active] s
    LEFT JOIN [Dictionary].[IP].[DischargeMethod] dict
        ON dict.BK_DischargeMethodCode = s.Discharge_Method_Hospital_Provider_Spell
    LEFT JOIN [Analytics].[vw_Dim_Discharge_Method] dim
        ON dim.Discharge_Method_Code = s.Discharge_Method_Hospital_Provider_Spell
    WHERE s.End_Date_Hospital_Provider_Spell BETWEEN @FromDate AND @ToDate
      AND s.Discharge_Method_Hospital_Provider_Spell IS NOT NULL
    GROUP BY s.Discharge_Method_Hospital_Provider_Spell
    HAVING MAX(CASE WHEN dim.Discharge_Method_Code IS NOT NULL THEN 1 ELSE 0 END) = 0;

    -- IP Admission Methods - Compare against Dictionary
    INSERT INTO #DictionaryValidation
    SELECT 'IP', 'Admission Method',
           s.Admission_Method_Hospital_Provider_Spell,
           COUNT(*),
           MAX(CASE WHEN dict.BK_AdmissionMethodCode IS NOT NULL THEN 1 ELSE 0 END),
           MAX(CASE WHEN dim.Admission_Method_Code IS NOT NULL THEN 1 ELSE 0 END),
           MAX(CASE
               WHEN dict.BK_AdmissionMethodCode IS NOT NULL AND dim.Admission_Method_Code IS NULL
                   THEN 'Add to Dimension (valid NHS code)'
               WHEN dict.BK_AdmissionMethodCode IS NULL
                   THEN 'Invalid code (not in NHS Dictionary)'
               ELSE 'OK'
           END)
    FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active] s
    LEFT JOIN [Dictionary].[IP].[AdmissionMethods] dict
        ON dict.BK_AdmissionMethodCode = s.Admission_Method_Hospital_Provider_Spell
    LEFT JOIN [Analytics].[vw_Dim_Admission_Method] dim
        ON dim.Admission_Method_Code = s.Admission_Method_Hospital_Provider_Spell
    WHERE s.End_Date_Hospital_Provider_Spell BETWEEN @FromDate AND @ToDate
      AND s.Admission_Method_Hospital_Provider_Spell IS NOT NULL
    GROUP BY s.Admission_Method_Hospital_Provider_Spell
    HAVING MAX(CASE WHEN dim.Admission_Method_Code IS NOT NULL THEN 1 ELSE 0 END) = 0;

    -- Commissioner - Compare against Dictionary
    INSERT INTO #DictionaryValidation
    SELECT 'IP/OP', 'Commissioner',
           CASE WHEN RIGHT(s.Organisation_Code_Code_of_Commissioner, 2) = '00'
                THEN LEFT(s.Organisation_Code_Code_of_Commissioner, 3)
                ELSE s.Organisation_Code_Code_of_Commissioner END,
           COUNT(*),
           MAX(CASE WHEN dict.CommissionerCode IS NOT NULL THEN 1 ELSE 0 END),
           MAX(CASE WHEN dim.Commissioner_Code IS NOT NULL THEN 1 ELSE 0 END),
           MAX(CASE
               WHEN dict.CommissionerCode IS NOT NULL AND dim.Commissioner_Code IS NULL
                   THEN 'Add to Dimension (valid NHS code)'
               WHEN dict.CommissionerCode IS NULL
                   THEN 'Invalid/Unknown code (not in NHS Dictionary)'
               ELSE 'OK'
           END)
    FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active] s
    LEFT JOIN [Dictionary].[dbo].[Commissioner] dict
        ON dict.CommissionerCode = CASE WHEN RIGHT(s.Organisation_Code_Code_of_Commissioner, 2) = '00'
                                        THEN LEFT(s.Organisation_Code_Code_of_Commissioner, 3)
                                        ELSE s.Organisation_Code_Code_of_Commissioner END
    LEFT JOIN [Analytics].[tbl_Dim_Commissioner] dim
        ON dim.Commissioner_Code = CASE WHEN RIGHT(s.Organisation_Code_Code_of_Commissioner, 2) = '00'
                                        THEN LEFT(s.Organisation_Code_Code_of_Commissioner, 3)
                                        ELSE s.Organisation_Code_Code_of_Commissioner END
    WHERE s.End_Date_Hospital_Provider_Spell BETWEEN @FromDate AND @ToDate
    GROUP BY CASE WHEN RIGHT(s.Organisation_Code_Code_of_Commissioner, 2) = '00'
                  THEN LEFT(s.Organisation_Code_Code_of_Commissioner, 3)
                  ELSE s.Organisation_Code_Code_of_Commissioner END
    HAVING MAX(CASE WHEN dim.Commissioner_Code IS NOT NULL THEN 1 ELSE 0 END) = 0;

    -- Specialty - Compare against Dictionary
    INSERT INTO #DictionaryValidation
    SELECT 'IP/OP', 'Specialty',
           s.Treatment_Function_Code,
           COUNT(*),
           MAX(CASE WHEN dict.BK_SpecialtyCode IS NOT NULL THEN 1 ELSE 0 END),
           MAX(CASE WHEN dim.BK_SpecialtyCode IS NOT NULL THEN 1 ELSE 0 END),
           MAX(CASE
               WHEN dict.BK_SpecialtyCode IS NOT NULL AND dim.BK_SpecialtyCode IS NULL
                   THEN 'Add to Dimension (valid NHS code)'
               WHEN dict.BK_SpecialtyCode IS NULL
                   THEN 'Invalid code (not in NHS Dictionary)'
               ELSE 'OK'
           END)
    FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active] s
    LEFT JOIN [Dictionary].[dbo].[Specialties] dict
        ON dict.BK_SpecialtyCode = s.Treatment_Function_Code
    LEFT JOIN [Analytics].[vw_Dim_Specialty] dim
        ON dim.BK_SpecialtyCode = s.Treatment_Function_Code
    WHERE s.End_Date_Hospital_Provider_Spell BETWEEN @FromDate AND @ToDate
      AND s.Treatment_Function_Code IS NOT NULL
    GROUP BY s.Treatment_Function_Code
    HAVING MAX(CASE WHEN dim.BK_SpecialtyCode IS NOT NULL THEN 1 ELSE 0 END) = 0;

    -- Provider - Compare against Dictionary.dbo.Organisation
    INSERT INTO #DictionaryValidation
    SELECT 'IP/OP', 'Provider',
           CASE WHEN RIGHT(s.Organisation_Code_Code_of_Provider, 2) = '00'
                THEN LEFT(s.Organisation_Code_Code_of_Provider, 3)
                ELSE s.Organisation_Code_Code_of_Provider END,
           COUNT(*),
           MAX(CASE WHEN dict.Organisation_Code IS NOT NULL THEN 1 ELSE 0 END),
           MAX(CASE WHEN dim.Provider_Code IS NOT NULL THEN 1 ELSE 0 END),
           MAX(CASE
               WHEN dict.Organisation_Code IS NOT NULL AND dim.Provider_Code IS NULL
                   THEN 'Add to Dimension (valid NHS code)'
               WHEN dict.Organisation_Code IS NULL
                   THEN 'Invalid/Unknown code (not in NHS Dictionary)'
               ELSE 'OK'
           END)
    FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active] s
    LEFT JOIN [Dictionary].[dbo].[Organisation] dict
        ON dict.Organisation_Code = CASE WHEN RIGHT(s.Organisation_Code_Code_of_Provider, 2) = '00'
                                         THEN LEFT(s.Organisation_Code_Code_of_Provider, 3)
                                         ELSE s.Organisation_Code_Code_of_Provider END
    LEFT JOIN [Analytics].[vw_Dim_Provider] dim
        ON dim.Provider_Code = CASE WHEN RIGHT(s.Organisation_Code_Code_of_Provider, 2) = '00'
                                    THEN LEFT(s.Organisation_Code_Code_of_Provider, 3)
                                    ELSE s.Organisation_Code_Code_of_Provider END
    WHERE s.End_Date_Hospital_Provider_Spell BETWEEN @FromDate AND @ToDate
    GROUP BY CASE WHEN RIGHT(s.Organisation_Code_Code_of_Provider, 2) = '00'
                  THEN LEFT(s.Organisation_Code_Code_of_Provider, 3)
                  ELSE s.Organisation_Code_Code_of_Provider END
    HAVING MAX(CASE WHEN dim.Provider_Code IS NOT NULL THEN 1 ELSE 0 END) = 0;

    -- GP Practice - Compare against Dictionary.dbo.Organisation
    INSERT INTO #DictionaryValidation
    SELECT 'IP/OP', 'GP Practice',
           s.GP_Practice_Code_Original_Data,
           COUNT(*),
           MAX(CASE WHEN dict.Organisation_Code IS NOT NULL THEN 1 ELSE 0 END),
           MAX(CASE WHEN dim.GPPractice_Code IS NOT NULL THEN 1 ELSE 0 END),
           MAX(CASE
               WHEN dict.Organisation_Code IS NOT NULL AND dim.GPPractice_Code IS NULL
                   THEN 'Add to Dimension (valid NHS code)'
               WHEN dict.Organisation_Code IS NULL
                   THEN 'Invalid/Unknown code (not in NHS Dictionary)'
               ELSE 'OK'
           END)
    FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active] s
    LEFT JOIN [Dictionary].[dbo].[Organisation] dict
        ON dict.Organisation_Code = s.GP_Practice_Code_Original_Data
    LEFT JOIN [Analytics].[tbl_Dim_GPPractice] dim
        ON dim.GPPractice_Code = s.GP_Practice_Code_Original_Data
    WHERE s.End_Date_Hospital_Provider_Spell BETWEEN @FromDate AND @ToDate
      AND s.GP_Practice_Code_Original_Data IS NOT NULL
    GROUP BY s.GP_Practice_Code_Original_Data
    HAVING MAX(CASE WHEN dim.GPPractice_Code IS NOT NULL THEN 1 ELSE 0 END) = 0;

    -- ==========================================================================
    -- OUTPUT RESULTS
    -- ==========================================================================
    PRINT '';
    PRINT '================================================================';
    PRINT 'VALIDATION SUMMARY';
    PRINT '================================================================';

    DECLARE @PassCount INT, @FailCount INT, @TotalTests INT;
    SELECT @PassCount = SUM(CASE WHEN Status = 'PASS' THEN 1 ELSE 0 END),
           @FailCount = SUM(CASE WHEN Status = 'FAIL' THEN 1 ELSE 0 END),
           @TotalTests = COUNT(*)
    FROM #ValidationResults;

    PRINT 'Total Tests: ' + CAST(@TotalTests AS VARCHAR);
    PRINT 'Passed: ' + CAST(@PassCount AS VARCHAR);
    PRINT 'Failed: ' + CAST(@FailCount AS VARCHAR);
    PRINT '';

    IF @FailCount = 0
        PRINT 'ALL TESTS PASSED';
    ELSE
        PRINT CAST(@FailCount AS VARCHAR) + ' TEST(S) FAILED';

    PRINT '';
    PRINT '================================================================';
    PRINT '';

    -- Return all results (failures first)
    SELECT Test_ID, Domain, Test_Category, Test_Name, Source_Value, Target_Value, Variance_Pct, Threshold_Pct, Status, Details
    FROM #ValidationResults
    ORDER BY CASE WHEN Status = 'FAIL' THEN 0 ELSE 1 END, Domain, Test_Category, Test_Name;

    -- Return summary
    SELECT @TotalTests AS Total_Tests, @PassCount AS Passed, @FailCount AS Failed,
           CASE WHEN @FailCount = 0 THEN 'PASS' ELSE 'FAIL' END AS Overall_Status;

    -- Return Distribution Health Summary (NEW)
    PRINT '';
    PRINT '================================================================';
    PRINT 'DISTRIBUTION HEALTH SUMMARY';
    PRINT '================================================================';
    PRINT '';

    SELECT Domain, Dimension_Name, Total_Codes, Codes_Matched, Codes_Mismatched,
           FORMAT(Total_Source_Records, 'N0') AS Total_Source_Records,
           FORMAT(Total_Target_Records, 'N0') AS Total_Target_Records,
           FORMAT(Total_Record_Discrepancy, 'N0') AS Total_Record_Discrepancy,
           Match_Rate_Pct, Health_Status
    FROM #DistributionHealth
    ORDER BY
        CASE Health_Status
            WHEN 'NEEDS ATTENTION' THEN 1
            WHEN 'ACCEPTABLE' THEN 2
            WHEN 'GOOD' THEN 3
            ELSE 4
        END, Domain, Dimension_Name;

    -- Return Distribution Issues (Material codes exceeding threshold - no TOP 5 limit)
    DECLARE @DistIssueCount INT;
    SELECT @DistIssueCount = COUNT(*) FROM #DistributionDetail WHERE Is_Material = 1 AND Exceeds_Threshold = 1;

    IF @DistIssueCount > 0
    BEGIN
        PRINT '';
        PRINT '================================================================';
        PRINT 'DISTRIBUTION ISSUES - MATERIAL CODES EXCEEDING THRESHOLD (' + CAST(@DistIssueCount AS VARCHAR) + ' issues)';
        PRINT '================================================================';
        PRINT '';

        SELECT Domain, Dimension_Name, Code,
               FORMAT(Source_Count, 'N0') AS Source_Count,
               FORMAT(Target_Count, 'N0') AS Target_Count,
               FORMAT(Difference, 'N0') AS Difference,
               CAST(Variance_Pct AS DECIMAL(10,2)) AS Variance_Pct
        FROM #DistributionDetail
        WHERE Is_Material = 1 AND Exceeds_Threshold = 1
        ORDER BY ABS(Difference) DESC, Domain, Dimension_Name;
    END
    ELSE
    BEGIN
        PRINT '';
        PRINT 'No material distribution issues found.';
    END

    -- Return missing dimension members (separate result set)
    DECLARE @MissingCount INT;
    SELECT @MissingCount = COUNT(*) FROM #MissingMembers;

    IF @MissingCount > 0
    BEGIN
        PRINT '';
        PRINT '================================================================';
        PRINT 'MISSING DIMENSION MEMBERS (' + CAST(@MissingCount AS VARCHAR) + ' codes not in dimensions)';
        PRINT '================================================================';
        PRINT '';

        SELECT Domain, Dimension_Name, Missing_Code, Source_Record_Count
        FROM #MissingMembers
        ORDER BY Domain, Dimension_Name, Source_Record_Count DESC;
    END
    ELSE
    BEGIN
        PRINT '';
        PRINT 'No missing dimension members found.';
    END

    -- Return dictionary validation (separate result set)
    DECLARE @DictIssueCount INT;
    SELECT @DictIssueCount = COUNT(*) FROM #DictionaryValidation;

    IF @DictIssueCount > 0
    BEGIN
        PRINT '';
        PRINT '================================================================';
        PRINT 'DICTIONARY VALIDATION (' + CAST(@DictIssueCount AS VARCHAR) + ' codes to review)';
        PRINT '================================================================';
        PRINT '';

        SELECT Domain, Dimension_Name, Code, Source_Record_Count,
               CASE WHEN In_Dictionary = 1 THEN 'Yes' ELSE 'No' END AS In_NHS_Dictionary,
               CASE WHEN In_Dimension = 1 THEN 'Yes' ELSE 'No' END AS In_Analytics_Dimension,
               Action_Required
        FROM #DictionaryValidation
        ORDER BY Domain, Dimension_Name, Source_Record_Count DESC;
    END
    ELSE
    BEGIN
        PRINT '';
        PRINT 'All source codes validated against NHS Dictionary.';
    END

    -- Optionally raise error
    IF @FailOnError = 1 AND @FailCount > 0
        RAISERROR('Validation failed: %d test(s) did not pass', 16, 1, @FailCount);

    DROP TABLE #ValidationResults;
    DROP TABLE #DistributionDetail;
    DROP TABLE #DistributionHealth;
    DROP TABLE #MissingMembers;
    DROP TABLE #DictionaryValidation;
END
GO

PRINT '[OK] Created Procedure: [Analytics].[sp_Validate_Fact_Data]';
GO

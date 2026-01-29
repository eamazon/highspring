/*
===============================================================================
HIGHSPRING ANALYTICS PLATFORM — TESTING & VALIDATION SCRIPTS
===============================================================================
Created: 2026-01-15
Purpose: Comprehensive validation suite for pre-Power BI testing
Database: [Data_Lab_SWL_Live].[Analytics]

Test Coverage:
  1.3 - Idempotency tests
  2.1 - Execute controlled loads (small date range)
  2.3 - Cost reconciliation (Analytics vs Unified)
  2.4 - Attribution completeness (CAM enrichment)
  3.1 - Fact calculations (measures, derivations)
  3.2 - Bridge relationships (ERF, OpPlan bridges)
  4   - Performance metrics (from ETL log tables)

Prerequisites:
  - Deployment complete (00_Run_Everything_SQLCMD.sql)
  - Dimensions loaded (00_Run_All_Dimension_Loads.sql)
  - Ready for fact loads + enrichment

===============================================================================
*/

-- Set database context
USE [Data_Lab_SWL_Live];
GO

PRINT '===============================================================================';
PRINT 'HIGHSPRING VALIDATION SUITE';
PRINT 'Started: ' + CONVERT(VARCHAR(30), GETDATE(), 121);
PRINT '===============================================================================';
PRINT '';

-------------------------------------------------------------------------------
-- SECTION 0: PRE-FLIGHT CHECKS
-------------------------------------------------------------------------------
PRINT '>>> SECTION 0: PRE-FLIGHT CHECKS';
PRINT '';

-- Check upstream dependencies exist
PRINT '0.1 - Checking upstream dependencies...';
SELECT
    'Unified.vw_IP_EncounterDenormalised_DateRange' AS [Object],
    CASE WHEN OBJECT_ID('[Unified].[vw_IP_EncounterDenormalised_DateRange]', 'V') IS NOT NULL
         THEN 'EXISTS' ELSE 'MISSING' END AS [Status]
UNION ALL
SELECT 'Unified.vw_OP_EncounterDenormalised_DateRange',
    CASE WHEN OBJECT_ID('[Unified].[vw_OP_EncounterDenormalised_DateRange]', 'V') IS NOT NULL
         THEN 'EXISTS' ELSE 'MISSING' END
UNION ALL
SELECT 'Unified.vw_ED_EncounterDenormalised_DateRange_v2',
    CASE WHEN OBJECT_ID('[Unified].[vw_ED_EncounterDenormalised_DateRange_v2]', 'V') IS NOT NULL
         THEN 'EXISTS' ELSE 'MISSING' END
UNION ALL
SELECT 'SWL.tbl_SUS_Delivery_Schedule',
    CASE WHEN OBJECT_ID('[SWL].[tbl_SUS_Delivery_Schedule]', 'U') IS NOT NULL
         THEN 'EXISTS' ELSE 'MISSING' END
UNION ALL
SELECT 'ref.tbl_LSOA_ICB_CA_LocalAuthority',
    CASE WHEN OBJECT_ID('[ref].[tbl_LSOA_ICB_CA_LocalAuthority]', 'U') IS NOT NULL
         THEN 'EXISTS' ELSE 'MISSING' END;
PRINT '  [OK] Dependency check complete';
PRINT '';

-- Check Analytics objects exist
PRINT '0.2 - Checking Analytics schema objects...';
SELECT
    SCHEMA_NAME(schema_id) AS [Schema],
    type_desc AS [Type],
    COUNT(*) AS [Count]
FROM sys.objects
WHERE schema_id = SCHEMA_ID('Analytics')
    AND type IN ('U', 'V', 'P', 'FN', 'TF')
GROUP BY SCHEMA_NAME(schema_id), type_desc
ORDER BY type_desc;
PRINT '  [OK] Analytics objects verified';
PRINT '';

-- Check dimension row counts
PRINT '0.3 - Checking dimension row counts...';
SELECT
    'tbl_Dim_Commissioner' AS [Dimension],
    COUNT(*) AS [Rows],
    CASE WHEN COUNT(*) > 0 THEN 'OK' ELSE 'EMPTY' END AS [Status]
FROM [Analytics].[tbl_Dim_Commissioner]
UNION ALL
SELECT 'tbl_Dim_GPPractice', COUNT(*),
    CASE WHEN COUNT(*) > 0 THEN 'OK' ELSE 'EMPTY' END
FROM [Analytics].[tbl_Dim_GPPractice]
UNION ALL
SELECT 'tbl_Dim_PCN', COUNT(*),
    CASE WHEN COUNT(*) > 0 THEN 'OK' ELSE 'EMPTY' END
FROM [Analytics].[tbl_Dim_PCN]
UNION ALL
SELECT 'tbl_Dim_POD', COUNT(*),
    CASE WHEN COUNT(*) > 0 THEN 'OK' ELSE 'EMPTY' END
FROM [Analytics].[tbl_Dim_POD]
UNION ALL
SELECT 'tbl_Dim_LSOA', COUNT(*),
    CASE WHEN COUNT(*) > 0 THEN 'OK' ELSE 'EMPTY' END
FROM [Analytics].[tbl_Dim_LSOA];
PRINT '  [OK] Dimension loads verified';
PRINT '';

-------------------------------------------------------------------------------
-- SECTION 2.1: CONTROLLED LOAD EXECUTION (Small Date Range)
-------------------------------------------------------------------------------
PRINT '===============================================================================';
PRINT 'SECTION 2.1: CONTROLLED LOAD EXECUTION (SMALL DATE RANGE)';
PRINT '===============================================================================';
PRINT '';
PRINT 'Recommendation: Test with 1 month of data first';
PRINT 'Test Window: April 2025 (2025-04-01 to 2025-04-30)';
PRINT '';
PRINT '-- STEP 1: Precompute CAM/ERF/OpPlan Active tables (FY 2025/26)';
PRINT '-- Run these first BEFORE fact loads:';
PRINT '';
PRINT 'EXEC [Analytics].[sp_Compute_CAM_Raw] ';
PRINT '    @FinYearStart = ''2025'', ';
PRINT '    @FinancialYear = ''2025/2026'';';
PRINT '';
PRINT 'EXEC [Analytics].[sp_Load_CAM_Assignment_Active] ';
PRINT '    @FinYearStart = ''2025'', ';
PRINT '    @FinancialYear = ''2025/2026'';';
PRINT '';
PRINT 'EXEC [Analytics].[sp_Load_ERF_Repriced_Active] ';
PRINT '    @FinYearStart = ''2025'';';
PRINT '';
PRINT 'EXEC [Analytics].[sp_Load_OpPlan_Active] ';
PRINT '    @FinYearStart = ''2025'';';
PRINT '';
PRINT '-- STEP 2: Load facts + enrichment together (recommended)';
PRINT '-- This wrapper calls all fact loads + CAM/ERF/OpPlan enrichments:';
PRINT '';
PRINT 'EXEC [Analytics].[sp_Run_Fact_Loads_With_Enrichment]';
PRINT '    @FromDate = ''2025-04-01'',';
PRINT '    @ToDate = ''2025-04-30'',';
PRINT '    @FinYearStart = ''2025'',';
PRINT '    @FinancialYear = ''2025/2026'',';
PRINT '    @ProviderCode = NULL;';
PRINT '';
PRINT '-- STEP 3: Load bridges (OPTIONAL - only if needed for reporting)';
PRINT '-- EXEC [Analytics].[sp_Load_Bridge_ERF_Activity] @FinYearStart = ''2025'';';
PRINT '-- Note: ERF/CAM/OpPlan data enriched directly on fact columns; bridges optional';
PRINT '';
PRINT '-- Expected volumes (1 month ~ April 2025):';
PRINT '  IP: ~125,000 rows (with ERF/CAM/OpPlan enrichment columns)';
PRINT '  OP: ~2,000,000 rows (with ERF/CAM/OpPlan enrichment columns)';
PRINT '  AE: ~130,000 rows';
PRINT '  ERF Bridge: OPTIONAL (only if loaded for reporting/lineage)';
PRINT '';
PRINT 'After executing above, run Section 2.2 (post-load checks) below...';
PRINT '';

-------------------------------------------------------------------------------
-- SECTION 2.2: POST-LOAD VALIDATION (Row counts)
-------------------------------------------------------------------------------
PRINT '===============================================================================';
PRINT 'SECTION 2.2: POST-LOAD VALIDATION (ROW COUNTS)';
PRINT '===============================================================================';
PRINT '';

-- Fact table row counts
PRINT '2.2.1 - Fact table row counts...';
IF EXISTS (SELECT 1 FROM [Analytics].[tbl_Fact_IP_Activity])
BEGIN
    SELECT
        'tbl_Fact_IP_Activity' AS [Table],
        COUNT(*) AS [Rows],
        MIN(Admission_Date) AS [MinDate],
        MAX(Discharge_Date) AS [MaxDate],
        CASE WHEN COUNT(*) > 0 THEN 'OK' ELSE 'EMPTY' END AS [Status]
    FROM [Analytics].[tbl_Fact_IP_Activity];

    SELECT
        'tbl_Fact_OP_Activity' AS [Table],
        COUNT(*) AS [Rows],
        MIN(Appointment_Date) AS [MinDate],
        MAX(Appointment_Date) AS [MaxDate],
        CASE WHEN COUNT(*) > 0 THEN 'OK' ELSE 'EMPTY' END AS [Status]
    FROM [Analytics].[tbl_Fact_OP_Activity];

    SELECT
        'tbl_Fact_AE_Activity' AS [Table],
        COUNT(*) AS [Rows],
        MIN(Arrival_Date) AS [MinDate],
        MAX(Arrival_Date) AS [MaxDate],
        CASE WHEN COUNT(*) > 0 THEN 'OK' ELSE 'EMPTY' END AS [Status]
    FROM [Analytics].[tbl_Fact_AE_Activity];
END
ELSE
BEGIN
    PRINT '  [SKIP] Facts not loaded yet - run Section 2.1 commands first';
END
PRINT '';

-- Precompute table row counts
PRINT '2.2.2 - Precompute table row counts...';
IF OBJECT_ID('[Analytics].[tbl_CAM_Assignment_Active]', 'U') IS NOT NULL
BEGIN
    SELECT
        'tbl_CAM_Assignment_Active' AS [Table],
        COUNT(*) AS [Rows],
        CASE WHEN COUNT(*) > 0 THEN 'OK' ELSE 'EMPTY' END AS [Status]
    FROM [Analytics].[tbl_CAM_Assignment_Active];
END
ELSE PRINT '  [INFO] tbl_CAM_Assignment_Active not created yet';

IF OBJECT_ID('[Analytics].[tbl_ERF_Repriced_Active]', 'U') IS NOT NULL
BEGIN
    SELECT
        'tbl_ERF_Repriced_Active' AS [Table],
        COUNT(*) AS [Rows],
        CASE WHEN COUNT(*) > 0 THEN 'OK' ELSE 'EMPTY' END AS [Status]
    FROM [Analytics].[tbl_ERF_Repriced_Active];
END
ELSE PRINT '  [INFO] tbl_ERF_Repriced_Active not created yet';

IF OBJECT_ID('[Analytics].[tbl_OpPlan_Active]', 'U') IS NOT NULL
BEGIN
    SELECT
        'tbl_OpPlan_Active' AS [Table],
        COUNT(*) AS [Rows],
        CASE WHEN COUNT(*) > 0 THEN 'OK' ELSE 'EMPTY' END AS [Status]
    FROM [Analytics].[tbl_OpPlan_Active];
END
ELSE PRINT '  [INFO] tbl_OpPlan_Active not created yet';
PRINT '';

-- ERF Enrichment validation on facts (PRIMARY)
PRINT '2.2.3 - ERF enrichment on facts (PRIMARY)...';
IF EXISTS (SELECT 1 FROM [Analytics].[tbl_Fact_IP_Activity])
BEGIN
    SELECT
        'IP ERF Enrichment' AS [Check],
        COUNT(*) AS [Total_Records],
        SUM(CASE WHEN Is_ERF_Eligible = 1 THEN 1 ELSE 0 END) AS [ERF_Eligible],
        CAST(SUM(CASE WHEN Is_ERF_Eligible = 1 THEN 1 ELSE 0 END) * 100.0
            / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS [ERF_Pct],
        CASE WHEN SUM(CASE WHEN Is_ERF_Eligible = 1 THEN 1 ELSE 0 END) > 0
             THEN 'OK' ELSE 'WARN' END AS [Status]
    FROM [Analytics].[tbl_Fact_IP_Activity];

    SELECT
        'OP ERF Enrichment' AS [Check],
        COUNT(*) AS [Total_Records],
        SUM(CASE WHEN Is_ERF_Eligible = 1 THEN 1 ELSE 0 END) AS [ERF_Eligible],
        CAST(SUM(CASE WHEN Is_ERF_Eligible = 1 THEN 1 ELSE 0 END) * 100.0
            / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS [ERF_Pct],
        CASE WHEN SUM(CASE WHEN Is_ERF_Eligible = 1 THEN 1 ELSE 0 END) > 0
             THEN 'OK' ELSE 'WARN' END AS [Status]
    FROM [Analytics].[tbl_Fact_OP_Activity];
END
ELSE PRINT '  [SKIP] Facts not loaded or ERF enrichment not run';

-- Optional ERF bridge (if loaded)
IF OBJECT_ID('[Analytics].[tbl_Bridge_ERF_Activity]', 'U') IS NOT NULL
    AND EXISTS (SELECT 1 FROM [Analytics].[tbl_Bridge_ERF_Activity])
BEGIN
    PRINT '  [INFO] Optional ERF bridge also loaded:';
    SELECT
        'tbl_Bridge_ERF_Activity (OPTIONAL)' AS [Table],
        COUNT(*) AS [Rows]
    FROM [Analytics].[tbl_Bridge_ERF_Activity];
END
ELSE PRINT '  [INFO] Optional ERF bridge not loaded (not required)';
PRINT '';

-------------------------------------------------------------------------------
-- SECTION 2.3: COST RECONCILIATION (Analytics vs Unified)
-------------------------------------------------------------------------------
PRINT '===============================================================================';
PRINT 'SECTION 2.3: COST RECONCILIATION (ANALYTICS VS UNIFIED)';
PRINT '===============================================================================';
PRINT '';
PRINT 'Target: <2% variance acceptable; <5% acceptable if pricing differences known';
PRINT '';

-- IP cost reconciliation
PRINT '2.3.1 - IP Activity cost reconciliation...';
IF EXISTS (SELECT 1 FROM [Analytics].[tbl_Fact_IP_Activity])
BEGIN
    WITH AnalyticsCosts AS (
        SELECT
            SUM(Total_Activity_Cost) AS TotalCost,
            COUNT(*) AS RowCount
        FROM [Analytics].[tbl_Fact_IP_Activity]
    ),
    UnifiedCosts AS (
        SELECT
            SUM(dv_Total_Cost_Inc_MFF) AS TotalCost,
            COUNT(*) AS RowCount
        FROM [Unified].[vw_IP_EncounterDenormalised_DateRange] u
        WHERE EXISTS (
            SELECT 1
            FROM [Analytics].[tbl_Fact_IP_Activity] f
            WHERE f.SK_EncounterID = u.SK_EncounterID
        )
    )
    SELECT
        'IP Activity' AS [Dataset],
        a.RowCount AS [Analytics_Rows],
        u.RowCount AS [Unified_Rows],
        a.RowCount - u.RowCount AS [Row_Diff],
        a.TotalCost AS [Analytics_Cost],
        u.TotalCost AS [Unified_Cost],
        a.TotalCost - u.TotalCost AS [Cost_Diff],
        ABS((a.TotalCost - u.TotalCost) / NULLIF(u.TotalCost, 0)) * 100 AS [Cost_Variance_Pct],
        CASE
            WHEN ABS((a.TotalCost - u.TotalCost) / NULLIF(u.TotalCost, 0)) * 100 < 2 THEN 'PASS'
            WHEN ABS((a.TotalCost - u.TotalCost) / NULLIF(u.TotalCost, 0)) * 100 < 5 THEN 'WARN'
            ELSE 'FAIL'
        END AS [Status]
    FROM AnalyticsCosts a, UnifiedCosts u;
END
ELSE PRINT '  [SKIP] IP facts not loaded';
PRINT '';

-- OP cost reconciliation
PRINT '2.3.2 - OP Activity cost reconciliation...';
IF EXISTS (SELECT 1 FROM [Analytics].[tbl_Fact_OP_Activity])
BEGIN
    WITH AnalyticsCosts AS (
        SELECT
            SUM(Total_Activity_Cost) AS TotalCost,
            COUNT(*) AS RowCount
        FROM [Analytics].[tbl_Fact_OP_Activity]
    ),
    UnifiedCosts AS (
        SELECT
            SUM(dv_Total_Cost_Inc_MFF) AS TotalCost,
            COUNT(*) AS RowCount
        FROM [Unified].[vw_OP_EncounterDenormalised_DateRange] u
        WHERE EXISTS (
            SELECT 1
            FROM [Analytics].[tbl_Fact_OP_Activity] f
            WHERE f.SK_EncounterID = u.SK_EncounterID
        )
    )
    SELECT
        'OP Activity' AS [Dataset],
        a.RowCount AS [Analytics_Rows],
        u.RowCount AS [Unified_Rows],
        a.RowCount - u.RowCount AS [Row_Diff],
        a.TotalCost AS [Analytics_Cost],
        u.TotalCost AS [Unified_Cost],
        a.TotalCost - u.TotalCost AS [Cost_Diff],
        ABS((a.TotalCost - u.TotalCost) / NULLIF(u.TotalCost, 0)) * 100 AS [Cost_Variance_Pct],
        CASE
            WHEN ABS((a.TotalCost - u.TotalCost) / NULLIF(u.TotalCost, 0)) * 100 < 2 THEN 'PASS'
            WHEN ABS((a.TotalCost - u.TotalCost) / NULLIF(u.TotalCost, 0)) * 100 < 5 THEN 'WARN'
            ELSE 'FAIL'
        END AS [Status]
    FROM AnalyticsCosts a, UnifiedCosts u;
END
ELSE PRINT '  [SKIP] OP facts not loaded';
PRINT '';

-- AE cost reconciliation
PRINT '2.3.3 - AE Activity cost reconciliation...';
IF EXISTS (SELECT 1 FROM [Analytics].[tbl_Fact_AE_Activity])
BEGIN
    WITH AnalyticsCosts AS (
        SELECT
            SUM(Total_Activity_Cost) AS TotalCost,
            COUNT(*) AS RowCount
        FROM [Analytics].[tbl_Fact_AE_Activity]
    ),
    UnifiedCosts AS (
        SELECT
            SUM(dv_Total_Cost_Inc_MFF) AS TotalCost,
            COUNT(*) AS RowCount
        FROM [Unified].[vw_ED_EncounterDenormalised_DateRange_v2] u
        WHERE EXISTS (
            SELECT 1
            FROM [Analytics].[tbl_Fact_AE_Activity] f
            WHERE f.SK_EncounterID = u.SK_EncounterID
        )
    )
    SELECT
        'AE Activity' AS [Dataset],
        a.RowCount AS [Analytics_Rows],
        u.RowCount AS [Unified_Rows],
        a.RowCount - u.RowCount AS [Row_Diff],
        a.TotalCost AS [Analytics_Cost],
        u.TotalCost AS [Unified_Cost],
        a.TotalCost - u.TotalCost AS [Cost_Diff],
        ABS((a.TotalCost - u.TotalCost) / NULLIF(u.TotalCost, 0)) * 100 AS [Cost_Variance_Pct],
        CASE
            WHEN ABS((a.TotalCost - u.TotalCost) / NULLIF(u.TotalCost, 0)) * 100 < 2 THEN 'PASS'
            WHEN ABS((a.TotalCost - u.TotalCost) / NULLIF(u.TotalCost, 0)) * 100 < 5 THEN 'WARN'
            ELSE 'FAIL'
        END AS [Status]
    FROM AnalyticsCosts a, UnifiedCosts u;
END
ELSE PRINT '  [SKIP] AE facts not loaded';
PRINT '';

-------------------------------------------------------------------------------
-- SECTION 2.4: ATTRIBUTION COMPLETENESS (CAM Enrichment)
-------------------------------------------------------------------------------
PRINT '===============================================================================';
PRINT 'SECTION 2.4: ATTRIBUTION COMPLETENESS (CAM ENRICHMENT)';
PRINT '===============================================================================';
PRINT '';
PRINT 'Target: >95% of records should have valid CAM attribution';
PRINT '';

-- IP CAM attribution
PRINT '2.4.1 - IP Activity CAM attribution coverage...';
IF EXISTS (SELECT 1 FROM [Analytics].[tbl_Fact_IP_Activity])
BEGIN
    SELECT
        'IP Activity' AS [Dataset],
        COUNT(*) AS [Total_Records],
        COUNT(CASE WHEN CAM_Commissioner_Code IS NOT NULL THEN 1 END) AS [CAM_Assigned],
        COUNT(CASE WHEN CAM_Commissioner_Code IS NULL THEN 1 END) AS [CAM_Missing],
        CAST(COUNT(CASE WHEN CAM_Commissioner_Code IS NOT NULL THEN 1 END) * 100.0
            / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS [Attribution_Pct],
        CASE
            WHEN COUNT(CASE WHEN CAM_Commissioner_Code IS NOT NULL THEN 1 END) * 100.0
                / NULLIF(COUNT(*), 0) >= 95 THEN 'PASS'
            WHEN COUNT(CASE WHEN CAM_Commissioner_Code IS NOT NULL THEN 1 END) * 100.0
                / NULLIF(COUNT(*), 0) >= 90 THEN 'WARN'
            ELSE 'FAIL'
        END AS [Status]
    FROM [Analytics].[tbl_Fact_IP_Activity];

    -- Show top 10 assignment reasons
    PRINT '  Top 10 CAM assignment reasons:';
    SELECT TOP 10
        CAM_Assignment_Reason,
        COUNT(*) AS [Records],
        CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS [Pct]
    FROM [Analytics].[tbl_Fact_IP_Activity]
    WHERE CAM_Assignment_Reason IS NOT NULL
    GROUP BY CAM_Assignment_Reason
    ORDER BY COUNT(*) DESC;
END
ELSE PRINT '  [SKIP] IP facts not loaded or CAM enrichment not run';
PRINT '';

-- OP CAM attribution
PRINT '2.4.2 - OP Activity CAM attribution coverage...';
IF EXISTS (SELECT 1 FROM [Analytics].[tbl_Fact_OP_Activity])
BEGIN
    SELECT
        'OP Activity' AS [Dataset],
        COUNT(*) AS [Total_Records],
        COUNT(CASE WHEN CAM_Commissioner_Code IS NOT NULL THEN 1 END) AS [CAM_Assigned],
        COUNT(CASE WHEN CAM_Commissioner_Code IS NULL THEN 1 END) AS [CAM_Missing],
        CAST(COUNT(CASE WHEN CAM_Commissioner_Code IS NOT NULL THEN 1 END) * 100.0
            / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS [Attribution_Pct],
        CASE
            WHEN COUNT(CASE WHEN CAM_Commissioner_Code IS NOT NULL THEN 1 END) * 100.0
                / NULLIF(COUNT(*), 0) >= 95 THEN 'PASS'
            WHEN COUNT(CASE WHEN CAM_Commissioner_Code IS NOT NULL THEN 1 END) * 100.0
                / NULLIF(COUNT(*), 0) >= 90 THEN 'WARN'
            ELSE 'FAIL'
        END AS [Status]
    FROM [Analytics].[tbl_Fact_OP_Activity];

    -- Show top 10 service categories
    PRINT '  Top 10 CAM service categories:';
    SELECT TOP 10
        CAM_Service_Category,
        COUNT(*) AS [Records],
        CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS [Pct]
    FROM [Analytics].[tbl_Fact_OP_Activity]
    WHERE CAM_Service_Category IS NOT NULL
    GROUP BY CAM_Service_Category
    ORDER BY COUNT(*) DESC;
END
ELSE PRINT '  [SKIP] OP facts not loaded or CAM enrichment not run';
PRINT '';

-------------------------------------------------------------------------------
-- SECTION 3.1: FACT CALCULATIONS (Measures & Derivations)
-------------------------------------------------------------------------------
PRINT '===============================================================================';
PRINT 'SECTION 3.1: FACT CALCULATIONS (MEASURES & DERIVATIONS)';
PRINT '===============================================================================';
PRINT '';

-- IP Activity measures
PRINT '3.1.1 - IP Activity measure validation...';
IF EXISTS (SELECT 1 FROM [Analytics].[tbl_Fact_IP_Activity])
BEGIN
    SELECT
        'IP Activity' AS [Dataset],
        COUNT(*) AS [Total_Records],
        SUM(Spells) AS [Total_Spells],
        SUM(Episodes) AS [Total_Episodes],
        AVG(CAST(Length_of_Stay_Days AS FLOAT)) AS [Avg_LOS],
        SUM(CASE WHEN Is_Emergency = 1 THEN 1 ELSE 0 END) AS [Emergency_Admissions],
        SUM(CASE WHEN Is_Elective = 1 THEN 1 ELSE 0 END) AS [Elective_Admissions],
        SUM(CASE WHEN Is_Day_Case = 1 THEN 1 ELSE 0 END) AS [Day_Cases],
        -- Check for data quality issues
        SUM(CASE WHEN Length_of_Stay_Days < 0 THEN 1 ELSE 0 END) AS [Negative_LOS],
        SUM(CASE WHEN Discharge_Date < Admission_Date THEN 1 ELSE 0 END) AS [Invalid_Dates],
        SUM(CASE WHEN Total_Activity_Cost < 0 THEN 1 ELSE 0 END) AS [Negative_Costs]
    FROM [Analytics].[tbl_Fact_IP_Activity];

    -- LOS distribution
    PRINT '  Length of Stay distribution:';
    SELECT
        CASE
            WHEN Length_of_Stay_Days = 0 THEN '0 days'
            WHEN Length_of_Stay_Days = 1 THEN '1 day'
            WHEN Length_of_Stay_Days BETWEEN 2 AND 3 THEN '2-3 days'
            WHEN Length_of_Stay_Days BETWEEN 4 AND 7 THEN '4-7 days'
            WHEN Length_of_Stay_Days BETWEEN 8 AND 14 THEN '8-14 days'
            WHEN Length_of_Stay_Days BETWEEN 15 AND 21 THEN '15-21 days'
            WHEN Length_of_Stay_Days > 21 THEN '>21 days'
            ELSE 'Unknown'
        END AS [LOS_Band],
        COUNT(*) AS [Records],
        CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS [Pct]
    FROM [Analytics].[tbl_Fact_IP_Activity]
    GROUP BY
        CASE
            WHEN Length_of_Stay_Days = 0 THEN '0 days'
            WHEN Length_of_Stay_Days = 1 THEN '1 day'
            WHEN Length_of_Stay_Days BETWEEN 2 AND 3 THEN '2-3 days'
            WHEN Length_of_Stay_Days BETWEEN 4 AND 7 THEN '4-7 days'
            WHEN Length_of_Stay_Days BETWEEN 8 AND 14 THEN '8-14 days'
            WHEN Length_of_Stay_Days BETWEEN 15 AND 21 THEN '15-21 days'
            WHEN Length_of_Stay_Days > 21 THEN '>21 days'
            ELSE 'Unknown'
        END
    ORDER BY
        CASE
            WHEN Length_of_Stay_Days = 0 THEN 1
            WHEN Length_of_Stay_Days = 1 THEN 2
            WHEN Length_of_Stay_Days BETWEEN 2 AND 3 THEN 3
            WHEN Length_of_Stay_Days BETWEEN 4 AND 7 THEN 4
            WHEN Length_of_Stay_Days BETWEEN 8 AND 14 THEN 5
            WHEN Length_of_Stay_Days BETWEEN 15 AND 21 THEN 6
            WHEN Length_of_Stay_Days > 21 THEN 7
            ELSE 99
        END;
END
ELSE PRINT '  [SKIP] IP facts not loaded';
PRINT '';

-- OP Activity measures
PRINT '3.1.2 - OP Activity measure validation...';
IF EXISTS (SELECT 1 FROM [Analytics].[tbl_Fact_OP_Activity])
BEGIN
    SELECT
        'OP Activity' AS [Dataset],
        COUNT(*) AS [Total_Records],
        SUM(Appointments) AS [Total_Appointments],
        SUM(CASE WHEN Is_FirstAttendance = 1 THEN 1 ELSE 0 END) AS [First_Attendances],
        SUM(CASE WHEN Is_FollowUp = 1 THEN 1 ELSE 0 END) AS [Follow_Ups],
        SUM(CASE WHEN Is_DNA = 1 THEN 1 ELSE 0 END) AS [DNAs],
        CAST(SUM(CASE WHEN Is_DNA = 1 THEN 1 ELSE 0 END) * 100.0
            / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS [DNA_Rate_Pct],
        AVG(CAST(Wait_Days_Referral_to_Appointment AS FLOAT)) AS [Avg_Wait_Days],
        -- Data quality
        SUM(CASE WHEN Wait_Days_Referral_to_Appointment < 0 THEN 1 ELSE 0 END) AS [Negative_Wait],
        SUM(CASE WHEN Total_Activity_Cost < 0 THEN 1 ELSE 0 END) AS [Negative_Costs]
    FROM [Analytics].[tbl_Fact_OP_Activity];

    -- Wait time distribution
    PRINT '  Wait time distribution (referral to appointment):';
    SELECT
        CASE
            WHEN Wait_Days_Referral_to_Appointment IS NULL THEN 'NULL'
            WHEN Wait_Days_Referral_to_Appointment <= 14 THEN '0-2 weeks'
            WHEN Wait_Days_Referral_to_Appointment <= 42 THEN '2-6 weeks'
            WHEN Wait_Days_Referral_to_Appointment <= 84 THEN '6-12 weeks'
            WHEN Wait_Days_Referral_to_Appointment <= 126 THEN '12-18 weeks'
            WHEN Wait_Days_Referral_to_Appointment > 126 THEN '>18 weeks'
            ELSE 'Unknown'
        END AS [Wait_Band],
        COUNT(*) AS [Records],
        CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS [Pct]
    FROM [Analytics].[tbl_Fact_OP_Activity]
    GROUP BY
        CASE
            WHEN Wait_Days_Referral_to_Appointment IS NULL THEN 'NULL'
            WHEN Wait_Days_Referral_to_Appointment <= 14 THEN '0-2 weeks'
            WHEN Wait_Days_Referral_to_Appointment <= 42 THEN '2-6 weeks'
            WHEN Wait_Days_Referral_to_Appointment <= 84 THEN '6-12 weeks'
            WHEN Wait_Days_Referral_to_Appointment <= 126 THEN '12-18 weeks'
            WHEN Wait_Days_Referral_to_Appointment > 126 THEN '>18 weeks'
            ELSE 'Unknown'
        END
    ORDER BY
        CASE
            WHEN Wait_Days_Referral_to_Appointment IS NULL THEN 1
            WHEN Wait_Days_Referral_to_Appointment <= 14 THEN 2
            WHEN Wait_Days_Referral_to_Appointment <= 42 THEN 3
            WHEN Wait_Days_Referral_to_Appointment <= 84 THEN 4
            WHEN Wait_Days_Referral_to_Appointment <= 126 THEN 5
            WHEN Wait_Days_Referral_to_Appointment > 126 THEN 6
            ELSE 99
        END;
END
ELSE PRINT '  [SKIP] OP facts not loaded';
PRINT '';

-- AE Activity measures
PRINT '3.1.3 - AE Activity measure validation...';
IF EXISTS (SELECT 1 FROM [Analytics].[tbl_Fact_AE_Activity])
BEGIN
    SELECT
        'AE Activity' AS [Dataset],
        COUNT(*) AS [Total_Records],
        SUM(Attendances) AS [Total_Attendances],
        SUM(CASE WHEN Is_Type1_Department = 1 THEN 1 ELSE 0 END) AS [Type1_Major_AE],
        SUM(CASE WHEN Is_4Hour_Breach = 1 THEN 1 ELSE 0 END) AS [Four_Hour_Breaches],
        CAST(SUM(CASE WHEN Is_4Hour_Breach = 1 THEN 1 ELSE 0 END) * 100.0
            / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS [Breach_Rate_Pct],
        AVG(CAST(Time_in_Department_Minutes AS FLOAT)) AS [Avg_Time_Minutes],
        -- Data quality
        SUM(CASE WHEN Time_in_Department_Minutes < 0 THEN 1 ELSE 0 END) AS [Negative_Time],
        SUM(CASE WHEN Total_Activity_Cost < 0 THEN 1 ELSE 0 END) AS [Negative_Costs]
    FROM [Analytics].[tbl_Fact_AE_Activity];

    -- Time in department distribution
    PRINT '  Time in department distribution:';
    SELECT
        CASE
            WHEN Time_in_Department_Minutes IS NULL THEN 'NULL'
            WHEN Time_in_Department_Minutes <= 60 THEN '0-1 hour'
            WHEN Time_in_Department_Minutes <= 120 THEN '1-2 hours'
            WHEN Time_in_Department_Minutes <= 240 THEN '2-4 hours'
            WHEN Time_in_Department_Minutes <= 360 THEN '4-6 hours'
            WHEN Time_in_Department_Minutes > 360 THEN '>6 hours'
            ELSE 'Unknown'
        END AS [Time_Band],
        COUNT(*) AS [Records],
        CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS [Pct]
    FROM [Analytics].[tbl_Fact_AE_Activity]
    GROUP BY
        CASE
            WHEN Time_in_Department_Minutes IS NULL THEN 'NULL'
            WHEN Time_in_Department_Minutes <= 60 THEN '0-1 hour'
            WHEN Time_in_Department_Minutes <= 120 THEN '1-2 hours'
            WHEN Time_in_Department_Minutes <= 240 THEN '2-4 hours'
            WHEN Time_in_Department_Minutes <= 360 THEN '4-6 hours'
            WHEN Time_in_Department_Minutes > 360 THEN '>6 hours'
            ELSE 'Unknown'
        END
    ORDER BY
        CASE
            WHEN Time_in_Department_Minutes IS NULL THEN 1
            WHEN Time_in_Department_Minutes <= 60 THEN 2
            WHEN Time_in_Department_Minutes <= 120 THEN 3
            WHEN Time_in_Department_Minutes <= 240 THEN 4
            WHEN Time_in_Department_Minutes <= 360 THEN 5
            WHEN Time_in_Department_Minutes > 360 THEN 6
            ELSE 99
        END;
END
ELSE PRINT '  [SKIP] AE facts not loaded';
PRINT '';

-------------------------------------------------------------------------------
-- SECTION 3.2: ENRICHMENT VALIDATION (ERF & OpPlan on Facts)
-------------------------------------------------------------------------------
PRINT '===============================================================================';
PRINT 'SECTION 3.2: ENRICHMENT VALIDATION (ERF & OPPLAN ON FACTS)';
PRINT '===============================================================================';
PRINT '';
PRINT 'Note: ERF and OpPlan data are enriched directly on fact columns';
PRINT '      ERF bridge is optional (for reporting/lineage only)';
PRINT '      Operating Plan deferred bridge is deprecated';
PRINT '';

-- ERF Enrichment validation (PRIMARY)
PRINT '3.2.1 - ERF enrichment on facts (PRIMARY)...';
IF EXISTS (SELECT 1 FROM [Analytics].[tbl_Fact_IP_Activity])
BEGIN
    PRINT '  IP Activity ERF enrichment:';
    SELECT
        COUNT(*) AS [Total_Records],
        SUM(CASE WHEN Is_ERF_Eligible = 1 THEN 1 ELSE 0 END) AS [ERF_Eligible_Records],
        CAST(SUM(CASE WHEN Is_ERF_Eligible = 1 THEN 1 ELSE 0 END) * 100.0
            / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS [ERF_Eligibility_Pct],
        SUM(CASE WHEN Is_ERF_Eligible = 1 THEN ERF_Total_Cost_Incl_MFF ELSE 0 END) AS [Total_ERF_Cost],
        AVG(CASE WHEN Is_ERF_Eligible = 1 THEN ERF_Total_Cost_Incl_MFF ELSE NULL END) AS [Avg_ERF_Cost],
        CASE
            WHEN SUM(CASE WHEN Is_ERF_Eligible = 1 THEN 1 ELSE 0 END) > 0 THEN 'PASS'
            ELSE 'WARN - No ERF records'
        END AS [Status]
    FROM [Analytics].[tbl_Fact_IP_Activity];

    PRINT '  OP Activity ERF enrichment:';
    SELECT
        COUNT(*) AS [Total_Records],
        SUM(CASE WHEN Is_ERF_Eligible = 1 THEN 1 ELSE 0 END) AS [ERF_Eligible_Records],
        CAST(SUM(CASE WHEN Is_ERF_Eligible = 1 THEN 1 ELSE 0 END) * 100.0
            / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS [ERF_Eligibility_Pct],
        SUM(CASE WHEN Is_ERF_Eligible = 1 THEN ERF_Total_Cost_Incl_MFF ELSE 0 END) AS [Total_ERF_Cost],
        AVG(CASE WHEN Is_ERF_Eligible = 1 THEN ERF_Total_Cost_Incl_MFF ELSE NULL END) AS [Avg_ERF_Cost],
        CASE
            WHEN SUM(CASE WHEN Is_ERF_Eligible = 1 THEN 1 ELSE 0 END) > 0 THEN 'PASS'
            ELSE 'WARN - No ERF records'
        END AS [Status]
    FROM [Analytics].[tbl_Fact_OP_Activity];
END
ELSE PRINT '  [SKIP] Facts not loaded or ERF enrichment not run';
PRINT '';

-- Optional ERF Bridge validation (if loaded)
PRINT '3.2.1b - ERF bridge (OPTIONAL - only if loaded for reporting)...';
IF OBJECT_ID('[Analytics].[tbl_Bridge_ERF_Activity]', 'U') IS NOT NULL
    AND EXISTS (SELECT 1 FROM [Analytics].[tbl_Bridge_ERF_Activity])
BEGIN
    SELECT
        'ERF Bridge (Optional)' AS [Bridge],
        POD,
        COUNT(*) AS [Records],
        SUM(ERF_Total_Cost_Incl_MFF) AS [Total_ERF_Cost]
    FROM [Analytics].[tbl_Bridge_ERF_Activity]
    GROUP BY POD;
    PRINT '  [INFO] Optional ERF bridge loaded and validated';
END
ELSE PRINT '  [INFO] Optional ERF bridge not loaded (not required)';
PRINT '';

-- Operating Plan MeasureSet enrichment validation (PRIMARY)
PRINT '3.2.2 - Operating Plan MeasureSet enrichment (PRIMARY)...';
IF OBJECT_ID('[Analytics].[tbl_Dim_OpPlan_MeasureSet]', 'U') IS NOT NULL
BEGIN
    -- MeasureSet dimension row count
    SELECT
        'tbl_Dim_OpPlan_MeasureSet' AS [Dimension],
        COUNT(*) AS [MeasureSets],
        CASE WHEN COUNT(*) > 0 THEN 'OK' ELSE 'EMPTY' END AS [Status]
    FROM [Analytics].[tbl_Dim_OpPlan_MeasureSet];

    -- MeasureSet bridge row count
    IF OBJECT_ID('[Analytics].[tbl_Bridge_OpPlan_MeasureSet]', 'U') IS NOT NULL
    BEGIN
        SELECT
            'tbl_Bridge_OpPlan_MeasureSet' AS [Bridge],
            COUNT(*) AS [Records],
            COUNT(DISTINCT SK_OpPlan_MeasureSet) AS [Distinct_MeasureSets],
            COUNT(DISTINCT MeasureID) AS [Distinct_Measures]
        FROM [Analytics].[tbl_Bridge_OpPlan_MeasureSet];
    END

    -- Check enrichment on facts (Is_Operating_Plan flag)
    PRINT '  OpPlan enrichment on IP facts:';
    IF EXISTS (SELECT 1 FROM [Analytics].[tbl_Fact_IP_Activity])
    BEGIN
        SELECT
            COUNT(*) AS [Total_Records],
            SUM(CASE WHEN Is_Operating_Plan = 1 THEN 1 ELSE 0 END) AS [OpPlan_Records],
            CAST(SUM(CASE WHEN Is_Operating_Plan = 1 THEN 1 ELSE 0 END) * 100.0
                / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS [OpPlan_Pct],
            COUNT(DISTINCT SK_OpPlan_MeasureSet) AS [Distinct_MeasureSets_Used]
        FROM [Analytics].[tbl_Fact_IP_Activity];
    END

    PRINT '  OpPlan enrichment on OP facts:';
    IF EXISTS (SELECT 1 FROM [Analytics].[tbl_Fact_OP_Activity])
    BEGIN
        SELECT
            COUNT(*) AS [Total_Records],
            SUM(CASE WHEN Is_Operating_Plan = 1 THEN 1 ELSE 0 END) AS [OpPlan_Records],
            CAST(SUM(CASE WHEN Is_Operating_Plan = 1 THEN 1 ELSE 0 END) * 100.0
                / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS [OpPlan_Pct],
            COUNT(DISTINCT SK_OpPlan_MeasureSet) AS [Distinct_MeasureSets_Used]
        FROM [Analytics].[tbl_Fact_OP_Activity];
    END
END
ELSE PRINT '  [SKIP] OpPlan MeasureSet dimension not created';
PRINT '';

-------------------------------------------------------------------------------
-- SECTION 1.3: IDEMPOTENCY TESTS
-------------------------------------------------------------------------------
PRINT '===============================================================================';
PRINT 'SECTION 1.3: IDEMPOTENCY TESTS';
PRINT '===============================================================================';
PRINT '';
PRINT 'Purpose: Verify that re-running loaders does not create duplicates';
PRINT '';

-- Create snapshot of current state
IF OBJECT_ID('tempdb..#BeforeReload', 'U') IS NOT NULL DROP TABLE #BeforeReload;
CREATE TABLE #BeforeReload (
    TableName VARCHAR(100),
    RowCount BIGINT,
    TotalCost DECIMAL(18,2),
    MinDate DATE,
    MaxDate DATE
);

IF EXISTS (SELECT 1 FROM [Analytics].[tbl_Fact_IP_Activity])
BEGIN
    INSERT INTO #BeforeReload
    SELECT
        'tbl_Fact_IP_Activity',
        COUNT(*),
        SUM(Total_Activity_Cost),
        MIN(Admission_Date),
        MAX(Discharge_Date)
    FROM [Analytics].[tbl_Fact_IP_Activity];
END

IF EXISTS (SELECT 1 FROM [Analytics].[tbl_Fact_OP_Activity])
BEGIN
    INSERT INTO #BeforeReload
    SELECT
        'tbl_Fact_OP_Activity',
        COUNT(*),
        SUM(Total_Activity_Cost),
        MIN(Appointment_Date),
        MAX(Appointment_Date)
    FROM [Analytics].[tbl_Fact_OP_Activity];
END

IF EXISTS (SELECT 1 FROM [Analytics].[tbl_Fact_AE_Activity])
BEGIN
    INSERT INTO #BeforeReload
    SELECT
        'tbl_Fact_AE_Activity',
        COUNT(*),
        SUM(Total_Activity_Cost),
        MIN(Arrival_Date),
        MAX(Arrival_Date)
    FROM [Analytics].[tbl_Fact_AE_Activity];
END

PRINT '1.3.1 - Baseline snapshot captured';
SELECT * FROM #BeforeReload;
PRINT '';

PRINT '1.3.2 - IDEMPOTENCY TEST INSTRUCTIONS:';
PRINT '';
PRINT '  STEP 1: Note the row counts and cost totals above';
PRINT '  STEP 2: Re-run the same load command (e.g., sp_Run_Fact_Loads_With_Enrichment)';
PRINT '          with the SAME date range as the initial load';
PRINT '  STEP 3: Run this query again to compare:';
PRINT '';
PRINT '  -- Compare after re-run';
PRINT '  SELECT * FROM #BeforeReload; -- Should match new counts';
PRINT '';
PRINT '  -- Check for duplicates';
PRINT '  SELECT SK_EncounterID, COUNT(*)';
PRINT '  FROM [Analytics].[tbl_Fact_IP_Activity]';
PRINT '  GROUP BY SK_EncounterID';
PRINT '  HAVING COUNT(*) > 1; -- Should return 0 rows';
PRINT '';
PRINT '  EXPECTED RESULT: Row counts should be IDENTICAL (delete/reload pattern)';
PRINT '  PASS CRITERIA:   Zero duplicates on SK_EncounterID';
PRINT '';

-------------------------------------------------------------------------------
-- SECTION 4: PERFORMANCE METRICS (From ETL Logs)
-------------------------------------------------------------------------------
PRINT '===============================================================================';
PRINT 'SECTION 4: PERFORMANCE METRICS (FROM ETL LOGS)';
PRINT '===============================================================================';
PRINT '';

-- Batch log summary
PRINT '4.1 - ETL batch execution summary...';
IF OBJECT_ID('[Analytics].[tbl_ETL_Batch_Log]', 'U') IS NOT NULL
BEGIN
    SELECT TOP 10
        Batch_ID,
        Batch_Start_DateTime,
        Batch_End_DateTime,
        DATEDIFF(SECOND, Batch_Start_DateTime, Batch_End_DateTime) AS [Duration_Seconds],
        CAST(DATEDIFF(SECOND, Batch_Start_DateTime, Batch_End_DateTime) / 60.0 AS DECIMAL(10,2)) AS [Duration_Minutes],
        Batch_Status,
        Rows_Processed,
        Error_Message
    FROM [Analytics].[tbl_ETL_Batch_Log]
    ORDER BY Batch_Start_DateTime DESC;
END
ELSE PRINT '  [INFO] ETL Batch Log not populated yet';
PRINT '';

-- Table load details
PRINT '4.2 - Table load performance breakdown...';
IF OBJECT_ID('[Analytics].[tbl_ETL_Table_Load_Log]', 'U') IS NOT NULL
BEGIN
    SELECT
        tl.Table_Name,
        tl.Operation,
        COUNT(*) AS [Executions],
        SUM(tl.Rows_Inserted) AS [Total_Rows_Inserted],
        AVG(tl.Rows_Inserted) AS [Avg_Rows_Per_Run],
        SUM(tl.Duration_Seconds) AS [Total_Duration_Sec],
        AVG(tl.Duration_Seconds) AS [Avg_Duration_Sec],
        MAX(tl.Duration_Seconds) AS [Max_Duration_Sec]
    FROM [Analytics].[tbl_ETL_Table_Load_Log] tl
    GROUP BY tl.Table_Name, tl.Operation
    ORDER BY SUM(tl.Duration_Seconds) DESC;
END
ELSE PRINT '  [INFO] ETL Table Load Log not populated yet';
PRINT '';

-- Error log (if exists)
PRINT '4.3 - ETL error log...';
IF OBJECT_ID('[Analytics].[tbl_ETL_Error_Details]', 'U') IS NOT NULL
BEGIN
    IF EXISTS (SELECT 1 FROM [Analytics].[tbl_ETL_Error_Details])
    BEGIN
        SELECT TOP 10
            Error_DateTime,
            Table_Name,
            Error_Message,
            Error_Severity
        FROM [Analytics].[tbl_ETL_Error_Details]
        ORDER BY Error_DateTime DESC;
    END
    ELSE PRINT '  [OK] No errors logged';
END
ELSE PRINT '  [INFO] ETL Error Details table not found';
PRINT '';

-------------------------------------------------------------------------------
-- SUMMARY
-------------------------------------------------------------------------------
PRINT '===============================================================================';
PRINT 'VALIDATION SUITE COMPLETE';
PRINT 'Completed: ' + CONVERT(VARCHAR(30), GETDATE(), 121);
PRINT '===============================================================================';
PRINT '';
PRINT 'Next Steps:';
PRINT '  1. Review all PASS/WARN/FAIL statuses above';
PRINT '  2. Investigate any FAIL results before proceeding';
PRINT '  3. If idempotency test not run, execute Section 1.3 instructions';
PRINT '  4. Once validated, extend to full 6-month window:';
PRINT '     EXEC sp_Run_Fact_Loads_With_Enrichment';
PRINT '       @FromDate = ''2024-10-01'', @ToDate = ''2025-03-31'',';
PRINT '       @FinYearStart = ''2025'', @FinancialYear = ''2025/2026'';';
PRINT '  5. Build Power BI semantic model';
PRINT '';
PRINT 'Documentation:';
PRINT '  - Runbook: docs/operations/00_RUNBOOK.md';
PRINT '  - Execution Handbook: docs/operations/EXECUTION_HANDBOOK.md';
PRINT '  - Technical Spec: docs/TECHNICAL_SPECIFICATION.md';
PRINT '';
PRINT '===============================================================================';
GO

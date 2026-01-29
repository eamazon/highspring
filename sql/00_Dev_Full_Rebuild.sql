/*
===============================================================================
DEV FULL REBUILD SCRIPT (SQLCMD Mode)
===============================================================================
Purpose: Single script for from-scratch dev rebuilds.
         Runs deploy + precompute + facts + enrichment in one go.

Usage:   TWO STEPS ONLY:

         Step 1 (WSL terminal - refresh staging data):
            ./scripts/refresh_staging_data.sh

            Or with options:
            ./scripts/refresh_staging_data.sh --skip-imd   # Use existing IMD data

         Step 2 (SSMS/ADS - run this script):
            Open H:\sql\00_Dev_Full_Rebuild.sql
            Enable SQLCMD Mode
            Execute (F5)

Config:  Edit the :setvar lines below to change parameters.
===============================================================================
*/

-- ═══════════════════════════════════════════════════════════════════════════
-- CONFIGURATION (edit these for your run)
-- ═══════════════════════════════════════════════════════════════════════════
:setvar ResetETLLogs 1
:setvar FinYearStart 2025
:setvar FinancialYear "2025/2026"
:setvar FromDate "2025-04-01"
:setvar ToDate "2025-12-31"

PRINT '===============================================================================';
PRINT 'DEV FULL REBUILD';
PRINT '===============================================================================';
PRINT 'Config:';
PRINT '  FinYearStart   = $(FinYearStart)';
PRINT '  FinancialYear  = $(FinancialYear)';
PRINT '  FromDate       = $(FromDate)';
PRINT '  ToDate         = $(ToDate)';
PRINT '  ResetETLLogs   = $(ResetETLLogs)';
PRINT '===============================================================================';
PRINT '';

-- ═══════════════════════════════════════════════════════════════════════════
-- PHASE 1: DEPLOY (objects + dimensions)
-- ═══════════════════════════════════════════════════════════════════════════
PRINT '>>> PHASE 1: DEPLOY (objects + dimensions)';
PRINT '    Running 00_Run_Everything_SQLCMD.sql...';
:r H:\sql\00_Run_Everything_SQLCMD.sql
PRINT '';
PRINT '>>> PHASE 1 COMPLETE: Deploy finished';
PRINT '';

-- ═══════════════════════════════════════════════════════════════════════════
-- PHASE 2: PRECOMPUTE (required before enrichment)
-- ═══════════════════════════════════════════════════════════════════════════
PRINT '>>> PHASE 2: PRECOMPUTE';
PRINT '';

PRINT '    [2.1] CAM Raw...';
EXEC [Analytics].[sp_Compute_CAM_Raw]
    @FinYearStart = '$(FinYearStart)',
    @FinancialYear = '$(FinancialYear)';
PRINT '    [OK] CAM Raw complete';

PRINT '    [2.2] CAM Assignment Active...';
EXEC [Analytics].[sp_Load_CAM_Assignment_Active]
    @FinYearStart = '$(FinYearStart)',
    @FinancialYear = '$(FinancialYear)';
PRINT '    [OK] CAM Assignment Active complete';

PRINT '    [2.3] ERF Repriced Active...';
EXEC [Analytics].[sp_Load_ERF_Repriced_Active]
    @FinYearStart = '$(FinYearStart)';
PRINT '    [OK] ERF Repriced Active complete';

PRINT '    [2.4] OpPlan Active...';
EXEC [Analytics].[sp_Load_OpPlan_Active]
    @FinYearStart = '$(FinYearStart)';
PRINT '    [OK] OpPlan Active complete';

PRINT '';
PRINT '>>> PHASE 2 COMPLETE: Precompute finished';
PRINT '';

-- ═══════════════════════════════════════════════════════════════════════════
-- PHASE 3: FACTS (individual loads)
-- ═══════════════════════════════════════════════════════════════════════════
PRINT '>>> PHASE 3: FACTS';
PRINT '';

PRINT '    [3.1] Fact_IP_Activity...';
EXEC [Analytics].[sp_Load_Fact_IP_Activity]
    @FromDate = '$(FromDate)',
    @ToDate = '$(ToDate)';
PRINT '    [OK] Fact_IP_Activity complete';

PRINT '    [3.2] Fact_OP_Activity...';
EXEC [Analytics].[sp_Load_Fact_OP_Activity]
    @FromDate = '$(FromDate)',
    @ToDate = '$(ToDate)';
PRINT '    [OK] Fact_OP_Activity complete';

PRINT '    [3.3] Fact_AE_Activity...';
EXEC [Analytics].[sp_Load_Fact_AE_Activity]
    @FromDate = '$(FromDate)',
    @ToDate = '$(ToDate)';
PRINT '    [OK] Fact_AE_Activity complete';

PRINT '';
PRINT '>>> PHASE 3 COMPLETE: Facts loaded';
PRINT '';

-- ═══════════════════════════════════════════════════════════════════════════
-- PHASE 4: ENRICHMENT (individual)
-- ═══════════════════════════════════════════════════════════════════════════
PRINT '>>> PHASE 4: ENRICHMENT';
PRINT '';

PRINT '    [4.1] Operating Plan enrichment...';
EXEC [Analytics].[sp_Enrich_Facts_Operating_Plan]
    @FinYearStart = '$(FinYearStart)';
PRINT '    [OK] Operating Plan enrichment complete';

PRINT '    [4.2] ERF enrichment...';
EXEC [Analytics].[sp_Enrich_Facts_ERF]
    @FinYearStart = '$(FinYearStart)';
PRINT '    [OK] ERF enrichment complete';

PRINT '    [4.3] CAM enrichment...';
EXEC [Analytics].[sp_Enrich_Facts_CAM]
    @FinancialYear = '$(FinancialYear)',
    @ProviderCode = NULL,
    @FromDate = '$(FromDate)',
    @ToDate = '$(ToDate)';
PRINT '    [OK] CAM enrichment complete';

PRINT '';
PRINT '>>> PHASE 4 COMPLETE: Enrichment finished';
PRINT '';

-- ═══════════════════════════════════════════════════════════════════════════
-- SUMMARY
-- ═══════════════════════════════════════════════════════════════════════════
PRINT '===============================================================================';
PRINT 'DEV FULL REBUILD COMPLETE';
PRINT '===============================================================================';
PRINT '';
PRINT 'Row counts:';

SELECT 'tbl_Fact_IP_Activity' AS [Table], COUNT(*) AS [Rows] FROM [Analytics].[tbl_Fact_IP_Activity]
UNION ALL
SELECT 'tbl_Fact_OP_Activity', COUNT(*) FROM [Analytics].[tbl_Fact_OP_Activity]
UNION ALL
SELECT 'tbl_Fact_AE_Activity', COUNT(*) FROM [Analytics].[tbl_Fact_AE_Activity]
UNION ALL
SELECT 'tbl_CAM_Assignment_Active', COUNT(*) FROM [Analytics].[tbl_CAM_Assignment_Active]
UNION ALL
SELECT 'tbl_ERF_Repriced_Active', COUNT(*) FROM [Analytics].[tbl_ERF_Repriced_Active]
UNION ALL
SELECT 'tbl_OpPlan_Active', COUNT(*) FROM [Analytics].[tbl_OpPlan_Active];

PRINT '';
PRINT 'Next steps (optional):';
PRINT '  - Run ERF bridge:        EXEC [Analytics].[sp_Load_Bridge_ERF_Activity] @FinYearStart = ''$(FinYearStart)'';';
PRINT '  - Run CF segmentation:   EXEC [Analytics].[sp_Load_Bridge_CF_Segment_Patient_Snapshot] @SnapshotMonth = 202509;';
PRINT '  - Run validation:        See docs/VALIDATION_QUERIES.sql';
PRINT '===============================================================================';
GO

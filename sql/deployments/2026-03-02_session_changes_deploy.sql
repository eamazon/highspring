/*
Deployment: Session changes up to 2026-03-02
Run in SQLCMD mode.

From repo root (example):
  sqlcmd -S <server> -d Data_Lab_SWL_Live -E -b -i sql/deployments/2026-03-02_session_changes_deploy.sql

Notes:
1) This applies object changes from this session.
2) For HRG data load, choose ONE option:
   - Option A (recommended): stage + run sp_Load_Dim_HRG
   - Option B: direct collapsed load into Analytics.tbl_HRG
*/

:ON ERROR EXIT

PRINT '=== Deploy Start: 2026-03-02 session changes ===';
GO

-------------------------------------------------------------------------------
-- 1) Function and dimension/view changes
-------------------------------------------------------------------------------
:r ../00_setup/08_Create_OP_POD_Function.sql
:r ../01_dimensions/19_Create_Dim_Ethnicity.sql
:r ../01_dimensions/26_Create_Dim_Age_Band.sql
GO

-------------------------------------------------------------------------------
-- 2) Fact loader procedure changes
-------------------------------------------------------------------------------
:r ../04_etl/10_sp_Load_Fact_IP_Activity.sql
:r ../04_etl/11_sp_Load_Fact_OP_Activity.sql
:r ../04_etl/12_sp_Load_Fact_AE_Activity.sql
GO

-------------------------------------------------------------------------------
-- 3) HRG model + loader changes
-------------------------------------------------------------------------------
-- Creates HRG staging table only (safe, no other staging-table resets)
:r ../00_setup/04b_Create_Staging_HRG.sql
-- Creates Analytics.tbl_HRG + Analytics.vw_Dim_HRG
:r ../01_dimensions/22_Create_Dim_HRG.sql
-- Creates Analytics.sp_Load_Dim_HRG
:r ../04_etl/05_Load_Dim_HRG.sql
GO

-------------------------------------------------------------------------------
-- 4) HRG data load - choose ONE option
-------------------------------------------------------------------------------

-- Option A (recommended): load staging then run SCD loader
-- :r ../04_etl/nhs_hrg_code_to_group_20260227_170649.sql
-- EXEC [Analytics].[sp_Load_Dim_HRG];
-- GO

-- Option B: direct collapsed load (one row per HRG code with Valid_From/Valid_To)
-- :r ../04_etl/nhs_hrg_code_to_group_collapsed_20260227_171017.sql
-- GO

PRINT '=== Deploy Complete: 2026-03-02 session changes ===';
GO

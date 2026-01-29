/*
===============================================================================
MASTER DEPLOYMENT SCRIPT (SQLCMD Mode)
===============================================================================
Purpose: Deploys the entire HighSpring environment in one click.
Usage:   Open in VS Code with MSSQL Extension.
         Ensure "SQLCMD Mode" is enabled.
         Execute the script.

Note:    Absolute paths for H:\sql\analytics_platform mapping.

Prerequisite (Week 4/5 facts):
- Fact loaders read from Unified denormalised encounter views.
- POD for IP/OP is derived in those views via `GetPodType` as `POD_Detailed`.
- Ensure Unified objects are deployed before running fact loads:
    - Unified.vw_IP_EncounterDenormalised_DateRange (includes POD_Detailed)
    - Unified.vw_OP_EncounterDenormalised_DateRange (includes POD_Detailed)
    - Unified.vw_ED_EncounterDenormalised_DateRange_v2
    - [IP].[GetPodType], [OP].[GetPodType]

Analytics fact loaders also use [OP].[fn_GetPODType] for OP POD mapping.

This script creates fact load stored procedures, but does not execute them.
===============================================================================
*/
:setvar ResetETLLogs 1
SELECT 1 AS TEST;

PRINT '>>> STARTING MASTER DEPLOYMENT';
PRINT '';

-------------------------------------------------------------------------------
-- 1. SETUP (Schemas, Logging, Staging)
-------------------------------------------------------------------------------
PRINT '>>> 1. Core Setup';
:r H:\sql\analytics_platform\00_setup\01_Create_Analytics_Schema.sql
:r H:\sql\analytics_platform\00_setup\02_Create_Partition_Function_Scheme.sql
:r H:\sql\analytics_platform\00_setup\03_Create_ETL_Logging.sql
:r H:\sql\analytics_platform\00_setup\04_Create_Staging_NHS_ODS.sql
:r H:\sql\analytics_platform\00_setup\07_Create_Staging_LSOA_IMD2019.sql
:r H:\sql\analytics_platform\00_setup\10_Create_Staging_PCN_Relationships.sql
:r H:\sql\analytics_platform\00_setup\05_Create_SUS_Published_Functions.sql
:r H:\sql\analytics_platform\00_setup\06_Create_SUS_Published_Functions_SWL.sql
:r H:\sql\analytics_platform\00_setup\08_Create_OP_POD_Function.sql
:r H:\sql\analytics_platform\00_setup\06_Create_Partition_Maintenance.sql
:r H:\sql\analytics_platform\00_setup\07_Create_CAM_View.sql
:r H:\sql\analytics_platform\00_setup\09_Create_ERF_Views.sql
:r H:\sql\cam\[CAM].[tbl_CAM_Raw].sql
:r H:\sql\analytics_platform\04_etl\24_sp_Compute_CAM_Raw.sql
PRINT '    [OK] Setup Complete';

-------------------------------------------------------------------------------
-- 1b. RESET ETL LOGS (Optional clean slate for reruns)
-------------------------------------------------------------------------------
PRINT '>>> 1b. Resetting ETL Logs';

IF $(ResetETLLogs) = 1
BEGIN
    BEGIN TRY
        IF OBJECT_ID('[Analytics].[tbl_ETL_Performance_Metrics]', 'U') IS NOT NULL
        BEGIN
            DELETE FROM [Analytics].[tbl_ETL_Performance_Metrics];
            DBCC CHECKIDENT ('[Analytics].[tbl_ETL_Performance_Metrics]', RESEED, 0);
        END

        IF OBJECT_ID('[Analytics].[tbl_ETL_Error_Details]', 'U') IS NOT NULL
        BEGIN
            DELETE FROM [Analytics].[tbl_ETL_Error_Details];
            DBCC CHECKIDENT ('[Analytics].[tbl_ETL_Error_Details]', RESEED, 0);
        END

        IF OBJECT_ID('[Analytics].[tbl_ETL_Table_Load_Log]', 'U') IS NOT NULL
        BEGIN
            DELETE FROM [Analytics].[tbl_ETL_Table_Load_Log];
            DBCC CHECKIDENT ('[Analytics].[tbl_ETL_Table_Load_Log]', RESEED, 0);
        END

        IF OBJECT_ID('[Analytics].[tbl_ETL_Batch_Log]', 'U') IS NOT NULL
        BEGIN
            DELETE FROM [Analytics].[tbl_ETL_Batch_Log];
            DBCC CHECKIDENT ('[Analytics].[tbl_ETL_Batch_Log]', RESEED, 0);
        END

        PRINT '    [OK] ETL Logs Reset';
    END TRY
    BEGIN CATCH
        PRINT '    [WARN] Failed to reset ETL logs: ' + ERROR_MESSAGE();
    END CATCH
END
ELSE
BEGIN
    PRINT '    [SKIP] ETL log reset disabled (ResetETLLogs = 0)';
END

-------------------------------------------------------------------------------
-- 2. DIMENSIONS (DDL)
-------------------------------------------------------------------------------
PRINT '>>> 2. Creating Dimensions';
PRINT '    2a. API Dimensions (Tables with ETL)';
:r H:\sql\analytics_platform\01_dimensions\00_Create_tbl_Dim_Patient.sql
:r H:\sql\analytics_platform\01_dimensions\01_Create_Dim_Commissioner.sql
:r H:\sql\analytics_platform\01_dimensions\02_Create_Dim_POD.sql
:r H:\sql\analytics_platform\01_dimensions\03_Create_Dim_GPPractice.sql
:r H:\sql\analytics_platform\01_dimensions\04_Create_Dim_PCN.sql
:r H:\sql\analytics_platform\01_dimensions\27_Create_Dim_LSOA.sql
:r H:\sql\analytics_platform\01_dimensions\29_Create_Dim_CAM_Service_Category.sql
:r H:\sql\analytics_platform\01_dimensions\30_Create_Dim_CAM_Assignment_Reason.sql
:r H:\sql\analytics_platform\01_dimensions\31_Create_Dim_OpPlan_MeasureSet.sql
:r H:\sql\analytics_platform\01_dimensions\05_Create_Dim_Measures_Catalogue.sql
PRINT '    2b. Dictionary NHS DD Dimensions (Views - IP)';
:r H:\sql\analytics_platform\01_dimensions\06_Create_Dim_Admission_Method.sql
:r H:\sql\analytics_platform\01_dimensions\07_Create_Dim_Admission_Source.sql
:r H:\sql\analytics_platform\01_dimensions\08_Create_Dim_Discharge_Method.sql
:r H:\sql\analytics_platform\01_dimensions\09_Create_Dim_Discharge_Destination.sql
:r H:\sql\analytics_platform\01_dimensions\10_Create_Dim_IP_Patient_Classification.sql
PRINT '    2c. Dictionary NHS DD Dimensions (Views - OP)';
:r H:\sql\analytics_platform\01_dimensions\11_Create_Dim_Attendance_Status.sql
:r H:\sql\analytics_platform\01_dimensions\12_Create_Dim_Attendance_Outcome.sql
:r H:\sql\analytics_platform\01_dimensions\14_Create_Dim_Attendance_Type.sql
:r H:\sql\analytics_platform\01_dimensions\15_Create_Dim_DNA_Indicator.sql
:r H:\sql\analytics_platform\01_dimensions\16_Create_Dim_Priority_Type.sql
:r H:\sql\analytics_platform\01_dimensions\17_Create_Dim_Referral_Source.sql
PRINT '    2d. Dictionary NHS DD Dimensions (Views - AE)';
:r H:\sql\analytics_platform\01_dimensions\18_Create_Dim_Attendance_Disposal.sql
PRINT '    2e. Dictionary NHS DD Dimensions (Views - Core)';
:r H:\sql\analytics_platform\01_dimensions\13_Create_Dim_Date.sql
:r H:\sql\analytics_platform\01_dimensions\18_Create_Dim_Gender.sql
:r H:\sql\analytics_platform\01_dimensions\19_Create_Dim_Ethnicity.sql
:r H:\sql\analytics_platform\01_dimensions\28_Create_Dim_LSOA_View.sql
:r H:\sql\analytics_platform\01_dimensions\25_Create_Dim_Provider.sql
:r H:\sql\analytics_platform\01_dimensions\21_Create_Dim_Specialty.sql
:r H:\sql\analytics_platform\01_dimensions\22_Create_Dim_HRG.sql
:r H:\sql\analytics_platform\01_dimensions\26_Create_Dim_Age_Band.sql
:r H:\sql\analytics_platform\01_dimensions\32_Create_Dim_OpPlan_Measure.sql
PRINT '    [OK] All Dimensions Created (29 total: 9 tables + 20 views)';

-------------------------------------------------------------------------------
-- 2.5. FACTS + BRIDGES (DDL)
-------------------------------------------------------------------------------
PRINT '>>> 2.5 Creating Facts + Bridges (DDL)';
:r H:\sql\analytics_platform\02_facts\01_Create_tbl_Fact_IP_Activity.sql
:r H:\sql\analytics_platform\02_facts\02_Create_tbl_Fact_OP_Activity.sql
:r H:\sql\analytics_platform\02_facts\03_Create_tbl_Fact_AE_Activity.sql

:r H:\sql\analytics_platform\03_bridges\01f_Create_tbl_Bridge_CF_Segment_Patient_Snapshot.sql
:r H:\sql\analytics_platform\03_bridges\01c_Create_tbl_Ref_CF_Segment_Rules.sql
:r H:\sql\analytics_platform\03_bridges\01e_Create_tbl_Ref_CF_Code_Lookup.sql
:r H:\sql\analytics_platform\03_bridges\01d_Load_tbl_Ref_CF_Segment_Rule_ICD10.sql
:r H:\sql\analytics_platform\03_bridges\02b_Create_tbl_Bridge_Operating_Plan_Deferred.sql
:r H:\sql\analytics_platform\03_bridges\02f_Create_tbl_Bridge_OpPlan_MeasureSet.sql
:r H:\sql\analytics_platform\03_bridges\03_Create_tbl_Bridge_ERF.sql
:r H:\sql\analytics_platform\03_bridges\04_Create_tbl_CAM_Assignment_Active.sql
:r H:\sql\analytics_platform\03_bridges\05_Create_tbl_ERF_Repriced_Active.sql
:r H:\sql\analytics_platform\03_bridges\06_Create_tbl_OpPlan_Active.sql
PRINT '    [OK] Facts + Bridges Created';

-------------------------------------------------------------------------------
-- 2.6 FACT DENORMALISED VIEWS
-------------------------------------------------------------------------------
PRINT '>>> 2.6 Creating Fact Denormalised Views';
:r H:\sql\analytics_platform\02_facts\04_Create_vw_Fact_IP_Activity_Denormalised.sql
:r H:\sql\analytics_platform\02_facts\05_Create_vw_Fact_OP_Activity_Denormalised.sql
PRINT '    [OK] Fact Denormalised Views Created';

-------------------------------------------------------------------------------
-- 3. ETL PROCEDURES (Create SPs)
-------------------------------------------------------------------------------
PRINT '>>> 3. Creating ETL Procedures';
:r H:\sql\analytics_platform\04_etl\01_Load_Dim_Commissioner.sql
:r H:\sql\analytics_platform\04_etl\02_Load_Dim_GPPractice.sql
:r H:\sql\analytics_platform\04_etl\03_Load_Dim_PCN.sql
:r H:\sql\analytics_platform\04_etl\04_Load_Dim_POD.sql
:r H:\sql\analytics_platform\04_etl\05_Load_Dim_LSOA.sql
:r H:\sql\analytics_platform\04_etl\06_Load_Dim_CAM_Service_Category.sql
:r H:\sql\analytics_platform\04_etl\07_Load_Dim_CAM_Assignment_Reason.sql
:r H:\sql\analytics_platform\04_etl\08_Load_Dim_Patient.sql

PRINT '    3b. Fact Load Procedures (Create only - do NOT execute yet)';
:r H:\sql\analytics_platform\04_etl\10_sp_Load_Fact_IP_Activity.sql
:r H:\sql\analytics_platform\04_etl\11_sp_Load_Fact_OP_Activity.sql
:r H:\sql\analytics_platform\04_etl\12_sp_Load_Fact_AE_Activity.sql

PRINT '    3c. Precompute CAM/ERF Procedures (Create only - execute when ready)';
:r H:\sql\analytics_platform\04_etl\21_sp_Load_CAM_Assignment_Active_OPTIMIZED.sql
:r H:\sql\analytics_platform\04_etl\22_sp_Load_ERF_Repriced_Active.sql
PRINT '    3c.1 Precompute Operating Plan Active (Create only - execute when ready)';
:r H:\sql\analytics_platform\04_etl\23_sp_Load_OpPlan_Active.sql
PRINT '    3c.2 CF Code Lookup Loader (Create only - execute when ready)';
:r H:\sql\analytics_platform\04_etl\25_sp_Load_Ref_CF_Code_Lookup.sql

PRINT '    3d. Bridge Load Procedures (Create only - execute when ready)';
:r H:\sql\analytics_platform\04_etl\13_sp_Load_Bridge_ERF_Activity.sql
:r H:\sql\analytics_platform\04_etl\14_sp_Load_Bridge_Operating_Plan_Deferred.sql

PRINT '    3e. Fact Enrichment Procedures (Create only - execute when ready)';
:r H:\sql\analytics_platform\04_etl\16_sp_Enrich_Facts_CAM.sql
:r H:\sql\analytics_platform\04_etl\19_sp_Enrich_Facts_Operating_Plan.sql
:r H:\sql\analytics_platform\04_etl\20_sp_Enrich_Facts_ERF.sql
:r H:\sql\analytics_platform\04_etl\09_sp_Run_Fact_Loads_With_Enrichment.sql

PRINT '    3f. Patient Segmentation Procedures (Create only - execute when ready)';
:r H:\sql\analytics_platform\04_etl\26_sp_Load_Bridge_CF_Segment_Patient_Snapshot.sql
PRINT '    [OK] ETL Procedures Created';

-------------------------------------------------------------------------------
-- 4. STATIC DATA LOAD
-------------------------------------------------------------------------------
PRINT '>>> 4. Loading Static Reference Data';
:r H:\sql\analytics_platform\01_dimensions\05_Populate_Dim_POD.sql
PRINT '    [OK] Static Data Loaded';

-------------------------------------------------------------------------------
-- 5. STAGING DATA LOAD (From Python Fetch)
-------------------------------------------------------------------------------
PRINT '>>> 5. Loading Staging Data (Snapshots)';
-- Fixed filenames: Python fetchers now write to these "latest" files automatically.
-- Run the fetchers to refresh data:
--   python scripts/data_integration/nhs_ods/fetch_all_commissioners.py --output sql --output-dir sql/analytics_platform/05_api
--   python scripts/data_integration/nhs_ods/fetch_gp_practices_csv.py
--   python scripts/data_integration/imd2019/fetch_imd2019_idaci_idaopi.py --url <IMD_URL> --out-dir sql/analytics_platform/05_api
:r H:\sql\analytics_platform\05_api\staging_commissioner.sql
:r H:\sql\analytics_platform\05_api\staging_gp_practice.sql
:r H:\sql\analytics_platform\05_api\staging_lsoa_imd.sql
PRINT '    [OK] Staging Tables Populated';

-------------------------------------------------------------------------------
-- 6. RUN ETL (Populate Dimensions)
-------------------------------------------------------------------------------
PRINT '>>> 6. Executing Dimension Loads';
:r H:\sql\analytics_platform\04_etl\00_Run_All_Dimension_Loads.sql
PRINT '    [OK] All Dimensions Loaded';


PRINT '';
PRINT '===============================================================================';
PRINT 'DEPLOYMENT & DATA LOAD COMPLETE';
PRINT '===============================================================================';
GO

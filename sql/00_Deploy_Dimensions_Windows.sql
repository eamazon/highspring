/*
===============================================================================
MASTER DEPLOYMENT SCRIPT - WINDOWS (SQLCMD with H:\ Paths)
===============================================================================
Purpose: Deploys the entire HighSpring dimensions for Windows SSMS.
Usage:   1. Map project folder to H:\
         2. Open this file in SSMS
         3. Enable SQLCMD Mode (Query > SQLCMD Mode)
         4. Execute (F5)

Last Fixed: 2026-01-08 - Renamed all VIEWs to vw_Dim_* with proper headers
===============================================================================
*/

PRINT '>>> STARTING MASTER DEPLOYMENT';
PRINT '';

-------------------------------------------------------------------------------
-- 2. DIMENSIONS (DDL)
-------------------------------------------------------------------------------
PRINT '>>> 2. Creating Dimensions';
PRINT '    2a. API Dimensions (Tables with ETL) - tbl_Dim_*';
:r H:\sql\analytics_platform\01_dimensions\01_Create_Dim_Commissioner.sql
:r H:\sql\analytics_platform\01_dimensions\02_Create_Dim_POD.sql
:r H:\sql\analytics_platform\01_dimensions\03_Create_Dim_GPPractice.sql
:r H:\sql\analytics_platform\01_dimensions\04_Create_Dim_PCN.sql
:r H:\sql\analytics_platform\01_dimensions\05_Create_Dim_Measures_Catalogue.sql

PRINT '    2b. Date Events Table - tbl_Dim_Date_Events';
:r H:\sql\analytics_platform\01_dimensions\23_Create_Dim_Date_Events.sql
:r H:\sql\analytics_platform\01_dimensions\24_Populate_Date_Events.sql

PRINT '    2c. Dictionary NHS DD Dimensions (Views - IP) - vw_Dim_*';
:r H:\sql\analytics_platform\01_dimensions\06_Create_Dim_Admission_Method.sql
:r H:\sql\analytics_platform\01_dimensions\07_Create_Dim_Admission_Source.sql
:r H:\sql\analytics_platform\01_dimensions\08_Create_Dim_Discharge_Method.sql
:r H:\sql\analytics_platform\01_dimensions\09_Create_Dim_Discharge_Destination.sql

PRINT '    2d. Dictionary NHS DD Dimensions (Views - OP) - vw_Dim_*';
:r H:\sql\analytics_platform\01_dimensions\12_Create_Dim_Attendance_Outcome.sql
:r H:\sql\analytics_platform\01_dimensions\14_Create_Dim_Attendance_Type.sql
:r H:\sql\analytics_platform\01_dimensions\15_Create_Dim_DNA_Indicator.sql
:r H:\sql\analytics_platform\01_dimensions\16_Create_Dim_Priority_Type.sql
:r H:\sql\analytics_platform\01_dimensions\17_Create_Dim_Referral_Source.sql

PRINT '    2e. Dictionary NHS DD Dimensions (Views - AE) - vw_Dim_*';
:r H:\sql\analytics_platform\01_dimensions\18_Create_Dim_Attendance_Disposal.sql

PRINT '    2f. Dictionary NHS DD Dimensions (Views - Core) - vw_Dim_*';
:r H:\sql\analytics_platform\01_dimensions\13_Create_Dim_Date.sql
:r H:\sql\analytics_platform\01_dimensions\18_Create_Dim_Gender.sql
:r H:\sql\analytics_platform\01_dimensions\19_Create_Dim_Ethnicity.sql
:r H:\sql\analytics_platform\01_dimensions\20_Create_Dim_Provider.sql
:r H:\sql\analytics_platform\01_dimensions\21_Create_Dim_Specialty.sql
:r H:\sql\analytics_platform\01_dimensions\22_Create_Dim_HRG.sql

PRINT '    [OK] All Dimensions Created';
PRINT '         - 5 tables (tbl_Dim_Commissioner, tbl_Dim_POD, tbl_Dim_GPPractice, tbl_Dim_PCN, tbl_Dim_Date_Events)';
PRINT '         - 15 views (14 Dictionary VIEWs + vw_Dim_Measures_Catalogue)';
PRINT '         - Enhanced vw_Dim_Date with UK calendar events and short names';
PRINT '         - All Dictionary VIEWs include _Short description columns for Power BI';

PRINT '';
PRINT '===============================================================================';
PRINT 'DIMENSION DEPLOYMENT COMPLETE';
PRINT '===============================================================================';
GO

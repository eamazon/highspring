-- ==============================================================================
-- CLEANUP SCRIPT: Drop Old Dictionary VIEWs
-- Purpose: Remove all old VIEW naming variants before deployment
-- ==============================================================================

USE [Data_Lab_SWL_Live];
GO

PRINT '>>> Dropping old Dictionary VIEWs (Dim_*, tbl_Dim_*)...';

-- Drop all three naming conventions for each Dictionary VIEW
DROP VIEW IF EXISTS [Analytics].[Dim_Date];
DROP VIEW IF EXISTS [Analytics].[tbl_Dim_Date];

DROP VIEW IF EXISTS [Analytics].[Dim_Gender];
DROP VIEW IF EXISTS [Analytics].[tbl_Dim_Gender];

DROP VIEW IF EXISTS [Analytics].[Dim_Ethnicity];
DROP VIEW IF EXISTS [Analytics].[tbl_Dim_Ethnicity];

DROP VIEW IF EXISTS [Analytics].[Dim_Provider];
DROP VIEW IF EXISTS [Analytics].[tbl_Dim_Provider];

DROP VIEW IF EXISTS [Analytics].[Dim_Specialty];
DROP VIEW IF EXISTS [Analytics].[tbl_Dim_Specialty];

DROP VIEW IF EXISTS [Analytics].[Dim_HRG];
DROP VIEW IF EXISTS [Analytics].[tbl_Dim_HRG];

DROP VIEW IF EXISTS [Analytics].[Dim_Admission_Method];
DROP VIEW IF EXISTS [Analytics].[tbl_Dim_Admission_Method];

DROP VIEW IF EXISTS [Analytics].[Dim_Admission_Source];
DROP VIEW IF EXISTS [Analytics].[tbl_Dim_Admission_Source];

DROP VIEW IF EXISTS [Analytics].[Dim_Discharge_Method];
DROP VIEW IF EXISTS [Analytics].[tbl_Dim_Discharge_Method];

DROP VIEW IF EXISTS [Analytics].[Dim_Discharge_Destination];
DROP VIEW IF EXISTS [Analytics].[tbl_Dim_Discharge_Destination];

DROP VIEW IF EXISTS [Analytics].[Dim_Attendance_Outcome];
DROP VIEW IF EXISTS [Analytics].[tbl_Dim_Attendance_Outcome];

DROP VIEW IF EXISTS [Analytics].[Dim_Attendance_Type];
DROP VIEW IF EXISTS [Analytics].[tbl_Dim_Attendance_Type];

DROP VIEW IF EXISTS [Analytics].[Dim_DNA_Indicator];
DROP VIEW IF EXISTS [Analytics].[tbl_Dim_DNA_Indicator];

DROP VIEW IF EXISTS [Analytics].[Dim_Priority_Type];
DROP VIEW IF EXISTS [Analytics].[tbl_Dim_Priority_Type];

DROP VIEW IF EXISTS [Analytics].[Dim_Referral_Source];
DROP VIEW IF EXISTS [Analytics].[tbl_Dim_Referral_Source];

DROP VIEW IF EXISTS [Analytics].[Dim_Attendance_Disposal];
DROP VIEW IF EXISTS [Analytics].[tbl_Dim_Attendance_Disposal];

PRINT '[OK] Dropped all old Dictionary VIEW variants';

PRINT '';
PRINT '>>> Dropping old dimension tables (Dim_*, tbl_Dim_*)...';

-- Drop OLD table names (Dim_Commissioner, etc.)
DROP TABLE IF EXISTS [Analytics].[Dim_Commissioner];
DROP TABLE IF EXISTS [Analytics].[Dim_POD];
DROP TABLE IF EXISTS [Analytics].[Dim_GPPractice];
DROP TABLE IF EXISTS [Analytics].[Dim_PCN];
DROP VIEW IF EXISTS [Analytics].[Dim_Measures_Catalogue];
PRINT '[OK] Dropped 5 old Dim_* tables';

-- Drop NEW table names (tbl_Dim_Commissioner, etc.)  
DROP TABLE IF EXISTS [Analytics].[tbl_Dim_Commissioner];
DROP TABLE IF EXISTS [Analytics].[tbl_Dim_POD];
DROP TABLE IF EXISTS [Analytics].[tbl_Dim_GPPractice];
DROP TABLE IF EXISTS [Analytics].[tbl_Dim_PCN];
DROP VIEW IF EXISTS [Analytics].[tbl_Dim_Measures_Catalogue];
PRINT '[OK] Dropped 5 new tbl_Dim_* tables';

PRINT '';
PRINT '>>> Dropping old fact tables (Fact_*, tbl_Fact_*)...';

-- Drop OLD fact tables
DROP TABLE IF EXISTS [Analytics].[Fact_IP_Activity];
DROP TABLE IF EXISTS [Analytics].[Fact_OP_Activity];
DROP TABLE IF EXISTS [Analytics].[Fact_AE_Activity];
PRINT '[OK] Dropped 3 old Fact_* tables (if existed)';

-- Drop NEW fact tables
DROP TABLE IF EXISTS [Analytics].[tbl_Fact_IP_Activity];
DROP TABLE IF EXISTS [Analytics].[tbl_Fact_OP_Activity];
DROP TABLE IF EXISTS [Analytics].[tbl_Fact_AE_Activity];
PRINT '[OK] Dropped 3 new tbl_Fact_* tables (if existed)';

PRINT '';
PRINT '===============================================================================';
PRINT 'CLEANUP COMPLETE';
PRINT '===============================================================================';
PRINT 'Dropped:';
PRINT '  - 28 old Dictionary VIEWs (Dim_* and tbl_Dim_* variants)';
PRINT '  - 5 old dimension tables (Dim_*)';
PRINT '  - 5 new dimension tables (tbl_Dim_*)';
PRINT '  - 3 old fact tables (Fact_*)';
PRINT '  - 3 new fact tables (tbl_Fact_*)';
PRINT  '';
PRINT 'You can now run: 00_Deploy_Dimensions_Windows.sql';
GO

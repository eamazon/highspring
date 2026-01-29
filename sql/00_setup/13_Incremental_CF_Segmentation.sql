USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Incremental deploy: CF segmentation loaders';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

-- Recreate stored procedures (safe to re-run)
:r H:\sql\analytics_platform\04_etl\25_sp_Load_Ref_CF_Code_Lookup.sql
:r H:\sql\analytics_platform\03_bridges\01f_Create_tbl_Bridge_CF_Segment_Patient_Snapshot.sql
:r H:\sql\analytics_platform\04_etl\26_sp_Load_Bridge_CF_Segment_Patient_Snapshot.sql

PRINT '[OK] Incremental deploy complete';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

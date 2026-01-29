-- Incremental deployment for CAM raw compute (Data_Lab_SWL)
-- Safe to run in SQLCMD mode after 00_Run_Everything_SQLCMD.sql
-- Creates/updates only the changed objects; does not drop data tables.

USE [Data_Lab_SWL];
GO

PRINT '>>> Incremental: CAM Raw deployment';

-- SUS cutoff helper function (Data_Lab_SWL)
:r H:\sql\analytics_platform\00_setup\06_Create_SUS_Published_Functions_SWL.sql

-- CAM raw table + compute procedure
:r H:\sql\cam\[CAM].[tbl_CAM_Raw].sql
:r H:\sql\analytics_platform\04_etl\24_sp_Compute_CAM_Raw.sql
-- CAM active loader (reads from CAM raw)
:r H:\sql\analytics_platform\04_etl\21_sp_Load_CAM_Assignment_Active.sql

PRINT '>>> Incremental: CAM Raw deployment complete';
GO

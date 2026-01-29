-- Incremental deployment for OpPlan Active (no LogId dependency)
-- Safe to run in SQLCMD mode after 00_Run_Everything_SQLCMD.sql
-- Creates/updates only the changed objects; does not drop data tables.

USE [Data_Lab_SWL_Live];
GO

PRINT '>>> Incremental: OpPlan Active deployment';

-- DDL (create-if-missing / alter)
:r H:\sql\analytics_platform\03_bridges\06_Create_tbl_OpPlan_Active.sql

-- Stored procedures (drop + create)
:r H:\sql\analytics_platform\04_etl\23_sp_Load_OpPlan_Active.sql
:r H:\sql\analytics_platform\04_etl\19_sp_Enrich_Facts_Operating_Plan.sql
:r H:\sql\analytics_platform\04_etl\09_sp_Run_Fact_Loads_With_Enrichment.sql

PRINT '>>> Incremental: OpPlan Active deployment complete';
GO

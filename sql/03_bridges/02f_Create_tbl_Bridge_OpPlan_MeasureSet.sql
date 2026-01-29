/**
-- Script Name: 02f_Create_tbl_Bridge_OpPlan_MeasureSet.sql
-- Description: Bridge between OpPlan measure sets and individual MeasureIDs.
-- Author:      Sridhar Peddi
-- Created:     2026-01-13
**/

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating tbl_Bridge_OpPlan_MeasureSet TABLE';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

IF OBJECT_ID('[Analytics].[tbl_Bridge_OpPlan_MeasureSet]', 'U') IS NOT NULL
BEGIN
    PRINT 'Table [Analytics].[tbl_Bridge_OpPlan_MeasureSet] already exists. Dropping...';
    DROP TABLE [Analytics].[tbl_Bridge_OpPlan_MeasureSet];
END
GO

CREATE TABLE [Analytics].[tbl_Bridge_OpPlan_MeasureSet] (
    [SK_OpPlan_MeasureSet] BIGINT NOT NULL,
    [MeasureID] VARCHAR(20) NOT NULL,
    [ETL_LoadDateTime] DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT [PK_Bridge_OpPlan_MeasureSet] PRIMARY KEY NONCLUSTERED ([SK_OpPlan_MeasureSet] ASC, [MeasureID] ASC)
) ON [PRIMARY];
GO

CREATE CLUSTERED COLUMNSTORE INDEX [CCI_Bridge_OpPlan_MeasureSet]
    ON [Analytics].[tbl_Bridge_OpPlan_MeasureSet];
GO

CREATE NONCLUSTERED INDEX [IX_Bridge_OpPlan_MeasureSet_MeasureID]
    ON [Analytics].[tbl_Bridge_OpPlan_MeasureSet] ([MeasureID]);
GO

PRINT '[OK] Created table: [Analytics].[tbl_Bridge_OpPlan_MeasureSet]';
GO

PRINT '';
PRINT '========================================';
PRINT 'tbl_Bridge_OpPlan_MeasureSet TABLE Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO

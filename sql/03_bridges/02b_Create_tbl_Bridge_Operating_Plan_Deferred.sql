/**
-- Script Name: 02b_Create_tbl_Bridge_Operating_Plan_Deferred.sql
-- Description: Detailed bridge table for Operating Plan (Phase 2 - DEFERRED).
--              Grain: Encounter + Measure (One-to-Many).
--              Size: ~20M rows (Significant Power BI impact).
-- Author:      Sridhar Peddi
-- Created:     2026-01-09

-- Change Log:
Change Log:
-- 2026-01-09   | Sridhar Peddi    | Initial creation - Deferred Detail Bridge
**/

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating tbl_Bridge_Operating_Plan_Deferred TABLE';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

IF OBJECT_ID('[Analytics].[tbl_Bridge_Operating_Plan_Deferred]', 'U') IS NOT NULL
BEGIN
    PRINT 'Table [Analytics].[tbl_Bridge_Operating_Plan_Deferred] already exists. Dropping...';
    DROP TABLE [Analytics].[tbl_Bridge_Operating_Plan_Deferred];
END
GO

/**
-- Table Name:  tbl_Bridge_Operating_Plan_Deferred
-- Description: Detailed Operating Plan mapping.
--              Grain: Encounter + Measure.
**/
CREATE TABLE [Analytics].[tbl_Bridge_Operating_Plan_Deferred] (
    [SK_OP_ActivityID] BIGINT IDENTITY(1,1) NOT NULL,
    [SK_EncounterID] BIGINT NOT NULL,                  -- Link to Fact
    [POD] VARCHAR(2) NOT NULL,
    [MeasureID] VARCHAR(20) NOT NULL,
    [Measure_Category] VARCHAR(50) NULL,
    
    [Is_Baseline_Activity] BIT DEFAULT 0,
    [Is_Recovery_Target] BIT DEFAULT 0,
    [Planning_Year] VARCHAR(7) NULL,                   -- '2024/25'
    
    [ETL_LoadDateTime] DATETIME2 DEFAULT GETDATE(),

    CONSTRAINT [PK_Bridge_OPPlan_Deferred] PRIMARY KEY NONCLUSTERED ([SK_OP_ActivityID] ASC)
) ON [PRIMARY];
GO

-- CLUSTERED COLUMNSTORE INDEX (Modern Standard)
CREATE CLUSTERED COLUMNSTORE INDEX [CCI_Bridge_Operating_Plan_Deferred] ON [Analytics].[tbl_Bridge_Operating_Plan_Deferred];
GO

PRINT '[OK] Created table: [Analytics].[tbl_Bridge_Operating_Plan_Deferred]';
GO

PRINT '';
PRINT '========================================';
PRINT 'tbl_Bridge_Operating_Plan_Deferred TABLE Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO

/**
-- Script Name: 01a_Create_tbl_Bridge_Patient_Segment_Agg.sql
-- Description: Aggregated bridge table for Patient Segments (Phase 1).
--              DEPRECATED: Use tbl_Bridge_CF_Segment_Patient_Snapshot instead.
--              Grain: One row per Segment per Month.
--              Purpose: High-performance Power BI reporting on segment trends.
-- Author:      Sridhar Peddi
-- Created:     2026-01-09

-- Change Log:
-- 2026-01-09   | Sridhar Peddi    | Initial creation - Aggregated Bridge
-- 2026-01-26   | Sridhar Peddi    | Deprecated in favor of patient snapshot table
**/

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating tbl_Bridge_Patient_Segment_Agg TABLE';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

IF OBJECT_ID('[Analytics].[tbl_Bridge_Patient_Segment_Agg]', 'U') IS NOT NULL
BEGIN
    PRINT 'Table [Analytics].[tbl_Bridge_Patient_Segment_Agg] already exists. Dropping...';
    DROP TABLE [Analytics].[tbl_Bridge_Patient_Segment_Agg];
END
GO

/**
-- Table Name:  tbl_Bridge_Patient_Segment_Agg
-- Description: Aggregated patient segments for trending.
--              Grain: Snapshot Month + Segment Type + Segment Value.
--              Size: ~600 rows (Tiny).
**/
CREATE TABLE [Analytics].[tbl_Bridge_Patient_Segment_Agg] (
    [SK_Patient_Segment_AggID] BIGINT IDENTITY(1,1) NOT NULL,
    [Snapshot_Month] INT NOT NULL,                     -- 202601, 202602
    [Segment_Type] VARCHAR(50) NOT NULL,               -- 'CF_Segment', 'Core20', 'LTC'
    [Segment_Value] VARCHAR(100) NOT NULL,             -- '7-Frailty', 'Diabetes'
    
    -- METRICS
    [Patient_Count] INT NOT NULL DEFAULT 0,
    [Avg_Age_Years] DECIMAL(5,2) NULL,
    [Pct_Core20] DECIMAL(5,2) NULL,
    [Total_Cost_12M] DECIMAL(15,2) NULL,
  
    -- AUDIT
    [ETL_LoadDateTime] DATETIME2 DEFAULT GETDATE(),

    CONSTRAINT [PK_Bridge_PatSeg_Agg] PRIMARY KEY CLUSTERED ([SK_Patient_Segment_AggID] ASC),
    CONSTRAINT [UQ_Bridge_PatSeg_Agg] UNIQUE ([Snapshot_Month], [Segment_Type], [Segment_Value])
) ON [PRIMARY];
GO

-- INDEXES
CREATE NONCLUSTERED INDEX [IX_Bridge_PatSeg_Agg_Month] 
  ON [Analytics].[tbl_Bridge_Patient_Segment_Agg]([Snapshot_Month]);

CREATE NONCLUSTERED INDEX [IX_Bridge_PatSeg_Agg_Type] 
  ON [Analytics].[tbl_Bridge_Patient_Segment_Agg]([Segment_Type], [Segment_Value])
  INCLUDE ([Patient_Count]);
GO

PRINT '[OK] Created table: [Analytics].[tbl_Bridge_Patient_Segment_Agg]';
GO

PRINT '';
PRINT '========================================';
PRINT 'tbl_Bridge_Patient_Segment_Agg TABLE Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO

/**
-- Script Name: 01b_Create_tbl_Bridge_CF_Segment_Patient.sql
-- Description: Detailed bridge table for CF patient segments (temporal).
--              DEPRECATED: Use tbl_Bridge_CF_Segment_Patient_Snapshot instead.
--              Grain: One row per Patient per Segment.
--              Purpose: Full granular analysis (requires Power BI Premium).
-- Author:      Sridhar Peddi
-- Created:     2026-01-09

-- Change Log:
-- 2026-01-09   | Sridhar Peddi    | Initial creation - Deferred Detail Bridge
-- 2026-01-26   | Sridhar Peddi    | Rename to tbl_Bridge_CF_Segment_Patient (clear intent)
-- 2026-01-26   | Sridhar Peddi    | Deprecated in favor of patient snapshot table
**/

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating tbl_Bridge_CF_Segment_Patient TABLE';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

IF OBJECT_ID('[Analytics].[tbl_Bridge_CF_Segment_Patient]', 'U') IS NOT NULL
BEGIN
    PRINT 'Table [Analytics].[tbl_Bridge_CF_Segment_Patient] already exists. Dropping...';
    DROP TABLE [Analytics].[tbl_Bridge_CF_Segment_Patient];
END
GO

/**
-- Table Name:  tbl_Bridge_CF_Segment_Patient
-- Description: Detailed CF segment bridge at patient grain (temporal).
--              Grain: Patient + Segment.
--              Size: ~6.4M rows.
**/
CREATE TABLE [Analytics].[tbl_Bridge_CF_Segment_Patient] (
    [SK_PatientSegmentID] BIGINT IDENTITY(1,1) NOT NULL,
    [SK_PatientID] BIGINT NOT NULL,
    [Segment_Type] VARCHAR(50) NOT NULL,               -- 'CF_Segment', 'Core20'
    [Segment_Value] VARCHAR(100) NOT NULL,             -- '7-Frailty'
    [Segment_Score] INT NULL,                          -- 1-8 for CF
    
    -- TEMPORAL TRACKING
    [Valid_From] DATE NOT NULL,
    [Valid_To] DATE NULL,
    [Is_Current] BIT DEFAULT 1,
    
    [Source_System] VARCHAR(50) NULL,
    [ETL_LoadDateTime] DATETIME2 DEFAULT GETDATE(),

    CONSTRAINT [PK_Bridge_CF_Segment_Patient] PRIMARY KEY NONCLUSTERED ([SK_PatientSegmentID] ASC)
) ON [PRIMARY];
GO

-- CLUSTERED COLUMNSTORE INDEX (Modern Standard - Critical for 6M+ rows)
CREATE CLUSTERED COLUMNSTORE INDEX [CCI_Bridge_CF_Segment_Patient] ON [Analytics].[tbl_Bridge_CF_Segment_Patient];
GO

-- FKs
ALTER TABLE [Analytics].[tbl_Bridge_CF_Segment_Patient] WITH CHECK ADD 
  CONSTRAINT [FK_Bridge_CF_Segment_Patient_Patient] FOREIGN KEY([SK_PatientID]) 
  REFERENCES [Analytics].[tbl_Dim_Patient] ([SK_PatientID]);
GO

PRINT '[OK] Created table: [Analytics].[tbl_Bridge_CF_Segment_Patient]';
GO

PRINT '';
PRINT '========================================';
PRINT 'tbl_Bridge_CF_Segment_Patient TABLE Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO

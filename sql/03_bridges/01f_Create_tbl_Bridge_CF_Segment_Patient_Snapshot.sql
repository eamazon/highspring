/**
-- Script Name: 01f_Create_tbl_Bridge_CF_Segment_Patient_Snapshot.sql
-- Description: Monthly patient-level CF segmentation snapshot for semantic model usage.
--              Grain: Snapshot_Month + SK_PatientID + Segment_Type.
-- Author:      Sridhar Peddi
-- Created:     2026-01-26
--
-- Change Log:
-- 2026-01-26  Sridhar Peddi    Initial creation
**/

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating tbl_Bridge_CF_Segment_Patient_Snapshot TABLE';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

IF OBJECT_ID('[Analytics].[tbl_Bridge_CF_Segment_Patient_Snapshot]', 'U') IS NOT NULL
BEGIN
    PRINT 'Table [Analytics].[tbl_Bridge_CF_Segment_Patient_Snapshot] already exists. Dropping...';
    DROP TABLE [Analytics].[tbl_Bridge_CF_Segment_Patient_Snapshot];
END
GO

/**
-- Table Name:  tbl_Bridge_CF_Segment_Patient_Snapshot
-- Description: Monthly patient-level CF segmentation snapshot.
--              Grain: Snapshot_Month + SK_PatientID + Segment_Type.
--              Purpose: Fast equality joins in Power BI (no range joins).
**/
CREATE TABLE [Analytics].[tbl_Bridge_CF_Segment_Patient_Snapshot] (
    [Snapshot_Month] INT NOT NULL,                -- YYYYMM
    [Snapshot_End_Date] DATE NOT NULL,
    [SK_PatientID] BIGINT NOT NULL,
    [Segment_Type] VARCHAR(50) NOT NULL,
    [Segment_Value] VARCHAR(100) NOT NULL,
    [Segment_Score] INT NOT NULL,
    [Source_System] VARCHAR(50) NULL,
    [ETL_LoadDateTime] DATETIME2 NOT NULL CONSTRAINT [DF_CF_Segment_Patient_Snapshot_LoadDtm] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_CF_Segment_Patient_Snapshot] PRIMARY KEY NONCLUSTERED (
        [Snapshot_Month],
        [SK_PatientID],
        [Segment_Type]
    )
) ON [PRIMARY];
GO

CREATE CLUSTERED COLUMNSTORE INDEX [CCI_CF_Segment_Patient_Snapshot]
    ON [Analytics].[tbl_Bridge_CF_Segment_Patient_Snapshot];
GO

CREATE NONCLUSTERED INDEX [IX_CF_Segment_Patient_Snapshot_Segment]
    ON [Analytics].[tbl_Bridge_CF_Segment_Patient_Snapshot] ([Segment_Score], [Snapshot_Month])
    INCLUDE ([Segment_Value], [SK_PatientID], [Segment_Type]);
GO

ALTER TABLE [Analytics].[tbl_Bridge_CF_Segment_Patient_Snapshot] WITH CHECK ADD
  CONSTRAINT [FK_CF_Segment_Patient_Snapshot_Patient] FOREIGN KEY([SK_PatientID])
  REFERENCES [Analytics].[tbl_Dim_Patient] ([SK_PatientID]);
GO

PRINT '[OK] Created table: [Analytics].[tbl_Bridge_CF_Segment_Patient_Snapshot]';
GO

PRINT '';
PRINT '========================================';
PRINT 'tbl_Bridge_CF_Segment_Patient_Snapshot TABLE Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO

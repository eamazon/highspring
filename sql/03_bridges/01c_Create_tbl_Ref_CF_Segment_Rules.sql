/**
-- Script Name: 01c_Create_tbl_Ref_CF_Segment_Rules.sql
-- Description: Reference tables to support CF segmentation derived from legacy rules.
--              This does NOT use HI.vw_CF_Segmentation.
-- Author:      Sridhar Peddi
-- Created:     2026-01-09
**/

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating CF segmentation reference tables';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

IF OBJECT_ID('[Analytics].[tbl_Ref_CF_Segment_Rule_ICD10]', 'U') IS NOT NULL
BEGIN
    DROP TABLE [Analytics].[tbl_Ref_CF_Segment_Rule_ICD10];
END
GO

IF OBJECT_ID('[Analytics].[tbl_Ref_CF_Segment]', 'U') IS NOT NULL
BEGIN
    DROP TABLE [Analytics].[tbl_Ref_CF_Segment];
END
GO

/**
-- Table Name:  tbl_Ref_CF_Segment
-- Description: Reference list of CF segment scores and display labels.
-- Notes:       Labels are placeholders until populated with the official CF segment names.
**/
CREATE TABLE [Analytics].[tbl_Ref_CF_Segment] (
    [Segment_Score] INT NOT NULL,
    [Segment_Value] VARCHAR(100) NOT NULL,
    [Is_Active] BIT NOT NULL CONSTRAINT [DF_CF_Segment_IsActive] DEFAULT (1),
    [ETL_LoadDateTime] DATETIME2 NOT NULL CONSTRAINT [DF_CF_Segment_LoadDtm] DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT [PK_Ref_CF_Segment] PRIMARY KEY CLUSTERED ([Segment_Score]),
    CONSTRAINT [UQ_Ref_CF_Segment_Value] UNIQUE ([Segment_Value])
) ON [PRIMARY];
GO

INSERT INTO [Analytics].[tbl_Ref_CF_Segment] ([Segment_Score], [Segment_Value])
VALUES
    (0, 'CF_Score_0'),
    (1, 'CF_Score_1'),
    (2, 'CF_Score_2'),
    (3, 'CF_Score_3'),
    (4, 'CF_Score_4'),
    (5, 'CF_Score_5'),
    (6, 'CF_Score_6'),
    (7, 'CF_Score_7'),
    (8, 'CF_Score_8');
GO

/**
-- Table Name:  tbl_Ref_CF_Segment_Rule_ICD10
-- Description: ICD10-based rules used to assign CF segment scores.
--              The loader procedures match diagnosis codes using LIKE patterns.
-- Notes:       Populate this table with the rule set from legacy_sql/clsp_cf (or your agreed subset).
**/
CREATE TABLE [Analytics].[tbl_Ref_CF_Segment_Rule_ICD10] (
    [Rule_ID] INT IDENTITY(1,1) NOT NULL,
    [Segment_Score] INT NOT NULL,
    [ICD10_Like] VARCHAR(20) NOT NULL,       -- e.g. 'C%'
    [Is_Primary_Only] BIT NOT NULL CONSTRAINT [DF_CF_Rule_PrimaryOnly] DEFAULT (0),
    [Lookback_Months] INT NULL,              -- optional override per rule
    [Rule_Notes] VARCHAR(255) NULL,
    [Is_Active] BIT NOT NULL CONSTRAINT [DF_CF_Rule_IsActive] DEFAULT (1),
    [ETL_LoadDateTime] DATETIME2 NOT NULL CONSTRAINT [DF_CF_Rule_LoadDtm] DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT [PK_Ref_CF_Segment_Rule_ICD10] PRIMARY KEY CLUSTERED ([Rule_ID]),
    CONSTRAINT [FK_Ref_CF_Rule_Segment] FOREIGN KEY ([Segment_Score]) REFERENCES [Analytics].[tbl_Ref_CF_Segment] ([Segment_Score])
) ON [PRIMARY];
GO

CREATE NONCLUSTERED INDEX [IX_Ref_CF_Rule_Score]
    ON [Analytics].[tbl_Ref_CF_Segment_Rule_ICD10] ([Segment_Score])
    INCLUDE ([ICD10_Like], [Is_Primary_Only], [Lookback_Months], [Is_Active]);
GO

CREATE NONCLUSTERED INDEX [IX_Ref_CF_Rule_Like]
    ON [Analytics].[tbl_Ref_CF_Segment_Rule_ICD10] ([ICD10_Like])
    INCLUDE ([Segment_Score], [Is_Primary_Only], [Lookback_Months], [Is_Active]);
GO

PRINT '[OK] Created: [Analytics].[tbl_Ref_CF_Segment]';
PRINT '[OK] Created: [Analytics].[tbl_Ref_CF_Segment_Rule_ICD10]';
GO

PRINT '';
PRINT '========================================';
PRINT 'CF segmentation reference tables created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO

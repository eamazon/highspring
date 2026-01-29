/**
-- Script Name: 31_Create_Dim_OpPlan_MeasureSet.sql
-- Description: Operating Plan measure-set dimension.
--              One row per distinct combination of MeasureIds.
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
PRINT 'Creating Dim_OpPlan_MeasureSet';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

IF OBJECT_ID('[Analytics].[tbl_Dim_OpPlan_MeasureSet]', 'U') IS NOT NULL
BEGIN
    PRINT 'Table [Analytics].[tbl_Dim_OpPlan_MeasureSet] already exists. Dropping...';
    DROP TABLE [Analytics].[tbl_Dim_OpPlan_MeasureSet];
END
GO

CREATE TABLE [Analytics].[tbl_Dim_OpPlan_MeasureSet] (
    [SK_OpPlan_MeasureSet] BIGINT IDENTITY(1,1) NOT NULL,
    [MeasureIds] VARCHAR(4000) NOT NULL,
    [MeasureCount] INT NOT NULL,
    [SetHash] VARBINARY(32) NOT NULL,
    [Is_Active] BIT NOT NULL DEFAULT 1,
    [Created_Date] DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT [PK_Dim_OpPlan_MeasureSet] PRIMARY KEY NONCLUSTERED ([SK_OpPlan_MeasureSet] ASC)
) ON [PRIMARY];
GO

CREATE CLUSTERED COLUMNSTORE INDEX [CCI_Dim_OpPlan_MeasureSet]
    ON [Analytics].[tbl_Dim_OpPlan_MeasureSet];
GO

SET IDENTITY_INSERT [Analytics].[tbl_Dim_OpPlan_MeasureSet] ON;

INSERT INTO [Analytics].[tbl_Dim_OpPlan_MeasureSet]
    ([SK_OpPlan_MeasureSet], [MeasureIds], [MeasureCount], [SetHash], [Is_Active])
VALUES
    (-1, 'UNKNOWN', 0, 0x0, 1);

SET IDENTITY_INSERT [Analytics].[tbl_Dim_OpPlan_MeasureSet] OFF;

CREATE UNIQUE INDEX [UQ_Dim_OpPlan_MeasureSet_Hash]
    ON [Analytics].[tbl_Dim_OpPlan_MeasureSet] ([SetHash], [MeasureIds]);
GO

PRINT '[OK] Created table: [Analytics].[tbl_Dim_OpPlan_MeasureSet]';
PRINT '[OK] Inserted default "Unknown" member (SK_OpPlan_MeasureSet = -1)';
GO

PRINT '========================================';
PRINT 'Dim_OpPlan_MeasureSet Creation Complete';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

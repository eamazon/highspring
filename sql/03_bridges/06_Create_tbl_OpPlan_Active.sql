USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating tbl_OpPlan_Active TABLE';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

/**
Script Name:   06_Create_tbl_OpPlan_Active.sql
Description:   Precomputed Operating Plan encounter measure sets for fast enrichment.
Author:        Sridhar Peddi
Created:       2026-01-15

Notes:
- Create-if-missing only. Do NOT drop.
- Stores one row per encounter + dataset with a resolved measure-set key.
**/
IF OBJECT_ID('[Analytics].[tbl_OpPlan_Active]', 'U') IS NULL
BEGIN
    CREATE TABLE [Analytics].[tbl_OpPlan_Active] (
        [SK_EncounterID] BIGINT NOT NULL,
        [Dataset] VARCHAR(20) NOT NULL, -- Inpatient / Outpatient / ED
        [Activity_Date] DATE NOT NULL,
        [MeasureIds] VARCHAR(4000) NOT NULL,
        [MeasureCount] INT NOT NULL,
        [SetHash] VARBINARY(32) NOT NULL,
        [SK_OpPlan_MeasureSet] BIGINT NOT NULL,
        [LogId] INT NULL,
        [ETL_LoadDateTime] DATETIME2 NOT NULL DEFAULT CURRENT_TIMESTAMP,
        [ETL_UpdateDateTime] DATETIME2 NULL,

        CONSTRAINT [PK_OpPlan_Active] PRIMARY KEY CLUSTERED ([SK_EncounterID] ASC, [Dataset] ASC)
    );
END
GO

IF OBJECT_ID('[Analytics].[tbl_OpPlan_Active]', 'U') IS NOT NULL
    AND NOT EXISTS (
        SELECT 1
        FROM sys.indexes
        WHERE name = 'IX_OpPlan_Active_ActivityDate'
          AND object_id = OBJECT_ID('[Analytics].[tbl_OpPlan_Active]')
    )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_OpPlan_Active_ActivityDate]
        ON [Analytics].[tbl_OpPlan_Active] ([Activity_Date], [Dataset])
        INCLUDE ([SK_OpPlan_MeasureSet], [LogId], [SK_EncounterID]);
END
GO

IF OBJECT_ID('[Analytics].[tbl_OpPlan_Active]', 'U') IS NOT NULL
    AND NOT EXISTS (
        SELECT 1
        FROM sys.indexes
        WHERE name = 'IX_OpPlan_Active_LogId'
          AND object_id = OBJECT_ID('[Analytics].[tbl_OpPlan_Active]')
    )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_OpPlan_Active_LogId]
        ON [Analytics].[tbl_OpPlan_Active] ([LogId])
        INCLUDE ([SK_EncounterID], [Dataset], [Activity_Date], [SK_OpPlan_MeasureSet]);
END
GO

IF OBJECT_ID('[Analytics].[tbl_OpPlan_Active]', 'U') IS NOT NULL
    AND EXISTS (
        SELECT 1
        FROM sys.columns
        WHERE object_id = OBJECT_ID('[Analytics].[tbl_OpPlan_Active]')
          AND name = 'LogId'
          AND is_nullable = 0
    )
BEGIN
    ALTER TABLE [Analytics].[tbl_OpPlan_Active]
        ALTER COLUMN [LogId] INT NULL;
END
GO

PRINT '[OK] Created table: [Analytics].[tbl_OpPlan_Active]';
PRINT '========================================';
GO

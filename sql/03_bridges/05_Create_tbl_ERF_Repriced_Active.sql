USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating tbl_ERF_Repriced_Active TABLE';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

/**
Script Name:   05_Create_tbl_ERF_Repriced_Active.sql
Description:   Precomputed ERF repriced outputs for fast fact enrichment.
Author:        Sridhar Peddi
Created:       2026-01-15

Notes:
- Create-if-missing only. Do NOT drop.
- Current FY only (windowed load).
**/
IF OBJECT_ID('[Analytics].[tbl_ERF_Repriced_Active]', 'U') IS NULL
BEGIN
    CREATE TABLE [Analytics].[tbl_ERF_Repriced_Active] (
        [SK_EncounterID] BIGINT NOT NULL,
        [POD] VARCHAR(2) NOT NULL, -- IP / OP
        [dv_FinYear] VARCHAR(9) NOT NULL,
        [ERF_National_Price] DECIMAL(12,2) NULL,
        [ERF_MFF_Applied] DECIMAL(12,6) NULL,
        [ERF_Total_Cost_Incl_MFF] DECIMAL(12,2) NULL,
        [ERF_Tariff_Used] VARCHAR(50) NULL,
        [ETL_LoadDateTime] DATETIME2 NOT NULL DEFAULT CURRENT_TIMESTAMP,
        [ETL_UpdateDateTime] DATETIME2 NULL,

        CONSTRAINT [PK_ERF_Repriced_Active] PRIMARY KEY CLUSTERED ([SK_EncounterID] ASC, [POD] ASC)
    );
END
GO

IF OBJECT_ID('[Analytics].[tbl_ERF_Repriced_Active]', 'U') IS NOT NULL
    AND COL_LENGTH('[Analytics].[tbl_ERF_Repriced_Active]', 'dv_FinYear') = 7
BEGIN
    IF EXISTS (
        SELECT 1
        FROM sys.indexes
        WHERE name = 'IX_ERF_Repriced_Active_FinYear'
          AND object_id = OBJECT_ID('[Analytics].[tbl_ERF_Repriced_Active]')
    )
        DROP INDEX [IX_ERF_Repriced_Active_FinYear]
        ON [Analytics].[tbl_ERF_Repriced_Active];

    ALTER TABLE [Analytics].[tbl_ERF_Repriced_Active]
        ALTER COLUMN [dv_FinYear] VARCHAR(9) NOT NULL;
END
GO

IF OBJECT_ID('[Analytics].[tbl_ERF_Repriced_Active]', 'U') IS NOT NULL
    AND NOT EXISTS (
        SELECT 1
        FROM sys.indexes
        WHERE name = 'IX_ERF_Repriced_Active_FinYear'
          AND object_id = OBJECT_ID('[Analytics].[tbl_ERF_Repriced_Active]')
    )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ERF_Repriced_Active_FinYear]
        ON [Analytics].[tbl_ERF_Repriced_Active] ([dv_FinYear])
        INCLUDE ([SK_EncounterID], [POD]);
END
GO

PRINT '[OK] Created table: [Analytics].[tbl_ERF_Repriced_Active]';
PRINT '========================================';
GO

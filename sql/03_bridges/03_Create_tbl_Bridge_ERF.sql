/**
-- Script Name: 03_Create_tbl_Bridge_ERF.sql
-- Description: Bridge table for Elective Recovery Fund (ERF) activity.
--              Grain: One row per ERF-eligible encounter.
--              Purpose: Tracking ERF financial performance vs plan.
-- Author:      Sridhar Peddi
-- Created:     2026-01-09

-- Change Log:
Change Log:
-- 2026-01-09   | Sridhar Peddi    | Initial creation - ERF Bridge
**/

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating tbl_Bridge_ERF_Activity TABLE';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

IF OBJECT_ID('[Analytics].[tbl_Bridge_ERF_Activity]', 'U') IS NOT NULL
BEGIN
    PRINT 'Table [Analytics].[tbl_Bridge_ERF_Activity] already exists. Dropping...';
    DROP TABLE [Analytics].[tbl_Bridge_ERF_Activity];
END
GO

/**
-- Table Name:  tbl_Bridge_ERF_Activity
-- Description: ERF activity mapping.
--              Grain: Encounter.
--              Size: ~2-3M rows.
**/
CREATE TABLE [Analytics].[tbl_Bridge_ERF_Activity] (
    [SK_ERF_ActivityID] BIGINT IDENTITY(1,1) NOT NULL,
    [SK_EncounterID] BIGINT NOT NULL,                  -- Link to Fact
    [POD] VARCHAR(2) NOT NULL,                         -- 'IP', 'OP'
    
    -- FINANCIALS
    [ERF_National_Price] DECIMAL(12,2) NULL,
    [ERF_MFF_Applied] DECIMAL(12,2) NULL,
    [ERF_Total_Cost_Incl_MFF] DECIMAL(12,2) NULL,
    
    -- METADATA
    [Tariff_Used] VARCHAR(50) NULL,
    [ERF_Financial_Year] VARCHAR(7) NULL,              -- '2024/25'
    [Is_ERF_Eligible] BIT DEFAULT 1,
    
    [ETL_LoadDateTime] DATETIME2 DEFAULT GETDATE(),

    CONSTRAINT [PK_Bridge_ERF] PRIMARY KEY NONCLUSTERED ([SK_ERF_ActivityID] ASC)
) ON [PRIMARY];
GO

-- CLUSTERED COLUMNSTORE INDEX (Modern Standard)
CREATE CLUSTERED COLUMNSTORE INDEX [CCI_Bridge_ERF_Activity] ON [Analytics].[tbl_Bridge_ERF_Activity];
GO

PRINT '[OK] Created table: [Analytics].[tbl_Bridge_ERF_Activity]';
GO

PRINT '';
PRINT '========================================';
PRINT 'tbl_Bridge_ERF_Activity TABLE Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO

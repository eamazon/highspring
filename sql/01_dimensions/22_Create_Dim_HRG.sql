

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating vw_Dim_HRG VIEW';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

-- Drop old naming conventions
IF OBJECT_ID('[Analytics].[Dim_HRG]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[Dim_HRG] already exists. Dropping...';
    DROP VIEW [Analytics].[Dim_HRG];
END
GO

IF OBJECT_ID('[Analytics].[tbl_Dim_HRG]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[tbl_Dim_HRG] already exists. Dropping...';
    DROP VIEW [Analytics].[tbl_Dim_HRG];
END
GO

IF OBJECT_ID('[Analytics].[vw_Dim_HRG]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[vw_Dim_HRG] already exists. Dropping...';
    DROP VIEW [Analytics].[vw_Dim_HRG];
END
GO

/**
Script Name:   22_Create_Dim_HRG.sql
Description:   Healthcare Resource Group (HRG) casemix classification for payment grouping.
               Maps procedures and diagnoses to tariff categories for costing and activity benchmarking.
               Includes chapter/subchapter hierarchy for service-line aggregation.
Author:        Sridhar Peddi
Created:       2026-01-09

Change Log:
  2026-01-09   Sridhar Peddi    Initial creation
**/
CREATE VIEW [Analytics].[vw_Dim_HRG] AS
SELECT
      CAST([SK_HRGID] AS INT) AS [SK_HRGID],
      [HRGCode],
      [HRGDescription],
      [HRGChapterKey],
      [HRGChapter],
      [HRGSubchapterKey],
      [HRGSubchapter],
      [HRG_Version],
      
      -- Short description for Power BI
      LEFT([HRGDescription], 50) AS [HRG_Short]
      
FROM [Dictionary].[dbo].[HRG];
GO

PRINT '[OK] Created view: [Analytics].[vw_Dim_HRG]';
PRINT '     Source: [Dictionary].[dbo].[HRG]';
GO

PRINT '';
PRINT 'Validation: Sample data from view';
SELECT TOP 5 * FROM [Analytics].[vw_Dim_HRG];
GO

PRINT '';
PRINT '========================================';
PRINT 'vw_Dim_HRG VIEW Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO

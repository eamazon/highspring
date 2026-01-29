

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating vw_Dim_Gender VIEW';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

-- Drop old naming conventions
IF OBJECT_ID('[Analytics].[Dim_Gender]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[Dim_Gender] already exists. Dropping...';
    DROP VIEW [Analytics].[Dim_Gender];
END
GO

IF OBJECT_ID('[Analytics].[tbl_Dim_Gender]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[tbl_Dim_Gender] already exists. Dropping...';
    DROP VIEW [Analytics].[tbl_Dim_Gender];
END
GO

IF OBJECT_ID('[Analytics].[vw_Dim_Gender]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[vw_Dim_Gender] already exists. Dropping...';
    DROP VIEW [Analytics].[vw_Dim_Gender];
END
GO

/**
Script Name:   18_Create_Dim_Gender.sql
Description:   Patient gender classification using NHS Data Dictionary codes (1=Male, 2=Female, 9=Not Known, X=Not Stated).
               Essential for demographic analysis, service planning, and equality monitoring.
               Supports health inequality reporting and population segmentation.
Author:        Sridhar Peddi
Created:       2026-01-09

Change Log:
  2026-01-09   Sridhar Peddi    Initial creation
**/
CREATE VIEW [Analytics].[vw_Dim_Gender] AS
SELECT
      CAST([SK_GenderID] AS INT) AS [SK_GenderID],
      [Gender],
      [GenderCode],
      [GenderCode1],
      [GenderCode2]
FROM [Dictionary].[dbo].[Gender];
GO

PRINT '[OK] Created view: [Analytics].[vw_Dim_Gender]';
PRINT '     Source: [Dictionary].[dbo].[Gender]';
GO

PRINT '';
PRINT 'Validation: Sample data from view';
SELECT TOP 5 * FROM [Analytics].[vw_Dim_Gender];
GO

PRINT '';
PRINT '========================================';
PRINT 'vw_Dim_Gender VIEW Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO

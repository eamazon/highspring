

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating vw_Dim_Measures_Catalogue VIEW';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

-- Drop old naming conventions
IF OBJECT_ID('[Analytics].[Dim_Measures_Catalogue]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[Dim_Measures_Catalogue] already exists. Dropping...';
    DROP VIEW [Analytics].[Dim_Measures_Catalogue];
END
GO

IF OBJECT_ID('[Analytics].[tbl_Dim_Measures_Catalogue]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[tbl_Dim_Measures_Catalogue] already exists. Dropping...';
    DROP VIEW [Analytics].[tbl_Dim_Measures_Catalogue];
END
GO

IF OBJECT_ID('[Analytics].[vw_Dim_Measures_Catalogue]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[vw_Dim_Measures_Catalogue] already exists. Dropping...';
    DROP VIEW [Analytics].[vw_Dim_Measures_Catalogue];
END
GO

/**
Script Name:   05_Create_Dim_Measures_Catalogue.sql
Description:   Measures catalogue defining available metrics and KPIs for the analytics platform.
               Reference table for measure metadata, definitions, and calculation logic.
               Supports dynamic measure selection and dashboard configuration.
Author:        Sridhar Peddi
Created:       2026-01-09

Change Log:
  2026-01-09   Sridhar Peddi    Initial creation
**/
CREATE VIEW [Analytics].[vw_Dim_Measures_Catalogue] AS
SELECT 
    'Placeholder' AS Measure_Name,
    'TBD' AS Measure_Type,
    'Not yet implemented' AS Description
WHERE 1 = 0;  -- Returns no rows (placeholder)
GO

PRINT '[OK] Created view: [Analytics].[vw_Dim_Measures_Catalogue]';
PRINT '     Note: Placeholder view - will be populated with actual measures in future';
GO

PRINT '';
PRINT '========================================';
PRINT 'vw_Dim_Measures_Catalogue VIEW Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO

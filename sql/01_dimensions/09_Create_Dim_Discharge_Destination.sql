

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating vw_Dim_Discharge_Destination VIEW';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

-- Drop old naming conventions
IF OBJECT_ID('[Analytics].[Dim_Discharge_Destination]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[Dim_Discharge_Destination] already exists. Dropping...';
    DROP VIEW [Analytics].[Dim_Discharge_Destination];
END
GO

IF OBJECT_ID('[Analytics].[tbl_Dim_Discharge_Destination]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[tbl_Dim_Discharge_Destination] already exists. Dropping...';
    DROP VIEW [Analytics].[tbl_Dim_Discharge_Destination];
END
GO

IF OBJECT_ID('[Analytics].[vw_Dim_Discharge_Destination]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[vw_Dim_Discharge_Destination] already exists. Dropping...';
    DROP VIEW [Analytics].[vw_Dim_Discharge_Destination];
END
GO

/**
Script Name:   09_Create_Dim_Discharge_Destination.sql
Description:   Inpatient discharge destination classification (Home/Care Home/Transfer/Hospice).
               Supports integrated care analysis, social care interface monitoring, and discharge pathways.
               Critical for Discharge to Assess and continuing healthcare (CHC) planning.
Author:        Sridhar Peddi
Created:       2026-01-09

Change Log:
  2026-01-09   Sridhar Peddi    Initial creation
**/
CREATE VIEW [Analytics].[vw_Dim_Discharge_Destination] AS
SELECT
    CAST([SK_DischargeDestinationID] AS INT) AS [SK_DischargeDestinationID],
    [BK_DischargeDestinationCode] AS [Discharge_Destination_Code],
    [DischargeDestinationName] AS [Discharge_Destination_Name],
    
    -- Short description for Power BI
    LEFT([DischargeDestinationName], 40) AS [Discharge_Destination_Short]
    
FROM [Dictionary].[IP].[DischargeDestination];
GO

PRINT '[OK] Created view: [Analytics].[vw_Dim_Discharge_Destination]';
PRINT '     Source: [Dictionary].[IP].[DischargeDestination]';
GO

PRINT '';
PRINT 'Validation: Sample data from view';
SELECT TOP 5 * FROM [Analytics].[vw_Dim_Discharge_Destination];
GO

PRINT '';
PRINT '========================================';
PRINT 'vw_Dim_Discharge_Destination VIEW Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO



USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating vw_Dim_Discharge_Method VIEW';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

-- Drop old naming conventions
IF OBJECT_ID('[Analytics].[Dim_Discharge_Method]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[Dim_Discharge_Method] already exists. Dropping...';
    DROP VIEW [Analytics].[Dim_Discharge_Method];
END
GO

IF OBJECT_ID('[Analytics].[tbl_Dim_Discharge_Method]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[tbl_Dim_Discharge_Method] already exists. Dropping...';
    DROP VIEW [Analytics].[tbl_Dim_Discharge_Method];
END
GO

IF OBJECT_ID('[Analytics].[vw_Dim_Discharge_Method]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[vw_Dim_Discharge_Method] already exists. Dropping...';
    DROP VIEW [Analytics].[vw_Dim_Discharge_Method];
END
GO

/**
Script Name:   08_Create_Dim_Discharge_Method.sql
Description:   Inpatient discharge method classification (Routine/Died/Self-discharge/Transfer).
               Tracks how patients left hospital for mortality reporting and discharge planning.
               Enables length-of-stay analysis segmented by discharge type.
Author:        Sridhar Peddi
Created:       2026-01-09

Change Log:
  2026-01-09   Sridhar Peddi    Initial creation
**/
CREATE VIEW [Analytics].[vw_Dim_Discharge_Method] AS
SELECT
    CAST([SK_DischargeMethodID] AS INT) AS [SK_DischargeMethodID],
    [BK_DischargeMethodCode] AS [Discharge_Method_Code],
    [DischargeMethodName] AS [Discharge_Method_Name],
    
    -- Short description for Power BI
    LEFT([DischargeMethodName], 35) AS [Discharge_Method_Short]
    
FROM [Dictionary].[IP].[DischargeMethod];
GO

PRINT '[OK] Created view: [Analytics].[vw_Dim_Discharge_Method]';
PRINT '     Source: [Dictionary].[IP].[DischargeMethod]';
GO

PRINT '';
PRINT 'Validation: Sample data from view';
SELECT TOP 5 * FROM [Analytics].[vw_Dim_Discharge_Method];
GO

PRINT '';
PRINT '========================================';
PRINT 'vw_Dim_Discharge_Method VIEW Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO

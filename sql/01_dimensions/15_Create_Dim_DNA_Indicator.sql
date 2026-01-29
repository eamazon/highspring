

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating vw_Dim_DNA_Indicator VIEW';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

-- Drop old naming conventions
IF OBJECT_ID('[Analytics].[Dim_DNA_Indicator]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[Dim_DNA_Indicator] already exists. Dropping...';
    DROP VIEW [Analytics].[Dim_DNA_Indicator];
END
GO

IF OBJECT_ID('[Analytics].[tbl_Dim_DNA_Indicator]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[tbl_Dim_DNA_Indicator] already exists. Dropping...';
    DROP VIEW [Analytics].[tbl_Dim_DNA_Indicator];
END
GO

IF OBJECT_ID('[Analytics].[vw_Dim_DNA_Indicator]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[vw_Dim_DNA_Indicator] already exists. Dropping...';
    DROP VIEW [Analytics].[vw_Dim_DNA_Indicator];
END
GO

/**
Script Name:   15_Create_Dim_DNA_Indicator.sql
Description:   Outpatient DNA indicator (attended / DNA / cancelled).
               Supports DNA rate reporting and appointment status analytics.
Author:        Sridhar Peddi
Created:       2026-01-26

Change Log:
  2026-01-26   Sridhar Peddi    Initial creation
**/
CREATE VIEW [Analytics].[vw_Dim_DNA_Indicator] AS
SELECT
    CAST([SK_DNAIndicatorID] AS INT) AS [SK_DNAIndicatorID],
    [BK_DNACode] AS [DNA_Indicator_Code],
    [DNAIndicatorDesc] AS [DNA_Indicator_Description],
    [DNAIndicatorStatus] AS [DNA_Indicator_Status]
FROM [Dictionary].[OP].[DNAIndicators];
GO

PRINT '[OK] Created view: [Analytics].[vw_Dim_DNA_Indicator]';
PRINT '     Source: [Dictionary].[OP].[DNAIndicators]';
GO

PRINT '';
PRINT 'Validation: Sample data from view';
SELECT TOP 5 * FROM [Analytics].[vw_Dim_DNA_Indicator];
GO

PRINT '';
PRINT '========================================';
PRINT 'vw_Dim_DNA_Indicator VIEW Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO

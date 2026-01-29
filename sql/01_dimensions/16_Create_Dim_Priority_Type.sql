

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating vw_Dim_Priority_Type VIEW';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

-- Drop old naming conventions
IF OBJECT_ID('[Analytics].[Dim_Priority_Type]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[Dim_Priority_Type] already exists. Dropping...';
    DROP VIEW [Analytics].[Dim_Priority_Type];
END
GO

IF OBJECT_ID('[Analytics].[tbl_Dim_Priority_Type]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[tbl_Dim_Priority_Type] already exists. Dropping...';
    DROP VIEW [Analytics].[tbl_Dim_Priority_Type];
END
GO

IF OBJECT_ID('[Analytics].[vw_Dim_Priority_Type]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[vw_Dim_Priority_Type] already exists. Dropping...';
    DROP VIEW [Analytics].[vw_Dim_Priority_Type];
END
GO

/**
Script Name:   16_Create_Dim_Priority_Type.sql
Description:   Outpatient referral priority classification (Urgent/Routine/Two-Week-Wait cancer pathway).
               Essential for RTT tracking, cancer pathway compliance, and clinical prioritization.
               Supports 62-day cancer target monitoring and urgent care access metrics.
Author:        Sridhar Peddi
Created:       2026-01-09

Change Log:
  2026-01-09   Sridhar Peddi    Initial creation
**/
CREATE VIEW [Analytics].[vw_Dim_Priority_Type] AS
SELECT
    CAST([SK_PriorityTypeID] AS INT) AS [SK_PriorityTypeID],
    [BK_PriorityTypeCode] AS [Priority_Type_Code],
    [PriorityTypeDesc] AS [Priority_Type_Description],
    
    -- Short description for Power BI
    LEFT([PriorityTypeDesc], 25) AS [Priority_Type_Short]
    
FROM [Dictionary].[OP].[PriorityType];
GO

PRINT '[OK] Created view: [Analytics].[vw_Dim_Priority_Type]';
PRINT '     Source: [Dictionary].[OP].[PriorityType]';
GO

PRINT '';
PRINT 'Validation: Sample data from view';
SELECT TOP 5 * FROM [Analytics].[vw_Dim_Priority_Type];
GO

PRINT '';
PRINT '========================================';
PRINT 'vw_Dim_Priority_Type VIEW Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO

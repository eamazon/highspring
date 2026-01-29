

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating vw_Dim_Provider VIEW';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

-------------------------------------------------------------------------------
-- Drop existing view if exists
-------------------------------------------------------------------------------
IF OBJECT_ID('[Analytics].[vw_Dim_Provider]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[vw_Dim_Provider] already exists. Dropping...';
    DROP VIEW [Analytics].[vw_Dim_Provider];
END
GO

/**
Script Name:   25_Create_Dim_Provider.sql
Description:   Healthcare provider/trust dimension sourced from NHS Organisation Data Service (ODS).
               Filtered to active Trusts and healthcare providers (RO codes: 172, 176, 197, 198).
               Supports provider-level performance analysis and inter-trust activity comparison.
Author:        Sridhar Peddi
Created:       2026-01-09

Change Log:
  2026-01-09   Sridhar Peddi    Initial creation
**/
CREATE VIEW [Analytics].[vw_Dim_Provider] AS
SELECT
    [SK_OrganisationID] AS [SK_ProviderID],
    [Organisation_Code] AS [Provider_Code],
    [Organisation_Name] AS [Provider_Name],
    [OrganisationPrimaryRole] AS [Provider_Type_Code],
    
    -- Friendly provider type
    CASE [OrganisationPrimaryRole]
        WHEN 'RO172' THEN 'NHS Trust'
        WHEN 'RO176' THEN 'NHS Foundation Trust'
        WHEN 'RO197' THEN 'Independent Provider'
        WHEN 'RO198' THEN 'NHS England Region'
        ELSE 'Other Provider'
    END AS [Provider_Type],
    
    [Country],
    [Address_Line_1],
    [Address_Line_2],
    [Address_Line_3],
    [Address_Line_4] AS [Town],
    [Address_Line_5] AS [County],
    
    [StartDate] AS [Provider_Start_Date],
    [EndDate] AS [Provider_End_Date],
    [Status] AS [Provider_Status],
    
    -- Active flag
    CASE 
        WHEN [Status] = 'Active' AND ([EndDate] IS NULL OR [EndDate] > GETDATE()) THEN 1
        ELSE 0
    END AS [Is_Active]
    
FROM [Dictionary].[dbo].[Organisation]
WHERE [OrganisationPrimaryRole] IN (
    'RO172',  -- NHS Trust
    'RO176',  -- NHS Foundation Trust
    'RO197',  -- Independent Provider
    'RO198'   -- NHS England Region
);
GO

PRINT '[OK] Created view: [Analytics].[vw_Dim_Provider]';
PRINT '     Source: [Dictionary].[dbo].[Organisation]';
GO

-- Validation: Sample data from view
PRINT '';
PRINT 'Validation: Sample providers';
SELECT TOP 10 
    Provider_Code,
    Provider_Name,
    Provider_Type,
    Is_Active
FROM [Analytics].[vw_Dim_Provider]
ORDER BY Provider_Name;
GO

PRINT '';
PRINT 'Provider counts by type:';
SELECT 
    Provider_Type,
    COUNT(*) AS Provider_Count,
    SUM(Is_Active) AS Active_Count
FROM [Analytics].[vw_Dim_Provider]
GROUP BY Provider_Type
ORDER BY Provider_Count DESC;
GO

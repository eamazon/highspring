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

IF OBJECT_ID('[Analytics].[vw_Dim_Provider]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[vw_Dim_Provider] already exists. Dropping...';
    DROP VIEW [Analytics].[vw_Dim_Provider];
END
GO

/**
Script Name:   20_Create_Dim_Provider.sql
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
    CAST([SK_OrganisationID] AS INT) AS [SK_ProviderID],
    [Organisation_Code] AS [Provider_Code],
    [Organisation_Name] AS [Provider_Name],
    [OrganisationPrimaryRole] AS [Primary_Role],
    [StartDate] AS [Valid_From],
    [EndDate] AS [Valid_To],
    [Status]
FROM [Dictionary].[dbo].[Organisation]
WHERE [OrganisationPrimaryRole] IN ('RO172','RO176','RO197','RO198'); -- Filter to healthcare providers
GO

PRINT '[OK] Created view: [Analytics].[vw_Dim_Provider]';
PRINT '     Source: [Dictionary].[dbo].[Organisation]';
GO

PRINT '';
PRINT 'Validation: Sample data from view';
SELECT TOP 5 * FROM [Analytics].[vw_Dim_Provider];
GO

PRINT '';
PRINT '========================================';
PRINT 'vw_Dim_Provider VIEW Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO

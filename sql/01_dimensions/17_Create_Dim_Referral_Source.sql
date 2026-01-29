

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating vw_Dim_Referral_Source VIEW';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

-- Drop old naming conventions
IF OBJECT_ID('[Analytics].[Dim_Referral_Source]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[Dim_Referral_Source] already exists. Dropping...';
    DROP VIEW [Analytics].[Dim_Referral_Source];
END
GO

IF OBJECT_ID('[Analytics].[tbl_Dim_Referral_Source]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[tbl_Dim_Referral_Source] already exists. Dropping...';
    DROP VIEW [Analytics].[tbl_Dim_Referral_Source];
END
GO

IF OBJECT_ID('[Analytics].[vw_Dim_Referral_Source]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[vw_Dim_Referral_Source] already exists. Dropping...';
    DROP VIEW [Analytics].[vw_Dim_Referral_Source];
END
GO

/**
Script Name:   17_Create_Dim_Referral_Source.sql
Description:   Outpatient referral source classification (GP/Consultant/Self-referral/A&E).
               Tracks referral pathway origins for demand management and pathway analysis.
               Supports Choose & Book integration and referral-to-treatment (RTT) tracking.
Author:        Sridhar Peddi
Created:       2026-01-09

Change Log:
  2026-01-09   Sridhar Peddi    Initial creation
**/
CREATE VIEW [Analytics].[vw_Dim_Referral_Source] AS
SELECT
    CAST([SK_SourceOfReferral] AS INT) AS [SK_ReferralSourceID],
    [BK_SourceOfReferralCode] AS [Referral_Source_Code],
    [ReferralType] AS [Referral_Source_Description],
    [ReferralGroup] AS [Referral_Source_Category],
    
    -- Short description for Power BI
    LEFT([ReferralType], 30) AS [Referral_Source_Short]
    
FROM [Dictionary].[OP].[SourceOfReferrals];
GO

PRINT '[OK] Created view: [Analytics].[vw_Dim_Referral_Source]';
PRINT '     Source: [Dictionary].[OP].[SourceOfReferrals]';
GO

PRINT '';
PRINT 'Validation: Sample data from view';
SELECT TOP 5 * FROM [Analytics].[vw_Dim_Referral_Source];
GO

PRINT '';
PRINT '========================================';
PRINT 'vw_Dim_Referral_Source VIEW Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO

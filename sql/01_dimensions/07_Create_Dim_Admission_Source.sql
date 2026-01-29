

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating vw_Dim_Admission_Source VIEW';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

-- Drop old naming conventions
IF OBJECT_ID('[Analytics].[Dim_Admission_Source]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[Dim_Admission_Source] already exists. Dropping...';
    DROP VIEW [Analytics].[Dim_Admission_Source];
END
GO

IF OBJECT_ID('[Analytics].[tbl_Dim_Admission_Source]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[tbl_Dim_Admission_Source] already exists. Dropping...';
    DROP VIEW [Analytics].[tbl_Dim_Admission_Source];
END
GO

IF OBJECT_ID('[Analytics].[vw_Dim_Admission_Source]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[vw_Dim_Admission_Source] already exists. Dropping...';
    DROP VIEW [Analytics].[vw_Dim_Admission_Source];
END
GO

/**
Script Name:   07_Create_Dim_Admission_Source.sql
Description:   Inpatient admission source classification (Home/Transfer/A&E/GP referral).
               Tracks patient origin for demand modeling and integrated care pathway analysis.
               Supports waiting list validation and elective pathway integrity checks.
Author:        Sridhar Peddi
Created:       2026-01-09

Change Log:
  2026-01-09   Sridhar Peddi    Initial creation
**/
CREATE VIEW [Analytics].[vw_Dim_Admission_Source] AS
SELECT
    CAST([SK_SourceOfAdmissionID] AS INT) AS [SK_AdmissionSourceID],
    [BK_SourceOfAdmissionCode] AS [Admission_Source_Code],
    [SourceOfAdmissionName] AS [Admission_Source_Name],
    [SourceOfAdmissionFullName] AS [Admission_Source_Full_Name],
    
    -- Short description for Power BI
    LEFT([SourceOfAdmissionName], 35) AS [Admission_Source_Short]
    
FROM [Dictionary].[IP].[SourceOfAdmissions];
GO

PRINT '[OK] Created view: [Analytics].[vw_Dim_Admission_Source]';
PRINT '     Source: [Dictionary].[IP].[SourceOfAdmissions]';
GO

PRINT '';
PRINT 'Validation: Sample data from view';
SELECT TOP 5 * FROM [Analytics].[vw_Dim_Admission_Source];
GO

PRINT '';
PRINT '========================================';
PRINT 'vw_Dim_Admission_Source VIEW Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO

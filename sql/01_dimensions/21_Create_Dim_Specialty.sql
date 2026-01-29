

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating vw_Dim_Specialty VIEW';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

-- Drop old naming conventions
IF OBJECT_ID('[Analytics].[Dim_Specialty]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[Dim_Specialty] already exists. Dropping...';
    DROP VIEW [Analytics].[Dim_Specialty];
END
GO

IF OBJECT_ID('[Analytics].[tbl_Dim_Specialty]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[tbl_Dim_Specialty] already exists. Dropping...';
    DROP VIEW [Analytics].[tbl_Dim_Specialty];
END
GO

IF OBJECT_ID('[Analytics].[vw_Dim_Specialty]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[vw_Dim_Specialty] already exists. Dropping...';
    DROP VIEW [Analytics].[vw_Dim_Specialty];
END
GO

/**
Script Name:   21_Create_Dim_Specialty.sql
Description:   Medical specialty classification using NHS Treatment Function Codes (TFCs).
               Supports service-line analysis, referral pattern tracking, and clinical directorate reporting.
               Maps to high-level specialties (Medicine, Surgery, Paediatrics, etc) for aggregation.
Author:        Sridhar Peddi
Created:       2026-01-09

Change Log:
  2026-01-09   Sridhar Peddi    Initial creation
**/
CREATE VIEW [Analytics].[vw_Dim_Specialty] AS
SELECT
      CAST(src.[SK_SpecialtyID] AS INT) AS [SK_SpecialtyID],
      src.[BK_SpecialtyCode],
      src.[SpecialtyName],
      src.[SpecialtyCategory],
      src.[IsTreatmentFunction],
      src.[IsMainSpecialty],
      src.[MainSpecialtyDescription],
      src.[TreatmentFunctionDescription],
      
      -- Short description for Power BI (prefer TFC short name where available)
      COALESCE(ref.[TFCNameShort], LEFT(src.[SpecialtyName], 35)) AS [Specialty_Short]
      
FROM [Dictionary].[dbo].[Specialties] AS src
LEFT JOIN [Data_Lab_SWL].[ref].[tbl_Treatment_Functions] AS ref
    ON src.[BK_SpecialtyCode] = ref.[TreatmentFunctionCode];
GO

PRINT '[OK] Created view: [Analytics].[vw_Dim_Specialty]';
PRINT '     Source: [Dictionary].[dbo].[Specialties]';
GO

PRINT '';
PRINT 'Validation: Sample data from view';
SELECT TOP 5 * FROM [Analytics].[vw_Dim_Specialty];
GO

PRINT '';
PRINT '========================================';
PRINT 'vw_Dim_Specialty VIEW Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO

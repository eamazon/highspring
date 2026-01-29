

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating vw_Dim_Admission_Method VIEW';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

-- Drop old naming conventions
IF OBJECT_ID('[Analytics].[Dim_Admission_Method]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[Dim_Admission_Method] already exists. Dropping...';
    DROP VIEW [Analytics].[Dim_Admission_Method];
END
GO

IF OBJECT_ID('[Analytics].[tbl_Dim_Admission_Method]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[tbl_Dim_Admission_Method] already exists. Dropping...';
    DROP VIEW [Analytics].[tbl_Dim_Admission_Method];
END
GO

IF OBJECT_ID('[Analytics].[vw_Dim_Admission_Method]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[vw_Dim_Admission_Method] already exists. Dropping...';
    DROP VIEW [Analytics].[vw_Dim_Admission_Method];
END
GO

/**
Script Name:   06_Create_Dim_Admission_Method.sql
Description:   Inpatient admission method classification (Elective/Emergency/Maternity/Transfer).
               Distinguishes between planned and unplanned admissions for capacity planning.
               Critical for emergency vs elective split reporting and bed management.
Author:        Sridhar Peddi
Created:       2026-01-09

Change Log:
  2026-01-09   Sridhar Peddi    Initial creation
**/
CREATE VIEW [Analytics].[vw_Dim_Admission_Method] AS
SELECT
    CAST([SK_AdmissionMethodID] AS INT) AS [SK_AdmissionMethodID],
    [BK_AdmissionMethodCode] AS [Admission_Method_Code],
    [AdmissionMethodName] AS [Admission_Method_Name],
    [AdmissionMethodGroup] AS [Admission_Method_Group],
    
    -- Short description for Power BI
    LEFT([AdmissionMethodName], 35) AS [Admission_Method_Short]
    
FROM [Dictionary].[IP].[AdmissionMethods];
GO

PRINT '[OK] Created view: [Analytics].[vw_Dim_Admission_Method]';
PRINT '     Source: [Dictionary].[IP].[AdmissionMethods]';
GO

PRINT '';
PRINT 'Validation: Sample data from view';
SELECT TOP 5 * FROM [Analytics].[vw_Dim_Admission_Method];
GO

PRINT '';
PRINT '========================================';
PRINT 'vw_Dim_Admission_Method VIEW Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO

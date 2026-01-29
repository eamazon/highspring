

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating vw_Dim_Attendance_Disposal VIEW';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

-- Drop old naming conventions
IF OBJECT_ID('[Analytics].[Dim_Attendance_Disposal]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[Dim_Attendance_Disposal] already exists. Dropping...';
    DROP VIEW [Analytics].[Dim_Attendance_Disposal];
END
GO

IF OBJECT_ID('[Analytics].[tbl_Dim_Attendance_Disposal]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[tbl_Dim_Attendance_Disposal] already exists. Dropping...';
    DROP VIEW [Analytics].[tbl_Dim_Attendance_Disposal];
END
GO

IF OBJECT_ID('[Analytics].[vw_Dim_Attendance_Disposal]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[vw_Dim_Attendance_Disposal] already exists. Dropping...';
    DROP VIEW [Analytics].[vw_Dim_Attendance_Disposal];
END
GO

/**
Script Name:   18_Create_Dim_Attendance_Disposal.sql
Description:   A&E attendance disposal/outcome classification defining patient journey after attendance.
               Categories include admitted, discharged, referred, left before treatment.
               Key metric for A&E performance, conversion rates, and patient flow analysis.
Author:        Sridhar Peddi
Created:       2026-01-09

Change Log:
  2026-01-09   Sridhar Peddi    Initial creation
**/
CREATE VIEW [Analytics].[vw_Dim_Attendance_Disposal] AS
SELECT
    CAST([SK_AttendanceDisposalID] AS INT) AS [SK_AttendanceDisposalID],
    [BK_AttendanceDisposal] AS [Attendance_Disposal_Code],
    [AttendanceDisposal] AS [Attendance_Disposal_Description],
    
    -- Short description for Power BI (max 40 chars)
    CASE
        WHEN [AttendanceDisposal] LIKE '%Admitted%hospital%' THEN 'Admitted'
        WHEN [AttendanceDisposal] LIKE '%Discharged%' THEN 'Discharged'
        WHEN [AttendanceDisposal] LIKE '%follow-up%' THEN 'Follow-up required'
        WHEN [AttendanceDisposal] LIKE '%Did not%' THEN 'Did not wait'
        WHEN [AttendanceDisposal] LIKE '%Left%' THEN 'Left department'
        WHEN [AttendanceDisposal] LIKE '%Referred%' THEN 'Referred'
        WHEN [AttendanceDisposal] LIKE '%Died%' THEN 'Died'
        ELSE LEFT([AttendanceDisposal], 40)
    END AS [Attendance_Disposal_Short]
    
FROM [Dictionary].[AE].[AttendanceDisposals];
GO

PRINT '[OK] Created view: [Analytics].[vw_Dim_Attendance_Disposal]';
PRINT '     Source: [Dictionary].[AE].[AttendanceDisposals]';
GO

PRINT '';
PRINT 'Validation: Sample data from view';
SELECT TOP 5 * FROM [Analytics].[vw_Dim_Attendance_Disposal];
GO

PRINT '';
PRINT '========================================';
PRINT 'vw_Dim_Attendance_Disposal VIEW Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO

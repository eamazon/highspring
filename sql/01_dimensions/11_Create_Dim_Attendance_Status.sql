

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating vw_Dim_Attendance_Status VIEW';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

-- Drop old naming conventions
IF OBJECT_ID('[Analytics].[Dim_Attendance_Status]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[Dim_Attendance_Status] already exists. Dropping...';
    DROP VIEW [Analytics].[Dim_Attendance_Status];
END
GO

IF OBJECT_ID('[Analytics].[tbl_Dim_Attendance_Status]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[tbl_Dim_Attendance_Status] already exists. Dropping...';
    DROP VIEW [Analytics].[tbl_Dim_Attendance_Status];
END
GO

IF OBJECT_ID('[Analytics].[vw_Dim_Attendance_Status]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[vw_Dim_Attendance_Status] already exists. Dropping...';
    DROP VIEW [Analytics].[vw_Dim_Attendance_Status];
END
GO

/**
Script Name:   11_Create_Dim_Attendance_Status.sql
Description:   Outpatient attendance status (attended, DNA, cancelled, etc.).
               Uses Dictionary.OP.DNAIndicators as the source (AttendanceStatus table not available).
Author:        Sridhar Peddi
Created:       2026-01-26

Change Log:
  2026-01-26   Sridhar Peddi    Initial creation
**/
CREATE VIEW [Analytics].[vw_Dim_Attendance_Status] AS
SELECT
    CAST([SK_DNAIndicatorID] AS INT) AS [SK_AttendanceStatusID],
    [BK_DNACode] AS [Attendance_Status_Code],
    [DNAIndicatorDesc] AS [Attendance_Status_Description],

    -- Short description for Power BI
    LEFT([DNAIndicatorDesc], 40) AS [Attendance_Status_Short]
FROM [Dictionary].[OP].[DNAIndicators];
GO

PRINT '[OK] Created view: [Analytics].[vw_Dim_Attendance_Status]';
PRINT '     Source: [Dictionary].[OP].[DNAIndicators]';
GO

PRINT '';
PRINT 'Validation: Sample data from view';
SELECT TOP 5 * FROM [Analytics].[vw_Dim_Attendance_Status];
GO

PRINT '';
PRINT '========================================';
PRINT 'vw_Dim_Attendance_Status VIEW Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO

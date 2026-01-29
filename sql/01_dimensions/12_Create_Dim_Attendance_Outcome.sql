USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating vw_Dim_Attendance_Outcome VIEW';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

IF OBJECT_ID('[Analytics].[vw_Dim_Attendance_Outcome]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[vw_Dim_Attendance_Outcome] already exists. Dropping...';
    DROP VIEW [Analytics].[vw_Dim_Attendance_Outcome];
END
GO

/**
Script Name:   12_Create_Dim_Attendance_Outcome.sql
Description:   Outpatient attendance outcome classification tracking appointment completion status.
               Distinguishes between seen, DNA, cancelled, and rebooked appointments.
               Critical for access metrics, DNA analysis, and capacity utilization reporting.
Author:        Sridhar Peddi
Created:       2026-01-08

Change Log:
  2026-01-08   Sridhar Peddi    Initial creation
**/
CREATE VIEW [Analytics].[vw_Dim_Attendance_Outcome] AS
SELECT
    CAST([SK_AttendanceOutcome] AS INT) AS [SK_AttendanceOutcomeID],
    [BK_AttendanceOutcome] AS [Attendance_Outcome_Code],
    [AttendanceOutcome] AS [Attendance_Outcome_Description],
    
    -- Short description for Power BI
    LEFT([AttendanceOutcome], 35) AS [Attendance_Outcome_Short]
    
FROM [Dictionary].[OP].[AttendanceOutcomes];
GO

PRINT '[OK] Created view: [Analytics].[vw_Dim_Attendance_Outcome]';
PRINT '     Source: [Dictionary].[OP].[AttendanceOutcomes]';
GO

PRINT '';
PRINT 'Validation: Sample data from view';
SELECT TOP 5 * FROM [Analytics].[vw_Dim_Attendance_Outcome];
GO

PRINT '';
PRINT '========================================';
PRINT 'vw_Dim_Attendance_Outcome VIEW Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO



USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating vw_Dim_Attendance_Type VIEW';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

-- Drop old naming conventions
IF OBJECT_ID('[Analytics].[Dim_Attendance_Type]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[Dim_Attendance_Type] already exists. Dropping...';
    DROP VIEW [Analytics].[Dim_Attendance_Type];
END
GO

IF OBJECT_ID('[Analytics].[tbl_Dim_Attendance_Type]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[tbl_Dim_Attendance_Type] already exists. Dropping...';
    DROP VIEW [Analytics].[tbl_Dim_Attendance_Type];
END
GO

IF OBJECT_ID('[Analytics].[vw_Dim_Attendance_Type]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[vw_Dim_Attendance_Type] already exists. Dropping...';
    DROP VIEW [Analytics].[vw_Dim_Attendance_Type];
END
GO

/**
Script Name:   14_Create_Dim_Attendance_Type.sql
Description:   Outpatient attendance type classification tracking first vs follow-up appointments.
               Essential for new:follow-up ratio monitoring and capacity planning.
               Supports outpatient dashboard metrics and activity type segmentation.
Author:        Sridhar Peddi
Created:       2026-01-09

Change Log:
  2026-01-09   Sridhar Peddi    Initial creation
**/
CREATE VIEW [Analytics].[vw_Dim_Attendance_Type] AS
SELECT
    CAST([SK_AttendanceType] AS INT) AS [SK_AttendanceTypeID],
    [BK_AttendanceTypeCode] AS [Attendance_Type_Code],
    [AttendantType] AS [Attendance_Type],
    [AttendantTypeDesc] AS [Attendance_Type_Description],
    
    -- Short description for Power BI
    LEFT([AttendantTypeDesc], 40) AS [Attendance_Type_Short]
    
FROM [Dictionary].[OP].[AttendanceTypes];
GO

PRINT '[OK] Created view: [Analytics].[vw_Dim_Attendance_Type]';
PRINT '     Source: [Dictionary].[OP].[AttendanceTypes]';
GO

PRINT '';
PRINT 'Validation: Sample data from view';
SELECT TOP 5 * FROM [Analytics].[vw_Dim_Attendance_Type];
GO

PRINT '';
PRINT '========================================';
PRINT 'vw_Dim_Attendance_Type VIEW Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO

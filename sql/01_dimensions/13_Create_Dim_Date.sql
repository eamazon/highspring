

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating vw_Dim_Date VIEW';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

-- Drop old naming conventions
IF OBJECT_ID('[Analytics].[Dim_Date]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[Dim_Date] already exists. Dropping...';
    DROP VIEW [Analytics].[Dim_Date];
END
GO

IF OBJECT_ID('[Analytics].[tbl_Dim_Date]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[tbl_Dim_Date] already exists. Dropping...';
    DROP VIEW [Analytics].[tbl_Dim_Date];
END
GO

IF OBJECT_ID('[Analytics].[vw_Dim_Date]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[vw_Dim_Date] already exists. Dropping...';
    DROP VIEW [Analytics].[vw_Dim_Date];
END
GO

/**
Script Name:   13_Create_Dim_Date.sql
Description:   Calendar date dimension with NHS financial year alignment (Apr-Mar).
               Includes week/month/quarter hierarchies, bank holidays, and reporting period flags.
               Essential for time-series analysis and year-on-year comparisons.
Author:        Sridhar Peddi
Created:       2026-01-09

Change Log:
  2026-01-09   Sridhar Peddi    Initial creation
**/
CREATE VIEW [Analytics].[vw_Dim_Date] AS
SELECT
    -- Core date attributes from Dictionary
    d.[SK_Date],
    d.[FullDate],
    d.[Day],
    d.[DayOfWeek],
    d.[DayOfWeekNumber],
    d.[DayOfYearNumber],
    d.[WeekOfYearNumber],
    d.[WeekOfMonthNumber],
    d.[CalendarMonthNumber],
    d.[CalendarMonthName],
    d.[CalendarQuarterNumber],
    d.[CalendarYearNumber],
    d.[FiscalCalendarMonthNumber],
    d.[FiscalCalendarQuarterNumber],
    d.[FiscalCalendarYearNumber],
    d.[FiscalCalendarYearName],
    d.[IsWeekend],
    
    -- NEW: Short name columns for Power BI
    LEFT(d.[CalendarMonthName], 3) AS CalendarMonthNameShort, -- Jan, Feb, Mar, etc.
    
    -- FiscalCalendarYearNameShort: '20/21', '24/25', etc.
    RIGHT('0' + CAST(d.[FiscalCalendarYearNumber] % 100 AS VARCHAR), 2) + '/' +
    RIGHT('0' + CAST((d.[FiscalCalendarYearNumber] + 1) % 100 AS VARCHAR), 2) AS FiscalCalendarYearNameShort,
    
    -- NEW: UK Calendar Event Flags
    ISNULL(e.[IsBankHoliday], 0) AS IsBankHoliday,
    e.[BankHoliday_Name],
    e.[BankHoliday_Region],
    
    ISNULL(e.[IsSchoolHoliday], 0) AS IsSchoolHoliday,
    ISNULL(e.[IsSchoolHalfTerm], 0) AS IsSchoolHalfTerm,
    e.[SchoolHoliday_Name],
    
    ISNULL(e.[IsNHSStrikeDay], 0) AS IsNHSStrikeDay,
    e.[NHS_Strike_Type],
    
    ISNULL(e.[IsTrainStrikeDay], 0) AS IsTrainStrikeDay,
    e.[Train_Strike_Operators],
    
    ISNULL(e.[IsChristmasPeriod], 0) AS IsChristmasPeriod,
    ISNULL(e.[IsEasterPeriod], 0) AS IsEasterPeriod,
    
    e.[Event_Notes]

FROM [Dictionary].[dbo].[Dates] d
LEFT JOIN [Analytics].[tbl_Dim_Date_Events] e 
    ON d.[FullDate] = e.[Event_Date];
GO

PRINT '[OK] Created view: [Analytics].[vw_Dim_Date]';
PRINT '     Source: [Dictionary].[dbo].[Dates]';
GO

PRINT '';
PRINT 'Validation: Sample data from view';
SELECT TOP 5 * FROM [Analytics].[vw_Dim_Date] ORDER BY SK_Date;
GO

PRINT '';
PRINT '========================================';
PRINT 'vw_Dim_Date VIEW Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO

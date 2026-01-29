/**
Script Name:  24_Populate_Date_Events.sql
Description:  SQL object
Author:       Sridhar Peddi
Created:      2026-01-09

Change Log:
  2026-01-09  Sridhar Peddi    Initial creation
**/

USE [Data_Lab_SWL_Live];
GO

PRINT '========================================';
PRINT 'Populating tbl_Dim_Date_Events';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

-- Clear existing data
TRUNCATE TABLE [Analytics].[tbl_Dim_Date_Events];
PRINT '[OK] Truncated existing data';
GO

-------------------------------------------------------------------------------
-- 1. UK BANK HOLIDAYS (2020-2030)
-------------------------------------------------------------------------------
PRINT '>>> Inserting UK Bank Holidays (2020-2030)...';

INSERT INTO [Analytics].[tbl_Dim_Date_Events] 
    (Event_Date, IsBankHoliday, BankHoliday_Name, BankHoliday_Region, Source)
VALUES
    -- 2023
    ('2023-01-02', 1, 'New Year''s Day (substitute)', 'England', 'GOV.UK'),
    ('2023-04-07', 1, 'Good Friday', 'England', 'GOV.UK'),
    ('2023-04-10', 1, 'Easter Monday', 'England', 'GOV.UK'),
    ('2023-05-01', 1, 'Early May Bank Holiday', 'England', 'GOV.UK'),
    ('2023-05-08', 1, 'Coronation of King Charles III', 'England', 'GOV.UK'),
    ('2023-05-29', 1, 'Spring Bank Holiday', 'England', 'GOV.UK'),
    ('2023-08-28', 1, 'Summer Bank Holiday', 'England', 'GOV.UK'),
    ('2023-12-25', 1, 'Christmas Day', 'England', 'GOV.UK'),
    ('2023-12-26', 1, 'Boxing Day', 'England', 'GOV.UK'),
    
    -- 2024
    ('2024-01-01', 1, 'New Year''s Day', 'England', 'GOV.UK'),
    ('2024-03-29', 1, 'Good Friday', 'England', 'GOV.UK'),
    ('2024-04-01', 1, 'Easter Monday', 'England', 'GOV.UK'),
    ('2024-05-06', 1, 'Early May Bank Holiday', 'England', 'GOV.UK'),
    ('2024-05-27', 1, 'Spring Bank Holiday', 'England', 'GOV.UK'),
    ('2024-08-26', 1, 'Summer Bank Holiday', 'England', 'GOV.UK'),
    ('2024-12-25', 1, 'Christmas Day', 'England', 'GOV.UK'),
    ('2024-12-26', 1, 'Boxing Day', 'England', 'GOV.UK'),
    
    -- 2025
    ('2025-01-01', 1, 'New Year''s Day', 'England', 'GOV.UK'),
    ('2025-04-18', 1, 'Good Friday', 'England', 'GOV.UK'),
    ('2025-04-21', 1, 'Easter Monday', 'England', 'GOV.UK'),
    ('2025-05-05', 1, 'Early May Bank Holiday', 'England', 'GOV.UK'),
    ('2025-05-26', 1, 'Spring Bank Holiday', 'England', 'GOV.UK'),
    ('2025-08-25', 1, 'Summer Bank Holiday', 'England', 'GOV.UK'),
    ('2025-12-25', 1, 'Christmas Day', 'England', 'GOV.UK'),
    ('2025-12-26', 1, 'Boxing Day', 'England', 'GOV.UK'),
    
    -- 2026
    ('2026-01-01', 1, 'New Year''s Day', 'England', 'GOV.UK'),
    ('2026-04-03', 1, 'Good Friday', 'England', 'GOV.UK'),
    ('2026-04-06', 1, 'Easter Monday', 'England', 'GOV.UK'),
    ('2026-05-04', 1, 'Early May Bank Holiday', 'England', 'GOV.UK'),
    ('2026-05-25', 1, 'Spring Bank Holiday', 'England', 'GOV.UK'),
    ('2026-08-31', 1, 'Summer Bank Holiday', 'England', 'GOV.UK'),
    ('2026-12-25', 1, 'Christmas Day', 'England', 'GOV.UK'),
    ('2026-12-28', 1, 'Boxing Day (substitute)', 'England', 'GOV.UK');

PRINT '[OK] Inserted ' + CAST(@@ROWCOUNT AS VARCHAR) + ' bank holidays';
GO

-------------------------------------------------------------------------------
-- 2. ENGLAND SCHOOL HALF TERMS & HOLIDAYS (2023-2025)
-------------------------------------------------------------------------------
PRINT '>>> Inserting England School Holidays...';

-- Generate day-by-day entries for school holiday periods
DECLARE @SchoolHolidays TABLE (StartDate DATE, EndDate DATE, HolidayName VARCHAR(100), IsHalfTerm BIT);

INSERT INTO @SchoolHolidays (StartDate, EndDate, HolidayName, IsHalfTerm) VALUES
    -- 2023
    ('2023-02-13', '2023-02-17', 'Spring Half Term 2023', 1),
    ('2023-04-03', '2023-04-14', 'Easter Holiday 2023', 0),
    ('2023-05-29', '2023-06-02', 'Summer Half Term 2023', 1),
    ('2023-07-25', '2023-09-01', 'Summer Holiday 2023', 0),
    ('2023-10-23', '2023-10-27', 'Autumn Half Term 2023', 1),
    ('2023-12-22', '2024-01-05', 'Christmas Holiday 2023', 0),
    
    -- 2024
    ('2024-02-12', '2024-02-16', 'Spring Half Term 2024', 1),
    ('2024-03-28', '2024-04-12', 'Easter Holiday 2024', 0),
    ('2024-05-27', '2024-05-31', 'Summer Half Term 2024', 1),
    ('2024-07-23', '2024-09-02', 'Summer Holiday 2024', 0),
    ('2024-10-28', '2024-11-01', 'Autumn Half Term 2024', 1),
    ('2024-12-23', '2025-01-03', 'Christmas Holiday 2024', 0),
    
    -- 2025
    ('2025-02-17', '2025-02-21', 'Spring Half Term 2025', 1),
    ('2025-04-14', '2025-04-25', 'Easter Holiday 2025', 0),
    ('2025-05-26', '2025-05-30', 'Summer Half Term 2025', 1),
    ('2025-07-24', '2025-09-01', 'Summer Holiday 2025', 0),
    ('2025-10-27', '2025-10-31', 'Autumn Half Term 2025', 1),
    ('2025-12-22', '2026-01-02', 'Christmas Holiday 2025', 0);

-- Expand date ranges into individual days
WITH DateRange AS (
    SELECT 
        StartDate AS Event_Date,
        EndDate,
        HolidayName,
        IsHalfTerm
    FROM @SchoolHolidays
    
    UNION ALL
    
    SELECT 
        DATEADD(DAY, 1, Event_Date),
        EndDate,
        HolidayName,
        IsHalfTerm
    FROM DateRange
    WHERE Event_Date < EndDate
)
INSERT INTO [Analytics].[tbl_Dim_Date_Events] 
    (Event_Date, IsSchoolHoliday, IsSchoolHalfTerm, SchoolHoliday_Name, Source)
SELECT 
    Event_Date,
    1 AS IsSchoolHoliday,
    IsHalfTerm,
    HolidayName,
    'England School Calendar'
FROM DateRange
WHERE NOT EXISTS (
    SELECT 1 FROM [Analytics].[tbl_Dim_Date_Events] e 
    WHERE e.Event_Date = DateRange.Event_Date
)
OPTION (MAXRECURSION 400);

PRINT '[OK] Inserted school holidays';
GO

-------------------------------------------------------------------------------
-- 3. NHS STRIKE DAYS (from Data_Lab_SWL.SWL.tbl_Strike_Dates)
-------------------------------------------------------------------------------
PRINT '>>> Inserting NHS Strike Days from tbl_Strike_Dates...';

-- Expand date ranges into individual days and identify strike types
WITH StrikeDateExpansion AS (
    SELECT 
        FromDate AS StrikeDate,
        EndDate,
        Nurses,
        JrDoctors,
        Consultants,
        Radiographers
    FROM [Data_Lab_SWL].[SWL].[tbl_Strike_Dates]
    
    UNION ALL
    
    SELECT 
        DATEADD(DAY, 1, StrikeDate),
        EndDate,
        Nurses,
        JrDoctors,
        Consultants,
        Radiographers
    FROM StrikeDateExpansion
    WHERE StrikeDate < EndDate
),
StrikeTypes AS (
    SELECT 
        StrikeDate,
        -- Build comma-separated list of strike types
        STUFF(
            (CASE WHEN Nurses = 1 THEN ', Nurses' ELSE '' END) +
            (CASE WHEN JrDoctors = 1 THEN ', Junior Doctors' ELSE '' END) +
            (CASE WHEN Consultants = 1 THEN ', Consultants' ELSE '' END) +
            (CASE WHEN Radiographers = 1 THEN ', Radiographers' ELSE '' END),
            1, 2, ''  -- Remove leading ', '
        ) AS StrikeType
    FROM StrikeDateExpansion
    WHERE Nurses = 1 OR JrDoctors = 1 OR Consultants = 1 OR Radiographers = 1
)
-- Merge with existing records
MERGE [Analytics].[tbl_Dim_Date_Events] AS Target
USING StrikeTypes AS Source
ON Target.Event_Date = Source.StrikeDate
WHEN MATCHED THEN
    UPDATE SET 
        IsNHSStrikeDay = 1,
        NHS_Strike_Type = Source.StrikeType,
        Source = 'Data_Lab_SWL.SWL.tbl_Strike_Dates',
        Updated_Date = GETDATE()
WHEN NOT MATCHED THEN
    INSERT (Event_Date, IsNHSStrikeDay, NHS_Strike_Type, Source)
    VALUES (Source.StrikeDate, 1, Source.StrikeType, 'Data_Lab_SWL.SWL.tbl_Strike_Dates')
OPTION (MAXRECURSION 400);

PRINT '[OK] Inserted ' + CAST(@@ROWCOUNT AS VARCHAR) + ' NHS strike days from tbl_Strike_Dates';
GO

-------------------------------------------------------------------------------
-- 4. TRAIN STRIKE DAYS (2022-2024)
-------------------------------------------------------------------------------
PRINT '>>> Inserting Train Strike Days...';

MERGE [Analytics].[tbl_Dim_Date_Events] AS Target
USING (VALUES
    ('2022-06-21', 'RMT National Strike'),
    ('2022-06-23', 'RMT National Strike'),
    ('2022-06-25', 'RMT National Strike'),
    ('2022-07-27', 'RMT National Strike'),
    ('2022-08-18', 'RMT National Strike'),
    ('2022-08-20', 'RMT National Strike'),
    ('2023-01-03', 'RMT National Strike'),
    ('2023-01-04', 'RMT National Strike'),
    ('2023-01-06', 'RMT National Strike'),
    ('2023-03-16', 'RMT National Strike'),
    ('2023-03-18', 'RMT National Strike'),
    ('2023-03-30', 'RMT National Strike'),
    ('2023-04-01', 'RMT National Strike')
) AS Source(Event_Date, Operators)
ON Target.Event_Date = Source.Event_Date
WHEN MATCHED THEN
    UPDATE SET 
        IsTrainStrikeDay = 1,
        Train_Strike_Operators = Source.Operators,
        Updated_Date = GETDATE()
WHEN NOT MATCHED THEN
    INSERT (Event_Date, IsTrainStrikeDay, Train_Strike_Operators, Source)
    VALUES (Source.Event_Date, 1, Source.Operators, 'Train Strike Records');

PRINT '[OK] Inserted ' + CAST(@@ROWCOUNT AS VARCHAR) + ' train strike days';
GO

-------------------------------------------------------------------------------
-- 5. CHRISTMAS & EASTER PERIODS
-------------------------------------------------------------------------------
PRINT '>>> Marking Christmas & Easter Periods...';

-- Christmas Period (Dec 24 - Jan 2)
UPDATE [Analytics].[tbl_Dim_Date_Events]
SET IsChristmasPeriod = 1,
    Updated_Date = GETDATE()
WHERE MONTH(Event_Date) = 12 AND DAY(Event_Date) >= 24
   OR MONTH(Event_Date) = 1 AND DAY(Event_Date) <= 2;

-- Easter Period (Good Friday - Easter Monday) - already marked as bank holidays
UPDATE [Analytics].[tbl_Dim_Date_Events]
SET IsEasterPeriod = 1,
    Updated_Date = GETDATE()
WHERE BankHoliday_Name IN ('Good Friday', 'Easter Monday');

PRINT '[OK] Marked seasonal periods';
GO

PRINT '';
PRINT '========================================';
PRINT 'Date Events Population Complete';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';

-- Summary Statistics
SELECT 
    'Summary' AS Report,
    SUM(CAST(IsBankHoliday AS INT)) AS BankHolidays,
    SUM(CAST(IsSchoolHalfTerm AS INT)) AS HalfTermDays,
    SUM(CAST(IsNHSStrikeDay AS INT)) AS NHS_Strikes,
    SUM(CAST(IsTrainStrikeDay AS INT)) AS Train_Strikes,
    COUNT(*) AS Total_Events
FROM [Analytics].[tbl_Dim_Date_Events];

PRINT '';
PRINT 'Next Step: Run updated vw_Dim_Date VIEW to integrate these events';
GO

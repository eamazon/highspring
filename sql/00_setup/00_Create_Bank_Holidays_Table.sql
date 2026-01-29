USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating Bank Holidays Reference Table';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO
IF OBJECT_ID('[Analytics].[tbl_Bank_Holidays]', 'U') IS NOT NULL
BEGIN
    PRINT 'Table [Analytics].[tbl_Bank_Holidays] already exists. Dropping...';
    DROP TABLE [Analytics].[tbl_Bank_Holidays];
END
GO

/**
Script Name:   00_Create_Bank_Holidays_Table.sql
Description:   Create and populate England bank holidays reference table. Grain: One row per bank holiday date.
Author:        Sridhar Peddi
Created:       2026-01-06

Change Log:
    2026-01-06  Sridhar Peddi    Initial creation
    2026-01-09  Sridhar Peddi    Corrected header placement and script structure
**/
CREATE TABLE [Analytics].[tbl_Bank_Holidays]
(
    Bank_Holiday_Date DATE NOT NULL PRIMARY KEY,
    Bank_Holiday_Name VARCHAR(100) NOT NULL,
    Holiday_Type VARCHAR(50) NULL,  -- 'New Year', 'Easter', 'Christmas', 'Other'
        [Year] INT NOT NULL,
    Notes VARCHAR(255) NULL
);
GO

PRINT '[OK] Created table: [Analytics].[tbl_Bank_Holidays]';
GO

-- Populate with England Bank Holidays 2019-2027
PRINT '';
PRINT 'Populating Bank Holidays (England, 2019-2027)...';
GO

INSERT INTO [Analytics].[tbl_Bank_Holidays] (Bank_Holiday_Date, Bank_Holiday_Name, Holiday_Type, [Year], Notes)
VALUES
-- 2019
('2019-01-01', 'New Year''s Day', 'New Year', 2019, NULL),
('2019-04-19', 'Good Friday', 'Easter', 2019, NULL),
('2019-04-22', 'Easter Monday', 'Easter', 2019, NULL),
('2019-05-06', 'Early May bank holiday', 'Other', 2019, NULL),
('2019-05-27', 'Spring bank holiday', 'Other', 2019, NULL),
('2019-08-26', 'Summer bank holiday', 'Other', 2019, NULL),
('2019-12-25', 'Christmas Day', 'Christmas', 2019, NULL),
('2019-12-26', 'Boxing Day', 'Christmas', 2019, NULL),

-- 2020
('2020-01-01', 'New Year''s Day', 'New Year', 2020, NULL),
('2020-04-10', 'Good Friday', 'Easter', 2020, NULL),
('2020-04-13', 'Easter Monday', 'Easter', 2020, NULL),
('2020-05-08', 'Early May bank holiday (VE day)', 'Other', 2020, 'Moved for VE Day 75th anniversary'),
('2020-05-25', 'Spring bank holiday', 'Other', 2020, NULL),
('2020-08-31', 'Summer bank holiday', 'Other', 2020, NULL),
('2020-12-25', 'Christmas Day', 'Christmas', 2020, NULL),
('2020-12-28', 'Boxing Day', 'Christmas', 2020, 'Substitute day'),

-- 2021
('2021-01-01', 'New Year''s Day', 'New Year', 2021, NULL),
('2021-04-02', 'Good Friday', 'Easter', 2021, NULL),
('2021-04-05', 'Easter Monday', 'Easter', 2021, NULL),
('2021-05-03', 'Early May bank holiday', 'Other', 2021, NULL),
('2021-05-31', 'Spring bank holiday', 'Other', 2021, NULL),
('2021-08-30', 'Summer bank holiday', 'Other', 2021, NULL),
('2021-12-27', 'Christmas Day', 'Christmas', 2021, 'Substitute day'),
('2021-12-28', 'Boxing Day', 'Christmas', 2021, 'Substitute day'),

-- 2022
('2022-01-03', 'New Year''s Day', 'New Year', 2022, 'Substitute day'),
('2022-04-15', 'Good Friday', 'Easter', 2022, NULL),
('2022-04-18', 'Easter Monday', 'Easter', 2022, NULL),
('2022-05-02', 'Early May bank holiday', 'Other', 2022, NULL),
('2022-06-02', 'Spring bank holiday', 'Other', 2022, NULL),
('2022-06-03', 'Platinum Jubilee bank holiday', 'Other', 2022, 'Additional bank holiday'),
('2022-08-29', 'Summer bank holiday', 'Other', 2022, NULL),
('2022-09-19', 'Bank Holiday for the State Funeral of Queen Elizabeth II', 'Other', 2022, 'One-off'),
('2022-12-26', 'Boxing Day', 'Christmas', 2022, NULL),
('2022-12-27', 'Christmas Day', 'Christmas', 2022, 'Substitute day'),

-- 2023
('2023-01-02', 'New Year''s Day', 'New Year', 2023, 'Substitute day'),
('2023-04-07', 'Good Friday', 'Easter', 2023, NULL),
('2023-04-10', 'Easter Monday', 'Easter', 2023, NULL),
('2023-05-01', 'Early May bank holiday', 'Other', 2023, NULL),
('2023-05-08', 'Bank holiday for the coronation of King Charles III', 'Other', 2023, 'Additional bank holiday'),
('2023-05-29', 'Spring bank holiday', 'Other', 2023, NULL),
('2023-08-28', 'Summer bank holiday', 'Other', 2023, NULL),
('2023-12-25', 'Christmas Day', 'Christmas', 2023, NULL),
('2023-12-26', 'Boxing Day', 'Christmas', 2023, NULL),

-- 2024
('2024-01-01', 'New Year''s Day', 'New Year', 2024, NULL),
('2024-03-29', 'Good Friday', 'Easter', 2024, NULL),
('2024-04-01', 'Easter Monday', 'Easter', 2024, NULL),
('2024-05-06', 'Early May bank holiday', 'Other', 2024, NULL),
('2024-05-27', 'Spring bank holiday', 'Other', 2024, NULL),
('2024-08-26', 'Summer bank holiday', 'Other', 2024, NULL),
('2024-12-25', 'Christmas Day', 'Christmas', 2024, NULL),
('2024-12-26', 'Boxing Day', 'Christmas', 2024, NULL),

-- 2025
('2025-01-01', 'New Year''s Day', 'New Year', 2025, NULL),
('2025-04-18', 'Good Friday', 'Easter', 2025, NULL),
('2025-04-21', 'Easter Monday', 'Easter', 2025, NULL),
('2025-05-05', 'Early May bank holiday', 'Other', 2025, NULL),
('2025-05-26', 'Spring bank holiday', 'Other', 2025, NULL),
('2025-08-25', 'Summer bank holiday', 'Other', 2025, NULL),
('2025-12-25', 'Christmas Day', 'Christmas', 2025, NULL),
('2025-12-26', 'Boxing Day', 'Christmas', 2025, NULL),

-- 2026
('2026-01-01', 'New Year''s Day', 'New Year', 2026, NULL),
('2026-04-03', 'Good Friday', 'Easter', 2026, NULL),
('2026-04-06', 'Easter Monday', 'Easter', 2026, NULL),
('2026-05-04', 'Early May bank holiday', 'Other', 2026, NULL),
('2026-05-25', 'Spring bank holiday', 'Other', 2026, NULL),
('2026-08-31', 'Summer bank holiday', 'Other', 2026, NULL),
('2026-12-25', 'Christmas Day', 'Christmas', 2026, NULL),
('2026-12-28', 'Boxing Day', 'Christmas', 2026, 'Substitute day'),

-- 2027
('2027-01-01', 'New Year''s Day', 'New Year', 2027, NULL),
('2027-03-26', 'Good Friday', 'Easter', 2027, NULL),
('2027-03-29', 'Easter Monday', 'Easter', 2027, NULL),
('2027-05-03', 'Early May bank holiday', 'Other', 2027, NULL),
('2027-05-31', 'Spring bank holiday', 'Other', 2027, NULL),
('2027-08-30', 'Summer bank holiday', 'Other', 2027, NULL),
('2027-12-27', 'Christmas Day', 'Christmas', 2027, 'Substitute day'),
('2027-12-28', 'Boxing Day', 'Christmas', 2027, 'Substitute day');

GO

PRINT '[OK] Populated ' + CAST(@@ROWCOUNT AS VARCHAR) + ' bank holiday records';
GO

-- Create index for efficient date lookups
CREATE NONCLUSTERED INDEX IX_Bank_Holidays_Year 
    ON [Analytics].[tbl_Bank_Holidays]([Year], Bank_Holiday_Date);
GO

PRINT '[OK] Created index: IX_Bank_Holidays_Year';
GO

-- Validation
PRINT '';
PRINT 'Validation: Bank holidays by year';
SELECT 
    [Year],
    COUNT(*) AS Bank_Holiday_Count
FROM [Analytics].[tbl_Bank_Holidays]
GROUP BY [Year]
ORDER BY [Year];
GO

PRINT '';
PRINT 'Validation: Sample bank holidays';
SELECT TOP 10
    Bank_Holiday_Date,
    Bank_Holiday_Name,
    Holiday_Type,
    Notes
FROM [Analytics].[tbl_Bank_Holidays]
ORDER BY Bank_Holiday_Date DESC;
GO

PRINT '';
PRINT '========================================';
PRINT 'Bank Holidays Table Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
PRINT 'NOTES:';
PRINT '- Contains England bank holidays 2019-2027';
PRINT '- Update annually by adding new year records';
PRINT '- Source: https://www.gov.uk/bank-holidays';
PRINT '- Next step: Update 23_Create_Dim_Date_Enhanced.sql to LEFT JOIN this table';
PRINT '';
GO

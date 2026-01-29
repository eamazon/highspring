

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating tbl_Dim_Date_Events TABLE';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

-- Drop existing table if exists
IF OBJECT_ID('[Analytics].[tbl_Dim_Date_Events]', 'U') IS NOT NULL
BEGIN
    PRINT 'Table [Analytics].[tbl_Dim_Date_Events] already exists. Dropping...';
    DROP TABLE [Analytics].[tbl_Dim_Date_Events];
END
GO

/**
Script Name:   23_Create_Dim_Date_Events.sql
Description:   Calendar event table capturing UK bank holidays, school holidays, and NHS strikes.
               Enriches date dimension for demand modeling sensitive to external events.
               Supports capacity planning around known disruption periods.
Author:        Sridhar Peddi
Created:       2026-01-09

Change Log:
  2026-01-09   Sridhar Peddi    Initial creation
**/
CREATE TABLE [Analytics].[tbl_Dim_Date_Events]
(
    -- Primary Key
    Event_Date DATE NOT NULL,
    
    -- Bank Holiday Flags
    IsBankHoliday BIT NOT NULL DEFAULT 0,
    BankHoliday_Name VARCHAR(100) NULL,
    BankHoliday_Region VARCHAR(50) NULL, -- England, Scotland, Wales, Northern Ireland
    
    -- School Holiday Flags
    IsSchoolHoliday BIT NOT NULL DEFAULT 0,
    IsSchoolHalfTerm BIT NOT NULL DEFAULT 0,
    SchoolHoliday_Name VARCHAR(100) NULL, -- 'Spring Half Term', 'Summer Holiday', etc.
    
    -- Strike Flags
    IsNHSStrikeDay BIT NOT NULL DEFAULT 0,
    NHS_Strike_Type VARCHAR(100) NULL, -- 'Doctors', 'Nurses', 'Ambulance', etc.
    
    IsTrainStrikeDay BIT NOT NULL DEFAULT 0,
    Train_Strike_Operators VARCHAR(200) NULL, -- Affected operators
    
    -- Other Event Flags
    IsChristmasPeriod BIT NOT NULL DEFAULT 0, -- Dec 24 - Jan 2
    IsEasterPeriod BIT NOT NULL DEFAULT 0,    -- Good Friday - Easter Monday
    
    -- Metadata
    Event_Notes VARCHAR(500) NULL,
    Source VARCHAR(100) NULL DEFAULT 'Manual Entry',
    Created_Date DATETIME2 NOT NULL DEFAULT GETDATE(),
    Updated_Date DATETIME2 NULL,
    
    -- CONSTRAINT
    CONSTRAINT [PK_Dim_Date_Events] PRIMARY KEY NONCLUSTERED ([SK_EventID] ASC)
) ON [PRIMARY];
GO

PRINT '[OK] Created table: [Analytics].[tbl_Dim_Date_Events]';
GO

-- CLUSTERED COLUMNSTORE INDEX (Modern Standard)
CREATE CLUSTERED COLUMNSTORE INDEX [CCI_Dim_Date_Events] ON [Analytics].[tbl_Dim_Date_Events];
GO

-- Create index on flag columns for fast filtering
CREATE NONCLUSTERED INDEX IX_Date_Events_Flags 
    ON [Analytics].[tbl_Dim_Date_Events](IsBankHoliday, IsSchoolHalfTerm, IsNHSStrikeDay, IsTrainStrikeDay)
    INCLUDE (Event_Date, BankHoliday_Name, SchoolHoliday_Name);
GO

PRINT '[OK] Created index: IX_Date_Events_Flags';
GO

PRINT '';
PRINT '========================================';
PRINT 'tbl_Dim_Date_Events TABLE Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
PRINT 'Next Steps:';
PRINT '  1. Run 24_Populate_Date_Events.sql to load UK calendar events';
PRINT '  2. Update vw_Dim_Date to reference this table';
PRINT '';
GO

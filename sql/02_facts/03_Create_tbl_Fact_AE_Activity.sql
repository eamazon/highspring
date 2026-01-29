/**
-- Script Name: 03_Create_tbl_Fact_AE_Activity.sql
-- Description: Fact table for A&E / Emergency Department activity (Singular).
--              Grain: One row per attendance.
--              Links to 17 dimensions including AE-specific disposal.
-- Author:      Sridhar Peddi
-- Created:     2026-01-09

-- Change Log:
Change Log:
-- 2026-01-09   | Sridhar Peddi    | Initial creation - AE fact table
**/

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating tbl_Fact_AE_Activity TABLE';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

IF OBJECT_ID('[Analytics].[tbl_Fact_AE_Activity]', 'U') IS NOT NULL
BEGIN
    PRINT 'Table [Analytics].[tbl_Fact_AE_Activity] already exists. Dropping...';
    DROP TABLE [Analytics].[tbl_Fact_AE_Activity];
END
GO

/**
-- Table Name:  tbl_Fact_AE_Activity
-- Description: Emergency Department activity fact table.
--              Architecture: Clustered Columnstore.
**/
CREATE TABLE [Analytics].[tbl_Fact_AE_Activity] (
    -- PRIMARY KEY (Non-Clustered)
    [SK_EncounterID] BIGINT NOT NULL,
  
    -- CORE DIMENSION FOREIGN KEYS (16 Core)
    [SK_PatientID] BIGINT NOT NULL,                    -- #1 tbl_Dim_Patient
    [SK_DateArrivalID] INT NOT NULL,                   -- #2 tbl_Dim_Date (Role: Arrival)
    [SK_DateDepartureID] INT NOT NULL,                 -- #2 tbl_Dim_Date (Role: Departure)
    [Arrival_Date] DATE NOT NULL,                      -- Partitioning date (Arrival)
    [Departure_Date] DATE NULL,                        -- Departure date (optional)
    [SK_Age_BandID] INT NOT NULL,                      -- #3 tbl_Dim_Age_Band
    [SK_GenderID] INT NOT NULL,                        -- #4 tbl_Dim_Gender
    [SK_EthnicityID] INT NOT NULL,                     -- #5 tbl_Dim_Ethnicity
    [SK_ProviderID] INT NOT NULL,                      -- #6 tbl_Dim_Provider
    [SK_LSOA_ID] INT NULL,                             -- #7 tbl_Dim_LSOA
    [LSOA_Code] VARCHAR(9) NULL,                       -- Degenerate LSOA code
    [SK_SpecialtyID] INT NULL,                         -- #8 tbl_Dim_Specialty (Treatment Function)
    [SK_HRG_ID] INT NULL,                              -- #9 tbl_Dim_HRG
    [SK_DiagnosisID] INT NULL,                         -- #10 tbl_Dim_Diagnosis (Primary)
    [SK_ProcedureID] INT NULL,                         -- #11 tbl_Dim_Procedure (Primary)
    [SK_CommissionerID] INT NOT NULL,                  -- #12 tbl_Dim_Commissioner
    [SK_GPPracticeID] INT NULL,                        -- #13 tbl_Dim_GPPractice
    [SK_PCN_ID] INT NULL,                              -- #14 tbl_Dim_PCN
    [SK_POD_ID] INT NOT NULL,                          -- #15 tbl_Dim_POD ('AE')
    [SK_OpPlan_MeasureSet] BIGINT NOT NULL DEFAULT (-1), -- #16 tbl_Dim_OpPlan_MeasureSet

    -- AE SPECIFIC DIMENSIONS
    [SK_Attendance_DisposalID] INT NULL,               -- #27 tbl_Dim_Attendance_Disposal

    -- MEASURES
    [Attendances] INT DEFAULT 1,
    [Time_In_Department_Mins] INT NULL,
    [Time_To_Initial_Assessment_Mins] INT NULL,
    [Total_Cost] DECIMAL(12,2) NULL,
    
    -- PERFORMANCE FLAGS
    [Is_4Hour_Breach] BIT DEFAULT 0,
    [Is_12Hour_Breach] BIT DEFAULT 0,
    [Is_Admitted] BIT DEFAULT 0,

    -- DEGENERATE DIMENSIONS / ATTRIBUTES
    [Arrival_Mode_Code] VARCHAR(2) NULL,
    [Attendance_Category_Code] VARCHAR(2) NULL,
    [Referral_Source_Code] VARCHAR(2) NULL,
    [Department_Type_Code] VARCHAR(2) NULL,

    -- OPERATING PLAN FLAG
    [Is_Operating_Plan] BIT NOT NULL DEFAULT 0,
  
    -- AUDIT (ANSI)
    [ETL_LoadDateTime] DATETIME2 DEFAULT CURRENT_TIMESTAMP,
    
    -- CONSTRAINTS
    CONSTRAINT [PK_Fact_AE_Activity] PRIMARY KEY NONCLUSTERED ([SK_EncounterID] ASC, [Arrival_Date] ASC),
    CONSTRAINT [CK_Fact_AE_Cost] CHECK ([Total_Cost] >= 0)
) ON [PS_AE_Activity_Monthly]([Arrival_Date]);
GO

-- CLUSTERED COLUMNSTORE INDEX (Modern Standard)
CREATE CLUSTERED COLUMNSTORE INDEX [CCI_Fact_AE_Activity] ON [Analytics].[tbl_Fact_AE_Activity];
GO

PRINT '[OK] Created table: [Analytics].[tbl_Fact_AE_Activity]';
GO

PRINT '';
PRINT '========================================';
PRINT 'tbl_Fact_AE_Activity TABLE Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO

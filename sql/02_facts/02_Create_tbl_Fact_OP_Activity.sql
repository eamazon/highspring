/**
-- Script Name: 02_Create_tbl_Fact_OP_Activity.sql
-- Description: Fact table for outpatient activity (Singular).
--              Grain: One row per appointment/attendance.
--              Links to 21 dimensions including OP-specific status/outcome.
-- Author:      Sridhar Peddi
-- Created:     2026-01-09

-- Change Log:
Change Log:
-- 2026-01-09   | Sridhar Peddi    | Initial creation - OP fact table
-- 2026-01-26   | Sridhar Peddi    | Add Is_FirstAttendance flag
**/

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating tbl_Fact_OP_Activity TABLE';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

IF OBJECT_ID('[Analytics].[tbl_Fact_OP_Activity]', 'U') IS NOT NULL
BEGIN
    PRINT 'Table [Analytics].[tbl_Fact_OP_Activity] already exists. Dropping...';
    DROP TABLE [Analytics].[tbl_Fact_OP_Activity];
END
GO

/**
-- Table Name:  tbl_Fact_OP_Activity
-- Description: Outpatient activity fact table.
--              Architecture: Clustered Columnstore (Modern Analytics).
**/
CREATE TABLE [Analytics].[tbl_Fact_OP_Activity] (
    -- PRIMARY KEY (Non-Clustered)
    [SK_EncounterID] BIGINT NOT NULL,
  
    -- CORE DIMENSION FOREIGN KEYS (16 Core)
    [SK_PatientID] BIGINT NOT NULL,                    -- #1 tbl_Dim_Patient
    [SK_DateAppointmentID] INT NOT NULL,               -- #2 tbl_Dim_Date (Role: Appointment)
    [SK_DateReferralID] INT NULL,                      -- #2 tbl_Dim_Date (Role: Referral)
    [Appointment_Date] DATE NOT NULL,                  -- Partitioning date (Appointment)
    [Referral_Date] DATE NULL,                         -- Referral date (optional)
    [SK_Age_BandID] INT NOT NULL,                      -- #3 tbl_Dim_Age_Band
    [SK_GenderID] INT NOT NULL,                        -- #4 tbl_Dim_Gender
    [SK_EthnicityID] INT NOT NULL,                     -- #5 tbl_Dim_Ethnicity
    [SK_ProviderID] INT NOT NULL,                      -- #6 tbl_Dim_Provider
    [SK_LSOA_ID] INT NULL,                             -- #7 tbl_Dim_LSOA
    [LSOA_Code] VARCHAR(9) NULL,                       -- Degenerate LSOA code
    [SK_SpecialtyID] INT NULL,                         -- #8 tbl_Dim_Specialty
    [SK_HRG_ID] INT NULL,                              -- #9 tbl_Dim_HRG
    [SK_DiagnosisID] INT NULL,                         -- #10 (Usually NULL for OP)
    [SK_ProcedureID] INT NULL,                         -- #11 tbl_Dim_Procedure (Primary)
    [SK_CommissionerID] INT NOT NULL,                  -- #12 tbl_Dim_Commissioner
    [SK_GPPracticeID] INT NULL,                        -- #13 tbl_Dim_GPPractice
    [SK_PCN_ID] INT NULL,                              -- #14 tbl_Dim_PCN
    [SK_POD_ID] INT NOT NULL,                          -- #15 tbl_Dim_POD ('OP')
    [SK_OpPlan_MeasureSet] BIGINT NOT NULL DEFAULT (-1), -- #16 tbl_Dim_OpPlan_MeasureSet

    -- OP SPECIFIC DIMENSIONS (6 Specific)
    [SK_Attendance_StatusID] INT NOT NULL,             -- #21 tbl_Dim_Attendance_Status
    [SK_Attendance_OutcomeID] INT NULL,                -- #22 tbl_Dim_Attendance_Outcome
    [SK_Attendance_TypeID] INT NULL,                   -- #23 tbl_Dim_Attendance_Type
    [SK_DNA_IndicatorID] INT NOT NULL,                 -- #24 tbl_Dim_DNA_Indicator
    [SK_Priority_TypeID] INT NULL,                     -- #25 tbl_Dim_Priority_Type
    [SK_Referral_SourceID] INT NULL,                   -- #26 tbl_Dim_Referral_Source

    -- MEASURES
    [Appointments] INT DEFAULT 1,
    [Total_Cost] DECIMAL(12,2) NULL,
    [DNA_Count] INT DEFAULT 0,
    [Is_FirstAttendance] BIT NOT NULL DEFAULT 0,
    
    -- WAIT TIMES
    [Referral_To_Appt_Days] INT NULL,
    [RTT_Wait_Weeks] DECIMAL(5,2) NULL,

    -- DEGENERATE DIMENSIONS / ATTRIBUTES
    [Outcome_Code] VARCHAR(2) NULL,
    [Priority_Code] VARCHAR(2) NULL,
    [Clinic_Code] VARCHAR(20) NULL,
    [Admin_Category_Code] VARCHAR(2) NULL,

    -- COMMISSIONER ATTRIBUTION (CAM)
    [SK_CAM_CommissionerID] INT NOT NULL DEFAULT (-1),
    [SK_CAM_Service_CategoryID] INT NOT NULL DEFAULT (-1),
    [SK_CAM_Assignment_ReasonID] INT NOT NULL DEFAULT (-1),
    [CAM_Commissioner_Code] VARCHAR(20) NULL,
    [CAM_Service_Category] VARCHAR(50) NULL,
    [CAM_Assignment_Reason] VARCHAR(255) NULL,
    [Commissioner_Variance] BIT NULL,
    [Service_Category_Variance] BIT NULL,

    -- OPERATING PLAN FLAG
    [Is_Operating_Plan] BIT NOT NULL DEFAULT 0,

    -- ERF ELIGIBILITY + PRICING
    [Is_ERF_Eligible] BIT NOT NULL DEFAULT 0,
    [ERF_National_Price] DECIMAL(12,2) NULL,
    [ERF_MFF_Applied] DECIMAL(12,2) NULL,
    [ERF_Total_Cost_Incl_MFF] DECIMAL(12,2) NULL,
    [ERF_Tariff_Used] VARCHAR(50) NULL,
  
    -- AUDIT (ANSI)
    [ETL_LoadDateTime] DATETIME2 DEFAULT CURRENT_TIMESTAMP,
    [ETL_UpdateDateTime] DATETIME2 NULL,
  
    -- CONSTRAINTS
    CONSTRAINT [PK_Fact_OP_Activity] PRIMARY KEY NONCLUSTERED ([SK_EncounterID] ASC, [Appointment_Date] ASC),
    CONSTRAINT [CK_Fact_OP_Cost] CHECK ([Total_Cost] >= 0)
) ON [PS_OP_Activity_Monthly]([Appointment_Date]);
GO

-- CLUSTERED COLUMNSTORE INDEX (Modern Standard)
CREATE CLUSTERED COLUMNSTORE INDEX [CCI_Fact_OP_Activity] ON [Analytics].[tbl_Fact_OP_Activity];
GO

-- Nonclustered index to support CAM enrichment joins and date filters
CREATE NONCLUSTERED INDEX [IX_Fact_OP_Activity_CAM]
    ON [Analytics].[tbl_Fact_OP_Activity] ([SK_EncounterID], [Appointment_Date])
    INCLUDE (
        [SK_CAM_CommissionerID],
        [SK_CAM_Service_CategoryID],
        [SK_CAM_Assignment_ReasonID],
        [CAM_Commissioner_Code],
        [CAM_Service_Category],
        [CAM_Assignment_Reason],
        [Commissioner_Variance],
        [Service_Category_Variance],
        [ETL_UpdateDateTime]
    )
    ON [PS_OP_Activity_Monthly]([Appointment_Date]);
GO

PRINT '[OK] Created table: [Analytics].[tbl_Fact_OP_Activity]';
GO

PRINT '';
PRINT '========================================';
PRINT 'tbl_Fact_OP_Activity TABLE Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO

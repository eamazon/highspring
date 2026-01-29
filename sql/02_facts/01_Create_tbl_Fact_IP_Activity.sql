/**
-- Script Name: 01_Create_tbl_Fact_IP_Activity.sql
-- Description: Fact table for inpatient admissions (Singular).
--              Grain: One row per inpatient spell (admission to discharge episode).
--              Links to 21 dimensions including patient, dates, provider, and clinical codes.
-- Author:      Sridhar Peddi
-- Created:     2026-01-09

-- Change Log:
Change Log:
-- 2026-01-09   | Sridhar Peddi    | Initial creation - IP fact table with 21 FK dimensions
**/

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating tbl_Fact_IP_Activity TABLE';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

-- Drop if exists (Standard Drop Pattern)
IF OBJECT_ID('[Analytics].[tbl_Fact_IP_Activity]', 'U') IS NOT NULL
BEGIN
    PRINT 'Table [Analytics].[tbl_Fact_IP_Activity] already exists. Dropping...';
    DROP TABLE [Analytics].[tbl_Fact_IP_Activity];
END
GO

/**
-- Table Name:  tbl_Fact_IP_Activity
-- Description: Inpatient activity fact table.
--              Grain: One row per inpatient spell.
--              Architecture: Clustered Columnstore (Modern Analytics / Snowflake-Ready).
**/
CREATE TABLE [Analytics].[tbl_Fact_IP_Activity] (
    -- PRIMARY KEY (Non-Clustered for CCI Compatibility)
  [SK_EncounterID] BIGINT NOT NULL,
  
    -- CORE DIMENSION FOREIGN KEYS (16 Core)
    [SK_PatientID] BIGINT NOT NULL,                    -- #1 tbl_Dim_Patient
    [SK_DateAdmissionID] INT NOT NULL,                 -- #2 tbl_Dim_Date (Role: Admission)
    [SK_DateDischargeID] INT NOT NULL,                 -- #2 tbl_Dim_Date (Role: Discharge)
    [Admission_Date] DATE NOT NULL,                    -- Partitioning date (Admission)
    [Discharge_Date] DATE NOT NULL,                    -- Partitioning date (Discharge)
    [SK_Age_BandID] INT NOT NULL,                      -- #3 tbl_Dim_Age_Band
    [SK_GenderID] INT NOT NULL,                        -- #4 tbl_Dim_Gender
    [SK_EthnicityID] INT NOT NULL,                     -- #5 tbl_Dim_Ethnicity
    [SK_ProviderID] INT NOT NULL,                      -- #6 tbl_Dim_Provider
    [SK_LSOA_ID] INT NULL,                             -- #7 tbl_Dim_LSOA
    [LSOA_Code] VARCHAR(9) NULL,                       -- Degenerate LSOA code
    [SK_SpecialtyID] INT NULL,                         -- #8 tbl_Dim_Specialty
    [SK_HRG_ID] INT NULL,                              -- #9 tbl_Dim_HRG
    [SK_DiagnosisID] INT NULL,                         -- #10 tbl_Dim_Diagnosis (Primary)
    [SK_ProcedureID] INT NULL,                         -- #11 tbl_Dim_Procedure (Primary)
    [SK_CommissionerID] INT NOT NULL,                  -- #12 tbl_Dim_Commissioner
    [SK_GPPracticeID] INT NULL,                        -- #13 tbl_Dim_GPPractice
    [SK_PCN_ID] INT NULL,                              -- #14 tbl_Dim_PCN
    [SK_POD_ID] INT NOT NULL,                          -- #15 tbl_Dim_POD ('IP')
    [SK_OpPlan_MeasureSet] BIGINT NOT NULL DEFAULT (-1), -- #16 tbl_Dim_OpPlan_MeasureSet

    -- IP SPECIFIC DIMENSIONS (5 Specific)
    [SK_Admission_MethodID] INT NULL,                  -- #16 tbl_Dim_Admission_Method
    [SK_Admission_SourceID] INT NULL,                  -- #17 tbl_Dim_Admission_Source
    [SK_Discharge_MethodID] INT NULL,                  -- #18 tbl_Dim_Discharge_Method
    [SK_Discharge_DestinationID] INT NULL,             -- #19 tbl_Dim_Discharge_Destination
    [SK_IP_Patient_ClassificationID] INT NULL,         -- #20 tbl_Dim_IP_Patient_Classification

    -- MEASURES
    [Admissions] INT DEFAULT 1,
    [Length_Of_Stay] INT NULL,
    [Total_Cost] DECIMAL(12,2) NULL,
    
    -- EFFICIENCY METRICS
    [Delayed_Discharge_Days] INT NULL,
    [Excess_Bed_Days] INT NULL,
    [Excess_Bed_Days_Cost] DECIMAL(12,2) NULL,
    [Palliative_Care_Days] INT NULL,
    [Rehab_Days] INT NULL,
    
    -- FINANCIAL BREAKDOWN
    [Base_Tariff] DECIMAL(12,2) NULL,
    [MFF_Multiplier] DECIMAL(5,4) NULL,
  
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
  
    -- AUDIT (ANSI Standard)
    [ETL_LoadDateTime] DATETIME2 DEFAULT CURRENT_TIMESTAMP,
    [ETL_UpdateDateTime] DATETIME2 NULL,
  
    -- CONSTRAINTS
    CONSTRAINT [PK_Fact_IP_Activity] PRIMARY KEY NONCLUSTERED ([SK_EncounterID] ASC, [Discharge_Date] ASC),
    CONSTRAINT [CK_Fact_IP_LOS] CHECK ([Length_Of_Stay] >= 0),
    CONSTRAINT [CK_Fact_IP_Cost] CHECK ([Total_Cost] >= 0)
) ON [PS_IP_Activity_Monthly]([Discharge_Date]);
GO

-- CLUSTERED COLUMNSTORE INDEX (The "Modern" Standard)
-- Provides 10x compression and high-speed aggregation.
-- Replaces the need for individual Non-Clustered indexes on Dimension FKs.
CREATE CLUSTERED COLUMNSTORE INDEX [CCI_Fact_IP_Activity] ON [Analytics].[tbl_Fact_IP_Activity];
GO

-- Nonclustered index to support CAM enrichment joins and date filters
CREATE NONCLUSTERED INDEX [IX_Fact_IP_Activity_CAM]
    ON [Analytics].[tbl_Fact_IP_Activity] ([SK_EncounterID], [Discharge_Date])
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
    ON [PS_IP_Activity_Monthly]([Discharge_Date]);
GO

PRINT '[OK] Created table: [Analytics].[tbl_Fact_IP_Activity]';
PRINT '     Grain: Inpatient Spell';
GO

PRINT '';
PRINT '========================================';
PRINT 'tbl_Fact_IP_Activity TABLE Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO

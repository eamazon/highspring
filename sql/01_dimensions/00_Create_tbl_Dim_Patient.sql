

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating tbl_Dim_Patient TABLE';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

IF OBJECT_ID('[Analytics].[tbl_Dim_Patient]', 'U') IS NULL
BEGIN
    /**
    Script Name:   00_Create_tbl_Dim_Patient.sql
    Description:   Patient demographic dimension with pseudonymized identifiers.
                   Tracks current patient attributes including LSOA, ethnicity, gender, age, and GP practice.
                   Degenerate dimension pattern - demographics stored in fact tables, this provides reference structure.
    Author:        Sridhar Peddi
    Created:       2026-01-09

    Change Log:
      2026-01-09   Sridhar Peddi    Initial creation
      2026-01-26   Sridhar Peddi    Removed local patient identifier from Analytics layer
    **/
    CREATE TABLE [Analytics].[tbl_Dim_Patient] (
        -- KEYS
      [SK_PatientID] BIGINT NOT NULL,                    -- Business Key (Pseudonymised Patient ID from Unified)
      [Pseudo_ID] VARCHAR(255) NULL,                     -- Optional secondary pseudonym if available

        -- DEMOGRAPHICS
        [Date_Of_Birth] DATE NULL,
        [Date_Of_Death] DATE NULL,
        [Gender_Code] VARCHAR(10) NULL,
        [Gender_Description] VARCHAR(50) NULL,
        [Ethnicity_Code] VARCHAR(10) NULL,
        [Ethnicity_Description] VARCHAR(100) NULL,
        
        -- GEOGRAPHY (Current)
        [LSOA_Code] VARCHAR(10) NULL,
        [Postcode_Sector] VARCHAR(10) NULL,
        
        -- REGISTRATION
        [GP_Practice_Code] VARCHAR(10) NULL,
        [GP_Practice_Name] VARCHAR(255) NULL,
        [PCN_Code] VARCHAR(10) NULL,
        [ICB_Code] VARCHAR(10) NULL,
        
        -- METADATA / SCD
        [Is_Sensitive] BIT DEFAULT 0,
        [Valid_From] DATE DEFAULT '1900-01-01',
        [Valid_To] DATE NULL,
        [Is_Current] BIT DEFAULT 1,
        
        [ETL_LoadDateTime] DATETIME2 DEFAULT CURRENT_TIMESTAMP,

        -- CONSTRAINT: PK is Non-Clustered to allow CCI
        CONSTRAINT [PK_Dim_Patient] PRIMARY KEY NONCLUSTERED ([SK_PatientID] ASC)
    ) ON [PRIMARY];
END
ELSE
BEGIN
    PRINT 'Table [Analytics].[tbl_Dim_Patient] already exists. Skipping create.';
END
GO

-- CLUSTERED COLUMNSTORE INDEX (The "Modern" Standard)
-- Critical for Patient Dimension as it is Large (>1M rows)
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'CCI_Dim_Patient'
      AND object_id = OBJECT_ID('[Analytics].[tbl_Dim_Patient]')
)
BEGIN
    CREATE CLUSTERED COLUMNSTORE INDEX [CCI_Dim_Patient] ON [Analytics].[tbl_Dim_Patient];
END
GO

-------------------------------------------------------------------------------
-- Insert default "Unknown" member (SK = -1)
-- For cases where patient is missing/unmapped in source data
-------------------------------------------------------------------------------

IF NOT EXISTS (SELECT 1 FROM [Analytics].[tbl_Dim_Patient] WHERE [SK_PatientID] = -1)
BEGIN
    INSERT INTO [Analytics].[tbl_Dim_Patient]
        ([SK_PatientID], [Pseudo_ID], [Is_Sensitive], [Valid_From], [Is_Current])
    VALUES
        (-1, 'UNKNOWN', 0, '1900-01-01', 1);
END
GO

PRINT '[OK] Created table: [Analytics].[tbl_Dim_Patient]';
GO

PRINT '';
PRINT '========================================';
PRINT 'tbl_Dim_Patient TABLE Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO



USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating Dim_GPPractice';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

-------------------------------------------------------------------------------
-- Create table IF NOT EXISTS (preserves surrogate keys on re-run)
-------------------------------------------------------------------------------

IF OBJECT_ID('[Analytics].[tbl_Dim_GPPractice]', 'U') IS NULL
BEGIN
    PRINT 'Creating table [Analytics].[tbl_Dim_GPPractice]...';

    /**
    Script Name:   03_Create_Dim_GPPractice.sql
    Description:   GP Practice dimension with SCD Type 2 change tracking for practice attributes.
                   Includes PCN/ICB/Sub-ICB relationships, prescribing settings, and closure tracking.
                   Supports patient list size analysis and practice-level performance monitoring.
    Author:        Sridhar Peddi
    Created:       2026-01-02

    Change Log:
      2026-01-02   Sridhar Peddi    Initial creation
      2026-01-28   Sridhar Peddi    Changed to CREATE IF NOT EXISTS pattern (preserves SKs)
    **/
    CREATE TABLE [Analytics].[tbl_Dim_GPPractice]
    (
        -- Surrogate key (artificial ID number, independent of business data)
        SK_GPPracticeID INT IDENTITY(1,1) NOT NULL,

        -- Natural key (NHS ODS Practice Code - the real business identifier)
        GPPractice_Code VARCHAR(10) NOT NULL,

        -- GP Practice attributes
        GPPractice_Name VARCHAR(255) NULL,
        Practice_Category VARCHAR(50) NULL,  -- 'Valid Practice', 'No Registered GP', 'Closed', etc.
        Prescribing_Setting VARCHAR(255) NULL, -- Increased from VARCHAR(5) to match staging
        Org_Sub_Type VARCHAR(5) NULL,        -- B=GP, etc.
        Address_Line1 VARCHAR(255) NULL,
        Address_Line2 VARCHAR(255) NULL,
        Address_Line3 VARCHAR(255) NULL,
        Town VARCHAR(255) NULL,
        Postcode VARCHAR(20) NULL,
        Contact_Telephone VARCHAR(50) NULL,

        -- PCN level (Primary Care Network)
        PCN_Code VARCHAR(10) NULL,
        PCN_Name VARCHAR(255) NULL,

        -- Sub-ICB level (formerly CCG - 6 Sub-ICBs in SWL)
        SubICB_Code VARCHAR(10) NULL,
        SubICB_Name VARCHAR(255) NULL,

        -- ICB level (Integrated Care Board)
        ICB_Code VARCHAR(10) NULL,             -- Supports 3-char (36L) and mixed codes
        ICB_Name VARCHAR(255) NULL,

        -- Grouping for reporting
        ICB_Grouping VARCHAR(50) NULL,         -- 'SWL ICB', 'London ICBs', 'Other ICB'
        ICB_Grouping_Sort INT NULL,            -- Sort order: 1=SWL, 2=London, 3=Other
        Registration_Status VARCHAR(20) NULL,  -- 'SWL' or 'Non-SWL'

        -- Active status (practices can close/merge)
        Is_Active BIT NOT NULL DEFAULT 1,
        Effective_From_Date DATE NULL,         -- When practice opened/changed
        Effective_To_Date DATE NULL,           -- When practice closed (NULL if still open)

        -- SCD Type 2 columns (for tracking historical changes)
        Valid_From DATE NOT NULL DEFAULT '1900-01-01',
        Valid_To DATE NULL DEFAULT '9999-12-31',
        Is_Current BIT NOT NULL DEFAULT 1,

        -- Audit columns
        Source_System VARCHAR(50) DEFAULT 'ref.tbl_GP_PCN_ICB_Details',
        Created_By VARCHAR(128) NULL DEFAULT SYSTEM_USER,
        Created_Date DATETIME2 NOT NULL DEFAULT GETDATE(),
        Updated_Date DATETIME2 NULL,
        Updated_By VARCHAR(128) NULL,

        -- CONSTRAINT
        CONSTRAINT [PK_Dim_GPPractice] PRIMARY KEY NONCLUSTERED ([SK_GPPracticeID] ASC)
    ) ON [PRIMARY];

    -- CLUSTERED COLUMNSTORE INDEX (Modern Standard)
    CREATE CLUSTERED COLUMNSTORE INDEX [CCI_Dim_GPPractice] ON [Analytics].[tbl_Dim_GPPractice];

    PRINT '[OK] Created table: [Analytics].[tbl_Dim_GPPractice]';

    ---------------------------------------------------------------------------
    -- Insert default "Unknown" member (SK = -1)
    -- For cases where GP Practice is not recorded in source data
    ---------------------------------------------------------------------------

    SET IDENTITY_INSERT [Analytics].[tbl_Dim_GPPractice] ON;

    INSERT INTO [Analytics].[tbl_Dim_GPPractice]
        (SK_GPPracticeID, GPPractice_Code, GPPractice_Name, Practice_Category,
         Address_Line1, Postcode, Contact_Telephone,
         PCN_Code, PCN_Name, SubICB_Code, SubICB_Name, ICB_Code, ICB_Name,
         ICB_Grouping, Registration_Status, Is_Active, Valid_From, Is_Current)
    VALUES
        (-1, 'UNKNOWN', 'Unknown GP Practice', 'Unknown',
         'Unknown Address', 'UNK', 'Unknown',
         'UNKNOWN', 'Unknown PCN', 'UNKNOWN', 'Unknown Sub-ICB', 'UNK', 'Unknown ICB',
         'Other ICB', 'Non-SWL', 1, '1900-01-01', 1);

    PRINT '[OK] Inserted default "Unknown" member (SK_GPPracticeID = -1)';

    ---------------------------------------------------------------------------
    -- Insert NHS standard "No Registered GP" members (V81997, V81998, V81999)
    -- These are official NHS codes for patients without registered GP
    ---------------------------------------------------------------------------

    INSERT INTO [Analytics].[tbl_Dim_GPPractice]
        (SK_GPPracticeID, GPPractice_Code, GPPractice_Name, Practice_Category,
         Address_Line1, Postcode, Contact_Telephone,
         PCN_Code, PCN_Name, SubICB_Code, SubICB_Name, ICB_Code, ICB_Name,
         ICB_Grouping, ICB_Grouping_Sort, Registration_Status, Is_Active, Valid_From, Is_Current)
    VALUES
        (-2, 'V81997', 'No Registered GP Practice', 'No Registered GP',
         'Not Applicable', 'N/A', 'N/A',
         'UNK', 'No PCN', 'UNK', 'No Sub-ICB', 'UNK', 'No ICB',
         'Other ICB', 3, 'Non-SWL', 1, '1900-01-01', 1),
        (-3, 'V81998', 'GP Practice Not Known', 'No Registered GP',
         'Not Applicable', 'N/A', 'N/A',
         'UNK', 'No PCN', 'UNK', 'No Sub-ICB', 'UNK', 'No ICB',
         'Other ICB', 3, 'Non-SWL', 1, '1900-01-01', 1),
        (-4, 'V81999', 'No Fixed Abode', 'No Registered GP',
         'Not Applicable', 'N/A', 'N/A',
         'UNK', 'No PCN', 'UNK', 'No Sub-ICB', 'UNK', 'No ICB',
         'Other ICB', 3, 'Non-SWL', 1, '1900-01-01', 1);

    SET IDENTITY_INSERT [Analytics].[tbl_Dim_GPPractice] OFF;

    PRINT '[OK] Inserted NHS standard "No Registered GP" members (IDs: -2, -3, -4)';

    ---------------------------------------------------------------------------
    -- Create indexes
    ---------------------------------------------------------------------------

    CREATE NONCLUSTERED INDEX IX_Dim_GPPractice_ICB
        ON [Analytics].[tbl_Dim_GPPractice](ICB_Code, Is_Current)
        INCLUDE (GPPractice_Code, GPPractice_Name, Registration_Status);

    PRINT '[OK] Created index: IX_Dim_GPPractice_ICB';

    CREATE NONCLUSTERED INDEX IX_Dim_GPPractice_PCN
        ON [Analytics].[tbl_Dim_GPPractice](PCN_Code, Is_Current)
        INCLUDE (GPPractice_Code, GPPractice_Name);

    PRINT '[OK] Created index: IX_Dim_GPPractice_PCN';

    CREATE NONCLUSTERED INDEX IX_Dim_GPPractice_Active
        ON [Analytics].[tbl_Dim_GPPractice](Is_Active, Is_Current)
        INCLUDE (GPPractice_Code, GPPractice_Name);

    PRINT '[OK] Created index: IX_Dim_GPPractice_Active';

    CREATE NONCLUSTERED INDEX IX_Dim_GPPractice_Validity
        ON [Analytics].[tbl_Dim_GPPractice](Valid_From, Valid_To)
        INCLUDE (SK_GPPracticeID, GPPractice_Code, Is_Current);

    PRINT '[OK] Created index: IX_Dim_GPPractice_Validity';

    CREATE UNIQUE NONCLUSTERED INDEX UX_Dim_GPPractice_Code_Current
        ON [Analytics].[tbl_Dim_GPPractice](GPPractice_Code)
        WHERE Is_Current = 1;

    PRINT '[OK] Created unique index: UX_Dim_GPPractice_Code_Current';
END
ELSE
BEGIN
    PRINT '[SKIP] Table [Analytics].[tbl_Dim_GPPractice] already exists - preserving surrogate keys';
END
GO

PRINT '';
PRINT '========================================';
PRINT 'Dim_GPPractice Creation Complete';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
PRINT 'Current Row Count:';
SELECT COUNT(*) as Row_Count FROM [Analytics].[tbl_Dim_GPPractice];
PRINT '';
GO

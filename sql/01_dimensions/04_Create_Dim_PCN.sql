

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating Dim_PCN';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

-------------------------------------------------------------------------------
-- Create table IF NOT EXISTS (preserves surrogate keys on re-run)
-------------------------------------------------------------------------------

IF OBJECT_ID('[Analytics].[tbl_Dim_PCN]', 'U') IS NULL
BEGIN
    PRINT 'Creating table [Analytics].[tbl_Dim_PCN]...';

    /**
    Script Name:   04_Create_Dim_PCN.sql
    Description:   Primary Care Network (PCN) dimension tracking GP practice collaboratives.
                   Supports integrated care analysis and PCN-level service planning.
                   One row per PCN code with ICB/Sub-ICB parent relationships.
    Author:        Sridhar Peddi
    Created:       2026-01-02

    Change Log:
      2026-01-02   Sridhar Peddi    Initial creation
      2026-01-28   Sridhar Peddi    Changed to CREATE IF NOT EXISTS pattern (preserves SKs)
    **/
    CREATE TABLE [Analytics].[tbl_Dim_PCN]
    (
        -- Surrogate key
        SK_PCNID INT IDENTITY(1,1) NOT NULL,

        -- Natural key
        PCN_Code VARCHAR(10) NOT NULL,

        -- Attributes
        PCN_Name VARCHAR(255) NULL,
        ICB_Code VARCHAR(10) NULL,       -- Matches staging (A3A8R etc.)
        ICB_Name VARCHAR(500) NULL,      -- Long names

        -- Operational dates
        Open_Date DATE NULL,
        Close_Date DATE NULL,
        Is_Active BIT NOT NULL DEFAULT 1,

        -- Geography
        Town VARCHAR(150) NULL,          -- Matches staging
        Postcode VARCHAR(20) NULL,       -- Matches staging

        -- SCD Type 1
        Valid_From DATE NOT NULL DEFAULT '1900-01-01',
        Is_Current BIT NOT NULL DEFAULT 1,

        -- Audit
        Source_System VARCHAR(50) DEFAULT 'NHS ODS',
        Created_By VARCHAR(128) NULL DEFAULT SYSTEM_USER,
        Created_Date DATETIME2 NOT NULL DEFAULT GETDATE(),
        Updated_Date DATETIME2 NULL,
        Updated_By VARCHAR(128) NULL,

        -- CONSTRAINT
        CONSTRAINT [PK_Dim_PCN] PRIMARY KEY NONCLUSTERED (SK_PCNID ASC)
    ) ON [PRIMARY];

    -- CLUSTERED COLUMNSTORE INDEX (Modern Standard)
    CREATE CLUSTERED COLUMNSTORE INDEX [CCI_Dim_PCN] ON [Analytics].[tbl_Dim_PCN];

    PRINT '[OK] Created table: [Analytics].[tbl_Dim_PCN]';
    PRINT '[OK] Created Clustered Columnstore Index: [CCI_Dim_PCN]';

    ---------------------------------------------------------------------------
    -- Insert default "Unknown" member (SK = -1)
    ---------------------------------------------------------------------------

    SET IDENTITY_INSERT [Analytics].[tbl_Dim_PCN] ON;

    INSERT INTO [Analytics].[tbl_Dim_PCN]
        (SK_PCNID, PCN_Code, PCN_Name, ICB_Code, ICB_Name, Is_Active, Valid_From, Is_Current)
    VALUES
        (-1, 'UNK', 'Unknown PCN', 'UNK', 'Unknown ICB', 1, '1900-01-01', 1);

    SET IDENTITY_INSERT [Analytics].[tbl_Dim_PCN] OFF;

    PRINT '[OK] Inserted default "Unknown" member (SK_PCNID = -1)';

    ---------------------------------------------------------------------------
    -- Create indexes
    ---------------------------------------------------------------------------

    CREATE NONCLUSTERED INDEX IX_Dim_PCN_Code
        ON [Analytics].[tbl_Dim_PCN](PCN_Code)
        INCLUDE (PCN_Name, ICB_Code);

    CREATE NONCLUSTERED INDEX IX_Dim_PCN_ICB
        ON [Analytics].[tbl_Dim_PCN](ICB_Code, Is_Current)
        INCLUDE (PCN_Code, PCN_Name);

    PRINT '[OK] Created indexes';

    ---------------------------------------------------------------------------
    -- Enforce natural key uniqueness for current records
    ---------------------------------------------------------------------------

    CREATE UNIQUE NONCLUSTERED INDEX UX_Dim_PCN_Code_Current
        ON [Analytics].[tbl_Dim_PCN](PCN_Code)
        WHERE Is_Current = 1;

    PRINT '[OK] Created unique index: UX_Dim_PCN_Code_Current';
END
ELSE
BEGIN
    PRINT '[SKIP] Table [Analytics].[tbl_Dim_PCN] already exists - preserving surrogate keys';
END
GO

PRINT '';
PRINT '========================================';
PRINT 'Dim_PCN Creation Complete';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
PRINT 'Current Row Count:';
SELECT COUNT(*) as Row_Count FROM [Analytics].[tbl_Dim_PCN];
PRINT '';
GO

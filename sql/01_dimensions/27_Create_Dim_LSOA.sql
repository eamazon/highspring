USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating Dim_LSOA';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

-------------------------------------------------------------------------------
-- Create table IF NOT EXISTS (preserves surrogate keys on re-run)
-------------------------------------------------------------------------------

IF OBJECT_ID('[Analytics].[tbl_Dim_LSOA]', 'U') IS NULL
BEGIN
    PRINT 'Creating table [Analytics].[tbl_Dim_LSOA]...';

    /**
    Script Name:   27_Create_Dim_LSOA.sql
    Description:   LSOA dimension using [ref].[tbl_LSOA_ICB_CA_LocalAuthority] as the source.
                   Provides LSOA to Local Authority, Sub-ICB, ICB, and Cancer Alliance mappings.
    Author:        Sridhar Peddi
    Created:       2026-01-12

    Change Log:
      2026-01-12  Sridhar Peddi    Initial creation
      2026-01-27  Sridhar Peddi    Add IMD 2019 supplementary indices (IDACI, IDAOPI)
      2026-01-28  Sridhar Peddi    Changed to CREATE IF NOT EXISTS pattern (preserves SKs)
    **/
    CREATE TABLE [Analytics].[tbl_Dim_LSOA]
    (
        -- Surrogate key
        SK_LSOA_ID INT IDENTITY(1,1) NOT NULL,

        -- Natural key
        LSOA_Code VARCHAR(9) NOT NULL,
        LSOA_Name VARCHAR(100) NULL,

        -- Sub-ICB mapping
        SubICB_Code VARCHAR(50) NULL,
        SubICB_Hierarchy_Code VARCHAR(50) NULL,
        SubICB_Name VARCHAR(100) NULL,

        -- ICB mapping
        ICB_Code VARCHAR(50) NULL,
        ICB_Hierarchy_Code VARCHAR(50) NULL,
        ICB_Name VARCHAR(150) NULL,

        -- Cancer Alliance mapping
        CancerAlliance_Code VARCHAR(50) NULL,
        CancerAlliance_Name VARCHAR(100) NULL,

        -- Local Authority mapping
        LocalAuthority_Code VARCHAR(50) NULL,
        LocalAuthority_Name VARCHAR(100) NULL,

        -- IMD 2019 supplementary indices
        IMD_Year SMALLINT NULL,
        IMD_Rank INT NULL,
        IMD_Decile TINYINT NULL,
        IDACI_Score DECIMAL(9,6) NULL,
        IDACI_Rank INT NULL,
        IDACI_Decile TINYINT NULL,
        IDAOPI_Score DECIMAL(9,6) NULL,
        IDAOPI_Rank INT NULL,
        IDAOPI_Decile TINYINT NULL,

        -- Computed display column
        LSOA_Display AS (LSOA_Code + ' - ' + ISNULL(LSOA_Name, 'Unknown')),

        -- Audit columns
        Source_System VARCHAR(50) DEFAULT 'ref.tbl_LSOA_ICB_CA_LocalAuthority',
        Created_By VARCHAR(128) NULL DEFAULT SYSTEM_USER,
        Created_Date DATETIME2 NOT NULL DEFAULT GETDATE(),
        Updated_Date DATETIME2 NULL,
        Updated_By VARCHAR(128) NULL,

        -- Constraints
        CONSTRAINT [PK_Dim_LSOA] PRIMARY KEY NONCLUSTERED ([SK_LSOA_ID] ASC),
        CONSTRAINT [UQ_Dim_LSOA_Code] UNIQUE NONCLUSTERED (LSOA_Code)
    ) ON [PRIMARY];

    -- CLUSTERED COLUMNSTORE INDEX
    CREATE CLUSTERED COLUMNSTORE INDEX [CCI_Dim_LSOA] ON [Analytics].[tbl_Dim_LSOA];

    PRINT '[OK] Created table: [Analytics].[tbl_Dim_LSOA]';

    ---------------------------------------------------------------------------
    -- Insert default "Unknown" member (SK = -1)
    ---------------------------------------------------------------------------

    SET IDENTITY_INSERT [Analytics].[tbl_Dim_LSOA] ON;

    INSERT INTO [Analytics].[tbl_Dim_LSOA]
        (SK_LSOA_ID, LSOA_Code, LSOA_Name, SubICB_Code, SubICB_Name, ICB_Code, ICB_Name,
         CancerAlliance_Code, CancerAlliance_Name, LocalAuthority_Code, LocalAuthority_Name,
         IMD_Year, IMD_Rank, IMD_Decile, IDACI_Score, IDACI_Rank, IDACI_Decile, IDAOPI_Score, IDAOPI_Rank, IDAOPI_Decile)
    VALUES
        (-1, 'UNKNOWN', 'Unknown LSOA', 'UNK', 'Unknown Sub-ICB', 'UNK', 'Unknown ICB',
         'UNK', 'Unknown Cancer Alliance', 'UNK', 'Unknown Local Authority',
         NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

    SET IDENTITY_INSERT [Analytics].[tbl_Dim_LSOA] OFF;

    PRINT '[OK] Inserted default "Unknown" member (SK_LSOA_ID = -1)';

    ---------------------------------------------------------------------------
    -- Indexes for common filters
    ---------------------------------------------------------------------------

    CREATE NONCLUSTERED INDEX IX_Dim_LSOA_SubICB
        ON [Analytics].[tbl_Dim_LSOA](SubICB_Code)
        INCLUDE (LSOA_Code, LSOA_Name, SubICB_Name);

    CREATE NONCLUSTERED INDEX IX_Dim_LSOA_ICB
        ON [Analytics].[tbl_Dim_LSOA](ICB_Code)
        INCLUDE (LSOA_Code, LSOA_Name, ICB_Name);

    CREATE NONCLUSTERED INDEX IX_Dim_LSOA_LocalAuthority
        ON [Analytics].[tbl_Dim_LSOA](LocalAuthority_Code)
        INCLUDE (LSOA_Code, LSOA_Name, LocalAuthority_Name);

    PRINT '[OK] Created indexes';
END
ELSE
BEGIN
    PRINT '[SKIP] Table [Analytics].[tbl_Dim_LSOA] already exists - preserving surrogate keys';
END
GO

PRINT '';
PRINT '========================================';
PRINT 'Dim_LSOA Creation Complete';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
PRINT 'Current Row Count:';
SELECT COUNT(*) as Row_Count FROM [Analytics].[tbl_Dim_LSOA];
PRINT '';
GO

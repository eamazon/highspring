

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating Dim_Commissioner';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

-------------------------------------------------------------------------------
-- Create table IF NOT EXISTS (preserves surrogate keys on re-run)
-------------------------------------------------------------------------------

IF OBJECT_ID('[Analytics].[tbl_Dim_Commissioner]', 'U') IS NULL
BEGIN
    PRINT 'Creating table [Analytics].[tbl_Dim_Commissioner]...';

    /**
    Script Name:   01_Create_Dim_Commissioner.sql
    Description:   NHS Commissioner dimension tracking ICBs, Sub-ICBs, and legacy CCGs with SCD Type 1.
                   Supports SWL attribution logic, POD team mapping, and organizational hierarchy.
                   Includes transition tracking for CCG to Sub-ICB changes (July 2022).
    Author:        Sridhar Peddi
    Created:       2026-01-02

    Change Log:
      2026-01-02   Sridhar Peddi    Initial creation
      2026-01-28   Sridhar Peddi    Changed to CREATE IF NOT EXISTS pattern (preserves SKs)
    **/
    CREATE TABLE [Analytics].[tbl_Dim_Commissioner]
    (
        -- Surrogate key (artificial ID number, independent of business data)
        SK_CommissionerID INT IDENTITY(1,1) NOT NULL,

        -- Natural key (the real business identifier from source data)
        Commissioner_Code VARCHAR(12) NOT NULL,

        -- Descriptive attributes
        Commissioner_Name VARCHAR(255) NULL,
        ICB_Code VARCHAR(12) NULL,
        ICB_Name VARCHAR(255) NULL,

        -- SWL ICB flag (for easy filtering to local commissioners)
        Is_SWL_ICB BIT NOT NULL DEFAULT 0,

        -- CAM attribution metadata
        CAM_Attribution_Method VARCHAR(50) NULL,  -- 'GP', 'Postcode', 'Provider', etc.

        -- POD (Point of Delivery) team information (from legacy v2 pattern)
        SK_PODTeamID TINYINT NULL,
        PODTeam_Code VARCHAR(50) NULL,
        PODTeam_Name VARCHAR(100) NULL,

        -- Sub-ICB location information (current NHS structure)
        SubICB_Code VARCHAR(10) NULL,
        SubICB_Name VARCHAR(255) NULL,
        SubICB_Location_Name VARCHAR(255) NULL,  -- More granular locality within Sub-ICB

        -- Code transition tracking (CCG to Sub-ICB transition, July 2022)
        Commissioner_Type VARCHAR(50) NULL,      -- 'CCG (Legacy)', 'Sub-ICB', 'Sub-ICB (former CCG)', 'ICB'
        Transition_Date DATE NULL,               -- Date of organizational change (e.g., '2022-07-01' for CCG->Sub-ICB)
        ODS_Role_Code VARCHAR(10) NULL,          -- NHS ODS Primary Role: RO98=CCG/Sub-ICB, RO207=ICB
        Legacy_Commissioner_Name VARCHAR(255) NULL, -- Original name before transition (e.g., 'NHS South West London CCG')

        -- SCD Type 1 placeholders (for future SCD Type 2 upgrade to track history)
        Valid_From DATE NOT NULL DEFAULT '1900-01-01',
        Valid_To DATE NULL DEFAULT '9999-12-31',
        Is_Current BIT NOT NULL DEFAULT 1,

        -- Audit columns (for troubleshooting)
        Source_System VARCHAR(50) DEFAULT 'CAM',
        Created_By VARCHAR(128) NULL DEFAULT SYSTEM_USER,
        Created_Date DATETIME2 NOT NULL DEFAULT GETDATE(),
        Updated_Date DATETIME2 NULL,
        Updated_By VARCHAR(128) NULL,

        -- CONSTRAINT
        CONSTRAINT [PK_Dim_Commissioner] PRIMARY KEY NONCLUSTERED ([SK_CommissionerID] ASC),
        CONSTRAINT UQ_Dim_Commissioner UNIQUE NONCLUSTERED (Commissioner_Code)
    ) ON [PRIMARY];

    -- CLUSTERED COLUMNSTORE INDEX (Modern Standard)
    CREATE CLUSTERED COLUMNSTORE INDEX [CCI_Dim_Commissioner] ON [Analytics].[tbl_Dim_Commissioner];

    PRINT '[OK] Created table: [Analytics].[tbl_Dim_Commissioner]';

    ---------------------------------------------------------------------------
    -- Insert default "Unknown" member (ID = -1)
    -- This prevents broken joins when source data is missing
    ---------------------------------------------------------------------------

    SET IDENTITY_INSERT [Analytics].[tbl_Dim_Commissioner] ON;

    INSERT INTO [Analytics].[tbl_Dim_Commissioner]
        (SK_CommissionerID, Commissioner_Code, Commissioner_Name,
         Is_SWL_ICB, SK_PODTeamID, PODTeam_Code, PODTeam_Name,
         SubICB_Code, SubICB_Name, SubICB_Location_Name,
         Commissioner_Type, Transition_Date, ODS_Role_Code, Legacy_Commissioner_Name,
         Valid_From, Is_Current)
    VALUES
        (-1, '0UNK', 'Unknown Commissioner',
         0, 0, 'UNKNOWN', 'UNKNOWN',
         'UNKNOWN', 'UNKNOWN', 'UNKNOWN',
         'Unknown', NULL, NULL, NULL,
         '1900-01-01', 1);

    PRINT '[OK] Inserted default "Unknown" member (SK_CommissionerID = -1)';

    ---------------------------------------------------------------------------
    -- Insert "Unassigned" member (ID = -2)
    -- For cases where attribution hasn't been determined yet
    ---------------------------------------------------------------------------

    INSERT INTO [Analytics].[tbl_Dim_Commissioner]
        (SK_CommissionerID, Commissioner_Code, Commissioner_Name,
         Is_SWL_ICB, SK_PODTeamID, PODTeam_Code, PODTeam_Name,
         SubICB_Code, SubICB_Name, SubICB_Location_Name,
         Commissioner_Type, Transition_Date, ODS_Role_Code, Legacy_Commissioner_Name,
         Valid_From, Is_Current)
    VALUES
        (-2, 'UNASSIGNED', 'Unassigned Commissioner',
         0, 0, 'UNKNOWN', 'UNKNOWN',
         'UNKNOWN', 'UNKNOWN', 'UNKNOWN',
         'Unknown', NULL, NULL, NULL,
         '1900-01-01', 1);

    SET IDENTITY_INSERT [Analytics].[tbl_Dim_Commissioner] OFF;

    PRINT '[OK] Inserted "Unassigned" member (SK_CommissionerID = -2)';

    ---------------------------------------------------------------------------
    -- Create nonclustered index on Is_SWL_ICB for common filtering
    ---------------------------------------------------------------------------

    CREATE NONCLUSTERED INDEX IX_Dim_Commissioner_SWL
        ON [Analytics].[tbl_Dim_Commissioner](Is_SWL_ICB)
        INCLUDE (Commissioner_Code, Commissioner_Name);

    PRINT '[OK] Created index: IX_Dim_Commissioner_SWL';
END
ELSE
BEGIN
    PRINT '[SKIP] Table [Analytics].[tbl_Dim_Commissioner] already exists - preserving surrogate keys';
END
GO

PRINT '';
PRINT '========================================';
PRINT 'Dim_Commissioner Creation Complete';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
PRINT 'Current Row Count:';
SELECT COUNT(*) as Row_Count FROM [Analytics].[tbl_Dim_Commissioner];
PRINT '';
GO

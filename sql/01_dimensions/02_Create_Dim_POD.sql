

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating Dim_POD';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

-------------------------------------------------------------------------------
-- Drop existing table if exists
-------------------------------------------------------------------------------

IF OBJECT_ID('[Analytics].[tbl_Dim_POD]', 'U') IS NOT NULL
BEGIN
    PRINT 'Table [Analytics].[tbl_Dim_POD] already exists. Dropping...';
    DROP TABLE [Analytics].[tbl_Dim_POD];
END
GO

-------------------------------------------------------------------------------
-- Create Dim_POD table
-------------------------------------------------------------------------------

/**
Script Name:   02_Create_Dim_POD.sql
Description:   Point of Delivery (POD) dimension defining NHS activity categories and metrics.
               4-level hierarchy: Domain → Subcategory → Measure → Description.
               Supports unified reporting across IP/OP/AE activity types with legacy compatibility.
Author:        Sridhar Peddi
Created:       2026-01-02

Change Log:
  2026-01-02   Sridhar Peddi    Initial creation
**/
CREATE TABLE [Analytics].[tbl_Dim_POD]
(
    -- Surrogate key (artificial ID number)
    SK_PodID INT IDENTITY(1,1) NOT NULL,
    
    -- Natural key (VARCHAR - matches IP.GetPodType and OP.GetPodType return values)
    POD_Code VARCHAR(20) NOT NULL,           -- 'NEL', 'OPFASPCL', 'DNA', 'AE', etc.
    
    -- NHS Taxonomy Hierarchy (4 levels for Power BI drill-down)
    POD_Domain VARCHAR(100) NULL,            -- Level 1: "Admitted Patient Care", "Outpatient", "A&E"
    POD_Subcategory VARCHAR(100) NULL,       -- Level 2: "Non-elective", "First Attendance", "Procedures"
    POD_Measure VARCHAR(50) NULL,            -- Level 3: "SPELL", "ATT", "OBD", "FCE", "HRG Count"
    POD_Description VARCHAR(500) NULL,       -- Level 4: Full text description
    
    -- Computed display column (for Power BI labels)
    POD_Display AS (POD_Code + ' - ' + ISNULL(POD_Description, 'Unknown')),
    
    -- Legacy hierarchy columns (for backward compatibility with Dictionary.dbo.PODGroups)
    POD_Dataset VARCHAR(50) NULL,            -- Simplified: 'IP', 'OP', 'AE', 'Other', 'Unbundled', 'Non-Activity'
    POD_MainGroup VARCHAR(100) NULL,         -- Mid-level classification
    POD_SubGroup VARCHAR(255) NULL,          -- Granular classification (same as POD_Description)
    
    -- Derived category for simplified reporting
    POD_Category VARCHAR(50) NULL,           -- 'Admitted', 'Outpatient', 'A&E', 'Other'
    
    -- Boolean classification flags (for fast WHERE clause filtering)
    Is_Elective BIT NULL,                    -- TRUE for planned care
    Is_Emergency BIT NULL,                   -- TRUE for unplanned care
    Is_Admitted BIT NULL,                    -- TRUE for IP activity (Dataset = 'IP')
    Is_Outpatient BIT NULL,                  -- TRUE for OP activity (Dataset = 'OP')
    Is_AE BIT NULL,                          -- TRUE for A&E activity (Dataset = 'AE')
    
    -- Audit columns
    Source_System VARCHAR(50) DEFAULT 'NHS England POD Taxonomy',
    Created_By VARCHAR(128) NULL DEFAULT SYSTEM_USER,
    Created_Date DATETIME2 NOT NULL DEFAULT GETDATE(),
    Updated_Date DATETIME2 NULL,
    Updated_By VARCHAR(128) NULL,
    
    -- Constraints
    CONSTRAINT [PK_Dim_POD] PRIMARY KEY NONCLUSTERED ([SK_PodID] ASC),
    CONSTRAINT UQ_Dim_POD_Code UNIQUE NONCLUSTERED (POD_Code)
) ON [PRIMARY];
GO

-- CLUSTERED COLUMNSTORE INDEX (Modern Standard)
CREATE CLUSTERED COLUMNSTORE INDEX [CCI_Dim_POD] ON [Analytics].[tbl_Dim_POD];
GO

PRINT '[OK] Created table: [Analytics].[tbl_Dim_POD]';
GO

-------------------------------------------------------------------------------
-- Insert default "Unknown" member (SK = -1)
-------------------------------------------------------------------------------

SET IDENTITY_INSERT [Analytics].[tbl_Dim_POD] ON;

INSERT INTO [Analytics].[tbl_Dim_POD] 
    (SK_PodID, POD_Code, POD_Domain, POD_Subcategory, POD_Measure, POD_Description,
     POD_Dataset, POD_MainGroup, POD_SubGroup, POD_Category,
     Is_Elective, Is_Emergency, Is_Admitted, Is_Outpatient, Is_AE)
VALUES 
    (-1, 'UNKNOWN', 'Unknown', 'Unknown', NULL, 'Unknown POD',
     'Unknown', 'Unknown', 'Unknown', 'Unknown',
     NULL, NULL, 0, 0, 0);

SET IDENTITY_INSERT [Analytics].[tbl_Dim_POD] OFF;

PRINT '[OK] Inserted default "Unknown" member (SK_PodID = -1)';
GO

-------------------------------------------------------------------------------
-- Create indexes for performance
-------------------------------------------------------------------------------

-- Index on POD_Domain for top-level filtering
CREATE NONCLUSTERED INDEX IX_Dim_POD_Domain 
    ON [Analytics].[tbl_Dim_POD](POD_Domain) 
    INCLUDE (POD_Code, POD_Subcategory, POD_Measure);
GO

PRINT '[OK] Created index: IX_Dim_POD_Domain';
GO

-- Index on POD_Dataset for legacy compatibility
CREATE NONCLUSTERED INDEX IX_Dim_POD_Dataset 
    ON [Analytics].[tbl_Dim_POD](POD_Dataset) 
    INCLUDE (POD_Code, POD_MainGroup);
GO

PRINT '[OK] Created index: IX_Dim_POD_Dataset';
GO

-- Index on POD_Category for simplified reporting
CREATE NONCLUSTERED INDEX IX_Dim_POD_Category 
    ON [Analytics].[tbl_Dim_POD](POD_Category) 
    INCLUDE (POD_Code, POD_Description);
GO

PRINT '[OK] Created index: IX_Dim_POD_Category';
GO

-- Index on boolean flags for filtering (covering index)
CREATE NONCLUSTERED INDEX IX_Dim_POD_Flags 
    ON [Analytics].[tbl_Dim_POD](Is_Elective, Is_Emergency, Is_Admitted, Is_Outpatient, Is_AE) 
    INCLUDE (POD_Code, POD_Description);
GO

PRINT '[OK] Created index: IX_Dim_POD_Flags';
GO

PRINT '';
PRINT '========================================';
PRINT 'Dim_POD Creation Complete';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
PRINT 'Summary:';
PRINT '  [OK] Table created with 4-level NHS taxonomy hierarchy';
PRINT '  [OK] POD_Code as VARCHAR(20) - matches function return values';
PRINT '  [OK] POD_Display computed column for clean labels';
PRINT '  [OK] Default "Unknown" member inserted (SK = -1)';
PRINT '  [OK] 4 Indexes created for performance';
PRINT '';
PRINT 'NHS Taxonomy Hierarchy (Power BI drill-down):';
PRINT '  Level 1: POD_Domain       - Admitted Patient Care, Outpatient, A&E, etc.';
PRINT '  Level 2: POD_Subcategory  - Non-elective, First Attendance, etc.';
PRINT '  Level 3: POD_Measure      - SPELL, ATT, OBD, FCE, etc.';
PRINT '  Level 4: POD_Code         - NEL, OPFASPCL, AE, etc.';
PRINT '';
PRINT 'Next Steps:';
PRINT '  1. Run 05_Populate_Dim_POD.sql to insert all NHS taxonomy codes';
PRINT '  2. POD codes will match values returned by IP.GetPodType and OP.GetPodType';
PRINT '  3. Use POD_Display column in Power BI for clean labels';
PRINT '';
GO



USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating NHS ODS Staging Table';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

-------------------------------------------------------------------------------
-- Drop existing table if exists
-------------------------------------------------------------------------------

IF OBJECT_ID('[Analytics].[tbl_Staging_NHS_ODS_Commissioner]', 'U') IS NOT NULL
BEGIN
    PRINT 'Table [Analytics].[tbl_Staging_NHS_ODS_Commissioner] already exists. Dropping...';
    DROP TABLE [Analytics].[tbl_Staging_NHS_ODS_Commissioner];
END
GO

-------------------------------------------------------------------------------
-- Create staging table (matches ODS API structure)
-------------------------------------------------------------------------------

/**
Script Name:   04_Create_Staging_NHS_ODS.sql
Description:   Create staging table for NHS Organisation Data Service (ODS) data
Author:        Sridhar Peddi
Created:       2026-01-02

Change Log:
  2026-01-02  Sridhar Peddi    Initial creation
**/
CREATE TABLE [Analytics].[tbl_Staging_NHS_ODS_Commissioner]
(
    -- Surrogate key for staging table
    Staging_ID INT IDENTITY(1,1) NOT NULL,
    
    -- Organization identification (from ODS API)
    Commissioner_Code VARCHAR(12) NOT NULL,        -- ODS OrgId.extension (e.g., '36L', '07V')
    Commissioner_Name VARCHAR(255) NOT NULL,       -- Organization.Name
    Status VARCHAR(20) NULL,                       -- Organization.Status (Active/Inactive)
    
    -- Organization type classification (derived from roles)
    Commissioner_Type VARCHAR(50) NULL,            -- 'ICB', 'Sub-ICB Location', 'CCG (Legacy)'
    ODS_Role_Code VARCHAR(10) NULL,                -- Primary role (RO98, RO207, etc.)
    Additional_Roles VARCHAR(255) NULL,            -- Comma-separated additional roles (RO319, RO326)
    
    -- Effective dates (from ODS API)
    Operational_Start_Date DATE NULL,              -- Date.Type=Operational.Start
    Operational_End_Date DATE NULL,                -- Date.Type=Operational.End
    Legal_Start_Date DATE NULL,                    -- Date.Type=Legal.Start
    Legal_End_Date DATE NULL,                      -- Date.Type=Legal.End
    Transition_Date DATE NULL,                     -- Date when RO319 role added (CCG→Sub-ICB)
    Last_Change_Date DATE NULL,                    -- Organization.LastChangeDate
    
    -- Location details
    Address_Line1 VARCHAR(255) NULL,
    Address_Line2 VARCHAR(255) NULL,
    Address_Line3 VARCHAR(255) NULL,
    Town VARCHAR(100) NULL,
    County VARCHAR(100) NULL,
    Postcode VARCHAR(15) NULL,
    Country VARCHAR(50) NULL,
    
    -- Relationship tracking (predecessor organizations)
    Predecessor_Codes VARCHAR(500) NULL,           -- Comma-separated list of predecessor codes
    Predecessor_Count INT NULL,                    -- Number of organizations that merged
    Successor_Code VARCHAR(12) NULL,               -- If this org merged into another
    
    -- Parent organization (ICB for Sub-ICB Locations)
    Parent_ICB_Code VARCHAR(12) NULL,              -- Relationship target (RE5)
    Parent_ICB_Name VARCHAR(255) NULL,
    
    -- API metadata
    ODS_URI VARCHAR(500) NULL,                     -- Full ODS URI from API
    API_Fetch_Date DATETIME2 NOT NULL DEFAULT GETDATE(),  -- When record was fetched
    API_Version VARCHAR(20) NULL DEFAULT '2-0-0',  -- ODS API version used
    
    -- ETL tracking
    Is_Processed BIT NOT NULL DEFAULT 0,           -- Has this been loaded to Dim_Commissioner?
    Process_Date DATETIME2 NULL,                   -- When loaded to dimension
    Validation_Status VARCHAR(50) NULL,            -- 'Valid', 'Invalid', 'Duplicate', 'Ignored'
    Validation_Notes VARCHAR(MAX) NULL,            -- Any data quality issues found
    
    -- Constraints
    CONSTRAINT PK_Staging_NHS_ODS PRIMARY KEY CLUSTERED (Staging_ID),
    CONSTRAINT UQ_Staging_NHS_ODS_Code_Fetch UNIQUE NONCLUSTERED (Commissioner_Code, API_Fetch_Date)
);
GO

PRINT '[OK] Created table: [Analytics].[tbl_Staging_NHS_ODS_Commissioner]';
GO

-------------------------------------------------------------------------------
-- Create indexes for ETL queries
-------------------------------------------------------------------------------

-- Index on Commissioner_Code for lookups
CREATE NONCLUSTERED INDEX IX_Staging_ODS_Code 
    ON [Analytics].[tbl_Staging_NHS_ODS_Commissioner](Commissioner_Code) 
    INCLUDE (Commissioner_Name, Status, Commissioner_Type);
GO

PRINT '[OK] Created index: IX_Staging_ODS_Code';
GO

-- Index on Status for filtering active/inactive
CREATE NONCLUSTERED INDEX IX_Staging_ODS_Status 
    ON [Analytics].[tbl_Staging_NHS_ODS_Commissioner](Status, Is_Processed) 
    INCLUDE (Commissioner_Code);
GO

PRINT '[OK] Created index: IX_Staging_ODS_Status';
GO

-- Index on processing status for ETL
CREATE NONCLUSTERED INDEX IX_Staging_ODS_Processed 
    ON [Analytics].[tbl_Staging_NHS_ODS_Commissioner](Is_Processed, Validation_Status);
GO

PRINT '[OK] Created index: IX_Staging_ODS_Processed';
GO

PRINT '';
PRINT '========================================';
PRINT 'NHS ODS Staging Table Creation Complete';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
PRINT 'Summary:';
PRINT '  [OK] Staging table created for ODS API data';
PRINT '  [OK] 3 Indexes created for ETL performance';
PRINT '  [OK] Audit columns for tracking fetch/process cycles';
PRINT '';
PRINT 'Next Steps:';
PRINT '  1. Run Python script to fetch ODS data:';
PRINT '     python scripts/data_integration/nhs_ods/fetch_commissioners.py --output staging';
PRINT '  2. Review staging data:';
PRINT '     SELECT * FROM [Analytics].[tbl_Staging_NHS_ODS_Commissioner] ORDER BY Commissioner_Code;';
PRINT '  3. Create ETL procedure to load from staging to Dim_Commissioner';
PRINT '';
PRINT 'Data Flow:';
PRINT '  NHS ODS API → Python Script → Staging Table → ETL Procedure → Dim_Commissioner';
PRINT '';
GO

-------------------------------------------------------------------------------
-- Staging: GP Practice
-------------------------------------------------------------------------------

IF OBJECT_ID('[Analytics].[tbl_Staging_GP_Practice]', 'U') IS NOT NULL
    DROP TABLE [Analytics].[tbl_Staging_GP_Practice];
GO

CREATE TABLE [Analytics].[tbl_Staging_GP_Practice]
(
    Practice_Code VARCHAR(10),
    Practice_Name VARCHAR(255),
    Status VARCHAR(50),
    Prescribing_Setting VARCHAR(255),    -- Col 26 from epraccur
    Org_Sub_Type VARCHAR(5),             -- Col 14 from epraccur
    Address_Line1 VARCHAR(255),
    Address_Line2 VARCHAR(255),
    Address_Line3 VARCHAR(255),
    Town VARCHAR(255),
    Postcode VARCHAR(20),
    Contact_Telephone VARCHAR(50),
    PCN_Code VARCHAR(10),
    PCN_Name VARCHAR(255),
    Commissioner_Code VARCHAR(10),       -- Col 15: Sub-ICB Location Code
    Commissioner_Name VARCHAR(255),      -- Sub-ICB Name (may need lookup)
    ICB_Code VARCHAR(10),                -- Col 4: ICB Code from epraccur!
    ICB_Name VARCHAR(255),               -- ICB Name (may need lookup)
    Open_Date DATE,
    Close_Date DATE
);
GO

PRINT '[OK] Created tbl_Staging_GP_Practice';
GO

-------------------------------------------------------------------------------
-- Staging: PCN
-------------------------------------------------------------------------------

IF OBJECT_ID('[Analytics].[tbl_Staging_PCN]', 'U') IS NOT NULL
    DROP TABLE [Analytics].[tbl_Staging_PCN];
GO

CREATE TABLE [Analytics].[tbl_Staging_PCN]
(
    PCN_Code VARCHAR(12),
    PCN_Name VARCHAR(100),
    Sub_ICB_Code VARCHAR(12),        -- Current Sub ICB Location Code
    Sub_ICB_Name VARCHAR(100),        -- Sub ICB Location Name
    Open_Date DATE,
    Close_Date DATE,
    Address1 VARCHAR(75),
    Address2 VARCHAR(75),
    Address3 VARCHAR(75),
    Town VARCHAR(75),
    Postcode VARCHAR(15)
);
GO

PRINT '[OK] Created tbl_Staging_PCN';
GO

-------------------------------------------------------------------------------
-- Staging Table: POD (Point of Delivery)
-------------------------------------------------------------------------------
IF OBJECT_ID('[Analytics].[Staging_POD]', 'U') IS NOT NULL
BEGIN
    PRINT 'Table [Analytics].[Staging_POD] already exists. Dropping...';
    DROP TABLE [Analytics].[Staging_POD];
END
GO

CREATE TABLE [Analytics].[Staging_POD]
(
    POD_Code VARCHAR(20) NOT NULL,
    POD_Domain VARCHAR(100) NOT NULL,
    POD_Subcategory VARCHAR(100) NOT NULL,
    POD_Measure VARCHAR(50) NOT NULL,
    POD_Description VARCHAR(255) NOT NULL
);
GO

PRINT '[OK] Created Staging_POD';
PRINT '[OK] All Staging Tables Created';
GO

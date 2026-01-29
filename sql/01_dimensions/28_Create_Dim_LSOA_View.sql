USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating vw_Dim_LSOA VIEW';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

-- Drop old naming conventions
IF OBJECT_ID('[Analytics].[Dim_LSOA]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[Dim_LSOA] already exists. Dropping...';
    DROP VIEW [Analytics].[Dim_LSOA];
END
GO

IF OBJECT_ID('[Analytics].[tbl_Dim_LSOA]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[tbl_Dim_LSOA] already exists. Dropping...';
    DROP VIEW [Analytics].[tbl_Dim_LSOA];
END
GO

IF OBJECT_ID('[Analytics].[vw_Dim_LSOA]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[vw_Dim_LSOA] already exists. Dropping...';
    DROP VIEW [Analytics].[vw_Dim_LSOA];
END
GO

/**
Script Name:   28_Create_Dim_LSOA_View.sql
Description:   LSOA dimension view for consistent access to LSOA, Local Authority,
               Sub-ICB, ICB, and Cancer Alliance attributes.
Author:        Sridhar Peddi
Created:       2026-01-12

Change Log:
  2026-01-12  Sridhar Peddi    Initial creation
  2026-01-27  Sridhar Peddi    Add IMD 2019 supplementary indices
**/
CREATE VIEW [Analytics].[vw_Dim_LSOA] AS
SELECT
    SK_LSOA_ID,
    LSOA_Code,
    LSOA_Name,
    SubICB_Code,
    SubICB_Hierarchy_Code,
    SubICB_Name,
    ICB_Code,
    ICB_Hierarchy_Code,
    ICB_Name,
    CancerAlliance_Code,
    CancerAlliance_Name,
    LocalAuthority_Code,
    LocalAuthority_Name,
    IMD_Year,
    IMD_Rank,
    IMD_Decile,
    IDACI_Score,
    IDACI_Rank,
    IDACI_Decile,
    IDAOPI_Score,
    IDAOPI_Rank,
    IDAOPI_Decile,
    LSOA_Display
FROM [Analytics].[tbl_Dim_LSOA];
GO

PRINT '[OK] Created view: [Analytics].[vw_Dim_LSOA]';
GO

PRINT '';
PRINT 'Validation: Sample data from view';
SELECT TOP 5 * FROM [Analytics].[vw_Dim_LSOA];
GO

PRINT '';
PRINT '========================================';
PRINT 'vw_Dim_LSOA VIEW Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO



USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating vw_Dim_Ethnicity VIEW';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

-- Drop old naming conventions
IF OBJECT_ID('[Analytics].[Dim_Ethnicity]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[Dim_Ethnicity] already exists. Dropping...';
    DROP VIEW [Analytics].[Dim_Ethnicity];
END
GO

IF OBJECT_ID('[Analytics].[tbl_Dim_Ethnicity]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[tbl_Dim_Ethnicity] already exists. Dropping...';
    DROP VIEW [Analytics].[tbl_Dim_Ethnicity];
END
GO

IF OBJECT_ID('[Analytics].[vw_Dim_Ethnicity]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[vw_Dim_Ethnicity] already exists. Dropping...';
    DROP VIEW [Analytics].[vw_Dim_Ethnicity];
END
GO

/**
Script Name:   19_Create_Dim_Ethnicity.sql
Description:   Patient ethnicity dimension using NHS HES 16+1 categories (inline reference list).
               Supports equality monitoring, health inequality analysis, and CORE20PLUS5 segmentation.
               Maps to short descriptions for reporting and joins on EthnicityCode.
Author:        Sridhar Peddi
Created:       2026-01-09

Change Log:
  2026-01-09   Sridhar Peddi    Initial creation
  2026-01-12   Sridhar Peddi    Replace Dictionary dependency with inline HES code list
**/
CREATE VIEW [Analytics].[vw_Dim_Ethnicity] AS
WITH Ethnicity_Source AS (
    SELECT
        v.SK_EthnicityID,
        v.EthnicityCode,
        v.EthnicityDesc,
        v.EthnicityShortDesc
    FROM (VALUES
        -- WHITE
        (1,  'A',  'White - British',                                    'White British'),
        (2,  'B',  'White - Irish',                                      'White Irish'),
        (3,  'C',  'White - Any other White background',                 'White Other'),

        -- MIXED
        (4,  'D',  'Mixed - White and Black Caribbean',                  'Mixed White/Black Caribbean'),
        (5,  'E',  'Mixed - White and Black African',                    'Mixed White/Black African'),
        (6,  'F',  'Mixed - White and Asian',                            'Mixed White/Asian'),
        (7,  'G',  'Mixed - Any other mixed background',                 'Mixed Other'),

        -- ASIAN
        (8,  'H',  'Asian or Asian British - Indian',                    'Asian Indian'),
        (9,  'J',  'Asian or Asian British - Pakistani',                 'Asian Pakistani'),
        (10, 'K',  'Asian or Asian British - Bangladeshi',               'Asian Bangladeshi'),
        (11, 'L',  'Asian or Asian British - Any other Asian background','Asian Other'),

        -- BLACK
        (12, 'M',  'Black or Black British - Caribbean',                 'Black Caribbean'),
        (13, 'N',  'Black or Black British - African',                   'Black African'),
        (14, 'P',  'Black or Black British - Any other Black background','Black Other'),

        -- OTHER
        (15, 'R',  'Other Ethnic Groups - Chinese',                      'Chinese'),
        (16, 'S',  'Other Ethnic Groups - Any other ethnic group',       'Other Ethnic Group'),

        -- NOT STATED / UNKNOWN
        (97, 'Z',  'Not stated',                                         'Unknown'),
        (98, '99', 'Not known',                                          'Unknown')
    ) AS v(SK_EthnicityID, EthnicityCode, EthnicityDesc, EthnicityShortDesc)
)
SELECT
      s.SK_EthnicityID,
      s.EthnicityCode,
      CAST('HES' AS VARCHAR(10)) AS EthnicityCodeType,
      s.EthnicityCode AS EthnicityCombinedCode,
      s.EthnicityDesc,
      s.EthnicityShortDesc AS EthnicityDesc2,
      CAST(NULL AS DATE) AS DateStart,
      CAST(NULL AS DATE) AS DateEnd,
      
      -- Short description for Power BI 
      LEFT(s.EthnicityDesc, 30) AS Ethnicity_Short
      
FROM Ethnicity_Source s;
GO

PRINT '[OK] Created view: [Analytics].[vw_Dim_Ethnicity]';
PRINT '     Source: Inline NHS HES ethnicity codes (no Dictionary dependency)';
GO

PRINT '';
PRINT 'Validation: Sample data from view';
SELECT TOP 5 * FROM [Analytics].[vw_Dim_Ethnicity];
GO

PRINT '';
PRINT '========================================';
PRINT 'vw_Dim_Ethnicity VIEW Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO

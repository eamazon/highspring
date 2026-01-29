USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating vw_Dim_Age_Band VIEW';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

IF OBJECT_ID('[Analytics].[vw_Dim_Age_Band]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[vw_Dim_Age_Band] already exists. Dropping...';
    DROP VIEW [Analytics].[vw_Dim_Age_Band];
END
GO

/**
Script Name:   26_Create_Dim_Age_Band.sql
Description:   Age band dimension with multiple banding schemes (5yr, 10yr, GP, clinical, summary).
               Supports flexible age-based analysis for different reporting requirements.
               Includes frailty bands and clinical age groups for risk stratification.
Author:        Sridhar Peddi
Created:       2026-01-09

Change Log:
  2026-01-09   Sridhar Peddi    Initial creation
**/
CREATE VIEW [Analytics].[vw_Dim_Age_Band] AS
SELECT 
    A.[SK_AgeID] AS [Age],
    
    -- 5-year age bands (0-4, 5-9, 10-14, etc.)
    B.[BK_AgeBand] AS [Age_Band_5yr],
    
    -- GP-specific banding (varies by practice)
    C.[BK_AgeBandGP] AS [Age_Band_GP],
    
    -- 10-year age bands (0-9, 10-19, 20-29, etc.)
    CASE 
        WHEN A.[SK_AgeID] = 255 THEN 'Unknown'
        WHEN A.[SK_AgeID] < 10 THEN '0-9'
        WHEN A.[SK_AgeID] < 20 THEN '10-19'
        WHEN A.[SK_AgeID] < 30 THEN '20-29'
        WHEN A.[SK_AgeID] < 40 THEN '30-39'
        WHEN A.[SK_AgeID] < 50 THEN '40-49'
        WHEN A.[SK_AgeID] < 60 THEN '50-59'
        WHEN A.[SK_AgeID] < 70 THEN '60-69'
        WHEN A.[SK_AgeID] < 80 THEN '70-79'
        WHEN A.[SK_AgeID] < 90 THEN '80-89'
        ELSE '90+'
    END AS [Age_Band_10yr],
    
    -- Clinical age bands (for frailty/risk analysis)
    CASE 
        WHEN A.[SK_AgeID] = 255 THEN 'Unknown'
        WHEN A.[SK_AgeID] < 18 THEN 'Children (0-17)'
        WHEN A.[SK_AgeID] < 65 THEN 'Working Age (18-64)'
        WHEN A.[SK_AgeID] < 75 THEN 'Older Adults (65-74)'
        WHEN A.[SK_AgeID] < 85 THEN 'Frail Elderly (75-84)'
        ELSE 'Very Frail (85+)'
    END AS [Age_Band_Clinical],
    
    -- Simple bands for high-level reporting
    CASE 
        WHEN A.[SK_AgeID] = 255 THEN 'Unknown'
        WHEN A.[SK_AgeID] < 5 THEN '0-4'
        WHEN A.[SK_AgeID] < 19 THEN '5-18'
        WHEN A.[SK_AgeID] < 50 THEN '19-49'
        WHEN A.[SK_AgeID] < 65 THEN '50-64'
        ELSE '65+'
    END AS [Age_Band_Summary]
    
FROM [Dictionary].[dbo].[Age] A
LEFT JOIN [Dictionary].[dbo].[AgeBand] B 
    ON A.[SK_AgeBandID] = B.[SK_AgeBandID]
LEFT JOIN [Dictionary].[dbo].[AgeBand_GP] C 
    ON A.[SK_AgeBandGPID] = C.[SK_AgeBandGPID];
GO

PRINT '[OK] Created view: [Analytics].[vw_Dim_Age_Band]';
PRINT '     Source: [Dictionary].[dbo].[Age] + AgeBand tables';
GO

-- Validation: Sample data from view
PRINT '';
PRINT 'Validation: Sample age bands';
SELECT TOP 20 
    Age,
    Age_Band_5yr,
    Age_Band_10yr,
    Age_Band_Clinical,
    Age_Band_Summary
FROM [Analytics].[vw_Dim_Age_Band]
WHERE Age < 100
ORDER BY Age;
GO

PRINT '';
PRINT 'Age distribution summary:';
SELECT 
    Age_Band_10yr,
    MIN(Age) AS Min_Age,
    MAX(Age) AS Max_Age,
    COUNT(*) AS Age_Count
FROM [Analytics].[vw_Dim_Age_Band]
WHERE Age < 255  -- Exclude 'Unknown'
GROUP BY Age_Band_10yr
ORDER BY MIN(Age);
GO

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
  2026-02-27   Sridhar Peddi            Remove Dictionary dependency; inline age dimension (0-100 + Unknown)
**/
CREATE VIEW [Analytics].[vw_Dim_Age_Band] AS
WITH AgeBase AS (
    SELECT CAST(-1 AS INT) AS Age
    UNION ALL
    SELECT TOP (101)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS Age
    FROM (VALUES (0),(0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) AS a(n)
    CROSS JOIN (VALUES (0),(0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) AS b(n)
)
SELECT
    A.Age,

    -- 5-year age bands (capped at 100+)
    CASE
        WHEN A.Age = -1 THEN 'Unknown'
        WHEN A.Age = 100 THEN '100+'
        ELSE CONCAT(CAST((A.Age / 5) * 5 AS VARCHAR(3)), '-', CAST(((A.Age / 5) * 5) + 4 AS VARCHAR(3)))
    END AS [Age_Band_5yr],

    -- GP banding aligned to 5-year bands for a self-contained dimension
    CASE
        WHEN A.Age = -1 THEN 'Unknown'
        WHEN A.Age = 100 THEN '100+'
        ELSE CONCAT(CAST((A.Age / 5) * 5 AS VARCHAR(3)), '-', CAST(((A.Age / 5) * 5) + 4 AS VARCHAR(3)))
    END AS [Age_Band_GP],

    -- 10-year age bands (capped at 100+)
    CASE
        WHEN A.Age = -1 THEN 'Unknown'
        WHEN A.Age = 100 THEN '100+'
        WHEN A.Age < 10 THEN '0-9'
        WHEN A.Age < 20 THEN '10-19'
        WHEN A.Age < 30 THEN '20-29'
        WHEN A.Age < 40 THEN '30-39'
        WHEN A.Age < 50 THEN '40-49'
        WHEN A.Age < 60 THEN '50-59'
        WHEN A.Age < 70 THEN '60-69'
        WHEN A.Age < 80 THEN '70-79'
        WHEN A.Age < 90 THEN '80-89'
        ELSE '90-99'
    END AS [Age_Band_10yr],

    -- Clinical age bands (commented out by request)
    --CASE
    --    WHEN A.Age = -1 THEN 'Unknown'
    --    WHEN A.Age < 18 THEN 'Children (0-17)'
    --    WHEN A.Age < 65 THEN 'Working Age (18-64)'
    --    WHEN A.Age < 75 THEN 'Older Adults (65-74)'
    --    WHEN A.Age < 85 THEN 'Frail Elderly (75-84)'
    --    ELSE 'Very Frail (85+)'
    --END AS [Age_Band_Clinical],

    -- Simple bands for high-level reporting
    CASE
        WHEN A.Age = -1 THEN 'Unknown'
        WHEN A.Age < 5 THEN '0-4'
        WHEN A.Age < 19 THEN '5-18'
        WHEN A.Age < 50 THEN '19-49'
        WHEN A.Age < 65 THEN '50-64'
        WHEN A.Age < 100 THEN '65-99'
        ELSE '100+'
    END AS [Age_Band_Summary]
FROM AgeBase A;
GO

PRINT '[OK] Created view: [Analytics].[vw_Dim_Age_Band]';
PRINT '     Source: Inline generated age set (0-100 + Unknown)';
GO

-- Validation: Sample data from view
PRINT '';
PRINT 'Validation: Sample age bands';
SELECT TOP 20 
    Age,
    Age_Band_5yr,
    Age_Band_10yr,
    --Age_Band_Clinical,
    Age_Band_Summary
FROM [Analytics].[vw_Dim_Age_Band]
WHERE Age BETWEEN 0 AND 100
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
WHERE Age BETWEEN 0 AND 100
GROUP BY Age_Band_10yr
ORDER BY MIN(Age);
GO

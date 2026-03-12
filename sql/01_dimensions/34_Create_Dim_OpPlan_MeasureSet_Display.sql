USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating vw_Dim_OpPlan_MeasureSet_Display';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

IF OBJECT_ID('[Analytics].[vw_Dim_OpPlan_MeasureSet_Display]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[vw_Dim_OpPlan_MeasureSet_Display] already exists. Dropping...';
    DROP VIEW [Analytics].[vw_Dim_OpPlan_MeasureSet_Display];
END
GO

/**
Script Name:   34_Create_Dim_OpPlan_MeasureSet_Display.sql
Description:   Friendly one-row-per-measure-set dimension for reporting tools.
               Expands SK_OpPlan_MeasureSet into concatenated human-readable
               measure attributes (name/short name/category).
Author:        Sridhar Peddi
Created:       2026-03-12
**/
CREATE VIEW [Analytics].[vw_Dim_OpPlan_MeasureSet_Display] AS
WITH MeasureAgg AS (
    SELECT
        b.[SK_OpPlan_MeasureSet],
        COUNT(1) AS [Resolved_Measure_Count],
        STRING_AGG(
            ISNULL(m.[Measure_Name], CONCAT('MeasureID ', CAST(b.[MeasureID] AS VARCHAR(20)))),
            ' | '
        ) WITHIN GROUP (ORDER BY b.[MeasureID]) AS [Measure_Names],
        STRING_AGG(
            ISNULL(m.[Measure_ShortName], ISNULL(m.[Measure_Name], CONCAT('MeasureID ', CAST(b.[MeasureID] AS VARCHAR(20))))),
            ' | '
        ) WITHIN GROUP (ORDER BY b.[MeasureID]) AS [Measure_ShortNames],
        STRING_AGG(
            ISNULL(m.[Measure_Category], 'Unknown'),
            ' | '
        ) WITHIN GROUP (ORDER BY b.[MeasureID]) AS [Measure_Categories],
        STRING_AGG(
            ISNULL(m.[Measure_SubCategory], 'Unknown'),
            ' | '
        ) WITHIN GROUP (ORDER BY b.[MeasureID]) AS [Measure_SubCategories]
    FROM [Analytics].[tbl_Bridge_OpPlan_MeasureSet] b
    LEFT JOIN [Analytics].[vw_Dim_OpPlan_Measure] m
        ON m.[MeasureID] = b.[MeasureID]
    GROUP BY b.[SK_OpPlan_MeasureSet]
)
SELECT
    ms.[SK_OpPlan_MeasureSet],
    ms.[MeasureIds],
    ms.[MeasureCount],
    ms.[Is_Active],
    ms.[Created_Date],
    ma.[Resolved_Measure_Count],
    CASE
        WHEN ms.[SK_OpPlan_MeasureSet] = -1 THEN 'Unknown Measure Set'
        ELSE ISNULL(ma.[Measure_Names], 'Unmapped Measure Set')
    END AS [Measure_Names],
    CASE
        WHEN ms.[SK_OpPlan_MeasureSet] = -1 THEN 'Unknown'
        ELSE ISNULL(ma.[Measure_ShortNames], 'Unmapped')
    END AS [Measure_ShortNames],
    CASE
        WHEN ms.[SK_OpPlan_MeasureSet] = -1 THEN 'Unknown'
        ELSE ISNULL(ma.[Measure_Categories], 'Unknown')
    END AS [Measure_Categories],
    CASE
        WHEN ms.[SK_OpPlan_MeasureSet] = -1 THEN 'Unknown'
        ELSE ISNULL(ma.[Measure_SubCategories], 'Unknown')
    END AS [Measure_SubCategories]
FROM [Analytics].[tbl_Dim_OpPlan_MeasureSet] ms
LEFT JOIN MeasureAgg ma
    ON ma.[SK_OpPlan_MeasureSet] = ms.[SK_OpPlan_MeasureSet];
GO

PRINT '[OK] Created view: [Analytics].[vw_Dim_OpPlan_MeasureSet_Display]';
GO

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating vw_Dim_OpPlan_MeasureSet_Detail';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

IF OBJECT_ID('[Analytics].[vw_Dim_OpPlan_MeasureSet_Detail]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[vw_Dim_OpPlan_MeasureSet_Detail] already exists. Dropping...';
    DROP VIEW [Analytics].[vw_Dim_OpPlan_MeasureSet_Detail];
END
GO

CREATE VIEW [Analytics].[vw_Dim_OpPlan_MeasureSet_Detail] AS
SELECT
    ms.[SK_OpPlan_MeasureSet],
    ms.[MeasureIds],
    ms.[MeasureCount],
    b.[MeasureID],
    m.[Measure_Name],
    m.[Measure_ShortName],
    m.[Measure_Category],
    m.[Measure_SubCategory]
FROM [Analytics].[tbl_Dim_OpPlan_MeasureSet] ms
LEFT JOIN [Analytics].[tbl_Bridge_OpPlan_MeasureSet] b
    ON ms.[SK_OpPlan_MeasureSet] = b.[SK_OpPlan_MeasureSet]
LEFT JOIN [Analytics].[vw_Dim_OpPlan_Measure] m
    ON b.[MeasureID] = m.[MeasureID];
GO

PRINT '[OK] Created view: [Analytics].[vw_Dim_OpPlan_MeasureSet_Detail]';
GO


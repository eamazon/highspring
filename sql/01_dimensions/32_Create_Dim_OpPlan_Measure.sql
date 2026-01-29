/**
-- Script Name: 32_Create_Dim_OpPlan_Measure.sql
-- Description: Operating Plan measure dimension (view over IM.tbl_Metrics_Catalogue).
-- Author:      Sridhar Peddi
-- Created:     2026-01-13
--
-- Change Log:
-- 2026-01-26  Sridhar Peddi    Allow all metrics by removing NHSEMetricId filter
-- 2026-01-26  Sridhar Peddi    Use MetricId as MeasureID (keep native datatype)
**/

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating vw_Dim_OpPlan_Measure';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

IF OBJECT_ID('[Analytics].[vw_Dim_OpPlan_Measure]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[vw_Dim_OpPlan_Measure] already exists. Dropping...';
    DROP VIEW [Analytics].[vw_Dim_OpPlan_Measure];
END
GO

CREATE VIEW [Analytics].[vw_Dim_OpPlan_Measure] AS
SELECT
    m.[MetricId] AS MeasureID,
    m.[MetricName] AS Measure_Name,
    m.[MetricDescription] AS Measure_Description,
    m.[Category] AS Measure_Category,
    m.[SubCategory] AS Measure_SubCategory,
    m.[ShortName] AS Measure_ShortName,
    m.[Scope] AS Measure_Scope,
    m.[UnitOfMeasure] AS Measure_Unit,
    m.[IsActive] AS Is_Active,
    m.[ValidFromDate] AS Valid_From,
    m.[ValidToDate] AS Valid_To
FROM [Data_Lab_SWL].[IM].[tbl_Metrics_Catalogue] m
-- WHERE m.[NHSEMetricId] IS NOT NULL;
GO

PRINT '[OK] Created view: [Analytics].[vw_Dim_OpPlan_Measure]';
GO

PRINT '';
PRINT '========================================';
PRINT 'vw_Dim_OpPlan_Measure VIEW Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO

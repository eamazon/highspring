USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating vw_OpPlan_ActualActivity_Analytics';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

IF OBJECT_ID('[Analytics].[vw_OpPlan_ActualActivity_Analytics]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[vw_OpPlan_ActualActivity_Analytics] already exists. Dropping...';
    DROP VIEW [Analytics].[vw_OpPlan_ActualActivity_Analytics];
END
GO

/**
Script Name:  06_Create_vw_OpPlan_ActualActivity_Analytics.sql
Description:  OpPlan actual activity at MeasureID grain (expanded from measure sets).
              Grain: MonthEnding + Provider + MeasureID + POD.
Author:       Sridhar Peddi
Created:      2026-01-26

Change Log:
  2026-01-26  Sridhar Peddi    Initial creation
**/
CREATE VIEW [Analytics].[vw_OpPlan_ActualActivity_Analytics] AS
SELECT
    EOMONTH(opa.Activity_Date) AS MonthEnding,
    opa.Activity_Date,
    opa.Dataset,
    prov.Provider_Code,
    d.MeasureID,
    d.[Measure_Name],
    CASE
        WHEN d.Measure_Category = 'Diagnostic Tests' THEN 'Diagnostic'
        WHEN d.Measure_ShortName = 'Outpatient procedures' THEN 'OutpatientProcedures'
        WHEN d.Measure_ShortName IN ('Day Case Children','Ordinary Children') THEN 'Elective (<18)'
        ELSE d.Measure_Category
    END AS POD,
    COUNT_BIG(1) AS ActualValue
FROM [Analytics].[tbl_OpPlan_Active] opa
INNER JOIN [Analytics].[tbl_Bridge_OpPlan_MeasureSet] b
    ON b.SK_OpPlan_MeasureSet = opa.SK_OpPlan_MeasureSet
INNER JOIN [Analytics].[vw_Dim_OpPlan_Measure] d
    ON d.MeasureID = b.MeasureID
LEFT JOIN [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active] ip
    ON opa.Dataset = 'Inpatient'
   AND opa.SK_EncounterID = ip.SK_EncounterID
LEFT JOIN [Data_Lab_SWL].[Unified].[tbl_OP_EncounterDenormalised_Active] op
    ON opa.Dataset = 'Outpatient'
   AND opa.SK_EncounterID = op.SK_EncounterID
LEFT JOIN [Data_Lab_SWL].[Unified].[tbl_ED_EncounterDenormalised_Active] ed
    ON opa.Dataset = 'ED'
   AND opa.SK_EncounterID = ed.SK_EncounterID
LEFT JOIN [Analytics].[vw_Dim_Provider] prov
    ON prov.Provider_Code = COALESCE(
        ip.Organisation_Code_Code_of_Provider,
        op.Organisation_Code_Code_of_Provider,
        ed.Organisation_Code_Code_of_Provider
    )
GROUP BY
    EOMONTH(opa.Activity_Date),
    opa.Activity_Date,
    opa.Dataset,
    prov.Provider_Code,
    d.MeasureID,
    d.[Measure_Name],
    CASE
        WHEN d.Measure_Category = 'Diagnostic Tests' THEN 'Diagnostic'
        WHEN d.Measure_ShortName = 'Outpatient procedures' THEN 'OutpatientProcedures'
        WHEN d.Measure_ShortName IN ('Day Case Children','Ordinary Children') THEN 'Elective (<18)'
        ELSE d.Measure_Category
    END;
GO

PRINT '[OK] Created view: [Analytics].[vw_OpPlan_ActualActivity_Analytics]';
GO

PRINT '';
PRINT '========================================';
PRINT 'vw_OpPlan_ActualActivity_Analytics VIEW Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating vw_Fact_IP_Activity_Denormalised VIEW';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

IF OBJECT_ID('[Analytics].[vw_Fact_IP_Activity_Denormalised]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[vw_Fact_IP_Activity_Denormalised] already exists. Dropping...';
    DROP VIEW [Analytics].[vw_Fact_IP_Activity_Denormalised];
END
GO

/**
Script Name:   04_Create_vw_Fact_IP_Activity_Denormalised.sql
Description:   Denormalised view of IP fact activity with dimension descriptions.
               Grain: One row per inpatient spell.
Author:        Sridhar Peddi
Created:       2026-01-21

Change Log:
  2026-01-21  Sridhar Peddi    Initial creation
  2026-01-26  Sridhar Peddi    Removed patient local identifier from output
**/
CREATE VIEW [Analytics].[vw_Fact_IP_Activity_Denormalised] AS
SELECT
    f.*,

    -- Patient (basic descriptive attributes)
    p.[Pseudo_ID] AS [Patient_Pseudo_ID],
    p.[Gender_Description] AS [Patient_Gender_Description],
    p.[Ethnicity_Description] AS [Patient_Ethnicity_Description],

    -- Date roles
    da.[FullDate] AS [Admission_Date_Full],
    da.[FiscalCalendarYearName] AS [Admission_Fiscal_Year],
    da.[FiscalCalendarMonthNumber] AS [Admission_Fiscal_Month],
    dd.[FullDate] AS [Discharge_Date_Full],
    dd.[FiscalCalendarYearName] AS [Discharge_Fiscal_Year],
    dd.[FiscalCalendarMonthNumber] AS [Discharge_Fiscal_Month],

    -- Core dimensions
    ab.[Age_Band_5yr],
    ab.[Age_Band_10yr],
    ab.[Age_Band_Clinical],
    ab.[Age_Band_Summary],
    g.[Gender] AS [Gender_Description],
    e.[EthnicityDesc] AS [Ethnicity_Description],
    prov.[Provider_Code],
    prov.[Provider_Name],
    prov.[Provider_Type],
    lsoa.[LSOA_Name],
    lsoa.[SubICB_Name],
    lsoa.[ICB_Name],
    lsoa.[LocalAuthority_Name],
    spec.[SpecialtyName] AS [Specialty_Name],
    hrg.[HRGCode],
    hrg.[HRGDescription] AS [HRG_Description],

    -- Organisation dimensions
    comm.[Commissioner_Code],
    comm.[Commissioner_Name],
    comm.[SubICB_Code] AS [Commissioner_SubICB_Code],
    comm.[SubICB_Name] AS [Commissioner_SubICB_Name],
    gp.[GPPractice_Code],
    gp.[GPPractice_Name],
    pcn.[PCN_Code],
    pcn.[PCN_Name],
    pod.[POD_Code],
    pod.[POD_Description],
    pod.[POD_Domain],
    pod.[POD_Subcategory],
    pod.[POD_Measure],
    opm.[MeasureIds] AS [OpPlan_Measure_Ids],
    opm.[MeasureCount] AS [OpPlan_Measure_Count],

    -- IP-specific dimensions
    adm_m.[Admission_Method_Code],
    adm_m.[Admission_Method_Name],
    adm_s.[Admission_Source_Code],
    adm_s.[Admission_Source_Name],
    dis_m.[Discharge_Method_Code],
    dis_m.[Discharge_Method_Name],
    dis_d.[Discharge_Destination_Code],
    dis_d.[Discharge_Destination_Name],
    ipc.[Patient_Classification_Code],
    ipc.[Patient_Classification_Description],

    -- CAM dimension lookups
    cam_comm.[Commissioner_Code] AS [CAM_Commissioner_Code_Dim],
    cam_comm.[Commissioner_Name] AS [CAM_Commissioner_Name_Dim],
    cam_sc.[CAM_Service_Category] AS [CAM_Service_Category_Dim],
    cam_ar.[CAM_Assignment_Code] AS [CAM_Assignment_Code_Dim],
    cam_ar.[CAM_Assignment_Reason] AS [CAM_Assignment_Reason_Dim]
FROM [Analytics].[tbl_Fact_IP_Activity] f
LEFT JOIN [Analytics].[tbl_Dim_Patient] p
    ON f.[SK_PatientID] = p.[SK_PatientID]
LEFT JOIN [Analytics].[vw_Dim_Date] da
    ON f.[SK_DateAdmissionID] = da.[SK_Date]
LEFT JOIN [Analytics].[vw_Dim_Date] dd
    ON f.[SK_DateDischargeID] = dd.[SK_Date]
LEFT JOIN [Analytics].[vw_Dim_Age_Band] ab
    ON f.[SK_Age_BandID] = ab.[Age]
LEFT JOIN [Analytics].[vw_Dim_Gender] g
    ON f.[SK_GenderID] = g.[SK_GenderID]
LEFT JOIN [Analytics].[vw_Dim_Ethnicity] e
    ON f.[SK_EthnicityID] = e.[SK_EthnicityID]
LEFT JOIN [Analytics].[vw_Dim_Provider] prov
    ON f.[SK_ProviderID] = prov.[SK_ProviderID]
LEFT JOIN [Analytics].[vw_Dim_LSOA] lsoa
    ON f.[SK_LSOA_ID] = lsoa.[SK_LSOA_ID]
LEFT JOIN [Analytics].[vw_Dim_Specialty] spec
    ON f.[SK_SpecialtyID] = spec.[SK_SpecialtyID]
LEFT JOIN [Analytics].[vw_Dim_HRG] hrg
    ON f.[SK_HRG_ID] = hrg.[SK_HRGID]
LEFT JOIN [Analytics].[tbl_Dim_Commissioner] comm
    ON f.[SK_CommissionerID] = comm.[SK_CommissionerID]
LEFT JOIN [Analytics].[tbl_Dim_GPPractice] gp
    ON f.[SK_GPPracticeID] = gp.[SK_GPPracticeID]
LEFT JOIN [Analytics].[tbl_Dim_PCN] pcn
    ON f.[SK_PCN_ID] = pcn.[SK_PCNID]
LEFT JOIN [Analytics].[tbl_Dim_POD] pod
    ON f.[SK_POD_ID] = pod.[SK_PodID]
LEFT JOIN [Analytics].[tbl_Dim_OpPlan_MeasureSet] opm
    ON f.[SK_OpPlan_MeasureSet] = opm.[SK_OpPlan_MeasureSet]
LEFT JOIN [Analytics].[vw_Dim_Admission_Method] adm_m
    ON f.[SK_Admission_MethodID] = adm_m.[SK_AdmissionMethodID]
LEFT JOIN [Analytics].[vw_Dim_Admission_Source] adm_s
    ON f.[SK_Admission_SourceID] = adm_s.[SK_AdmissionSourceID]
LEFT JOIN [Analytics].[vw_Dim_Discharge_Method] dis_m
    ON f.[SK_Discharge_MethodID] = dis_m.[SK_DischargeMethodID]
LEFT JOIN [Analytics].[vw_Dim_Discharge_Destination] dis_d
    ON f.[SK_Discharge_DestinationID] = dis_d.[SK_DischargeDestinationID]
LEFT JOIN [Analytics].[vw_Dim_IP_Patient_Classification] ipc
    ON f.[SK_IP_Patient_ClassificationID] = ipc.[SK_PatientClassificationID]
LEFT JOIN [Analytics].[tbl_Dim_Commissioner] cam_comm
    ON f.[SK_CAM_CommissionerID] = cam_comm.[SK_CommissionerID]
LEFT JOIN [Analytics].[tbl_Dim_CAM_Service_Category] cam_sc
    ON f.[SK_CAM_Service_CategoryID] = cam_sc.[SK_CAM_Service_CategoryID]
LEFT JOIN [Analytics].[tbl_Dim_CAM_Assignment_Reason] cam_ar
    ON f.[SK_CAM_Assignment_ReasonID] = cam_ar.[SK_CAM_Assignment_ReasonID];
GO

PRINT '[OK] Created view: [Analytics].[vw_Fact_IP_Activity_Denormalised]';
GO

PRINT '';
PRINT '========================================';
PRINT 'vw_Fact_IP_Activity_Denormalised VIEW Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO

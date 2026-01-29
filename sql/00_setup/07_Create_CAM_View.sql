USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating vw_SUS_CAM VIEW';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

IF OBJECT_ID('[Analytics].[vw_SUS_CAM]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[vw_SUS_CAM] already exists. Dropping...';
    DROP VIEW [Analytics].[vw_SUS_CAM];
END
GO

/**
Script Name:   07_Create_CAM_View.sql
Description:   Analytics-scoped CAM-compatible view of IP/OP activity for commissioner assignment.
Author:        Sridhar Peddi
Created:       2026-01-12 21:45

Change Log:
  2026-01-12  Sridhar Peddi    Moved CAM view to Analytics schema
**/
CREATE VIEW [Analytics].[vw_SUS_CAM] AS
SELECT
    SK_EncounterID AS [PLD_ident],
    REPLACE([dv_FinYear], '/20', '') AS [RAW_Activity_Year],
    [dv_FinMonth] AS [RAW_Activity_Month],
    [dv_FinYear] AS [DER_Activity_Year],
    [GP_Practice_Code_Original_Data] AS [RAW_gp_practice_code],
    CASE WHEN RIGHT(Organisation_Code_Code_Of_Commissioner, 2) = '00'
        THEN LEFT(Organisation_Code_Code_Of_Commissioner, 3)
        ELSE Organisation_Code_Code_Of_Commissioner
    END AS [RAW_ccg_code],
    [Organisation_Code_PCT_of_Residence] AS [RAW_Org_Residence_Responsibility],
    [Organisation_Code_Code_of_Provider] AS [RAW_Provider_Code],
    CASE WHEN RIGHT(Organisation_Code_Code_Of_Commissioner, 2) = '00'
        THEN LEFT(Organisation_Code_Code_Of_Commissioner, 3)
        ELSE Organisation_Code_Code_Of_Commissioner
    END AS [RAW_Commissioner_Code],
    [dv_SpecCom_ServiceCode_National_Spell] AS [STP_NHSE_ServiceLine],
    NULL AS [RAW_nhse_servicecategory],
    [Treatment_Function_Code] AS [RAW_treatment_function_code],
    [Data_Lab_SWL].[IP].[GetPodType](
        Admission_Method_Hospital_Provider_Spell,
        Patient_Classification,
        Intended_Management,
        Start_Date_Hospital_Provider_Spell,
        End_Date_Hospital_Provider_Spell,
        Spell_Core_HRG
    ) AS [RAW_national_pod_code],
    [dv_Total_Cost_Inc_MFF] AS [CLN_Total_Cost],
    'IP' AS [Dataset],
    NULL AS [Activity_Type],
    Start_Date_Hospital_Provider_Spell AS [AdmissionDate],
    End_Date_Hospital_Provider_Spell AS [DischargeDate]
FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active] WITH (NOLOCK)
WHERE [dv_FinYear] = '2025/2026'
  AND [dv_IsSpell] = 1
  AND [End_Date_Hospital_Provider_Spell] >= '2025-04-01'
UNION ALL
SELECT
    SK_EncounterID AS [PLD_ident],
    REPLACE([dv_FinYear], '/20', '') AS [RAW_Activity_Year],
    [dv_FinMonth] AS [RAW_Activity_Month],
    [dv_FinYear] AS [DER_Activity_Year],
    [GP_Practice_Code_Original_Data] AS [RAW_gp_practice_code],
    CASE WHEN RIGHT(Organisation_Code_Code_Of_Commissioner, 2) = '00'
        THEN LEFT(Organisation_Code_Code_Of_Commissioner, 3)
        ELSE Organisation_Code_Code_Of_Commissioner
    END AS [RAW_ccg_code],
    [Organisation_Code_PCT_of_Residence] AS [RAW_Org_Residence_Responsibility],
    [Organisation_Code_Code_of_Provider] AS [RAW_Provider_Code],
    CASE WHEN RIGHT(Organisation_Code_Code_Of_Commissioner, 2) = '00'
        THEN LEFT(Organisation_Code_Code_Of_Commissioner, 3)
        ELSE Organisation_Code_Code_Of_Commissioner
    END AS [RAW_Commissioner_Code],
    dv_SpecCom_ServiceCode_National AS [STP_NHSE_ServiceLine],
    NULL AS [RAW_nhse_servicecategory],
    [Treatment_Function_Code] AS [RAW_treatment_function_code],
    [Data_Lab_SWL].[OP].[GetPodType](
        Core_HRG,
        Attended_Or_Did_Not_Attend,
        First_Attendance,
        Main_Specialty_Code
    ) AS [RAW_national_pod_code],
    [dv_Total_Cost_Inc_MFF] AS [CLN_Total_Cost],
    'OP' AS [Dataset],
    NULL AS [Activity_Type],
    Appointment_Date AS [AdmissionDate],
    Appointment_Date AS [DischargeDate]
FROM [Data_Lab_SWL].[Unified].[tbl_OP_EncounterDenormalised_Active] WITH (NOLOCK)
WHERE [dv_FinYear] = '2025/2026'
  AND Appointment_Date >= '2025-04-01';
GO

PRINT '[OK] Created view: [Analytics].[vw_SUS_CAM]';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

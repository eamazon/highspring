USE [Data_Lab_SWL]
GO

/****** Object:  View [CAM].[vw_SUS_CAM]    Script Date: 31/12/2025 19:46:46 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





/*======================================================================================================================
 Object:        [CAM].[vw_SUS_CAM] 
 Type:          VIEW
 Purpose:       CAM-compatible view of IP AND op DATA mapping SUS fields to CAM required field names
 Usage:         Used by CAM validation logic to determine correct commissioner assignment
 
 Change Log:
    Date (UTC)    Version   Author            Change
    ------------  -------   ----------------  ---------------------------------------------------------------------------
    2025-09-26    1.0       Sridhar Peddi     Initial creation for CAM validation on SUS IP data
======================================================================================================================*/

ALTER   VIEW [CAM].[vw_SUS_CAM] AS
SELECT
    SK_EncounterID AS [PLD_ident],
    REPLACE([dv_FinYear], '/20', '') AS [RAW_Activity_Year],
    [dv_FinMonth] AS [RAW_Activity_Month],
    [dv_FinYear] AS [DER_Activity_Year],
    [GP_Practice_Code_Original_Data] AS [RAW_gp_practice_code],
    CASE WHEN RIGHT(Organisation_Code_Code_Of_Commissioner, 2) = '00' THEN LEFT(Organisation_Code_Code_Of_Commissioner, 3) ELSE Organisation_Code_Code_Of_Commissioner END AS [RAW_ccg_code],
    [Organisation_Code_PCT_of_Residence] AS [RAW_Org_Residence_Responsibility],
    [Organisation_Code_Code_of_Provider] AS [RAW_Provider_Code],
    CASE WHEN RIGHT(Organisation_Code_Code_Of_Commissioner, 2) = '00' THEN LEFT(Organisation_Code_Code_Of_Commissioner, 3) ELSE Organisation_Code_Code_Of_Commissioner END AS [RAW_Commissioner_Code],
    [dv_SpecCom_ServiceCode_National_Spell] AS [STP_NHSE_ServiceLine],
    NULL AS [RAW_nhse_servicecategory],
    [Treatment_Function_Code] AS [RAW_treatment_function_code],
    [IP].[GetPodType](Admission_Method_Hospital_Provider_Spell, Patient_Classification, Intended_Management, Start_Date_Hospital_Provider_Spell,End_Date_Hospital_Provider_Spell, Spell_Core_HRG)  AS [RAW_national_pod_code],
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
    CASE WHEN RIGHT(Organisation_Code_Code_Of_Commissioner, 2) = '00' THEN LEFT(Organisation_Code_Code_Of_Commissioner, 3) ELSE Organisation_Code_Code_Of_Commissioner END AS [RAW_ccg_code],
    [Organisation_Code_PCT_of_Residence] AS [RAW_Org_Residence_Responsibility],
    [Organisation_Code_Code_of_Provider] AS [RAW_Provider_Code],
    CASE WHEN RIGHT(Organisation_Code_Code_Of_Commissioner, 2) = '00' THEN LEFT(Organisation_Code_Code_Of_Commissioner, 3) ELSE Organisation_Code_Code_Of_Commissioner END AS [RAW_Commissioner_Code],
    dv_SpecCom_ServiceCode_National AS [STP_NHSE_ServiceLine],
    NULL AS [RAW_nhse_servicecategory],
    [Treatment_Function_Code] AS [RAW_treatment_function_code],
	[OP].[GetPodType](Core_HRG, Attended_Or_Did_Not_Attend, First_Attendance, Main_Specialty_Code)  AS [RAW_national_pod_code],
	[dv_Total_Cost_Inc_MFF] AS [CLN_Total_Cost],
    'OP' AS [Dataset],
    NULL AS [Activity_Type],
    Appointment_Date AS [AdmissionDate],
    Appointment_Date AS [DischargeDate]
FROM [Data_Lab_SWL].[Unified].[tbl_OP_EncounterDenormalised_Active] WITH (NOLOCK)
WHERE [dv_FinYear] = '2025/2026'
  AND Appointment_Date >= '2025-04-01';
GO



USE [Data_Lab_SWL]
GO

/****** Object:  View [IP].[vw_Admissions_CAM]    Script Date: 31/12/2025 19:46:16 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/*======================================================================================================================
 Object:        [IP].[vw_Admissions_CAM]
 Type:          VIEW
 Purpose:       CAM-compatible view of IP admissions data mapping SUS fields to CAM required field names
 Usage:         Used by CAM validation logic to determine correct commissioner assignment
 
 Change Log:
    Date (UTC)    Version   Author            Change
    ------------  -------   ----------------  ---------------------------------------------------------------------------
    2025-09-26    1.0       Sridhar Peddi     Initial creation for CAM validation on SUS IP data
======================================================================================================================*/

ALTER   VIEW [IP].[vw_Admissions_CAM] AS
SELECT 
    -- Identity & Record Management
    Unique_CDS_Identifier AS [PLD_ident],                    -- Record identifier for CAM processing
    
    -- Financial Period
    REPLACE([dv_FinYear],'/20','') AS [RAW_Activity_Year],                -- Financial year (e.g., '2025/2026')
    [dv_FinMonth] AS [RAW_Activity_Month],              -- Financial month (1-12)
    [dv_FinYear] AS [DER_Activity_Year],                -- Derived activity year for filtering
    
    -- Commissioner Assignment Fields (Who Pays logic)
    [GP_Practice_Code_Original_Data] AS [RAW_gp_practice_code],                           -- GP Practice code for patient registration
    CASE WHEN RIGHT(Organisation_Code_Code_Of_Commissioner,2) = '00' THEN LEFT(Organisation_Code_Code_Of_Commissioner,3) ELSE Organisation_Code_Code_Of_Commissioner END as [RAW_ccg_code],
	--Organisation_Code_Code_Of_Commissioner AS [RAW_ccg_code],                                          -- Current commissioner/sub-ICB code
    [Organisation_Code_PCT_of_Residence] AS [RAW_Org_Residence_Responsibility],    -- Residence-based commissioner
    
    -- Provider Information
    [Organisation_Code_Code_of_Provider] AS [RAW_Provider_Code],              -- Provider organisation code
    CASE WHEN RIGHT(Organisation_Code_Code_Of_Commissioner,2) = '00' THEN LEFT(Organisation_Code_Code_Of_Commissioner,3) ELSE Organisation_Code_Code_Of_Commissioner END AS [RAW_Commissioner_Code],      -- Current commissioner assignment
    
    -- Service Classification
    [dv_SpecCom_ServiceCode_National_Spell] AS [STP_NHSE_ServiceLine],  -- NHSE service line code
    NULL AS [RAW_nhse_servicecategory],                                 -- Service category (CAM will derive)
    
    -- Activity Classification
    [Treatment_Function_Code] AS [RAW_treatment_function_code],         -- Treatment Function Code (TFC)
        [IP].[GetPodType](Admission_Method_Hospital_Provider_Spell, Patient_Classification, Intended_Management, Start_Date_Hospital_Provider_Spell,End_Date_Hospital_Provider_Spell, Spell_Core_HRG)  AS [RAW_national_pod_code],
                                   -- Point of Delivery code
    
    -- Financial
    [dv_Total_Cost_Inc_MFF] AS [CLN_Total_Cost],        -- Total cost including Market Forces Factor
    
    -- Additional context for IP-specific processing
    'IP' as [Dataset],                                          -- 'IP' indicator
    null as [Activity_Type],                                    -- 'Elective'/'Non-Elective'
    Start_Date_Hospital_Provider_Spell [AdmissionDate],                                    -- Admission date
    End_Date_Hospital_Provider_Spell [DischargeDate],                                    -- Discharge date
    [Patient_Classification],                           -- Inpatient classification
    [Admission_Method_Hospital_Provider_Spell],         -- Admission method
    
    -- Geographic and demographic context
    [Age_At_CDS_Activity_Date],                        -- Patient age
    --[Gender],                                          -- Patient gender
    --[EthnicityCategory],                               -- Ethnicity code
    [dv_LSOACode]                                      -- LSOA for geographic analysis

FROM [SUS].[IP].[EncounterDenormalised_DateRange]--[Data_Lab_SWL].[IP].[vw_Admissions]
WHERE [dv_FinYear] = '2025/2026'                       -- Focus on current financial year
  AND [dv_IsSpell] = 1                                 -- IP spells only
  AND [End_Date_Hospital_Provider_Spell] >= '2025-04-01' -- Activity from start of financial year
  -- Exclude DRUG/DEVICE PODs and specific service categories as per CAM logic
  --AND (COALESCE([POD],'') NOT IN ('DRUG','DEVICE'))
GO



USE [Data_Lab_SWL]
GO

/****** Object:  View [ERF].[vw_OP_RePriced_Activity_2526]    Script Date: 06/01/2026 15:11:32 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO








/**
*--------------------------Change Log------------------------------------------------------------------------------------------
* 29/09/2023 - SP - Initial Creation
* 03/10/2023 - SP - Changed the version to bring in trustwide data 
* 04/10/2023 - SP - Changed to include Specialist TopUp for all Spec-Comm activity
* 05/10/2023 - SP - Amended the code to include ISP, OOS
* 06/10/2023 - SP - Amended the logic for CommissionedBy, devolved administrations, private patients which has VPP00
* 19/10/2023 - SP - Merged all FY views into single view and all repriced views into this new view
* 23/10/2023 - SP - Dynamic Tariff Slection based on ERF.tbl_Current_Tariff_Used
* 25/10/2023 - SP - Fixed where OPPROC has no tariff to the equivalent attendance tariff
* 25/11/2023 - SP - Amended the code to reflect the default price to £197, amended the MFF logic as well (bringing ISL MFF value)
* 25/11/2023 - SP - Non-Face-Face should default to Face-Face attendance and if Face-Face has null price then default it to £197
* 07/02/2024 - SP - Updated the comments to exclude FU OPPROCS if there is no tariff (it will not default to £197)
  03/06/2024 - SP - Modified the SQL code to work with FY change, amemended the tariff tables
  01/08/2024 - SP - Topups to be removed for the ERF (agreed with James Lutaya)
  09/08/2024 - SP - Added additional column for topups
  05/11/2024 - SP - MFF table no longer required, repointing to ISL MFF
  02/09/2025 - SP - Changes to the 25/26 methodology based on new guidance where the default tariff (where there is no national tariff) is £210 and £105
  27/09/2025 - SP - Changes to the MFF table and moving to granular and commenting the GROUP BY 
*-------------------------------------------------------------------------------------------------------------------------------
**/


ALTER   VIEW [ERF].[vw_OP_RePriced_Activity_2526]
AS

-- OUTPATIENT PROCEDURES  				
WITH Data as (
SELECT 
	SK_EncounterID,
	Der_Activity_Month = LEFT(OPA.[dv_Activity_Period_Date], 6),
	dv_FinYear,
	dv_FinMonth,
	-- Provider code to assign activity carried out in NHS Trusts to an STP, and split data by provider					
	Provider_Code = OPA.Organisation_Code_Code_of_Provider, -- LEFT(OPA.Organisation_Code_Code_of_Provider, 3),
	-- Provider Type
	Provider_Type =
					CASE WHEN LEFT(OPA.Organisation_Code_Code_of_Provider, 3) IN ('RAX', 'RJ6', 'RJ7', 'RPY', 'RVR') then 'SWL Trust'
						 WHEN LEFT(OPA.Organisation_Code_Code_of_Commissioner,3) IN ('36L','07V','08J','08P','08R','08T','08X') AND ORG.OrganisationPrimaryRole IN ('RO172', 'RO176') THEN 'ISP'
						 WHEN LEFT(OPA.Organisation_Code_Code_of_Commissioner,3) IN ('36L','07V','08J','08P','08R','08T','08X') AND ORG.OrganisationPrimaryRole IN ('RO197', 'RO198') THEN 'OOS'
						 ELSE 'Unknown'
					END,
	Commissioner_Code = Organisation_Code_Code_of_Commissioner,
	CommissionedBy= CASE 
						WHEN LEFT(OPA.Organisation_Code_Code_of_Commissioner,3) IN ('36L','07V','08J','08P','08R','08T','08X') AND   ([dv_SpecCom_ServiceCode_National] IS NULL OR [dv_SpecCom_ServiceCode_National]  LIKE 'CCG%') THEN 'SWL ICB' 
						WHEN LEFT(OPA.Organisation_Code_Code_of_Commissioner,3) NOT IN ('36L','07V','08J','08P','08R','08T','08X') AND ([dv_SpecCom_ServiceCode_National] IS NULL OR [dv_SpecCom_ServiceCode_National]  LIKE 'CCG%')  THEN 'Other ICB' 
						WHEN LEFT(OPA.Organisation_Code_Code_of_Commissioner,3) IN ('13R','Y56','13Q','Y59','Y56','Y62','Y60','Y58','14M','Y61','Y63','97T','14G','14T','14E','14A') OR [dv_SpecCom_ServiceCode_National] LIKE 'N%' THEN 'Spec Comm' 				
					ELSE 'Unknown' END,
	--If there is no National Tariff for the submitted OP PROC, change the appointment type
	Der_Appointment_Type =   CASE WHEN /*Prices2324.[National Tariff]*/ Outpatient_Procedure_Tariff IS NULL 
							   AND ( 
									CASE	
										WHEN OPA.First_Attendance = 1 and OPA.Treatment_Function_Code <> 812 THEN [WF01B_First_Attendance_Single_Professional]--Prices2324a.WF01B
										WHEN OPA.First_Attendance = 3 and OPA.Treatment_Function_Code <> 812 THEN [WF02B_First_Attendance_Multiprofessional]--Prices2324a.WF02B
									ELSE 0 END
									) <> 0 THEN 'OPFA'
							 ELSE 'OPPROC'
							END,
	--Derived HRG Code as there is no National Tariff for the submitted OP PROC, default it to FA (HRG in brackets represent the original PROC HRG)
	HRG_Code = CASE WHEN /*Prices2324.[National Tariff]*/ Outpatient_Procedure_Tariff IS NULL THEN 
							CONCAT(
							CASE
								WHEN OPA.First_Attendance = 1 and OPA.Treatment_Function_Code <> 812 THEN 'WF01B'
								WHEN OPA.First_Attendance = 3 and OPA.Treatment_Function_Code <> 812 THEN 'WF02B'
								ELSE 'Unk' 
							END,'(',OPA.[Core_HRG], ')')
						ELSE OPA.[Core_HRG] END,
	OPA.Treatment_Function_Code,
	---- Site Code					
	OPA.[Site_code_of_Treatment],
	--If there is no National Tariff for the submitted OP PROC, default it to FA Tariff 
	National_Price = coalesce(/*Prices2324.[National Tariff]*/ Outpatient_Procedure_Tariff,
							-- Where there is no national price for OPPROC use the corresponding OP attendance tariff based on FA or FU
							CASE	WHEN OPA.First_Attendance = 1 and OPA.Treatment_Function_Code <> 812 THEN [WF01B_First_Attendance_Single_Professional]--Prices2324a.WF01B
									WHEN OPA.First_Attendance = 3 and OPA.Treatment_Function_Code <> 812 THEN [WF02B_First_Attendance_Multiprofessional]--Prices2324a.WF02B
									ELSE 0 -- This will exclude FU OPPROCS which havent got a tariff>> NHSE: If an OPROCFU is coded as an OPAFU due to there bring no HRG price then it is out of scope of ERF.
							END),
	Specialist_Topup = COALESCE(topup.Rate, 1),
	--TU2.Fin_Year as Tariff_Used,
	dv_MFF_Index_Applied
	,[dv_Total_Cost_Inc_MFF_Original],
	[Organisation_Code_PCT_of_Residence],
	[dv_SpecCom_ServiceCode_National],
	[PCT_Derived_from_GP_Practice],
	GP_Practice_Code_Original_Data,
	[OP].[GetPodType](OPA.[Core_HRG],Attended_Or_Did_Not_Attend, First_Attendance, Main_Specialty_Code) as POD_Detail,
	Appointment_Date
FROM [Data_Lab_SWL].[ERF].[vw_OP_DateRange_2526] AS OPA
LEFT JOIN (select HRG_Code, Outpatient_Procedure_Tariff from [SWL].[tbl_Tariff_APC_OPPROC] Prices2425 where outpatient_procedure_tariff is not null AND FinancialYear = '2025/2026') tariff_proc ON OPA.[Core_HRG] = tariff_proc.[HRG_Code] 
LEFT JOIN [Data_Lab_SWL].[PLNG].[tbl_Specialist_TopUp_Rates] topup ON topup.[PSS_Flag] = [dv_SpecCom_ServiceCode_National] AND Financial_Year = '2025/2026'
LEFT JOIN [Dictionary].[dbo].[Organisation] ORG ON ORG.Organisation_Code = CASE when RIGHT(Organisation_Code_Code_of_Provider,2)= '00' then LEFT(Organisation_Code_Code_of_Provider,3) ELSE Organisation_Code_Code_of_Provider END
LEFT JOIN [SWL].[tbl_Tariff_OP] tariff on tariff.[Treatment_Function_Code] = OPA.Treatment_Function_Code and FinancialYear = '2025/2026'
WHERE 1 = 1
	-- Range of baseline for the scheme					
	-- Method to identify patients who attended
	AND OPA.Attended_Or_Did_Not_Attend IN ('5', '6')
	-- Method used to exclude overseas patients, private patients and patients from Wales, Scotland, Northern Ireland and Isle of Man (i.e. responsibility of devolved administration) 					
	AND OPA.Administrative_Category NOT IN ('2','02')
	-- Method to exclude maternity pathway activity procedure (activity for subchapter NZ (maternity) is excluded)				
	AND OPA.[Core_HRG] NOT LIKE 'NZ%'
	-- Method to exclude mental health TFCs and Maternity TFCs					
	AND OPA.Treatment_Function_Code NOT IN ('501', '560', '700', '710', '711', '712', '713', '715', '720', '721', '722', '723', '724', '725', '726', '727', '199', '499')
	-- To Exclude TOPs HRGs					
	AND OPA.[Core_HRG] NOT IN ('MA50Z', 'MA51Z', 'MA52A', 'MA52B', 'MA53Z', 'MA54Z', 'MA55A', 'MA55B', 'MA56A', 'MA56B')
	--Method to include priced OP procedures only, if marked as local priced will still be included					
	AND OPA.[Core_HRG] <> 'NULL'
	-- Method to exclude 'UZ%' HRG where 'Data Invalid for Grouping'					
	AND OPA.[Core_HRG] NOT LIKE 'UZ%'
	
	-- Exclude zero priced activity	even if it defaults to FU tariff				
	AND coalesce(tariff_proc.Outpatient_Procedure_Tariff, 
							-- Where there is no national price for OPPROC use the corresponding OP attendance tariff based on FA or FU
							CASE	WHEN OPA.First_Attendance = 1 and OPA.Treatment_Function_Code <> 812 THEN [WF01B_First_Attendance_Single_Professional]--Prices2324a.WF01B
									WHEN OPA.First_Attendance = 3 and OPA.Treatment_Function_Code <> 812 THEN [WF02B_First_Attendance_Multiprofessional]--Prices2324a.WF02B
									ELSE 0 
							END) <> 0
	AND (LEFT(OPA.Organisation_Code_Code_of_Provider, 3) IN ('RAX', 'RJ6', 'RJ7', 'RPY', 'RVR') OR LEFT(OPA.Organisation_Code_Code_of_Commissioner, 3) IN ('36L', '07V', '08J', '08P', '08R', '08T', '08X'))
	AND OPA.[Core_HRG] not like 'WF%'
	-- Exclude devolved assemblies such as Welsh, Scotland etc..
	AND ORG.OrganisationPrimaryRole NOT IN ('RO144', 'RO190', 'RO155')
	-- Exclude Private patients
	AND NOT(Organisation_Code_Code_of_Commissioner like 'VPP00')

--Outpatient Attendances

UNION ALL
--OP Attendances
SELECT 
	SK_EncounterID,
	Der_Activity_Month = LEFT(OPA.[dv_Activity_Period_Date], 6),
	dv_FinYear,
	dv_FinMonth,
	-- Provider code to assign activity carried out in NHS Trusts to an STP, and split data by provider					
	Provider_Code = OPA.Organisation_Code_Code_of_Provider, --LEFT(OPA.Organisation_Code_Code_of_Provider, 3),
	-- Provider Type
	Provider_Type =
					CASE WHEN LEFT(OPA.Organisation_Code_Code_of_Provider, 3) IN ('RAX', 'RJ6', 'RJ7', 'RPY', 'RVR') then 'SWL Trust'
						 WHEN LEFT(OPA.Organisation_Code_Code_of_Commissioner,3) IN ('36L','07V','08J','08P','08R','08T','08X') AND ORG.OrganisationPrimaryRole IN ('RO172', 'RO176') THEN 'ISP'
						 WHEN LEFT(OPA.Organisation_Code_Code_of_Commissioner,3) IN ('36L','07V','08J','08P','08R','08T','08X') AND ORG.OrganisationPrimaryRole IN ('RO197') THEN 'OOS'
						 ELSE 'Unknown'
					END,
	Commissioner_Code = Organisation_Code_Code_of_Commissioner,
	CommissionedBy= CASE 
						WHEN LEFT(OPA.Organisation_Code_Code_of_Commissioner,3) IN ('36L','07V','08J','08P','08R','08T','08X') AND   ([dv_SpecCom_ServiceCode_National] IS NULL OR [dv_SpecCom_ServiceCode_National]  LIKE 'CCG%') THEN 'SWL ICB' 
						WHEN LEFT(OPA.Organisation_Code_Code_of_Commissioner,3) NOT IN ('36L','07V','08J','08P','08R','08T','08X') AND ([dv_SpecCom_ServiceCode_National] IS NULL OR [dv_SpecCom_ServiceCode_National]  LIKE 'CCG%')  THEN 'Other ICB' 
						WHEN LEFT(OPA.Organisation_Code_Code_of_Commissioner,3) IN ('13R','Y56','13Q','Y59','Y56','Y62','Y60','Y58','14M','Y61','Y63','97T','14G','14T','14E','14A') OR [dv_SpecCom_ServiceCode_National] LIKE 'N%' THEN 'Spec Comm' 				
					ELSE 'Unknown' END,
	--Der_Appointment_Type = CASE WHEN [First_Attendance] IN (1,3) THEN 'OPFA' WHEN [First_Attendance] IN (2,4) THEN 'OPFU' ELSE 'Unknown' END,	
	Der_Appointment_Type = CASE 
		WHEN [First_Attendance] IN (1,3) THEN 'OPFA' 
		WHEN [First_Attendance] IN (2,4) 
			 AND LEFT(OPA.Organisation_Code_Code_of_Commissioner,3) IN ('36L','07V','08J','08P','08R','08T','08X') 
			 AND ORG.OrganisationPrimaryRole IN ('RO172', 'RO176') THEN 'OPFU'
		ELSE 'Unknown' 
	END,
	HRG_Code = OPA.Core_HRG,
	OPA.Treatment_Function_Code,
	---- Site Code					
	OPA.[Site_code_of_Treatment],
	National_Price =
						CASE
						--WHEN (OPA.[Core_HRG] = 'WF01A') THEN Prices2324.WF01A
						WHEN (OPA.[Core_HRG] = 'WF01B' OR OPA.[Core_HRG] = 'WF01D') THEN [WF01B_First_Attendance_Single_Professional]--Prices2324.WF01B
						--WHEN (OPA.[Core_HRG] = 'WF02A') THEN Prices2324.WF02A
						WHEN (OPA.[Core_HRG] = 'WF02B' OR OPA.[Core_HRG] = 'WF02D') THEN [WF02B_First_Attendance_Multiprofessional]--Prices2324.WF02B
						ELSE NULL
						END,
	Specialist_Topup = COALESCE(topup.Rate, 1),
	--TU2.Fin_Year as Tariff_Used,
	dv_MFF_Index_Applied,
	[dv_Total_Cost_Inc_MFF_Original],
	[Organisation_Code_PCT_of_Residence],
	[dv_SpecCom_ServiceCode_National],
	[PCT_Derived_from_GP_Practice],
	GP_Practice_Code_Original_Data,
	[OP].[GetPodType](OPA.[Core_HRG],Attended_Or_Did_Not_Attend, First_Attendance, Main_Specialty_Code) as POD_Detail,
	opa.Appointment_Date

FROM [Data_Lab_SWL].[ERF].[vw_OP_DateRange_2526] AS OPA
LEFT JOIN [SWL].[tbl_Tariff_OP] tariff on tariff.[Treatment_Function_Code] = OPA.Treatment_Function_Code AND tariff.FinancialYear = '2025/2026'
LEFT JOIN [Data_Lab_SWL].[PLNG].[tbl_Specialist_TopUp_Rates] topup ON topup.[PSS_Flag] = [dv_SpecCom_ServiceCode_National] AND Financial_Year = '2025/2026'
LEFT JOIN [Dictionary].[dbo].[Organisation] ORG ON ORG.Organisation_Code = CASE when RIGHT(Organisation_Code_Code_of_Provider,2)= '00' then LEFT(Organisation_Code_Code_of_Provider,3) ELSE Organisation_Code_Code_of_Provider END
WHERE 1 = 1
	-- Range of baseline for the scheme						
	-- Method to identify patients who attended
	AND OPA.Attended_Or_Did_Not_Attend IN ('5', '6')	
	AND OPA.Administrative_Category NOT IN ('2','02')
	-- Method to exclude maternity pathway activity procedure					
	AND OPA.[Core_HRG] NOT LIKE 'NZ%'
	-- Method to exclude mental health TFCs and Maternity TFCs					
	AND OPA.Treatment_Function_Code NOT IN ('501', '560', '700', '710', '711', '712', '713', '715', '720', '721', '722', '723', '724', '725', '726', '727', '199', '499',  '812')
	-- To Exclude TOPs HRGs					
	AND OPA.[Core_HRG] NOT IN ('MA50Z', 'MA51Z', 'MA52A', 'MA52B', 'MA53Z', 'MA54Z', 'MA55A', 'MA55B', 'MA56A', 'MA56B')
	--Method to include priced OP procedures only, if marked as local priced will still be included						
	AND OPA.[Core_HRG] <> 'NULL' --??
	-- Method to exclude 'UZ%' HRG where 'Data Invalid for Grouping'					
	AND OPA.[Core_HRG] NOT LIKE 'UZ%'
	AND (LEFT(OPA.Organisation_Code_Code_of_Provider, 3) IN ('RAX', 'RJ6', 'RJ7', 'RPY', 'RVR') OR LEFT(OPA.Organisation_Code_Code_of_Commissioner, 3) IN ('36L', '07V', '08J', '08P', '08R', '08T', '08X'))
	--with any WF subchapter HRG (i.e. includes first attendances that are consultant-led and non-consultant-led, face to face and non-face to face, multi-professional and single professional)
	AND OPA.[Core_HRG] like 'WF%'
	--which is a first outpatient attendance, follow-ups are excluded
	--AND OPA.First_Attendance in (1, 3)
	AND (
		OPA.First_Attendance IN (1, 3) -- First attendances for all providers
		OR (
			OPA.First_Attendance IN (2, 4) -- Follow-ups for IS providers only
			AND LEFT(OPA.Organisation_Code_Code_of_Commissioner,3) IN ('36L','07V','08J','08P','08R','08T','08X') 
			AND ORG.OrganisationPrimaryRole IN ('RO172', 'RO176')
		)
	)
	-- Exclude devolved asseblies such as Welsh, Scotland etc..
	AND ORG.OrganisationPrimaryRole NOT IN ('RO144', 'RO190', 'RO155')
	-- Exclude Private patients
	AND NOT(Organisation_Code_Code_of_Commissioner like 'VPP00')
)
,AggData as (
SELECT
     SK_EncounterID,
	 [Der_Activity_Month]
	,dv_FinYear
	,[dv_FinMonth]
	,[Provider_Code]
	,[Provider_Type]
	,[Commissioner_Code]
	,[CommissionedBy]
	,[Der_Appointment_Type]
	,[HRG_Code] -- --Derived HRG Code as there is no National Tariff for the submitted OP PROC, default it to FA (HRG in brackets represent the original PROC HRG)
	,[Treatment_Function_Code]
	,[Site_code_of_Treatment]
	,National_Price
	-- Apply flat price for First where there was no National Price					
	--,Price_to_apply = CASE WHEN National_Price IS NULL THEN 197 ELSE National_Price END
	,Price_to_apply = CASE 
		WHEN National_Price IS NULL THEN 
			CASE WHEN Der_Appointment_Type LIKE 'OPFA' THEN 210  -- First attendances (all providers)
				WHEN Der_Appointment_Type LIKE 'OPFU' THEN 105 ELSE 0   -- Follow-ups (IS providers only)
			END
		ELSE National_Price 
	END,
	1 as Activity,
	--,COUNT(DISTINCT SK_EncounterID) AS Activity
	dv_MFF_Index_Applied as MFF,
	--,coalesce([2023_24_MFF], dv_MFF_Index_Applied, 1.061299920) as MFF --SP 05/11/2024 - no longer required
	'2025/2026'as Tariff_Used,
	Specialist_Topup,
	[Organisation_Code_PCT_of_Residence],
	[dv_SpecCom_ServiceCode_National] as ServiceCode,
	[PCT_Derived_from_GP_Practice] as [Organisation_Code_PCT_of_GP_Practice],
	GP_Practice_Code_Original_Data,
	POD_Detail,
	Appointment_Date
	--,[dv_Total_Cost_Inc_MFF_Original]
FROM Data d
LEFT JOIN [SWL].[tbl_MFF] MFF on MFF.[ProviderCode] = [Provider_Code] and mff.Financial_Year = d.dv_FinYear
--LEFT JOIN  Data_Lab_SWL_Dev.[SWL].[ERF_MFF_DATA_2324] MFF on MFF.[Provider Code] = [Provider_Code]
--GROUP BY
--	   [Der_Activity_Month]
--	  ,dv_FinYear
--      ,[dv_FinMonth]
--      ,[Provider_Code]
--      ,[Provider_Type]
--      ,[Commissioner_Code]
--      ,[CommissionedBy]
--      ,[Der_Appointment_Type]
--      ,[HRG_Code]
--      ,[Treatment_Function_Code]
--      ,[Site_code_of_Treatment]
--      ,National_Price
--	  ,dv_MFF_Index_Applied
--	  --,coalesce([2023_24_MFF], dv_MFF_Index_Applied, 1.061299920)--SP 05/11/2024 - no longer required
--	  --,coalesce(Tariff_Used,'2023/24_V1.1')
--	  ,Specialist_Topup
--	  ,[Organisation_Code_PCT_of_Residence]
--	  ,[dv_SpecCom_ServiceCode_National]
--	  ,[PCT_Derived_from_GP_Practice]
--	  --,[dv_Total_Cost_Inc_MFF_Original]
)
SELECT 
	 [Der_Activity_Month]
	,dv_FinYear
	,[dv_FinMonth]
	,[Provider_Code]
	,[Provider_Type]
	,[Commissioner_Code]
	,[CommissionedBy]
	,[Der_Appointment_Type]
	,[HRG_Code]
	,[Treatment_Function_Code]
	,[Site_code_of_Treatment]
	,National_Price
	,Activity
	,MFF
	,Tariff_Used
	,[Organisation_Code_PCT_of_Residence]
	,ServiceCode
	,Price_to_apply
	,Price_to_apply * Activity * MFF /* * Specialist_Topup */ as TotalCostInclMFF
	,Price_to_apply * Activity * MFF  * Specialist_Topup  as TotalCostInclMFF_Topup
	,[Organisation_Code_PCT_of_GP_Practice]
	,SK_EncounterID
	,GP_Practice_Code_Original_Data
	,POD_Detail
	,Appointment_Date
	--,[dv_Total_Cost_Inc_MFF_Original]
--into dbo.tbl_temp_OP_191023_SP_DeleteLater
FROM AggData 
WHERE 1=1
	-- Exclude Bridgestock family practice from Croydons data as they are not performing Elective activity
	--SP 
	--AND ISNULL([Site_code_of_Treatment],'') NOT IN ('RJ661')
	-- Exclude Commissioner Codes from the table ERF.tbl_Excluded_Commissioners as these are identified by Finance 
	--AND LEFT(Commissioner_Code,3) NOT IN (SELECT Commissioner_Code FROM ERF.tbl_Excluded_Commissioners)
GO



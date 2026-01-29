USE [Data_Lab_SWL]
GO

/****** Object:  View [ERF].[vw_IP_DateRange_2526]    Script Date: 06/01/2026 15:12:58 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

























/**
---------------------------------------------------------------------------------------------------
 View to retrieve all Financial Years OP data recosted to 23/24 Consultation Grouper 
 28/09/2023 - SP - Initial Creation
 --------------------------------------------------------------------------------------------------

 **/
ALTER VIEW [ERF].[vw_IP_DateRange_2526]
AS
WITH ip_data AS
(
SELECT SK_EncounterID, [Unique_CDS_Identifier], [Spell_Identifier], [Core_HRG_Calculated],[Spell_Core_HRG],[dv_HRG], dv_Total_Cost_Inc_MFF

FROM [SUS].[IP].[EncounterDenormalised_DateRange] EDn  WITH (NOLOCK)
WHERE 1=1 
and LEFT (EDn.dv_FinYear,4) IN ( 2024, 2025)
and dv_IsSpell = 1
)
/****** Script for SelectTopNRows command from SSMS  ******/
SELECT 
	   ip.[SK_EncounterID]
      ,ip.[dv_Extract_Type]
      ,ip.[dv_Query_ID]
      ,ip.[dv_FinYear]
      ,ip.[dv_FinMonth]
      ,ip.[dv_Activity_Period_Date]
      ,ip.[Generated_Record_ID]
      ,ip.[Spell_Identifier]
      ,ip.[Unique_CDS_Identifier]
      ,ip.[Hospital_Provider_Spell_No]
      ,ip.[Referrer_Code]
      ,ip.[Referring_Organisation_Code]
      ,ip.[Organisation_Code_Patient_Pathway_Identifier]
      ,ip.[RTT_Patient_Pathway_Identifier]
      ,ip.[RTT_Period_End_Date]
      ,ip.[RTT_Period_Start_Date]
      ,ip.[dv_RTT_Length_Derived]
      ,ip.[RTT_Status]
      ,ip.[Decided_To_Admit_Date]
      ,ip.[Episode_Start_Date]
      ,ip.[Episode_End_Date]
      ,ip.[dv_EpisodeGrossLengthOfStay]
      ,ip.[Episode_Number]
      ,ip.[Last_Episode_in_Spell_Indicator]
      ,ip.[Start_Date_Hospital_Provider_Spell] as Admission_Date
      ,ip.[Start_Time_Hospital_Provider_Spell] 
      ,ip.[End_Date_Hospital_Provider_Spell] as Discharge_Date
      ,ip.[Discharge_Time_Hospital_Provider_Spell]
      ,ip.[Ready_For_Discharge_Date]
      ,ip.[dv_LengthOfStay_Gross]
      ,ip.[dv_CDSActivityDate]
      ,ip.[Source_of_Admission_Hospital_Provider_Spell]
      ,ip.[Discharge_Destination_Hospital_Provider_Spell]
      ,ip.[Discharge_Method_Hospital_Provider_Spell]
      ,ip.[Administrative_Category_on_Admission]
      ,ip.[First_Regular_Day_Night_Admission]
      ,ip.[Intended_Management]
      ,ip.[Patient_Classification]
      ,ip.[Admission_Method_Hospital_Provider_Spell]
      ,ip.[Age_Group_Intended_at_Epiend]
      ,ip.[Neonatal_Level_of_Care]
      ,ip.[dv_NumberDiagnoses]
      ,ip.[dv_NumberProcedures]
      ,ip.[dv_NumberUnbundledHRGs]
      ,ip.[SK_PatientID]
      ,ip.[DW_NHS_Number]
      ,ip.[CCG_NHS_Number]
      ,ip.[Local_Patient_Identifier]
      ,ip.[Carer_Support_Indicator]
      ,ip.[Ethnic_Category_Code]
      ,ip.[Age_At_CDS_Activity_Date]
      ,ip.[Birth_Date]
      ,ip.[dv_YearOfBirth]
      ,ip.[Gender_Code]
      ,ip.[Postcode_of_Usual_Address]
      ,ip.[dv_LSOACode]
      ,ip.[Legal_Status_Classification_Code]
      ,ip.[GP_Code_Original_data]
      ,ip.[GP_Practice_Code_Original_Data]
      ,ip.[GP_Practice_Code_Derived]
      ,ip.[dv_PracticeCode_Validated]
      ,ip.[Provider_Reference_No]
      ,ip.[Commissioner_Reference_No]
      ,ip.[Commissioner_Serial_No_Agreement_No]
      ,ip.[NHS_Service_Agreement_Line_No]
      ,ip.[Consultant_Code]
      ,ip.[Main_Specialty_Code]
      ,ip.[Treatment_Function_Code]
      ,ip.[Local_Sub_Specialty_Code]
      ,ip.[Ward_Code_at_Episode_Start_Date]
      ,ip.[Ward_Code_at_Episode_End_Date]
      ,ip.[dv_WardCode_At_Admission]
      ,ip.[dv_WardCode_At_Discharge]
      ,ip.[dv_SpecCom_ServiceCode_National_Episode]
      ,ip.[dv_SpecCom_ServiceCode_National_Spell] as [dv_SpecCom_ServiceCode_National_Spell_Original]
      ,ip.[dv_SpecCom_ServiceCode_Local_Episode]
      ,ip.[dv_SpecCom_ServiceCode_Local_Spell]
      ,ip.[Organisation_Code_Code_of_Provider]
      ,ip.[Organisation_Code_Code_of_Commissioner] as [Organisation_Code_Code_of_Commissioner_Original] -->
	  ,[Organisation_Code_Code_of_Commissioner] = CASE WHEN LEFT(ISNULL([Organisation_Code_Code_of_Commissioner],''), 3) IN ('13Q', '14R','14T', '14Q', '14M', '15L', '32T', '76A', '97T') THEN Patient_PostCode_Derived_PCT ELSE [Organisation_Code_Code_of_Commissioner] END
      ,ip.[Site_code_of_Treatment_at_start_of_episode]
      ,ip.[Organisation_Code_PCT_of_Residence]
      ,ip.[Commissioner_Code_Original_Data]
      ,ip.[PCT_Derived_from_GP_Practice]
      ,ip.[Patient_Postcode_Derived_PCT]
      ,ip.[dv_CCAM_SEL]
      ,ip.[dv_CCAM_SWL]
      ,ip.[dv_Commissioner_Code_of_Residence]
      ,ip.[dv_Purchaser_ID]
      ,ip.[dv_Contract_Suffix]
      ,ip.[dv_CostMethodDescription]
      ,ip.[Programme_Budgeting_Category]      
      ,ip.[Spell_In_Pbr_Not_In_Pbr]
      ,ip.[dv_IsPBR]
      ,ip.[dv_ApplicableTariff]
      ,ip.[dv_Base_Cost]
      ,ip.[dv_IsShortStay]
      ,ip.[dv_SpecialServiceID]
      ,ip.[dv_ServiceAdjustment_Cost]
      ,ip.[dv_BestPracticeTariff_Code]
      ,ip.[dv_SpecialistPalliativeCareDays]
      ,ip.[dv_RehabDays]
      ,ip.[dv_DelayedDischargeDays]
      ,ip.[dv_TariffType]
      ,ip.[dv_LengthOfStay_Net] AS [dv_LengthOfStay_Net_Original]
      ,ip.[dv_ExcessBedDays] as [dv_ExcessBedDays_Original]
      ,ip.[dv_ExcessBedDays_Cost]
      ,ip.[dv_MFF_Index_Applied]
      ,ip.[Pbr_Final_Tariff]
      ,ip.[dv_Total_Cost_Inc_MFF] as [dv_Total_Cost_Inc_MFF_Original]
	  --FROM REPRICED TABLE
	  --changed this to restrict to the filtered FY otherwise use the payment grouper
	  ,CASE WHEN dv_FinYear IN ('2019/2020','2020/2021','2022/2023','2023/2024', '2024/2025') THEN ip_r.[Total_Cost] ELSE ip.[dv_Total_Cost_Inc_MFF] END as [dv_Total_Cost_Inc_MFF]
      ,ip.[Primary_Diagnosis_Code]
      ,ip.[dv_IsSpell]
      ,ip.[Operation_Status]
      ,ip.[Primary_Procedure_Code]
      ,ip.[dv_Unbundled_Days_Total]
      ,ip.[dv_Unbundled_Cost_Total]
      ,ip.[dv_Critical_CareDay_Count]
	  ,ip.[Core_HRG_Calculated]
	 -- ,ip_o.Spell_Core_HRG as Old_Spell_Core_HRG
      ,ip.[dv_HRG]
      ,ip.[dv_Local_Cost_Code]
      ,ip.[dv_Reason_for_Difference]
	  ,ip.[Spell_Core_HRG] as [Spell_Core_HRG_Original]
	   -- 23/24 will use the defaults
	  ,CASE WHEN dv_FinYear IN ('2019/2020','2020/2021','2022/2023','2023/2024', '2024/2025') THEN ip_r.HRG_Code ELSE ip.[Spell_Core_HRG] END as [Spell_Core_HRG] -- as there is an issue with 21/22 grouped revert to 21/22 
	  ,CASE WHEN dv_FinYear IN ('2019/2020','2020/2021','2022/2023','2023/2024', '2024/2025') THEN ip_r.Outlier_Days ELSE ip.[dv_ExcessBedDays] END as [dv_ExcessBedDays]-- as there is an issue with 21/22 grouped revert to 21/22 
	  ,CASE WHEN dv_FinYear IN ('2019/2020','2020/2021','2022/2023','2023/2024', '2024/2025') THEN ip_r.SpellServiceLine ELSE [dv_SpecCom_ServiceCode_National_Spell] END  as [dv_SpecCom_ServiceCode_National_Spell]-- as there is an issue with 21/22 grouped revert to 21/22 
	  ,CASE WHEN dv_FinYear IN ('2019/2020','2020/2021','2022/2023','2023/2024', '2024/2025') THEN ip_r.Adj_Final_Length_Of_Stay ELSE [dv_LengthOfStay_Net] END  [dv_LengthOfStay_Net]
	  ,CASE 
		WHEN LEFT(ISNULL([Organisation_Code_Code_of_Commissioner],''), 3) in ('36L','07V','08J','08P','08R','08T','08X') OR 
		LEFT(ISNULL(Organisation_Code_PCT_of_Residence,''), 3) in ('36L','07V','08J','08P','08R','08T','08X') OR
		LEFT(ISNULL(Commissioner_Code_Original_Data,''), 3) in ('36L','07V','08J','08P','08R','08T','08X') OR
		LEFT(ISNULL(PCT_Derived_from_GP_Practice,''), 3) in ('36L','07V','08J','08P','08R','08T','08X') OR
		LEFT(ISNULL(Patient_Postcode_Derived_PCT,''), 3) in ('36L','07V','08J','08P','08R','08T','08X') OR
		LEFT(ISNULL(dv_Commissioner_Code_of_Residence,''), 3) in ('36L','07V','08J','08P','08R','08T','08X') OR
		LEFT(ISNULL(dv_Purchaser_ID,''), 3) in ('36L','07V','08J','08P','08R','08T','08X') THEN 1
		ELSE 0
	   END as Is_SWLPatient,	   
	   dt.ISOWeekOfFiscalYearNumber as WeekNumber,
	    EndOfISOWeekDate as WeekEndingDt,	 
		coalesce(bh.IsBankholiday,0) as IsBankholiday,
		coalesce(sd.IsStrikeday,0) as IsStrikeday,
		dt.IsWeekend,
		CASE WHEN IsWeekend = 1 then 0 ELSE 1 END as IsWeekday,
		[DayofWeek]
  
  
  FROM ip_data ip_o
inner JOIN sus.IP.EncounterDenormalised_DateRange ip WITH (NOLOCK) on ip_o.SK_EncounterID = ip.SK_EncounterID
--****IMPORTANT*** If the Financial year changes change the costing alogrithm code
left JOIN [SUS].[IP].[EncounterBillingRepriced] ip_r WITH (NOLOCK) ON ip.SK_EncounterID = ip_r.SK_EncounterID and ip_r.SK_CostingAlgorithmID = 111 
inner JOIN [Dictionary].[dbo].[Dates] dt WITH (NOLOCK) on dt.FullDate = [End_Date_Hospital_Provider_Spell]
LEFT JOIN [SWL].[vw_Bankholidays_Daily] bh WITH (NOLOCK) on bh.BankholidayDate = dt.FullDate
LEFT JOIN [SWL].[vw_Strikedays_Daily] sd WITH (NOLOCK) on sd.Strikedate = dt.FullDate

where 1=1
--and dv_IsSpell = 1


GO



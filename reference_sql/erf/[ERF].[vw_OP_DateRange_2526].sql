USE [Data_Lab_SWL]
GO

/****** Object:  View [ERF].[vw_OP_DateRange_2526]    Script Date: 06/01/2026 15:14:26 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO










/**
 View to retrieve all Financial Years OP data recosted to 23/24 Consultation Grouper 
**/
ALTER   VIEW [ERF].[vw_OP_DateRange_2526]
AS

WITH op_data AS
(
SELECT Core_HRG, dv_HRG, dv_Total_Cost_Inc_MFF, SK_EncounterID, Attendance_Identifier
FROM sus.OP.EncounterDenormalised_DateRange EDn
WHERE 1=1 
and LEFT (EDn.dv_FinYear,4) IN (2024, 2025)
--and dv_HRG not like 'WF%'
)
SELECT  --op_r.*,
op.[SK_EncounterID]
    ,op.[dv_Extract_Type]
      ,op.[dv_Query_ID]
      ,op.[dv_FinYear]
      ,op.[dv_FinMonth]
      ,op.[dv_Activity_Period_Date]
      ,op.[dv_Month_at_End_Activity]
      ,op.[Generated_Record_ID]
      ,op.[Attendance_Identifier]
      ,op.[Spell_Identifier]
      ,op.[Unique_CDS_Identifier]
      ,op.[Referrer_Code]
      ,op.[Referring_Organisation_Code]
      ,op.[Referral_Request_Received_Date]
      ,op.[Priority_Type]
      ,op.[Service_Type_Requested]
      ,op.[Source_of_Referral_for_Outpatients]
      ,op.[Is_Valid_UBRN]
      ,op.[UBRN_Occurrence_Count]
      ,op.[Organisation_Code_Patient_Pathway_Identifier]
      ,op.[RTT_Patient_Pathway_Identifier]
      ,op.[RTT_Period_Start_Date]
      ,op.[RTT_Period_End_Date]
      ,op.[dv_RTT_Length_Derived]
      ,op.[RTT_Status]
      ,op.[Appointment_Date]
      ,op.[Appointment_Time]
      ,op.[dv_CDSActivityDate]
      ,op.[Administrative_Category]
      ,op.[First_Attendance]
      ,op.[Attended_Or_Did_Not_Attend]
      ,op.[Outcome_of_Attendance]
      ,op.[Consultant_Code]
      ,op.[Medical_Staff_Type_Seeing_Patient]
      ,op.[Location_Type_Code]
      ,op.[SK_PatientID]
      ,op.[DW_NHS_Number]
      ,op.[CCG_NHS_Number]
      ,op.[Local_Patient_Identifier]
      ,op.[Ethnic_Category_Code]
      ,op.[Age]
      ,op.[dv_YearOfBirth]
      ,op.[Gender_Code]
      ,op.[Postcode_of_Usual_Address]
      ,op.[dv_LSOA]
      ,op.[GP_Code]
      ,op.[GP_Practice_Code_Original_Data]
      ,op.[GP_Practice_Code_Derived]
      ,op.[dv_PracticeCode_Validated]
      ,op.[Provider_Reference_No]
      ,op.[Commissioner_Reference_No]
      ,op.[Commissioning_Serial_No_Agreement_No]
      ,op.[NHS_Service_Agreement_Line_No]
      ,op.[Main_Specialty_Code]
      ,op.[Treatment_Function_Code]
      ,op.[Local_Sub_Specialty_Code]
      ,op.[Clinic_Code]
	  ,op.[dv_SpecCom_ServiceCode_National] as [dv_SpecCom_ServiceCode_National_Original]
	  ,op_r.ServiceLine as [dv_SpecCom_ServiceCode_National]
      ,op.[dv_SpecCom_ServiceCode_Local]
      ,op.[Spell_NPOC]
      ,op.[Organisation_Code_Code_of_Provider]
      ,op.[Site_code_of_Treatment]
      ,op.[Organisation_Code_PCT_of_Residence]
      ,op.[Patient_Postcode_Derived_PCT]
      ,op.[Organisation_Code_Code_of_Commissioner]
      ,op.[PCT_Derived_from_GP_Practice]
      ,op.[dv_CCAM_SWL]
      ,op.[dv_Commissioner_Code_of_Residence]
      ,op.[dv_Purchaser_ID]
      ,op.[dv_Contract_Suffix]
      ,op.[dv_CostMethodDescription]
	  ,op_o.[Core_HRG] as [Core_HRG_Original]
	  ,coalesce(op_r.HRG_Code, op.[Core_HRG]) as [Core_HRG]
      --,HRG_Code as [Core_HRG] -- coalesce(HRG_Code, op.[Core_HRG])  as [Core_HRG] -- in case the 23/24 doesnt group revert it to the original grouped HRG from 19/20
      ,op.[dv_HRGUsedForTariff]
	  ,op.[dv_HRG] as [dv_HRG_Original]
	  ,coalesce(op_r.HRG_Code,op.dv_HRG) as [dv_HRG] 
      --,HRG_Code as [dv_HRG] -- coalesce(HRG_Code,op.dv_HRG) as [dv_HRG]  -- in case the 23/24 doesnt group revert it to the original PGISUS grouped HRG from 19/20
      ,op.[dv_Local_Cost_Code]
      ,op.[dv_Reason_for_Difference]
      ,op.[Spell_In_PbR_Not_In_PbR]
      ,op.[dv_IsPBR]
      ,op.[dv_ApplicableTariff]
	  ,op.[dv_Base_Cost] as [dv_Base_Cost_Original]
      ,Base_Cost as [dv_Base_Cost] -- coalesce(Base_Cost,[dv_Base_Cost])  as [dv_Base_Cost]  -- in case the 23/24 doesnt group revert it to the original PGISUS price from HRG from 19/20
      ,op.[dv_TariffType]
      ,op.[dv_MFF_Index_Applied]
      ,op.[Tariff_Initial_Amount_National]
      ,op.[Tariff_Pre_MFF_Adjusted_National]
      ,op.[Tariff_Total_Payment_National]
      ,op.[Pbr_Final_Tariff]
	  ,op.[dv_Total_Cost_Inc_MFF] as [dv_Total_Cost_Inc_MFF_Original]
      ,Total_Cost as [dv_Total_Cost_Inc_MFF] -- coalesce(Total_Cost,op.[dv_Total_Cost_Inc_MFF]) as [dv_Total_Cost_Inc_MFF]-- in case the 23/24 doesnt group revert it to the original PGISUS price from HRG from 19/20
      ,op.[Number_Diagnosis]
      ,op.[Primary_Diagnosis_Code]
      ,op.[Operation_Status]
      ,op.[Number_Procedures]
      ,op.[Primary_Procedure_Code]
      ,op.[Primary_Procedure_Date]
      ,op.[dv_Number_Unbundled_HRGs]
      ,op.[dv_Number_Unbundled_Non_Priced_HRGs]
      ,op.[dv_Number_Unbundled_Priced_HRGs]
	  ,coalesce(SK_CostingAlgorithmID, 109) as SK_CostingAlgorithmID
	  ,op_r.POD_Description
	  ,CASE 
		WHEN LEFT(ISNULL([Organisation_Code_Code_of_Commissioner],''), 3) in ('36L','07V','08J','08P','08R','08T','08X') OR 
		LEFT(ISNULL(Organisation_Code_PCT_of_Residence,''), 3) in ('36L','07V','08J','08P','08R','08T','08X') OR
		--LEFT(ISNULL(Commissioner_Code_Original_Data,''), 3) in ('36L','07V','08J','08P','08R','08T','08X') OR
		LEFT(ISNULL(PCT_Derived_from_GP_Practice,''), 3) in ('36L','07V','08J','08P','08R','08T','08X') OR
		LEFT(ISNULL(Patient_Postcode_Derived_PCT,''), 3) in ('36L','07V','08J','08P','08R','08T','08X') OR
		LEFT(ISNULL(dv_Commissioner_Code_of_Residence,''), 3) in ('36L','07V','08J','08P','08R','08T','08X') OR
		LEFT(ISNULL(dv_Purchaser_ID,''), 3) in ('36L','07V','08J','08P','08R','08T','08X') THEN 1
		ELSE 0
	   END as Is_SWLPatient,
	   ISOWeekOfFiscalYearNumber as WeekNumber,
	    EndOfISOWeekDate as WeekEndingDt,	 
		coalesce(bh.IsBankholiday,0) as IsBankholiday,
		coalesce(sd.IsStrikeday,0) as IsStrikeday,
		dt.IsWeekend,
		CASE WHEN IsWeekend = 1 then 0 ELSE 1 END as IsWeekday,
		[DayofWeek],
		SK_Date,
		Provider_Type = CASE WHEN LEFT(Organisation_Code_Code_of_Provider, 3) IN ('RAX', 'RJ6', 'RJ7', 'RPY', 'RVR') then 'SWL Trust'
						 WHEN LEFT(Organisation_Code_Code_of_Commissioner,3) IN ('36L','07V','08J','08P','08R','08T','08X') AND (Organisation_Code_Code_of_Provider) IN ('NPG00', 'NT3X3', 'NT436', 'NVC01', 'NVC11', 'ROF4N') THEN 'ISP'
						 --ORG.OrganisationPrimaryRole IN ('RO172', 'RO176') 
						 WHEN LEFT(Organisation_Code_Code_of_Commissioner,3) IN ('36L','07V','08J','08P','08R','08T','08X') AND  LEFT(Organisation_Code_Code_of_Provider, 3) IN ('R1H', 'R1K', 'RA2', 'RAL', 'RAN', 'RDU', 'RJ1', 'RJ2', 'RJZ', 'RP4', 'RP6', 'RQM', 'RRV', 'RTK', 'RTP', 'RY', 'RYR') THEN 'OOS'
						 --ORG.OrganisationPrimaryRole IN ('RO197', 'RO198') THEN 'OOS'
						 ELSE 'Unknown'
					END
  
FROM op_data op_o
inner JOIN sus.OP.EncounterDenormalised_DateRange op on op_o.SK_EncounterID = op.SK_EncounterID
--IMPORTANT If the Financial year changes change the costing alogrithm code below
left JOIN [SUS].[OP].[EncounterBillingRepriced] op_r ON op.SK_EncounterID = op_r.SK_EncounterID and op_r.SK_CostingAlgorithmID = 112
inner JOIN [Dictionary].[dbo].[Dates] dt on dt.FullDate = [Appointment_Date]
LEFT JOIN [SWL].[vw_Bankholidays_Daily] bh on bh.BankholidayDate = dt.FullDate
LEFT JOIN [SWL].[vw_Strikedays_Daily] sd on sd.Strikedate = dt.FullDate
WHERE 1=1
GO



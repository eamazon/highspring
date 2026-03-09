USE [Data_Lab_SWL]
GO

/****** Object:  StoredProcedure [CAM].[sproc_CAM_v5_3_IP]    Script Date: 26/09/2025 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON

GO

--ALTER PROCEDURE [CAM].[sproc_CAM_v5_3_IP]
--AS

---------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------
--- NOTE:                                                                                                               ---
--- Before proceeding, ensure that the following reference tables are set up in your database.  These are fixed         ---
--- tables derived from either ODS Organisational data, the ACM/PLCM Specifications or a hybrid of both data sources:   ---
---		[CAM_Ref].[ArmedForcesGP]                                                                                       ---
---		[CAM_Ref].[Ref_HandJ_CommissionerCode]                                                                          ---
---		[CAM_Ref].[REF_Provider]                                                                                        ---
---		[CAM_Ref].[ServiceCodes]                                                                                        ---
---		[CAM_Ref].[ServiceFlags]                                                                                        ---
---		[CAM_Ref].[SubICBtoDirectComm]                                                                                  ---
---		[CAM_Ref].[CommissionerAssignmentReason] (New to 25/26)                                                         ---
---		[CAM_Ref].[YearMonthBridge] (New to 25/26)                                                                      ---
---------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------------
--- 1a. Stage 1                                                                                     -----------------------
--- Create and load SUS IP activity into temp schema table that will create a reassignment ID       -----------------------
---------------------------------------------------------------------------------------------------------------------------

---DROP Temp Table to re-identify Commissioner Assignment as per Delegation Guidance
IF EXISTS (
	SELECT * FROM INFORMATION_SCHEMA.TABLES
	WHERE TABLE_NAME = 'DelegatedCommissionerProvider_v5_3_IP_Stage1' AND TABLE_SCHEMA = 'temp')
	DROP TABLE [Data_Lab_SWL].[temp].[DelegatedCommissionerProvider_v5_3_IP_Stage1]

---CREATE Temp Table to re-identify Commissioner Assignment as per Delegation Guidance
CREATE TABLE [Data_Lab_SWL].[temp].[DelegatedCommissionerProvider_v5_3_IP_Stage1](
	[RecordIdentifier] [bigint] NOT NULL,
	[GENERAL MEDICAL PRACTICE CODE (PATIENT REGISTRATION)] [varchar](50) NULL,
	[ORGANISATION IDENTIFIER (GP PRACTICE RESPONSIBILITY)] [varchar](50) NULL,
	[ORGANISATION IDENTIFIER (RESIDENCE RESPONSIBILITY)] [varchar](50) NULL,
	[Effective_Date] [date] NULL, --New processing field in 25/26 to allow for year on year changes
	[Host subICB Location] [varchar](10) NULL,
	[Armed Forces Flag] [bit] NULL,
	[Public Health Flag] [bit] NULL,
	[Health In Justice Flag] [bit] NULL,
	[ORGANISATION IDENTIFIER (CODE OF PROVIDER)] [varchar](50) NULL,
	[Current ORGANISATION IDENTIFIER (CODE OF COMMISSIONER)] [varchar](50) NULL,
	[Current COMMISSIONED SERVICE CATEGORY CODE] [varchar](50) NULL,
	[Current SERVICE CODE] [varchar](50) NULL,
	[Current NATIONAL POINT OF DELIVERY CODE] [varchar](50) NULL,  --New field added to correctly allocate Health and Justice activity
	[TFC] [varchar] (50),
	[TotalCost] [decimal](22, 6) NULL
) ON [PRIMARY]

---INSERT records from SUS IP output to re-identify Commissioner Assignment as per Delegation Guidance
INSERT INTO [Data_Lab_SWL].[temp].[DelegatedCommissionerProvider_v5_3_IP_Stage1]
           ([RecordIdentifier]
           ,[GENERAL MEDICAL PRACTICE CODE (PATIENT REGISTRATION)]
		   ,[ORGANISATION IDENTIFIER (GP PRACTICE RESPONSIBILITY)]
           ,[ORGANISATION IDENTIFIER (RESIDENCE RESPONSIBILITY)]
		   ,[Effective_Date]
		   ,[Host subICB Location]
           ,[Armed Forces Flag]
           ,[Public Health Flag]
           ,[Health In Justice Flag]
           ,[ORGANISATION IDENTIFIER (CODE OF PROVIDER)]   
           ,[Current ORGANISATION IDENTIFIER (CODE OF COMMISSIONER)]
		   ,[Current COMMISSIONED SERVICE CATEGORY CODE]
		   ,[Current SERVICE CODE]
		   ,[Current NATIONAL POINT OF DELIVERY CODE]  --New field added to correctly allocate Health and Justice activity
		   ,[TFC] 
		   ,[TotalCost])

SELECT 
	  A.[PLD_ident] as [RecordIdentifier] --Row ID for the IP activity
-------------------------------------------------------------------------------------------------------------------------------
------- Fields associated with Commissioner Responsibility as per Who Pays Guidance -------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
	  ,A.[RAW_gp_practice_code] AS [GENERAL MEDICAL PRACTICE CODE (PATIENT REGISTRATION)]
	  ,A.[RAW_ccg_code] AS [ORGANISATION IDENTIFIER (GP PRACTICE RESPONSIBILITY)]
	  ,A.[RAW_Org_Residence_Responsibility] AS [ORGANISATION IDENTIFIER (RESIDENCE RESPONSIBILITY)]
	  ,YearMonthBridge.[Effective_Date] --Effective date derived from FINANCIAL_YEAR and FINANCIAL_MONTH
	  ,HostSubICB.[Host subICB]  AS [Host subICB Location] --This is referenced from the Table provided by AGEM to obtain the host sub-ICB location as this doesn't currently exist in ODS.

-------------------------------------------------------------------------------------------------------------------------------
------- Fields associated with Population Based Commissioner as per Who Pays Guidance -----------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
	  
	  ,COALESCE(ServiceFlags.[Armed Forces Flag],0) as [Armed Forces Flag]
	  ,COALESCE(ServiceFlags.[Public Health Flag],0) as [Public Health Flag]
	  ,COALESCE(ServiceFlags.[Health In Justice Flag],0) as [Health In Justice Flag]
	  
-------------------------------------------------------------------------------------------------------------------------------
------- Current Key Provider Data Elements ------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
	  
	  ,A.[RAW_Provider_Code] AS [ORGANISATION IDENTIFIER (CODE OF PROVIDER)]
	  ,A.[RAW_Commissioner_Code] 
		AS [Current ORGANISATION IDENTIFIER (CODE OF COMMISSIONER)]
	  ,A.[RAW_nhse_servicecategory] AS [Current COMMISSIONED SERVICE CATEGORY CODE] --Provider submitted value
	  ,A.[STP_NHSE_ServiceLine] AS [Current SERVICE CODE]
	  ,A.[RAW_national_pod_code] AS [Current NATIONAL POINT OF DELIVERY CODE]
	  ,A.[RAW_treatment_function_code] as [TFC]
	  ,A.[CLN_Total_Cost] AS [TotalCost] --IP TotalCost

  FROM [Data_Lab_SWL].[IP].[vw_Admissions_CAM] A --SUS IP data source

  --Temp Stage 1 - JOIN 1 - Service Code Flag Reference table to remove CASE statement and improve logic performance
  LEFT JOIN [Data_Lab_SWL].[CAM_Ref].[ServiceFlags] ServiceFlags
  ON A.[RAW_nhse_servicecategory] = ServiceFlags.[NHSE_ServiceCategory]

  --Temp Stage 1 - JOIN 2 - Bridge for Effective Date
  LEFT JOIN [Data_Lab_SWL].[CAM_Ref].[YearMonthBridge] YearMonthBridge
  ON A.[RAW_Activity_Year] = YearMonthBridge.[FINANCIAL_YEAR]
  AND A.[RAW_Activity_Month] = YearMonthBridge.[FINANCIAL_MONTH]

  --Temp Stage 1 - JOIN 3 - Identify Host Sub-ICB location
  LEFT JOIN (SELECT DISTINCT 
					Prov1.[Provider_Code]
					,Prov1.[Host SubICB] AS [Host subICB]		
				FROM [Data_Lab_SWL].[CAM_Ref].[REF_Provider] Prov1
				
				--WHERE Prov1.[Is_Latest] = 1 --AND Prov1.[Is_Current] = 1

				) AS HostSubICB
			
			ON A.[RAW_provider_code] = HostSubICB.[Provider_Code]
			
			WHERE (COALESCE(A.[RAW_National_POD_Code],'') NOT IN ('DRUG','DEVICE') AND COALESCE(A.[RAW_NHSE_ServiceCategory],'') NOT IN ('31','32','41')) --Excludes PODs and Commissioned Service Category Codes relating to Drugs
			AND A.[DER_Activity_Year] IN ('2025/2026') --Focus on current financial year
GO

---------------------------------------------------------------------------------------------------------------------------
--- 1b. Stage 2                                                                                     -----------------------
--- Create and load SUS IP activity into temp schema table that will create a reassignment ID       -----------------------
---------------------------------------------------------------------------------------------------------------------------

---DROP Temp Table to re-identify Commissioner Assignment as per Delegation Guidance
IF EXISTS (
	SELECT * FROM INFORMATION_SCHEMA.TABLES
	WHERE TABLE_NAME = 'DelegatedCommissionerProvider_v5_3_IP_Stage2' AND TABLE_SCHEMA = 'temp')
	DROP TABLE [Data_Lab_SWL].[temp].[DelegatedCommissionerProvider_v5_3_IP_Stage2]

---CREATE Temp Table to re-identify Commissioner Assignment as per Delegation Guidance
CREATE TABLE [Data_Lab_SWL].[temp].[DelegatedCommissionerProvider_v5_3_IP_Stage2](
	[RecordIdentifier] [bigint] NOT NULL,
	[ReassignmentID] [varchar](50) NULL
) ON [PRIMARY]

---INSERT records from SUS IP output to re-identify Commissioner Assignment as per Delegation Guidance
INSERT INTO [Data_Lab_SWL].[temp].[DelegatedCommissionerProvider_v5_3_IP_Stage2]
           ([RecordIdentifier]
           ,[ReassignmentID])

SELECT B.[RecordIdentifier]
        
-------------------------------------------------------------------------------------------------------------------------------
------- CASE statement based on the CAM guidance where information is readily available in current Specifications -------------
------- Flowchart / Annotation references are provided to understand the flow of information ----------------------------------
------- Output provides a reassigned / Primary Commissioner -------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
	  ,CASE
		
		/*Delegated Mental Health - not in flowchart but allocating appropriate Service Category ahead of onward logic*/

		WHEN ServiceCode.[Specialised MH Flag] = 1 AND COALESCE(ServiceCode.[SERVICE CODE],'') != '99999999' AND COALESCE(ServiceCode.[SERVICE CODE],'') != 'NCBPSXXX'
			THEN
				CASE WHEN ServiceCode.[ICBDelegationStatus] = 'GREEN' THEN 'MH_Delegated' ELSE 'MH_Non_Delegated' END

		-- C-0: Is the activity record for specialised or highly-specialised care?  Yes - Go to C-0a; No - Go to D
		-- Yes: Inpatient and Outpatient activity excluding Cross-border activity that contains a Specialised/Highly Specialised Service Code
		-- No: Inpatient and Outpatient activity excluding Cross-border activity that DOES NOT contain a Specialised/Highly Specialised Service Code
				
		-- C-0a: Is the service in scope for delegation?  Yes - Go to C-0b; No - Go to C-2
		-- Yes: Code included in the corresponding output (see C-0b) WHERE the 'ICBDelegationStatus' IN ('GREEN','AMBER')
		-- No: Code included in the corresponding output (see C-2) WHERE the 'ICBDelegationStatus' IN ('RED','BLUE')

		-- C-0b: Is the service a 'GREEN' service?  Yes - Go to D; No - Responsible NHS England Specialised Commissioning Hub (GP Practice)
		-- Yes: Reference the table [ServiceCodes] WHERE the 'ICBDelegationStatus' is 'GREEN'.  Where the value is GREEN, the activity will flow through the remainder of the CASE statement.
		-- No: Reference the table [ServiceCodes] WHERE the 'ICBDelegationStatus' is 'AMBER'
		WHEN (
				(
				(ServiceCode.[SERVICE CODE] IS NOT NULL AND ServiceCode.[Specialised Flag] = 1 AND COALESCE(ServiceCode.[SERVICE CODE],'') != '99999999')
				OR (B.[Current COMMISSIONED SERVICE CATEGORY CODE] IN ('21') AND (ServiceCode.[SERVICE CODE] IS NULL OR ServiceCode.[SERVICE CODE] = '99999999'))
				)
				)
				/*(C-0 ='Yes')*/ AND ServiceCode.[ICBDelegationStatus] IN ('AMBER') /*(C-0a = 'Yes' & C-0b ='No')*/ --In scope for Delegation but not Suitable.
			THEN 
				CASE
					WHEN SubICB1.[SubICB_Code] IS NOT NULL THEN SubICB1.[ODSCommHub] + '_C_0b_1' --See JOIN 3
					WHEN SubICB2.[ICB_Code] IS NOT NULL THEN SubICB2.[ODSCommHub]  + '_C_0b_2'--See JOIN 4
					WHEN SubICB3.[SubICB_Code] IS NOT NULL THEN SubICB3.[ODSCommHub]  + '_C_0b_3'--See JOIN 5
					WHEN SubICB4.[ICB_Code] IS NOT NULL THEN SubICB4.[ODSCommHub]  + '_C_0b_4'--See JOIN 6
					WHEN HostSubICB.[SubICB_Code] IS NOT NULL THEN HostSubICB.[ODSCommHub] + '_C_0b_5' --See JOIN 1
					ELSE 'C_0b_X'
					END

		-- C2: Does NHS England have a contract with the specialised service provider?  Yes - Responsible NHS England Specialised Commissioning Hub (Provider); No - Not applicable
		-- Yes: 

				WHEN (
				(
				(ServiceCode.[SERVICE CODE] IS NOT NULL AND ServiceCode.[Specialised Flag] = 1 AND COALESCE(ServiceCode.[SERVICE CODE],'') != '99999999')
				OR (B.[Current COMMISSIONED SERVICE CATEGORY CODE] IN ('21') AND (ServiceCode.[SERVICE CODE] IS NULL OR ServiceCode.[SERVICE CODE] = '99999999'))
				) /*(C-0 ='Yes')*/ 
				
				AND (ServiceCode.[ICBDelegationStatus] IN ('RED','BLUE', 'N/a', 'NOT APPLICABLE') OR ServiceCode.[ICBDelegationStatus] IS NULL)/*(C-0a = 'No' & C-2 ='Yes')*/
				)		

				-- This identifies where the Provider has explicitly identified that the Service is 'NHS England - Specialised Services' BUT the Service Code is invalid
			THEN
				CASE
					WHEN HostSubICB.[SubICB_Code] IS NOT NULL THEN HostSubICB.[ODSCommHub] + '_C_2_1' --Commissioned on a Provider Host basis only
					ELSE 'C_2_X'
					END 
		
		-- D: Is the activity for Secondary Dental care?  Yes - Responsible sub-ICB Location; No - Go to E
		-- Yes: ACTIVITY TREATMENT FUNCTION CODE is in the following list: 
			--140 (oral surgery),
			--141 (restorative dentistry),
			--142 (paediatric dentistry),
			--143 (orthodontics),
			--144 (oral and maxillofacial surgery),
			--145 (oral and maxillofacial surgery service),
			--217 (paediatric maxillofacial surgery),
			--450 (dental medicine specialties),
			--451 (special care dentistry service)
		WHEN (B.[TFC] IN ('140','141','142','143','144','145','217','450','451') 
		AND (ServiceCode.[Specialised Flag] = 0 OR ServiceCode.[SERVICE CODE] = '99999999' OR ServiceCode.[SERVICE CODE] IS NULL))
		OR B.[Current COMMISSIONED SERVICE CATEGORY CODE] IN ('51','55') --Provider Submitted Commissioned Service Category Code added 17/01 as this assumes the Provider has supplied the correct information.
		OR (ServiceCode.[Secondary Dental Flag] = 1 AND COALESCE(ServiceCode.[SERVICE CODE],'') != '99999999')
			THEN 
				CASE
					WHEN SubICB1.[SubICB_Code] IS NOT NULL THEN SubICB1.[SubICB_Code] + '_D_1' --See JOIN 3
					WHEN SubICB2.[ICB_Code] IS NOT NULL THEN 'D_X'
					WHEN SubICB3.[SubICB_Code] IS NOT NULL THEN SubICB3.[SubICB_Code] + '_D_2' --See JOIN 5
					WHEN SubICB4.[ICB_Code] IS NOT NULL THEN 'D_X'
					WHEN HostSubICB.[SubICB_Code] IS NOT NULL THEN HostSubICB.[SubICB_Code] + '_D_3' --See JOIN 1
					ELSE 'D_X'
					END
		-- No: Go to E
		
		-- E: Is the patient part of the eligible health and justice population?  Yes - Commissioning Hub for Health and Justice Commissioning; No - Go to F
		-- Yes: Reference either the GP Practice code submitted or the Patient Postcode which will be unique to the facility.
		WHEN (HandJ.[Y0Prescribingcode] IS NOT NULL AND COALESCE(B.[Current NATIONAL POINT OF DELIVERY CODE],'') != 'AE')
		OR (B.[Current COMMISSIONED SERVICE CATEGORY CODE] IN ('71','75') AND COALESCE(B.[Current NATIONAL POINT OF DELIVERY CODE],'') != 'AE') --Provider Submitted Commissioned Service Category Code added 17/01 as this assumes the Provider has supplied the correct information.
			THEN 
				CASE
					WHEN HandJ.[Y0Prescribingcode] IS NOT NULL THEN HandJ.[EnglandHealthandJusticeCommissioningHubCode] + '_E_1'
					ELSE 'E_X'
					END

		-- No: Go to F
		
		-- F: Is the activity related to public health service described in the Section 7a agreement?  Yes - Responsible NHS England Regional Geography for Public Health Services; No - Go to H
		-- Yes:
		WHEN (ServiceCode.[SERVICE CODE] IS NOT NULL AND ServiceCode.[Public Health Flag] = 1 AND COALESCE(B.[Current SERVICE CODE],'') != '99999999') 
		OR B.[Current COMMISSIONED SERVICE CATEGORY CODE] IN ('81','85') --Provider Submitted Commissioned Service Category Code added 17/01 as this assumes the Provider has supplied the correct information.
			THEN
				CASE
					WHEN SubICB1.[SubICB_Code] IS NOT NULL THEN SubICB1.[ODSRegion] + '_F_1' --See JOIN 3
					WHEN SubICB2.[ICB_Code] IS NOT NULL THEN SubICB2.[ODSRegion] + '_F_2' --See JOIN 4
					WHEN SubICB3.[SubICB_Code] IS NOT NULL THEN SubICB3.[ODSRegion] + '_F_3' --See JOIN 5
					WHEN SubICB4.[ICB_Code] IS NOT NULL THEN SubICB4.[ODSRegion] + '_F_4' --See JOIN 6
					WHEN HostSubICB.[SubICB_Code] IS NOT NULL THEN HostSubICB.[ODSRegion] + '_F_5' --See JOIN 1
					ELSE 'F_X'
					END
		-- No: Go to H
		-- H: Is the activity related to other public health activity?  Yes - Responsible Local Authority; No - Go to I --NOTE: No current reference table to determine 'Other' public health activity.
		-- Yes:
		-- No: Go to I

		-- I: Is the activity for Infertility treatment?  Yes - Go to I-1; No - Go to J
		-- Yes: NOTE: This can only be identified BY CDS Diagnosis codes that are not present in ACM or PLCM Datasets.  Provider to include metrics here for flagging this activity appropriately
		-- No: Go to J

		-- I-1: Does the activity meet NHS England eligibility for Armed Forces?  Yes - NHS England Armed Forces Commissioning Hub; No - Responsible sub-ICB location
		-- Yes: See NOTE in Step I
		-- No: See NOTE in Step I

		-- J: Is the patient registered with an English GP Practice that has 13Q as the parent code?  Yes - NHS England Armed Forces Commissioning Hub; No - Go to C-5
		-- Yes: Reference the GP practice code to the Armed Forces GP practices with epraccur
		WHEN ArmedForces.[Organisation_Code] IS NOT NULL OR B.[Current COMMISSIONED SERVICE CATEGORY CODE] IN ('61') --Provider Submitted Commissioned Service Category Code added 17/01 as this assumes the Provider has supplied the correct information.
			THEN '13Q_J_1'

		-- No: Go to C-5

		-- C-5: Is the service a specialised 'GREEN' service?  Yes - Go to C-6; No - Responsible sub-ICB location
		-- Yes: Reference the table [ServiceCodes] WHERE the 'ICBDelegationStatus' is 'GREEN'
		WHEN 
				(
				(ServiceCode.[SERVICE CODE] IS NOT NULL AND ServiceCode.[Specialised Flag] = 1 AND COALESCE(ServiceCode.[SERVICE CODE],'') != '99999999')
				OR (B.[Current COMMISSIONED SERVICE CATEGORY CODE] IN ('21') AND (ServiceCode.[SERVICE CODE] IS NULL OR ServiceCode.[SERVICE CODE] = '99999999'))
				) /*(C-0 ='Yes')*/ 
				AND ServiceCode.[ICBDelegationStatus] IN ('GREEN') /*C-5 = 'yes'*/

			THEN
				-- C-6: Is the ICB ready to accept delegation?  Yes - Responsible sub-ICB location; No - Responsible NHS England Specialised Commissioning Hub (GP Practice)

				-----------------------------------------------------------------------------------------------------------------------------------
				--NOTE:  All ICBs have a delegation status of Yes for 25/26.  The REF_Provider table is based on pre 25/26 contracted activity.
				-----------------------------------------------------------------------------------------------------------------------------------				
				--Yes:
				CASE
					
					--For activity from 25/26 onwards
					WHEN [Effective_Date] >= '2025-04-01'

					THEN
						CASE 
							WHEN SubICB1.[SubICB_Code] IS NOT NULL THEN SubICB1.[SubICB_Code] + '_C_6_1' --See JOIN 3
							
							WHEN SubICB3.[SubICB_Code] IS NOT NULL THEN SubICB3.[SubICB_Code] + '_C_6_2' --See JOIN 5
						
							WHEN HostSubICB.[SubICB_Code] IS NOT NULL THEN HostSubICB.[SubICB_Code] + '_C_6_3' --See JOIN 1
							ELSE 'C_5_X' 
						END

					--For activity pre 25/26				
					WHEN COALESCE(  SubICB1.[ProvisionalICBDelegationStatus],
									SubICB2.[ProvisionalICBDelegationStatus], 
									SubICB3.[ProvisionalICBDelegationStatus], 
									SubICB4.[ProvisionalICBDelegationStatus],
									HostSubICB.[ProvisionalICBDelegationStatus]) = 'Yes'
					THEN
						CASE 
							WHEN SubICB1.[SubICB_Code] IS NOT NULL THEN SubICB1.[SubICB_Code] + '_C_6_1' --See JOIN 3
							
							WHEN SubICB3.[SubICB_Code] IS NOT NULL THEN SubICB3.[SubICB_Code] + '_C_6_2' --See JOIN 5
						
							WHEN HostSubICB.[SubICB_Code] IS NOT NULL THEN HostSubICB.[SubICB_Code] + '_C_6_3' --See JOIN 1
							ELSE 'C_5_X' 
						END
				--No:

						WHEN (COALESCE(  SubICB1.[ProvisionalICBDelegationStatus],
									SubICB2.[ProvisionalICBDelegationStatus], 
									SubICB3.[ProvisionalICBDelegationStatus], 
									SubICB4.[ProvisionalICBDelegationStatus],
									HostSubICB.[ProvisionalICBDelegationStatus]) = 'No'
									OR SubICB2.[ICB_Code] IS NOT NULL
									OR SubICB4.[ICB_Code] IS NOT NULL) --See note. Added as per V4.9.  Not fully included in all 3 CASE statements. SK 2025 03 05
				
						THEN CASE
							WHEN SubICB1.[SubICB_Code] IS NOT NULL THEN SubICB1.[ODSCommHub] + '_C_6_4' --See JOIN 3
							WHEN SubICB2.[ICB_Code] IS NOT NULL THEN SubICB2.[ODSCommHub] + '_C_6_5' --See JOIN 4
							WHEN SubICB3.[SubICB_Code] IS NOT NULL THEN SubICB3.[ODSCommHub] + '_C_6_6' --See JOIN 5
							WHEN SubICB4.[ICB_Code] IS NOT NULL THEN SubICB4.[ODSCommHub] + '_C_6_7' --See JOIN 6
							WHEN HostSubICB.[SubICB_Code] IS NOT NULL THEN HostSubICB.[ODSCommHub] + '_C_6_8' --See JOIN 1
							END
							ELSE 'C_5_X'
						END
				

		-- No:
		WHEN SubICB1.[SubICB_Code] IS NOT NULL THEN SubICB1.[SubICB_Code] + '_C_5_1' --See JOIN 3 --Determines the final output where it is assumed that the activity relates to ICB's as it has not been identified in the above Direct Commissioning steps
		--WHEN SubICB2.[ICB_Code] IS NOT NULL THEN 'X' --See JOIN 4
		WHEN SubICB3.[SubICB_Code] IS NOT NULL THEN SubICB3.[SubICB_Code] + '_C_5_1' --See JOIN 5 --Determines the final output where it is assumed that the activity relates to ICB's as it has not been identified in the above Direct Commissioning steps
		--WHEN SubICB4.[ICB_Code] IS NOT NULL THEN 'X' --See JOIN 6
		WHEN HostSubICB.[SubICB_Code] IS NOT NULL THEN HostSubICB.[SubICB_Code] + '_C_5_1' --See JOIN 1 --Determines the final output where it is assumed that the activity relates to ICB's as it has not been identified in the above Direct Commissioning steps

		ELSE 'X'
		END as [ReassignmentID]

  FROM [Data_Lab_SWL].[temp].[DelegatedCommissionerProvider_v5_3_IP_Stage1] B
  
  --JOIN 1 - Provider to Host SubICB location Delegation Status Reference Table --
  LEFT JOIN (
  SELECT DISTINCT 
					[SubICB_Code]
					,[ODSCommHub]
					,[ODSHealthandJustice]
					,[ODSRegion]
					,[ProvisionalICBDelegationStatus]
					,[Effective_From] --For delegation status only
					,[Effective_To] --For delegation status only

				FROM [Data_Lab_SWL].[CAM_Ref].[SubICBtoDirectComm]

				) AS HostSubICB
  ON B.[Host subICB Location] = HostSubICB.[SubICB_Code]
  AND B.[Effective_Date] BETWEEN HostSubICB.[Effective_From] AND HostSubICB.[Effective_To]

  --JOIN 2 - Service Code Reference table as created in Step 1--
  LEFT JOIN [Data_Lab_SWL].[CAM_Ref].[ServiceCodes] AS ServiceCode
  ON B.[Current SERVICE CODE] = ServiceCode.[SERVICE CODE]
  AND B.[Effective_Date] BETWEEN ServiceCode.[Effective_From] AND ServiceCode.[Effective_To]
  
  --JOIN 3 - SubICB GP Practice Responsibility to subICB as created in Step 1 -- Assumes that in Part 1 processing the GP Practice Responsibility has been correctly populated with an subICB location code
  LEFT JOIN [Data_Lab_SWL].[CAM_Ref].[SubICBtoDirectComm] AS SubICB1
  ON B.[ORGANISATION IDENTIFIER (GP PRACTICE RESPONSIBILITY)] = SubICB1.[SubICB_Code]
  AND B.[Effective_Date] BETWEEN SubICB1.[Effective_From] AND SubICB1.[Effective_To]
  
  --JOIN 4 - ICB GP Practice Responsibility to ICB as created in Step 1 -- Assumes that in Part 1 processing the GP Practice Responsibility has been incorrectly populated with an ICB code
  LEFT JOIN (SELECT DISTINCT [ICB_Code], [ODSCommHub], [ODSRegion], [ODSHealthandJustice], [ProvisionalICBDelegationStatus], [Effective_From], [Effective_To] FROM [Data_Lab_SWL].[CAM_Ref].[SubICBtoDirectComm]) AS SubICB2
  ON B.[ORGANISATION IDENTIFIER (GP PRACTICE RESPONSIBILITY)] = SubICB2.[ICB_Code]
  AND B.[Effective_Date] BETWEEN SubICB2.[Effective_From] AND SubICB2.[Effective_To]
  
  --JOIN 5 - SubICB Residential Responsibility to subICB -- Assumes that in Part 1 processing the Residence Responsibility has been correctly populated with an subICB location code
  LEFT JOIN [Data_Lab_SWL].[CAM_Ref].[SubICBtoDirectComm] AS SubICB3
  ON B.[ORGANISATION IDENTIFIER (RESIDENCE RESPONSIBILITY)] = SubICB3.[SubICB_Code]
  AND B.[Effective_Date] BETWEEN SubICB3.[Effective_From] AND SubICB3.[Effective_To]
  
  --JOIN 6 - ICB Residential Responsibility to ICB -- Assumes that in Part 1 processing the Residence Responsibility has been incorrectly populated with an ICB code
  LEFT JOIN (SELECT DISTINCT [ICB_Code], [ODSCommHub], [ODSRegion], [ODSHealthandJustice], [ProvisionalICBDelegationStatus], [Effective_From], [Effective_To] FROM [Data_Lab_SWL].[CAM_Ref].[SubICBtoDirectComm]) AS SubICB4
  ON B.[ORGANISATION IDENTIFIER (RESIDENCE RESPONSIBILITY)] = SubICB4.[ICB_Code]
  AND B.[Effective_Date] BETWEEN SubICB4.[Effective_From] AND SubICB4.[Effective_To]

  --JOIN 7 - Prison GP Practice Code as created in Step 1 -- APPENDIX E - Identifies Health and Justice patients WHERE the submitted GP Practice is within APPENDIX E
  LEFT JOIN (SELECT DISTINCT [EnglandHealthandJusticeCommissioningHubCode], [Y0Prescribingcode] FROM [Data_Lab_SWL].[CAM_Ref].[Ref_HandJ_CommissionerCode] WHERE [Y0PrescribingCode] IS NOT NULL) HandJ
  ON B.[GENERAL MEDICAL PRACTICE CODE (PATIENT REGISTRATION)] = HandJ.[Y0Prescribingcode]

  --JOIN 9 -- Armed Forces GP Practices
  LEFT JOIN [Data_Lab_SWL].[CAM_Ref].[ArmedForcesGP] ArmedForces  
  ON B.[ORGANISATION IDENTIFIER (GP PRACTICE RESPONSIBILITY)] = ArmedForces.[Organisation_Code] 
  AND ArmedForces.English_AF_GP_Practice_Flag = 1

---------------------------------------------------------------------------------------------------------------------------
--- 1c. Final                                                                                       -----------------------
--- Combine analysis with commissioner assignment reference table                                   -----------------------
---------------------------------------------------------------------------------------------------------------------------

---DROP Temp Table to re-identify Commissioner Assignment as per Delegation Guidance
IF EXISTS (
	SELECT * FROM INFORMATION_SCHEMA.TABLES
	WHERE TABLE_NAME = 'DelegatedCommissionerProvider_v5_3_IP_Final' AND TABLE_SCHEMA = 'CAM')
	DROP TABLE [Data_Lab_SWL].[CAM].[DelegatedCommissionerProvider_v5_3_IP_Final]

---CREATE Temp Table to re-identify Commissioner Assignment as per Delegation Guidance
CREATE TABLE [Data_Lab_SWL].[CAM].[DelegatedCommissionerProvider_v5_3_IP_Final](
	[RecordIdentifier] [bigint] NOT NULL,
	[ORGANISATION IDENTIFIER (GP PRACTICE RESPONSIBILITY)] [varchar](50) NULL,
	[ORGANISATION IDENTIFIER (RESIDENCE RESPONSIBILITY)] [varchar](50) NULL,
	[ORGANISATION IDENTIFIER (CODE OF PROVIDER)] [varchar](50) NULL,
	[Current ORGANISATION IDENTIFIER (CODE OF COMMISSIONER)] [varchar](50) NULL,
	[Current COMMISSIONED SERVICE CATEGORY CODE] [varchar](50) NULL,
	[Current SERVICE CODE] [varchar](50) NULL,
	[CAM ORGANISATION IDENTIFIER (CODE OF COMMISSIONER)] [varchar](50) NULL,
	[CAM COMMISSIONED SERVICE CATEGORY CODE] [varchar](50) NULL,
	[Commissioner Assignment Reason] [varchar](255) NULL,
	[TotalCost] [decimal](22, 6) NULL
) ON [PRIMARY]

---INSERT records from SUS IP output to re-identify Commissioner Assignment as per Delegation Guidance
INSERT INTO [Data_Lab_SWL].[CAM].[DelegatedCommissionerProvider_v5_3_IP_Final]
           ([RecordIdentifier]
           ,[ORGANISATION IDENTIFIER (GP PRACTICE RESPONSIBILITY)]
           ,[ORGANISATION IDENTIFIER (RESIDENCE RESPONSIBILITY)]
           ,[ORGANISATION IDENTIFIER (CODE OF PROVIDER)]   
           ,[Current ORGANISATION IDENTIFIER (CODE OF COMMISSIONER)]
		   ,[Current COMMISSIONED SERVICE CATEGORY CODE]
		   ,[Current SERVICE CODE]
		   ,[CAM ORGANISATION IDENTIFIER (CODE OF COMMISSIONER)]
		   ,[CAM COMMISSIONED SERVICE CATEGORY CODE]
		   ,[Commissioner Assignment Reason]
		   ,[TotalCost])

		   SELECT 
		   Stage1.[RecordIdentifier],
		   Stage1.[ORGANISATION IDENTIFIER (GP PRACTICE RESPONSIBILITY)],
           Stage1.[ORGANISATION IDENTIFIER (RESIDENCE RESPONSIBILITY)],
           Stage1.[ORGANISATION IDENTIFIER (CODE OF PROVIDER)],  
           Stage1.[Current ORGANISATION IDENTIFIER (CODE OF COMMISSIONER)],
		   Stage1.[Current COMMISSIONED SERVICE CATEGORY CODE],
		   Stage1.[Current SERVICE CODE],
		   StageFinal.[Comm] as [CAM ORGANISATION IDENTIFIER (CODE OF COMMISSIONER)],
		   StageFinal.[Service Category] as [CAM COMMISSIONED SERVICE CATEGORY CODE],
		   StageFinal.[Commissioner Assignment Reason],
		   [TotalCost]

		   FROM [Data_Lab_SWL].[temp].[DelegatedCommissionerProvider_v5_3_IP_Stage1] Stage1

		   LEFT JOIN [temp].[DelegatedCommissionerProvider_v5_3_IP_Stage2] Stage2
		   ON Stage1.[RecordIdentifier] = Stage2.[RecordIdentifier]

		   LEFT JOIN [CAM_Ref].[CommissionerAssignmentReason] StageFinal
		   ON Stage2.[ReassignmentID] = StageFinal.[CAM_Code]

----Review Output --
----Control Totals --

--SELECT COUNT(*) AS [TotalRecords], SUM([TotalCost]) AS [OriginalTable] FROM [Data_Lab_SWL].[IP].[vw_Admissions_CAM]
--WHERE [DER_Activity_Year] = '2025/2026'

--SELECT COUNT(*) AS [TotalRecords], SUM([TotalCost]) AS [DelegatedTable] FROM [Data_Lab_SWL].[CAM].[DelegatedCommissionerProvider_v5_3_IP_Final]

--SELECT [Commissioner Assignment Reason], COUNT(*) [RowCount], SUM([TotalCost]) [SumOfTotalCost]
--  FROM [Data_Lab_SWL].[CAM].[DelegatedCommissionerProvider_v5_3_IP_Final]
--  GROUP BY [Commissioner Assignment Reason]
--  ORDER BY [Commissioner Assignment Reason]
--GO


select * from [Data_Lab_SWL].[CAM].[DelegatedCommissionerProvider_v5_3_IP_Final]
where [ORGANISATION IDENTIFIER (CODE OF PROVIDER)] = 'RJ7'
--and [Current ORGANISATION IDENTIFIER (CODE OF COMMISSIONER)] <> [CAM ORGANISATION IDENTIFIER (CODE OF COMMISSIONER)]
--and [Current ORGANISATION IDENTIFIER (CODE OF COMMISSIONER)] = '13R'

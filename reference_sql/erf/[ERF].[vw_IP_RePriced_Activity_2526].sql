USE [Data_Lab_SWL]
GO

/****** Object:  View [ERF].[vw_IP_RePriced_Activity_2526]    Script Date: 06/01/2026 15:12:29 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO







/******************************************************************************************
* View Name      : [ERF].[vw_IP_RePriced_Activity_2526]
* Description    : Inpatient activity repricing view for ERF analysis. Applies national 
*                  tariff rates to actual activity with MFF adjustments and specialist 
*                  topups where applicable.
*
* Parameters     : None (View)
*
* Returns        : Repriced inpatient activity with costs, topups, and ERF categorisation
*
* Author         : SP
* Created Date   : 2023-09-29
*
* Revision History:
*   Date        Author        Description
*   ----------  ------------  ------------------------------------------------------------
*   2023-09-29  SP            Initial creation
*   2023-10-03  SP            Changed version to bring in trustwide data
*   2023-10-04  SP            Include specialist topup for all spec-comm activity
*   2023-10-05  SP            Amended to include ISP and OOS provider types
*   2023-10-06  SP            Logic changes for CommissionedBy, devolved administrations, private patients
*   2023-10-19  SP            Merged all FY views into single view
*   2023-10-23  SP            Dynamic tariff selection based on ERF.tbl_Current_Tariff_Used
*   2023-11-26  SP            Amended code to include MFF (bringing ISL MFF value)
*   2024-06-03  SP            Modified for FY change, amended tariff tables
*   2024-08-01  SP            Topups removed for ERF (agreed with James Lutaya)
*   2024-08-02  SP            Changes to CASE when pricing Cataracts
*   2024-08-09  SP            Added additional column for topups
*   2024-11-05  SP            MFF table no longer required, repointing to SUS
*   2025-02-04  SP            Provider code to flow as 5 characters
*   2025-07-03  SP            Adapted for 2025/26 financial year
*   2025-07-04  SP            Performance engineering - eliminated unnecessary CTEs and double scans
*   2025-09-10  SP            Amended for 2025/2026
*   2025-09-27  SP            Removed the grouping so that records are granular for further processing
*
* Dependencies   : [Data_Lab_SWL].[ERF].[vw_IP_DateRange_2526]
*                  [SWL].[tbl_Tariff_APC_OPPROC]
*                  [Data_Lab_SWL].[PLNG].[tbl_Specialist_TopUp_Rates_2425]
*                  [Dictionary].[dbo].[Organisation]
*                  [SWL].[tbl_MFF]
*                  [SWL].[GetCommissionedBy] - Function
* Notes          : Optimised for single table scan with efficient joins.
*                  Uses SARGable predicates for index utilisation.
******************************************************************************************/

ALTER  VIEW [ERF].[vw_IP_RePriced_Activity_2526]
AS
WITH base_data AS (
    SELECT 	
        ap.dv_FinYear,
         LEFT([dv_Activity_Period_Date],6) AS Der_Activity_Month,
        ap.dv_FinMonth,
        ap.Organisation_Code_Code_of_Provider AS Provider_Code,
        
        -- Provider type categorisation using function
        [SWL].[GetProviderType](
            ap.Organisation_Code_Code_of_Provider,
            ap.Organisation_Code_Code_of_Commissioner
        ) AS Provider_Type,
        
        ap.Organisation_Code_Code_of_Commissioner AS Commissioner_Code,
        
        -- Use function for CommissionedBy calculation
        [SWL].[GetCommissionedBy](
            ap.Organisation_Code_Code_of_Commissioner,
            ap.dv_SpecCom_ServiceCode_National_Spell,
            ap.dv_FinYear
        ) AS CommissionedBy,
        
        CASE 
            WHEN ap.Patient_Classification IN ('1','01') THEN 'EL' 
            WHEN ap.Patient_Classification IN ('2','02') THEN 'DC' 
        END AS Der_Management_Type,
        
        ap.Spell_Core_HRG,
        ap.Treatment_Function_Code,
        
        CASE 
            WHEN ap.dv_WardCode_At_Discharge IN ('PI Parkside', 'PI Portland', 'Harley St') 
                THEN ap.dv_WardCode_At_Discharge 
            ELSE ap.Site_code_of_Treatment_at_start_of_episode 
        END AS Site_code_of_Treatment,
        
        -- Aggregate fields
        (ap.dv_LengthOfStay_Net_Original) AS dv_LengthOfStay_Net_Original, --sp removed SUM
        (ap.dv_ExcessBedDays_Original) AS dv_ExcessBedDays_Original, -- sp removed SUM
        
        -- Excess bed days calculation
        CASE 
            WHEN ap.Patient_Classification IN ('1','01') 
                 AND ap.dv_LengthOfStay_Net > ISNULL(tf.Ordinary_Elective_Long_Stay_Trimpoint_Days, 999) 
                THEN ap.dv_LengthOfStay_Net - ISNULL(tf.Ordinary_Elective_Long_Stay_Trimpoint_Days, 999)
            ELSE 0 
        END AS Excess_bed_days,
        
        ISNULL(tf.Per_Day_Long_Stay_Payment_For_Days_Exceeding_Trim_Point, 0) AS LongStay_Day_Tariff,
        
        -- Tariff price selection
        COALESCE(
            tf.Combined_Day_Case_Ordinary_Elective_Spell_Tariff,
            CASE 
                WHEN ap.Patient_Classification IN ('1','01') THEN tf.Ordinary_Elective_Spell_Tariff 
                WHEN ap.Patient_Classification IN ('2','02') THEN tf.Day_Case_Spell_Tariff
                ELSE 0
            END,
            0
        ) AS Price,
        
        ISNULL(topup.Rate, 1) AS Specialist_Topup,
        COALESCE(mff.MFF, ap.dv_MFF_Index_Applied, 1.061299920) AS MFF_Applied,
        1 as Activity,
        --COUNT(DISTINCT ap.SK_EncounterID) AS Activity, -- sp commented
        --SUM(ap.dv_Total_Cost_Inc_MFF) AS PGISUS_Cost, -- sp commented
		ap.dv_Total_Cost_Inc_MFF AS PGISUS_Cost,
        ap.SK_EncounterID,
        '2025/2026' AS Tariff_Used,
		[Organisation_Code_PCT_of_Residence],
		dv_SpecCom_ServiceCode_National_Spell as ServiceCode,
	    [PCT_Derived_from_GP_Practice] as [Organisation_Code_PCT_of_GP_Practice],
		ap.GP_Practice_Code_Original_Data,
		[IP].[GetPodType](ap.Admission_Method_Hospital_Provider_Spell, ap.Patient_Classification, ap.Intended_Management, ap.Admission_Date, ap.Discharge_Date, ap.Spell_Core_HRG) as POD_Detail,
		ap.Admission_Date,
		ap.Discharge_Date

	FROM [Data_Lab_SWL].[ERF].[vw_IP_DateRange_2526] ap
    
    -- Efficient joins with small reference tables
    LEFT JOIN [SWL].[tbl_Tariff_APC_OPPROC] tf
        ON ap.Spell_Core_HRG = tf.HRG_Code 
        AND tf.FinancialYear = '2025/2026'
        
    LEFT JOIN [Data_Lab_SWL].[PLNG].[tbl_Specialist_TopUp_Rates] topup
        ON topup.PSS_Flag = ap.dv_SpecCom_ServiceCode_National_Spell and topup.Financial_Year = '2025/2026'
        
    LEFT JOIN [SWL].[tbl_MFF] mff
        ON mff.ProviderCode = LEFT(ap.Organisation_Code_Code_of_Provider, 3)
        AND mff.Financial_Year = '2025/2026'

    WHERE 1 = 1
        -- ERF inclusion criteria (optimised for indexing)
        AND ap.Spell_Core_HRG NOT LIKE 'UZ%'
        AND ap.Spell_Core_HRG NOT LIKE 'NZ%'
        AND ap.Patient_Classification IN ('1','01', '2','02')
        AND ap.Treatment_Function_Code NOT IN ('501','560', '700', '710', '711', '712', '713', '715', '720', '721', '722', '723', '724', '725', '726', '727', '199', '499')
        --AND ap.Spell_Core_HRG NOT IN ('MA50Z','MA51Z','MA52A','MA52B','MA53Z','MA54Z','MA55A','MA55B','MA56A','MA56B')
        AND ((ap.Organisation_Code_Code_of_Provider LIKE 'RAX%' OR
             ap.Organisation_Code_Code_of_Provider LIKE 'RJ6%' OR 
             ap.Organisation_Code_Code_of_Provider LIKE 'RJ7%' OR
             ap.Organisation_Code_Code_of_Provider LIKE 'RPY%' OR
             ap.Organisation_Code_Code_of_Provider LIKE 'RVR%' ) OR
             (ap.Organisation_Code_Code_of_Commissioner LIKE '36L%' OR
             ap.Organisation_Code_Code_of_Commissioner LIKE '07V%' OR
             ap.Organisation_Code_Code_of_Commissioner LIKE '08J%' OR
             ap.Organisation_Code_Code_of_Commissioner LIKE '08P%' OR
             ap.Organisation_Code_Code_of_Commissioner LIKE '08R%' OR
             ap.Organisation_Code_Code_of_Commissioner LIKE '08T%' OR
             ap.Organisation_Code_Code_of_Commissioner LIKE '08X%'))
        AND ap.Admission_Method_Hospital_Provider_Spell IN ('11','12','13')
        AND ap.Administrative_Category_on_Admission <> 2 
        AND ap.Organisation_Code_Code_of_Commissioner NOT LIKE 'VPP00%'

  --  GROUP BY
  --      ap.SK_EncounterID,
  --      ap.dv_FinYear,
  --      LEFT(ap.dv_Activity_Period_Date, 6),
  --      ap.dv_FinMonth,
  --      ap.Organisation_Code_Code_of_Provider,
  --      ap.Organisation_Code_Code_of_Commissioner,
  --      ap.dv_SpecCom_ServiceCode_National_Spell,
  --      ap.Patient_Classification,
  --      ap.Spell_Core_HRG,
  --      ap.Treatment_Function_Code,
  --      ap.dv_WardCode_At_Discharge,
  --      ap.Site_code_of_Treatment_at_start_of_episode,
  --      ap.dv_LengthOfStay_Net,
  --      tf.Ordinary_Elective_Long_Stay_Trimpoint_Days,
  --      tf.Per_Day_Long_Stay_Payment_For_Days_Exceeding_Trim_Point,
  --      tf.Combined_Day_Case_Ordinary_Elective_Spell_Tariff,
  --      tf.Ordinary_Elective_Spell_Tariff,
  --      tf.Day_Case_Spell_Tariff,
  --      mff.MFF,
  --      ap.dv_MFF_Index_Applied,
  --      topup.Rate,
		--[Organisation_Code_PCT_of_Residence],
		--[PCT_Derived_from_GP_Practice] 
)


-- Final calculation with cost derivation
SELECT 
    *,
    -- Standard cost calculation (topups removed per James Lutaya agreement 01/08/24)
    ROUND(((Activity * Price) + (Excess_bed_days * Activity * LongStay_Day_Tariff)) * MFF_Applied, 2) AS TotalCostInclMFF,
    
    -- Cost calculation with topups (for comparison purposes)
    ROUND(((Activity * Price) + (Excess_bed_days * Activity * LongStay_Day_Tariff)) * Specialist_Topup * MFF_Applied, 2) AS TotalCostInclMFF_Topup

FROM base_data

GO



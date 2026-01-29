USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('[Analytics].[sp_Compute_CAM_Raw]', 'P') IS NOT NULL
DROP PROCEDURE [Analytics].[sp_Compute_CAM_Raw];
GO

/**
Script Name:   [Analytics].[sp_Compute_CAM_Raw].sql
Description:   Weekly compute of CAM assignment outputs into CAM.tbl_CAM_Raw.
Author:        Sridhar Peddi
Created:       2026-01-15

Notes:
- Uses SWL.fn_SUS_Published_Cutoff_Date for rolling window defaults.
- Deletes/reloads the rolling window (no TRUNCATE).
- De-duplicates per (RecordIdentifier, Dataset).
- Reads Unified.tbl_*_EncounterDenormalised_Active directly (no view dependency).
- Stages base rows into #CAM_Base with indexes for CAM logic joins.
- Logs ETL activity to Data_Lab_SWL_Live Analytics audit tables.
**/
CREATE PROCEDURE [Analytics].[sp_Compute_CAM_Raw]
    @FinYearStart CHAR(4),
    @FinancialYear VARCHAR(9) = NULL,
    @ProviderCode VARCHAR(10) = NULL,
    @FromDate DATE = NULL,
    @ToDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ETL_Start DATETIME2 = CURRENT_TIMESTAMP;
    DECLARE @BatchName VARCHAR(100) = 'Compute_CAM_Raw';
    DECLARE @BatchID INT = NULL;
    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsDeleted INT = 0;
    DECLARE @DuplicateKeyCount INT = 0;
    DECLARE @DQMessage NVARCHAR(4000);
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @FinYearInt INT;
    DECLARE @FinYearStartDate DATE;
    DECLARE @FinYearEndDate DATE;
    DECLARE @WindowStartDate DATE;
    DECLARE @WindowEndDate DATE;
    DECLARE @CutoffDate DATE;

    SET @FinYearInt = CASE
        WHEN ISNUMERIC(@FinYearStart) = 1 THEN CAST(@FinYearStart AS INT)
        ELSE NULL
    END;

    IF @FinYearInt IS NULL
    BEGIN
        RAISERROR('Parameter @FinYearStart is required (e.g. ''2025'')', 16, 1);
        RETURN;
    END

    IF @FinancialYear IS NULL OR LTRIM(RTRIM(@FinancialYear)) = ''
        SET @FinancialYear = CAST(@FinYearInt AS VARCHAR(4)) + '/' + CAST(@FinYearInt + 1 AS VARCHAR(4));

    SET @FinYearStartDate = CONVERT(DATE, CONCAT(@FinYearStart, '0401'), 112);
    SET @FinYearEndDate = DATEADD(DAY, -1, DATEADD(YEAR, 1, @FinYearStartDate));
    SET @CutoffDate = [Data_Lab_SWL].[SWL].[fn_SUS_Published_Cutoff_Date](NULL);

    SET @WindowEndDate = COALESCE(@ToDate, @CutoffDate, @FinYearEndDate);
    SET @WindowStartDate = COALESCE(
        @FromDate,
        DATEADD(MONTH, -5, DATEFROMPARTS(YEAR(@WindowEndDate), MONTH(@WindowEndDate), 1))
    );

    IF @WindowStartDate < @FinYearStartDate
        SET @WindowStartDate = @FinYearStartDate;

    IF @WindowEndDate > @FinYearEndDate
        SET @WindowEndDate = @FinYearEndDate;

    IF @WindowEndDate < @WindowStartDate
    BEGIN
        RAISERROR('ToDate must be on or after FromDate.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (
        SELECT 1
        FROM [Data_Lab_SWL].sys.tables t
        INNER JOIN [Data_Lab_SWL].sys.schemas s ON s.schema_id = t.schema_id
        WHERE s.name = 'CAM'
          AND t.name = 'tbl_CAM_Raw'
    )
    BEGIN
        RAISERROR('Required table [Data_Lab_SWL].[CAM].[tbl_CAM_Raw] was not found.', 16, 1);
        RETURN;
    END

    SET @FromDate = @WindowStartDate;
    SET @ToDate = @WindowEndDate;

    BEGIN TRY
        EXEC [Data_Lab_SWL_Live].[Analytics].[sp_Start_ETL_Batch]
            @BatchName = @BatchName,
            @BatchID = @BatchID OUTPUT;

        DELETE FROM [Data_Lab_SWL].[CAM].[tbl_CAM_Raw]
        WHERE [Financial_Year] = @FinancialYear
          AND [Activity_Date] >= @WindowStartDate
          AND [Activity_Date] < DATEADD(DAY, 1, @WindowEndDate)
          AND (@ProviderCode IS NULL OR [Provider_Code] = @ProviderCode);

        SET @RowsDeleted = @@ROWCOUNT;

        IF OBJECT_ID('tempdb..#CAM_Base') IS NOT NULL
            DROP TABLE #CAM_Base;
        IF OBJECT_ID('tempdb..#CAM_Final') IS NOT NULL
            DROP TABLE #CAM_Final;

        SELECT
            ip.[SK_EncounterID] AS [PLD_ident],
            REPLACE(ip.[dv_FinYear], '/20', '') AS [RAW_Activity_Year],
            ip.[dv_FinMonth] AS [RAW_Activity_Month],
            ip.[dv_FinYear] AS [DER_Activity_Year],
            ip.[GP_Practice_Code_Original_Data] AS [RAW_gp_practice_code],
            CASE
                WHEN RIGHT(ip.[Organisation_Code_Code_Of_Commissioner], 2) = '00'
                    THEN LEFT(ip.[Organisation_Code_Code_Of_Commissioner], 3)
                ELSE ip.[Organisation_Code_Code_Of_Commissioner]
            END AS [RAW_ccg_code],
            ip.[Organisation_Code_PCT_of_Residence] AS [RAW_Org_Residence_Responsibility],
            ip.[Organisation_Code_Code_of_Provider] AS [RAW_Provider_Code],
            CASE
                WHEN RIGHT(ip.[Organisation_Code_Code_Of_Commissioner], 2) = '00'
                    THEN LEFT(ip.[Organisation_Code_Code_Of_Commissioner], 3)
                ELSE ip.[Organisation_Code_Code_Of_Commissioner]
            END AS [RAW_Commissioner_Code],
            ip.[dv_SpecCom_ServiceCode_National_Spell] AS [STP_NHSE_ServiceLine],
            NULL AS [RAW_nhse_servicecategory],
            ip.[Treatment_Function_Code] AS [RAW_treatment_function_code],
            [Data_Lab_SWL].[IP].[GetPodType](
                ip.[Admission_Method_Hospital_Provider_Spell],
                ip.[Patient_Classification],
                ip.[Intended_Management],
                ip.[Start_Date_Hospital_Provider_Spell],
                ip.[End_Date_Hospital_Provider_Spell],
                ip.[Spell_Core_HRG]
            ) AS [RAW_national_pod_code],
            ip.[dv_Total_Cost_Inc_MFF] AS [CLN_Total_Cost],
            'IP' AS [Dataset],
            NULL AS [Activity_Type],
            CAST(ip.[Start_Date_Hospital_Provider_Spell] AS DATE) AS [AdmissionDate],
            CAST(ip.[End_Date_Hospital_Provider_Spell] AS DATE) AS [DischargeDate],
            CAST(ip.[End_Date_Hospital_Provider_Spell] AS DATE) AS [Activity_Date]
        INTO #CAM_Base
        FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active] ip
        WHERE ip.[dv_FinYear] = @FinancialYear
          AND ip.[dv_IsSpell] = 1
          AND ip.[End_Date_Hospital_Provider_Spell] >= @FromDate
          AND ip.[End_Date_Hospital_Provider_Spell] < DATEADD(DAY, 1, @ToDate)
          AND (@ProviderCode IS NULL OR ip.[Organisation_Code_Code_of_Provider] = @ProviderCode)

        UNION ALL

        SELECT
            op.[SK_EncounterID] AS [PLD_ident],
            REPLACE(op.[dv_FinYear], '/20', '') AS [RAW_Activity_Year],
            op.[dv_FinMonth] AS [RAW_Activity_Month],
            op.[dv_FinYear] AS [DER_Activity_Year],
            op.[GP_Practice_Code_Original_Data] AS [RAW_gp_practice_code],
            CASE
                WHEN RIGHT(op.[Organisation_Code_Code_Of_Commissioner], 2) = '00'
                    THEN LEFT(op.[Organisation_Code_Code_Of_Commissioner], 3)
                ELSE op.[Organisation_Code_Code_Of_Commissioner]
            END AS [RAW_ccg_code],
            op.[Organisation_Code_PCT_of_Residence] AS [RAW_Org_Residence_Responsibility],
            op.[Organisation_Code_Code_of_Provider] AS [RAW_Provider_Code],
            CASE
                WHEN RIGHT(op.[Organisation_Code_Code_Of_Commissioner], 2) = '00'
                    THEN LEFT(op.[Organisation_Code_Code_Of_Commissioner], 3)
                ELSE op.[Organisation_Code_Code_Of_Commissioner]
            END AS [RAW_Commissioner_Code],
            op.[dv_SpecCom_ServiceCode_National] AS [STP_NHSE_ServiceLine],
            NULL AS [RAW_nhse_servicecategory],
            op.[Treatment_Function_Code] AS [RAW_treatment_function_code],
            [Data_Lab_SWL].[OP].[GetPodType](
                op.[Core_HRG],
                op.[Attended_Or_Did_Not_Attend],
                op.[First_Attendance],
                op.[Main_Specialty_Code]
            ) AS [RAW_national_pod_code],
            op.[dv_Total_Cost_Inc_MFF] AS [CLN_Total_Cost],
            'OP' AS [Dataset],
            NULL AS [Activity_Type],
            CAST(op.[Appointment_Date] AS DATE) AS [AdmissionDate],
            CAST(op.[Appointment_Date] AS DATE) AS [DischargeDate],
            CAST(op.[Appointment_Date] AS DATE) AS [Activity_Date]
        FROM [Data_Lab_SWL].[Unified].[tbl_OP_EncounterDenormalised_Active] op
        WHERE op.[dv_FinYear] = @FinancialYear
          AND op.[Appointment_Date] >= @FromDate
          AND op.[Appointment_Date] < DATEADD(DAY, 1, @ToDate)
          AND (@ProviderCode IS NULL OR op.[Organisation_Code_Code_of_Provider] = @ProviderCode);

        CREATE CLUSTERED INDEX [IX_CAM_Base_Record]
            ON #CAM_Base ([PLD_ident], [Dataset]);

        CREATE NONCLUSTERED INDEX [IX_CAM_Base_Activity]
            ON #CAM_Base ([Activity_Date], [Dataset])
            INCLUDE ([RAW_Provider_Code], [RAW_national_pod_code], [DER_Activity_Year]);

        ;WITH CAM_Stage1 AS (
            -- Stage 1: Base data staged from Unified active tables
            SELECT 
                A.[PLD_ident] as [RecordIdentifier],
                A.[RAW_gp_practice_code] AS [GENERAL MEDICAL PRACTICE CODE (PATIENT REGISTRATION)],
                A.[RAW_ccg_code] AS [ORGANISATION IDENTIFIER (GP PRACTICE RESPONSIBILITY)],
                A.[RAW_Org_Residence_Responsibility] AS [ORGANISATION IDENTIFIER (RESIDENCE RESPONSIBILITY)],
                YearMonthBridge.[Effective_Date],
                HostSubICB.[Host subICB] AS [Host subICB Location],
                COALESCE(ServiceFlags.[Armed Forces Flag],0) as [Armed Forces Flag],
                COALESCE(ServiceFlags.[Public Health Flag],0) as [Public Health Flag],
                COALESCE(ServiceFlags.[Health In Justice Flag],0) as [Health In Justice Flag],
                A.[RAW_Provider_Code] AS [ORGANISATION IDENTIFIER (CODE OF PROVIDER)],
                A.[RAW_Commissioner_Code] AS [Current ORGANISATION IDENTIFIER (CODE OF COMMISSIONER)],
                A.[RAW_nhse_servicecategory] AS [Current COMMISSIONED SERVICE CATEGORY CODE],
                A.[STP_NHSE_ServiceLine] AS [Current SERVICE CODE],
                A.[RAW_national_pod_code] AS [Current NATIONAL POINT OF DELIVERY CODE],
                A.[RAW_treatment_function_code] as [TFC],
                A.[CLN_Total_Cost] AS [TotalCost],
                -- Additional context fields for your workflows
                A.[AdmissionDate],
                A.[DischargeDate],
                A.[Activity_Date],
                A.[Activity_Type],
                A.[Dataset]
            FROM #CAM_Base A
            LEFT JOIN [Data_Lab_SWL].[CAM_Ref].[ServiceFlags] ServiceFlags
                ON A.[RAW_nhse_servicecategory] = ServiceFlags.[NHSE_ServiceCategory]
            LEFT JOIN [Data_Lab_SWL].[CAM_Ref].[YearMonthBridge] YearMonthBridge
                ON A.[RAW_Activity_Year] = YearMonthBridge.[FINANCIAL_YEAR]
                AND A.[RAW_Activity_Month] = YearMonthBridge.[FINANCIAL_MONTH]
            LEFT JOIN (
                SELECT DISTINCT 
                    Prov1.[Provider_Code],
                    Prov1.[Host SubICB] AS [Host subICB]		
                FROM [Data_Lab_SWL].[CAM_Ref].[REF_Provider] Prov1
            ) AS HostSubICB ON A.[RAW_provider_code] = HostSubICB.[Provider_Code]
            WHERE 
                A.[DER_Activity_Year] = @FinancialYear
                AND (COALESCE(A.[RAW_National_POD_Code],'') NOT IN ('DRUG','DEVICE') 
                     AND COALESCE(A.[RAW_NHSE_ServiceCategory],'') NOT IN ('31','32','41'))
        ),
        
        CAM_Stage2 AS (
            -- Stage 2: COMPLETE CAM Logic - Exact replica of your working logic
            SELECT 
                B.[RecordIdentifier],
                B.[GENERAL MEDICAL PRACTICE CODE (PATIENT REGISTRATION)],
                B.[ORGANISATION IDENTIFIER (GP PRACTICE RESPONSIBILITY)],
                B.[ORGANISATION IDENTIFIER (RESIDENCE RESPONSIBILITY)],
                B.[ORGANISATION IDENTIFIER (CODE OF PROVIDER)],
                B.[Current ORGANISATION IDENTIFIER (CODE OF COMMISSIONER)],
                B.[Current COMMISSIONED SERVICE CATEGORY CODE],
                B.[Current SERVICE CODE],
                B.[TotalCost],
                B.[AdmissionDate],
                B.[DischargeDate],
                B.[Activity_Date],
                B.[Effective_Date],
                B.[Activity_Type],
                B.[Dataset],
            
            -- COMPLETE CAM CASE LOGIC - Preserving ALL functionality
            CASE
                /*Delegated Mental Health - not in flowchart but allocating appropriate Service Category ahead of onward logic*/
                WHEN ServiceCode.[Specialised MH Flag] = 1 AND COALESCE(ServiceCode.[SERVICE CODE],'') != '99999999' AND COALESCE(ServiceCode.[SERVICE CODE],'') != 'NCBPSXXX'
                    THEN
                        CASE WHEN ServiceCode.[ICBDelegationStatus] = 'GREEN' THEN 'MH_Delegated' ELSE 'MH_Non_Delegated' END

                -- C-0: Is the activity record for specialised or highly-specialised care?  Yes - Go to C-0a; No - Go to D
                -- C-0a: Is the service in scope for delegation?  Yes - Go to C-0b; No - Go to C-2
                -- C-0b: Is the service a 'GREEN' service?  Yes - Go to D; No - Responsible NHS England Specialised Commissioning Hub (GP Practice)
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
                WHEN (
                        (
                        (ServiceCode.[SERVICE CODE] IS NOT NULL AND ServiceCode.[Specialised Flag] = 1 AND COALESCE(ServiceCode.[SERVICE CODE],'') != '99999999')
                        OR (B.[Current COMMISSIONED SERVICE CATEGORY CODE] IN ('21') AND (ServiceCode.[SERVICE CODE] IS NULL OR ServiceCode.[SERVICE CODE] = '99999999'))
                        ) /*(C-0 ='Yes')*/ 
                        
                        AND (ServiceCode.[ICBDelegationStatus] IN ('RED','BLUE', 'N/a', 'NOT APPLICABLE') OR ServiceCode.[ICBDelegationStatus] IS NULL)/*(C-0a = 'No' & C-2 ='Yes')*/
                        )		
                    THEN
                        CASE
                            WHEN HostSubICB.[SubICB_Code] IS NOT NULL THEN HostSubICB.[ODSCommHub] + '_C_2_1' --Commissioned on a Provider Host basis only
                            ELSE 'C_2_X'
                            END 
                
                -- D: Is the activity for Secondary Dental care?  Yes - Responsible sub-ICB Location; No - Go to E
                WHEN (B.[TFC] IN ('140','141','142','143','144','145','217','450','451') 
                AND (ServiceCode.[Specialised Flag] = 0 OR ServiceCode.[SERVICE CODE] = '99999999' OR ServiceCode.[SERVICE CODE] IS NULL))
                OR B.[Current COMMISSIONED SERVICE CATEGORY CODE] IN ('51','55') --Provider Submitted Commissioned Service Category Code
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
                
                -- E: Is the patient part of the eligible health and justice population?  Yes - Commissioning Hub for Health and Justice Commissioning; No - Go to F
                WHEN (HandJ.[Y0Prescribingcode] IS NOT NULL AND COALESCE(B.[Current NATIONAL POINT OF DELIVERY CODE],'') != 'AE')
                OR (B.[Current COMMISSIONED SERVICE CATEGORY CODE] IN ('71','75') AND COALESCE(B.[Current NATIONAL POINT OF DELIVERY CODE],'') != 'AE') --Provider Submitted Commissioned Service Category Code
                    THEN 
                        CASE
                            WHEN HandJ.[Y0Prescribingcode] IS NOT NULL THEN HandJ.[EnglandHealthandJusticeCommissioningHubCode] + '_E_1'
                            ELSE 'E_X'
                            END
                
                -- F: Is the activity related to public health service described in the Section 7a agreement?  Yes - Responsible NHS England Regional Geography for Public Health Services; No - Go to H
                WHEN (ServiceCode.[SERVICE CODE] IS NOT NULL AND ServiceCode.[Public Health Flag] = 1 AND COALESCE(B.[Current SERVICE CODE],'') != '99999999') 
                OR B.[Current COMMISSIONED SERVICE CATEGORY CODE] IN ('81','85') --Provider Submitted Commissioned Service Category Code
                    THEN
                        CASE
                            WHEN SubICB1.[SubICB_Code] IS NOT NULL THEN SubICB1.[ODSRegion] + '_F_1' --See JOIN 3
                            WHEN SubICB2.[ICB_Code] IS NOT NULL THEN SubICB2.[ODSRegion] + '_F_2' --See JOIN 4
                            WHEN SubICB3.[SubICB_Code] IS NOT NULL THEN SubICB3.[ODSRegion] + '_F_3' --See JOIN 5
                            WHEN SubICB4.[ICB_Code] IS NOT NULL THEN SubICB4.[ODSRegion] + '_F_4' --See JOIN 6
                            WHEN HostSubICB.[SubICB_Code] IS NOT NULL THEN HostSubICB.[ODSRegion] + '_F_5' --See JOIN 1
                            ELSE 'F_X'
                            END

                -- J: Is the patient registered with an English GP Practice that has 13Q as the parent code?  Yes - NHS England Armed Forces Commissioning Hub; No - Go to C-5
                WHEN ArmedForces.[Organisation_Code] IS NOT NULL OR B.[Current COMMISSIONED SERVICE CATEGORY CODE] IN ('61') --Provider Submitted Commissioned Service Category Code
                    THEN '13Q_J_1'

                -- C-5: Is the service a specialised 'GREEN' service?  Yes - Go to C-6; No - Responsible sub-ICB location
                WHEN 
                        (
                        (ServiceCode.[SERVICE CODE] IS NOT NULL AND ServiceCode.[Specialised Flag] = 1 AND COALESCE(ServiceCode.[SERVICE CODE],'') != '99999999')
                        OR (B.[Current COMMISSIONED SERVICE CATEGORY CODE] IN ('21') AND (ServiceCode.[SERVICE CODE] IS NULL OR ServiceCode.[SERVICE CODE] = '99999999'))
                        ) /*(C-0 ='Yes')*/ 
                        AND ServiceCode.[ICBDelegationStatus] IN ('GREEN') /*C-5 = 'yes'*/
                    THEN
                        -- C-6: Is the ICB ready to accept delegation?  Yes - Responsible sub-ICB location; No - Responsible NHS England Specialised Commissioning Hub (GP Practice)
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
                                            OR SubICB4.[ICB_Code] IS NOT NULL)
                            THEN CASE
                                WHEN SubICB1.[SubICB_Code] IS NOT NULL THEN SubICB1.[ODSCommHub] + '_C_6_4' --See JOIN 3
                                WHEN SubICB2.[ICB_Code] IS NOT NULL THEN SubICB2.[ODSCommHub] + '_C_6_5' --See JOIN 4
                                WHEN SubICB3.[SubICB_Code] IS NOT NULL THEN SubICB3.[ODSCommHub] + '_C_6_6' --See JOIN 5
                                WHEN SubICB4.[ICB_Code] IS NOT NULL THEN SubICB4.[ODSCommHub] + '_C_6_7' --See JOIN 6
                                WHEN HostSubICB.[SubICB_Code] IS NOT NULL THEN HostSubICB.[ODSCommHub] + '_C_6_8' --See JOIN 1
                                END
                                ELSE 'C_5_X'
                            END

                -- No: Default ICB assignment
                WHEN SubICB1.[SubICB_Code] IS NOT NULL THEN SubICB1.[SubICB_Code] + '_C_5_1' --See JOIN 3
                WHEN SubICB3.[SubICB_Code] IS NOT NULL THEN SubICB3.[SubICB_Code] + '_C_5_1' --See JOIN 5
                WHEN HostSubICB.[SubICB_Code] IS NOT NULL THEN HostSubICB.[SubICB_Code] + '_C_5_1' --See JOIN 1

                ELSE 'X'
            END as [ReassignmentID]
            
        FROM CAM_Stage1 B
        
        -- ALL ORIGINAL REFERENCE TABLE JOINs - Complete functionality preserved
        LEFT JOIN (
            SELECT DISTINCT 
                [SubICB_Code],
                [ODSCommHub],
                [ODSHealthandJustice],
                [ODSRegion],
                [ProvisionalICBDelegationStatus],
                [Effective_From],
                [Effective_To]
            FROM [Data_Lab_SWL].[CAM_Ref].[SubICBtoDirectComm]
        ) AS HostSubICB
            ON B.[Host subICB Location] = HostSubICB.[SubICB_Code]
            AND B.[Effective_Date] BETWEEN HostSubICB.[Effective_From] AND HostSubICB.[Effective_To]

        LEFT JOIN [Data_Lab_SWL].[CAM_Ref].[ServiceCodes] AS ServiceCode
            ON B.[Current SERVICE CODE] = ServiceCode.[SERVICE CODE]
            AND B.[Effective_Date] BETWEEN ServiceCode.[Effective_From] AND ServiceCode.[Effective_To]
        
        LEFT JOIN [Data_Lab_SWL].[CAM_Ref].[SubICBtoDirectComm] AS SubICB1
            ON B.[ORGANISATION IDENTIFIER (GP PRACTICE RESPONSIBILITY)] = SubICB1.[SubICB_Code]
            AND B.[Effective_Date] BETWEEN SubICB1.[Effective_From] AND SubICB1.[Effective_To]
        
        LEFT JOIN (SELECT DISTINCT [ICB_Code], [ODSCommHub], [ODSRegion], [ODSHealthandJustice], [ProvisionalICBDelegationStatus], [Effective_From], [Effective_To] FROM [Data_Lab_SWL].[CAM_Ref].[SubICBtoDirectComm]) AS SubICB2
            ON B.[ORGANISATION IDENTIFIER (GP PRACTICE RESPONSIBILITY)] = SubICB2.[ICB_Code]
            AND B.[Effective_Date] BETWEEN SubICB2.[Effective_From] AND SubICB2.[Effective_To]
        
        LEFT JOIN [Data_Lab_SWL].[CAM_Ref].[SubICBtoDirectComm] AS SubICB3
            ON B.[ORGANISATION IDENTIFIER (RESIDENCE RESPONSIBILITY)] = SubICB3.[SubICB_Code]
            AND B.[Effective_Date] BETWEEN SubICB3.[Effective_From] AND SubICB3.[Effective_To]
        
        LEFT JOIN (SELECT DISTINCT [ICB_Code], [ODSCommHub], [ODSRegion], [ODSHealthandJustice], [ProvisionalICBDelegationStatus], [Effective_From], [Effective_To] FROM [Data_Lab_SWL].[CAM_Ref].[SubICBtoDirectComm]) AS SubICB4
            ON B.[ORGANISATION IDENTIFIER (RESIDENCE RESPONSIBILITY)] = SubICB4.[ICB_Code]
            AND B.[Effective_Date] BETWEEN SubICB4.[Effective_From] AND SubICB4.[Effective_To]

        LEFT JOIN (SELECT DISTINCT [EnglandHealthandJusticeCommissioningHubCode], [Y0Prescribingcode] FROM [Data_Lab_SWL].[CAM_Ref].[Ref_HandJ_CommissionerCode] WHERE [Y0PrescribingCode] IS NOT NULL) HandJ
            ON B.[GENERAL MEDICAL PRACTICE CODE (PATIENT REGISTRATION)] = HandJ.[Y0Prescribingcode]

        LEFT JOIN [Data_Lab_SWL].[CAM_Ref].[ArmedForcesGP] ArmedForces  
            ON B.[ORGANISATION IDENTIFIER (GP PRACTICE RESPONSIBILITY)] = ArmedForces.[Organisation_Code] 
            AND ArmedForces.English_AF_GP_Practice_Flag = 1
    ),
    
    -- Final SELECT with complete commissioner assignment
    CAM_Final AS (
        SELECT 
            S2.[RecordIdentifier],
            S2.[GENERAL MEDICAL PRACTICE CODE (PATIENT REGISTRATION)] as [GP_Practice_Code],
            S2.[ORGANISATION IDENTIFIER (GP PRACTICE RESPONSIBILITY)] as [CCG_Code],
            S2.[ORGANISATION IDENTIFIER (RESIDENCE RESPONSIBILITY)] as [Residence_Code],
            S2.[ORGANISATION IDENTIFIER (CODE OF PROVIDER)] as [Provider_Code],
            S2.[Current ORGANISATION IDENTIFIER (CODE OF COMMISSIONER)] as [Current_Commissioner_Code],
            S2.[Current COMMISSIONED SERVICE CATEGORY CODE] as [Current_Service_Category],
            S2.[Current SERVICE CODE] as [Current_Service_Code],
            S2.[ReassignmentID],
            CAR.[Comm] as [CAM_Commissioner_Code],
            CAR.[Service Category] as [CAM_Service_Category],
            CAR.[Commissioner Assignment Reason] AS [CAM_Assignment_Reason],
            S2.[TotalCost],
            S2.[AdmissionDate],
            S2.[DischargeDate],
            S2.[Activity_Date],
            S2.[Effective_Date],
            S2.[Activity_Type],
            S2.[Dataset],
            
            -- Variance flags for monitoring
            CASE WHEN S2.[Current ORGANISATION IDENTIFIER (CODE OF COMMISSIONER)] != CAR.[Comm] THEN 1 ELSE 0 END as [Commissioner_Variance],
            CASE WHEN S2.[Current COMMISSIONED SERVICE CATEGORY CODE] != CAR.[Service Category] THEN 1 ELSE 0 END as [Service_Category_Variance]
            
        FROM CAM_Stage2 S2
        LEFT JOIN [Data_Lab_SWL].[CAM_Ref].[CommissionerAssignmentReason] CAR
            ON S2.[ReassignmentID] = CAR.[CAM_Code]
        WHERE S2.[Current ORGANISATION IDENTIFIER (CODE OF COMMISSIONER)] <> 'VPP'
    )
    SELECT
        [RecordIdentifier],
        [Dataset],
        [Provider_Code],
        [GP_Practice_Code],
        [CAM_Commissioner_Code],
        [CAM_Service_Category],
        [CAM_Assignment_Reason],
        [ReassignmentID],
        [Commissioner_Variance],
        [Service_Category_Variance],
        [AdmissionDate],
        [DischargeDate],
        [Activity_Date],
        [Effective_Date]
    INTO #CAM_Final
    FROM CAM_Final;

        SELECT @DuplicateKeyCount = ISNULL(SUM(d.DuplicateRows), 0)
        FROM (
            SELECT COUNT(1) - 1 AS DuplicateRows
            FROM #CAM_Final
            GROUP BY [RecordIdentifier], [Dataset]
            HAVING COUNT(1) > 1
        ) d;

        IF @DuplicateKeyCount > 0
        BEGIN
            SET @DQMessage = 'Discarded ' + CAST(@DuplicateKeyCount AS VARCHAR(20))
                + ' duplicate rows for (RecordIdentifier, Dataset).';
            PRINT @DQMessage;

            INSERT INTO [Data_Lab_SWL_Live].[Analytics].[tbl_ETL_Error_Details] (
                Batch_ID,
                Load_ID,
                Source_Table,
                Target_Table,
                Failed_Row_Data,
                Business_Key,
                Error_Message,
                Error_Type
            )
            VALUES (
                @BatchID,
                NULL,
                'Data_Lab_SWL.CAM.tbl_CAM_Raw',
                'Data_Lab_SWL.CAM.tbl_CAM_Raw',
                CONCAT('{"FromDate":"', CONVERT(VARCHAR(10), @WindowStartDate, 120),
                       '","ToDate":"', CONVERT(VARCHAR(10), @WindowEndDate, 120),
                       '","DuplicateKeyCount":', @DuplicateKeyCount, '}'),
                'DUPLICATE_PK',
                @DQMessage,
                'DataQuality'
            );
        END

        ;WITH Ranked AS (
            SELECT
                *,
                ROW_NUMBER() OVER (
                    PARTITION BY [RecordIdentifier], [Dataset]
                    ORDER BY [Activity_Date] DESC, [Effective_Date] DESC, [DischargeDate] DESC,
                        [ReassignmentID] DESC, [CAM_Service_Category] DESC
                ) AS RowNum
            FROM #CAM_Final
        )
        INSERT INTO [Data_Lab_SWL].[CAM].[tbl_CAM_Raw] (
        [RecordIdentifier],
        [Dataset],
        [Provider_Code],
        [GP_Practice_Code],
        [CAM_Commissioner_Code],
        [CAM_Service_Category],
        [CAM_Assignment_Reason],
        [ReassignmentID],
        [Commissioner_Variance],
        [Service_Category_Variance],
        [AdmissionDate],
        [DischargeDate],
        [Financial_Year],
        [ETL_LoadDateTime]
    )
        SELECT
            [RecordIdentifier],
            [Dataset],
            [Provider_Code],
            [GP_Practice_Code],
            [CAM_Commissioner_Code],
            [CAM_Service_Category],
            [CAM_Assignment_Reason],
            [ReassignmentID],
            [Commissioner_Variance],
            [Service_Category_Variance],
            [AdmissionDate],
            [DischargeDate],
            @FinancialYear,
            @ETL_Start
        FROM Ranked
        WHERE RowNum = 1;

        SET @RowsInserted = @@ROWCOUNT;

        EXEC [Data_Lab_SWL_Live].[Analytics].[sp_Log_Table_Load]
            @BatchID = @BatchID,
            @TableName = 'Data_Lab_SWL.CAM.tbl_CAM_Raw',
            @LoadType = 'Full',
            @RowsAffected = @RowsInserted,
            @Status = 'Success';

        EXEC [Data_Lab_SWL_Live].[Analytics].[sp_End_ETL_Batch]
            @BatchID = @BatchID,
            @Status = 'Success',
            @RowsInserted = @RowsInserted,
            @RowsUpdated = 0,
            @RowsDeleted = @RowsDeleted,
            @RowsFailed = 0,
            @ErrorMessage = NULL;
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();
        PRINT 'Error Loading CAM Raw: ' + @ErrorMessage;

        IF @BatchID IS NOT NULL
        BEGIN
            EXEC [Data_Lab_SWL_Live].[Analytics].[sp_Log_Table_Load]
                @BatchID = @BatchID,
                @TableName = 'Data_Lab_SWL.CAM.tbl_CAM_Raw',
                @LoadType = 'Full',
                @RowsAffected = 0,
                @RowsFailed = 1,
                @Status = 'Failed',
                @ErrorMessage = @ErrorMessage;

            EXEC [Data_Lab_SWL_Live].[Analytics].[sp_End_ETL_Batch]
                @BatchID = @BatchID,
                @Status = 'Failed',
                @RowsInserted = 0,
                @RowsUpdated = 0,
                @RowsDeleted = 0,
                @RowsFailed = 1,
                @ErrorMessage = @ErrorMessage;
        END

        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END CATCH
END
GO

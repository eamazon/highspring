USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating vw_IP_ERF VIEW';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

IF OBJECT_ID('[Analytics].[vw_IP_ERF]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[vw_IP_ERF] already exists. Dropping...';
    DROP VIEW [Analytics].[vw_IP_ERF];
END
GO

/**
Script Name:   09_Create_ERF_Views.sql
Description:   Analytics-scoped ERF repricing views (25/26) for IP/OP fact enrichment.
Author:        Sridhar Peddi
Created:       2026-01-15

Notes:
- Output columns are limited to downstream ERF enrichment needs.
- Sources Unified SUS encounter tables directly (no SUS repricing joins).
**/
/**
View Name:     [Analytics].[vw_IP_ERF]
Description:   Minimal ERF repricing output for IP encounters (25/26).
Dependencies:  [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active],
               [Data_Lab_SWL].[SWL].[tbl_Tariff_APC_OPPROC],
               [Data_Lab_SWL].[SWL].[tbl_MFF]
**/
CREATE VIEW [Analytics].[vw_IP_ERF] AS
WITH base_data AS (
    SELECT
        ap.SK_EncounterID,
        ap.dv_FinYear,
        ap.Organisation_Code_Code_of_Provider,
        ap.Organisation_Code_Code_of_Commissioner,
        ap.Patient_Classification,
        ap.Spell_Core_HRG,
        ap.Treatment_Function_Code,
        ap.dv_LengthOfStay_Net,
        ap.dv_MFF_Index_Applied,
        ap.Admission_Method_Hospital_Provider_Spell,
        ap.Administrative_Category_on_Admission
    FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active] ap WITH (NOLOCK)
    WHERE LEFT(ap.dv_FinYear, 4) IN (2024, 2025)
      AND ap.dv_IsSpell = 1
),
pricing AS (
    SELECT
        b.SK_EncounterID,
        b.dv_FinYear,
        COALESCE(
            tf.Combined_Day_Case_Ordinary_Elective_Spell_Tariff,
            CASE
                WHEN b.Patient_Classification IN ('1','01') THEN tf.Ordinary_Elective_Spell_Tariff
                WHEN b.Patient_Classification IN ('2','02') THEN tf.Day_Case_Spell_Tariff
                ELSE 0
            END,
            0
        ) AS Price,
        CASE
            WHEN b.Patient_Classification IN ('1','01')
                 AND b.dv_LengthOfStay_Net > ISNULL(tf.Ordinary_Elective_Long_Stay_Trimpoint_Days, 999)
                THEN b.dv_LengthOfStay_Net - ISNULL(tf.Ordinary_Elective_Long_Stay_Trimpoint_Days, 999)
            ELSE 0
        END AS Excess_bed_days,
        ISNULL(tf.Per_Day_Long_Stay_Payment_For_Days_Exceeding_Trim_Point, 0) AS LongStay_Day_Tariff,
        COALESCE(mff.MFF, b.dv_MFF_Index_Applied, 1.061299920) AS MFF_Applied,
        '2025/2026' AS Tariff_Used
    FROM base_data b
    LEFT JOIN [Data_Lab_SWL].[SWL].[tbl_Tariff_APC_OPPROC] tf
        ON b.Spell_Core_HRG = tf.HRG_Code
        AND tf.FinancialYear = '2025/2026'
    LEFT JOIN [Data_Lab_SWL].[SWL].[tbl_MFF] mff
        ON mff.ProviderCode = LEFT(b.Organisation_Code_Code_of_Provider, 3)
        AND mff.Financial_Year = '2025/2026'
    WHERE 1 = 1
        AND b.Spell_Core_HRG NOT LIKE 'UZ%'
        AND b.Spell_Core_HRG NOT LIKE 'NZ%'
        AND b.Patient_Classification IN ('1','01','2','02')
        AND b.Treatment_Function_Code NOT IN ('501','560','700','710','711','712','713','715','720','721','722','723','724','725','726','727','199','499')
        AND (
            b.Organisation_Code_Code_of_Provider LIKE 'RAX%' OR
            b.Organisation_Code_Code_of_Provider LIKE 'RJ6%' OR
            b.Organisation_Code_Code_of_Provider LIKE 'RJ7%' OR
            b.Organisation_Code_Code_of_Provider LIKE 'RPY%' OR
            b.Organisation_Code_Code_of_Provider LIKE 'RVR%' OR
            b.Organisation_Code_Code_of_Commissioner LIKE '36L%' OR
            b.Organisation_Code_Code_of_Commissioner LIKE '07V%' OR
            b.Organisation_Code_Code_of_Commissioner LIKE '08J%' OR
            b.Organisation_Code_Code_of_Commissioner LIKE '08P%' OR
            b.Organisation_Code_Code_of_Commissioner LIKE '08R%' OR
            b.Organisation_Code_Code_of_Commissioner LIKE '08T%' OR
            b.Organisation_Code_Code_of_Commissioner LIKE '08X%'
        )
        AND b.Admission_Method_Hospital_Provider_Spell IN ('11','12','13')
        AND b.Administrative_Category_on_Admission <> 2
        AND b.Organisation_Code_Code_of_Commissioner NOT LIKE 'VPP00%'
)
SELECT
    p.SK_EncounterID,
    p.dv_FinYear,
    CAST(p.Price AS DECIMAL(12,2)) AS Price,
    CAST(p.MFF_Applied AS DECIMAL(12,6)) AS MFF_Applied,
    CAST(ROUND(((p.Price) + (p.Excess_bed_days * p.LongStay_Day_Tariff)) * p.MFF_Applied, 2) AS DECIMAL(12,2)) AS TotalCostInclMFF,
    p.Tariff_Used
FROM pricing p;
GO

PRINT '[OK] Created view: [Analytics].[vw_IP_ERF]';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

PRINT '========================================';
PRINT 'Creating vw_OP_ERF VIEW';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

IF OBJECT_ID('[Analytics].[vw_OP_ERF]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[vw_OP_ERF] already exists. Dropping...';
    DROP VIEW [Analytics].[vw_OP_ERF];
END
GO

/**
View Name:     [Analytics].[vw_OP_ERF]
Description:   Minimal ERF repricing output for OP encounters (25/26).
Dependencies:  [Data_Lab_SWL].[Unified].[tbl_OP_EncounterDenormalised_Active],
               [Data_Lab_SWL].[SWL].[tbl_Tariff_APC_OPPROC],
               [Data_Lab_SWL].[SWL].[tbl_Tariff_OP],
               [Dictionary].[dbo].[Organisation]
**/
CREATE VIEW [Analytics].[vw_OP_ERF] AS
WITH op_base AS (
    SELECT
        op.SK_EncounterID,
        op.dv_FinYear,
        op.Organisation_Code_Code_of_Provider,
        op.Organisation_Code_Code_of_Commissioner,
        op.Core_HRG,
        op.Treatment_Function_Code,
        op.Attended_Or_Did_Not_Attend,
        op.Administrative_Category,
        op.First_Attendance,
        op.Main_Specialty_Code,
        op.dv_MFF_Index_Applied
    FROM [Data_Lab_SWL].[Unified].[tbl_OP_EncounterDenormalised_Active] op WITH (NOLOCK)
    WHERE LEFT(op.dv_FinYear, 4) IN (2024, 2025)
),
proc_data AS (
    SELECT
        op.SK_EncounterID,
        op.dv_FinYear,
        Der_Appointment_Type = CASE
            WHEN tariff_proc.Outpatient_Procedure_Tariff IS NULL
                 AND (
                     CASE
                         WHEN op.First_Attendance = 1 AND op.Treatment_Function_Code <> 812 THEN [WF01B_First_Attendance_Single_Professional]
                         WHEN op.First_Attendance = 3 AND op.Treatment_Function_Code <> 812 THEN [WF02B_First_Attendance_Multiprofessional]
                         ELSE 0
                     END
                 ) <> 0 THEN 'OPFA'
            ELSE 'OPPROC'
        END,
        National_Price = COALESCE(
            tariff_proc.Outpatient_Procedure_Tariff,
            CASE
                WHEN op.First_Attendance = 1 AND op.Treatment_Function_Code <> 812 THEN [WF01B_First_Attendance_Single_Professional]
                WHEN op.First_Attendance = 3 AND op.Treatment_Function_Code <> 812 THEN [WF02B_First_Attendance_Multiprofessional]
                ELSE 0
            END
        ),
        op.dv_MFF_Index_Applied AS MFF
    FROM op_base op
    LEFT JOIN (
        SELECT HRG_Code, Outpatient_Procedure_Tariff
        FROM [Data_Lab_SWL].[SWL].[tbl_Tariff_APC_OPPROC]
        WHERE Outpatient_Procedure_Tariff IS NOT NULL
          AND FinancialYear = '2025/2026'
    ) tariff_proc
        ON op.Core_HRG = tariff_proc.HRG_Code
    LEFT JOIN [Dictionary].[dbo].[Organisation] ORG
        ON ORG.Organisation_Code = CASE
            WHEN RIGHT(op.Organisation_Code_Code_of_Provider, 2) = '00'
                THEN LEFT(op.Organisation_Code_Code_of_Provider, 3)
            ELSE op.Organisation_Code_Code_of_Provider
        END
    LEFT JOIN [Data_Lab_SWL].[SWL].[tbl_Tariff_OP] tariff
        ON tariff.Treatment_Function_Code = op.Treatment_Function_Code
        AND tariff.FinancialYear = '2025/2026'
    WHERE 1 = 1
        AND op.Attended_Or_Did_Not_Attend IN ('5','6')
        AND op.Administrative_Category NOT IN ('2','02')
        AND op.Core_HRG NOT LIKE 'NZ%'
        AND op.Treatment_Function_Code NOT IN ('501','560','700','710','711','712','713','715','720','721','722','723','724','725','726','727','199','499')
        AND op.Core_HRG NOT IN ('MA50Z','MA51Z','MA52A','MA52B','MA53Z','MA54Z','MA55A','MA55B','MA56A','MA56B')
        AND op.Core_HRG <> 'NULL'
        AND op.Core_HRG NOT LIKE 'UZ%'
        AND COALESCE(
            tariff_proc.Outpatient_Procedure_Tariff,
            CASE
                WHEN op.First_Attendance = 1 AND op.Treatment_Function_Code <> 812 THEN [WF01B_First_Attendance_Single_Professional]
                WHEN op.First_Attendance = 3 AND op.Treatment_Function_Code <> 812 THEN [WF02B_First_Attendance_Multiprofessional]
                ELSE 0
            END
        ) <> 0
        AND (
            LEFT(op.Organisation_Code_Code_of_Provider, 3) IN ('RAX','RJ6','RJ7','RPY','RVR')
            OR LEFT(op.Organisation_Code_Code_of_Commissioner, 3) IN ('36L','07V','08J','08P','08R','08T','08X')
        )
        AND op.Core_HRG NOT LIKE 'WF%'
        AND ORG.OrganisationPrimaryRole NOT IN ('RO144','RO190','RO155')
        AND NOT(op.Organisation_Code_Code_of_Commissioner LIKE 'VPP00')
),
att_data AS (
    SELECT
        op.SK_EncounterID,
        op.dv_FinYear,
        Der_Appointment_Type = CASE
            WHEN op.First_Attendance IN (1,3) THEN 'OPFA'
            WHEN op.First_Attendance IN (2,4)
                 AND LEFT(op.Organisation_Code_Code_of_Commissioner,3) IN ('36L','07V','08J','08P','08R','08T','08X')
                 AND ORG.OrganisationPrimaryRole IN ('RO172','RO176') THEN 'OPFU'
            ELSE 'Unknown'
        END,
        National_Price = CASE
            WHEN op.Core_HRG IN ('WF01B', 'WF01D') THEN [WF01B_First_Attendance_Single_Professional]
            WHEN op.Core_HRG IN ('WF02B', 'WF02D') THEN [WF02B_First_Attendance_Multiprofessional]
            ELSE NULL
        END,
        op.dv_MFF_Index_Applied AS MFF
    FROM op_base op
    LEFT JOIN [Data_Lab_SWL].[SWL].[tbl_Tariff_OP] tariff
        ON tariff.Treatment_Function_Code = op.Treatment_Function_Code
        AND tariff.FinancialYear = '2025/2026'
    LEFT JOIN [Dictionary].[dbo].[Organisation] ORG
        ON ORG.Organisation_Code = CASE
            WHEN RIGHT(op.Organisation_Code_Code_of_Provider, 2) = '00'
                THEN LEFT(op.Organisation_Code_Code_of_Provider, 3)
            ELSE op.Organisation_Code_Code_of_Provider
        END
    WHERE 1 = 1
        AND op.Attended_Or_Did_Not_Attend IN ('5','6')
        AND op.Administrative_Category NOT IN ('2','02')
        AND op.Core_HRG NOT LIKE 'NZ%'
        AND op.Treatment_Function_Code NOT IN ('501','560','700','710','711','712','713','715','720','721','722','723','724','725','726','727','199','499','812')
        AND op.Core_HRG NOT IN ('MA50Z','MA51Z','MA52A','MA52B','MA53Z','MA54Z','MA55A','MA55B','MA56A','MA56B')
        AND op.Core_HRG <> 'NULL'
        AND op.Core_HRG NOT LIKE 'UZ%'
        AND (
            LEFT(op.Organisation_Code_Code_of_Provider, 3) IN ('RAX','RJ6','RJ7','RPY','RVR')
            OR LEFT(op.Organisation_Code_Code_of_Commissioner, 3) IN ('36L','07V','08J','08P','08R','08T','08X')
        )
        AND op.Core_HRG LIKE 'WF%'
        AND (
            op.First_Attendance IN (1,3)
            OR (
                op.First_Attendance IN (2,4)
                AND LEFT(op.Organisation_Code_Code_of_Commissioner,3) IN ('36L','07V','08J','08P','08R','08T','08X')
                AND ORG.OrganisationPrimaryRole IN ('RO172','RO176')
            )
        )
        AND ORG.OrganisationPrimaryRole NOT IN ('RO144','RO190','RO155')
        AND NOT(op.Organisation_Code_Code_of_Commissioner LIKE 'VPP00')
),
agg_data AS (
    SELECT
        SK_EncounterID,
        dv_FinYear,
        National_Price,
        Price_to_apply = CASE
            WHEN National_Price IS NULL THEN
                CASE
                    WHEN Der_Appointment_Type LIKE 'OPFA' THEN 210
                    WHEN Der_Appointment_Type LIKE 'OPFU' THEN 105
                    ELSE 0
                END
            ELSE National_Price
        END,
        MFF,
        Tariff_Used = '2025/2026'
    FROM proc_data
    UNION ALL
    SELECT
        SK_EncounterID,
        dv_FinYear,
        National_Price,
        Price_to_apply = CASE
            WHEN National_Price IS NULL THEN
                CASE
                    WHEN Der_Appointment_Type LIKE 'OPFA' THEN 210
                    WHEN Der_Appointment_Type LIKE 'OPFU' THEN 105
                    ELSE 0
                END
            ELSE National_Price
        END,
        MFF,
        Tariff_Used = '2025/2026'
    FROM att_data
)
SELECT
    a.SK_EncounterID,
    a.dv_FinYear,
    CAST(a.National_Price AS DECIMAL(12,2)) AS National_Price,
    CAST(a.MFF AS DECIMAL(12,6)) AS MFF,
    CAST(ROUND(a.Price_to_apply * a.MFF, 2) AS DECIMAL(12,2)) AS TotalCostInclMFF,
    a.Tariff_Used
FROM agg_data a;
GO

PRINT '[OK] Created view: [Analytics].[vw_OP_ERF]';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

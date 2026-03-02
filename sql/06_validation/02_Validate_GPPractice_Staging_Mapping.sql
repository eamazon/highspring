USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Validate GP Practice Staging and Mapping';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

-------------------------------------------------------------------------------
-- 1) Profile raw staging coverage
-------------------------------------------------------------------------------
SELECT
    COUNT(*) AS Total_Staging_Rows,
    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Practice_Code)), '') IS NULL THEN 1 ELSE 0 END) AS Missing_Practice_Code,
    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(PCN_Code)), '') IS NULL THEN 1 ELSE 0 END) AS Missing_PCN_Code,
    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Commissioner_Code)), '') IS NULL THEN 1 ELSE 0 END) AS Missing_Commissioner_Code,
    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(ICB_Code)), '') IS NULL THEN 1 ELSE 0 END) AS Missing_ICB_Code
FROM [Analytics].[tbl_Staging_GP_Practice];
GO

-------------------------------------------------------------------------------
-- 2) Identify candidate filtering fields before enforcing any hard filter
-- NOTE: RO76 is an ODS role identifier concept; this report checks what is
-- actually present in staging columns used by this pipeline.
-------------------------------------------------------------------------------
SELECT
    ISNULL(NULLIF(LTRIM(RTRIM(Org_Sub_Type)), ''), '(NULL/BLANK)') AS Org_Sub_Type,
    COUNT(*) AS Row_Count
FROM [Analytics].[tbl_Staging_GP_Practice]
GROUP BY ISNULL(NULLIF(LTRIM(RTRIM(Org_Sub_Type)), ''), '(NULL/BLANK)')
ORDER BY Row_Count DESC;
GO

SELECT
    ISNULL(NULLIF(LTRIM(RTRIM(Prescribing_Setting)), ''), '(NULL/BLANK)') AS Prescribing_Setting,
    COUNT(*) AS Row_Count
FROM [Analytics].[tbl_Staging_GP_Practice]
GROUP BY ISNULL(NULLIF(LTRIM(RTRIM(Prescribing_Setting)), ''), '(NULL/BLANK)')
ORDER BY Row_Count DESC;
GO

-- Eligibility profile for Dim_GPPractice load rule:
-- Status = 'Active', Org_Sub_Type = 'B', Prescribing_Setting = 'RO76'
SELECT
    COUNT(*) AS Total_Staging_Rows,
    SUM(CASE WHEN ISNULL(Status, '') = 'Active' THEN 1 ELSE 0 END) AS Active_Rows,
    SUM(CASE WHEN ISNULL(Status, '') = 'Active' AND ISNULL(Org_Sub_Type, '') = 'B' THEN 1 ELSE 0 END) AS Active_B_SubType,
    SUM(CASE WHEN ISNULL(Status, '') = 'Active' AND ISNULL(Org_Sub_Type, '') = 'B' AND ISNULL(Prescribing_Setting, '') = 'RO76' THEN 1 ELSE 0 END) AS Eligible_For_Dim_Load,
    SUM(CASE WHEN ISNULL(Status, '') = 'Active' AND ISNULL(Org_Sub_Type, '') = 'B' AND ISNULL(Prescribing_Setting, '') <> 'RO76' THEN 1 ELSE 0 END) AS Active_B_But_NonRO76
FROM [Analytics].[tbl_Staging_GP_Practice];
GO

SELECT
    ISNULL(NULLIF(LTRIM(RTRIM(Prescribing_Setting)), ''), '(NULL/BLANK)') AS Prescribing_Setting,
    COUNT(*) AS Active_B_Row_Count
FROM [Analytics].[tbl_Staging_GP_Practice]
WHERE
    ISNULL(Status, '') = 'Active'
    AND ISNULL(Org_Sub_Type, '') = 'B'
    AND ISNULL(Prescribing_Setting, '') <> 'RO76'
GROUP BY ISNULL(NULLIF(LTRIM(RTRIM(Prescribing_Setting)), ''), '(NULL/BLANK)')
ORDER BY Active_B_Row_Count DESC, Prescribing_Setting;
GO

IF OBJECT_ID('[Analytics].[Ref_Prescribing_Setting]', 'U') IS NOT NULL
BEGIN
    SELECT
        ISNULL(NULLIF(LTRIM(RTRIM(s.Prescribing_Setting)), ''), '(NULL/BLANK)') AS Prescribing_Setting,
        r.Role_ID,
        r.Setting_Description,
        COUNT(*) AS Row_Count
    FROM [Analytics].[tbl_Staging_GP_Practice] s
    LEFT JOIN [Analytics].[Ref_Prescribing_Setting] r
        ON r.Role_ID = s.Prescribing_Setting
    GROUP BY
        ISNULL(NULLIF(LTRIM(RTRIM(s.Prescribing_Setting)), ''), '(NULL/BLANK)'),
        r.Role_ID,
        r.Setting_Description
    ORDER BY Row_Count DESC, Prescribing_Setting;

END
ELSE
BEGIN
    PRINT '[INFO] [Analytics].[Ref_Prescribing_Setting] not found; skipped role-description join.';
END
GO

-------------------------------------------------------------------------------
-- 3) Check commissioner code quality against Dim_Commissioner
-------------------------------------------------------------------------------
SELECT TOP (100)
    s.Commissioner_Code,
    COUNT(*) AS Uses_In_Staging
FROM [Analytics].[tbl_Staging_GP_Practice] s
LEFT JOIN [Analytics].[tbl_Dim_Commissioner] c
    ON c.Commissioner_Code = s.Commissioner_Code
WHERE NULLIF(LTRIM(RTRIM(s.Commissioner_Code)), '') IS NOT NULL
  AND c.Commissioner_Code IS NULL
GROUP BY s.Commissioner_Code
ORDER BY Uses_In_Staging DESC, s.Commissioner_Code;
GO

-------------------------------------------------------------------------------
-- 4) Check PCN linkage quality against staging PCN table
-------------------------------------------------------------------------------
SELECT TOP (100)
    s.PCN_Code,
    COUNT(*) AS Uses_In_Staging
FROM [Analytics].[tbl_Staging_GP_Practice] s
LEFT JOIN [Analytics].[tbl_Staging_PCN] p
    ON p.PCN_Code = s.PCN_Code
WHERE NULLIF(LTRIM(RTRIM(s.PCN_Code)), '') IS NOT NULL
  AND p.PCN_Code IS NULL
GROUP BY s.PCN_Code
ORDER BY Uses_In_Staging DESC, s.PCN_Code;
GO

-------------------------------------------------------------------------------
-- 5) Reproduce ETL resolution logic and measure residual UNKNOWNs
-------------------------------------------------------------------------------
;WITH SourceResolved AS (
    SELECT
        s.Practice_Code,
        ISNULL(NULLIF(s.PCN_Code, ''), 'UNK') AS Resolved_PCN_Code,
        ISNULL(
            NULLIF(p.Sub_ICB_Code, ''),
            CASE WHEN ISNULL(cs.Commissioner_Type, '') <> 'ICB' THEN NULLIF(s.Commissioner_Code, '') END,
            CASE WHEN ISNULL(cs.Commissioner_Type, '') <> 'ICB' THEN NULLIF(cs.SubICB_Code, '') END,
            'UNK'
        ) AS Resolved_SubICB_Code,
        ISNULL(
            NULLIF(s.ICB_Code, ''),
            CASE WHEN cs.Commissioner_Type = 'ICB' THEN NULLIF(s.Commissioner_Code, '') END,
            NULLIF(cs.ICB_Code, ''),
            NULLIF(cp.ICB_Code, ''),
            'UNK'
        ) AS Resolved_ICB_Code
    FROM [Analytics].[tbl_Staging_GP_Practice] s
    LEFT JOIN [Analytics].[tbl_Staging_PCN] p
        ON s.PCN_Code = p.PCN_Code
    LEFT JOIN [Analytics].[tbl_Dim_Commissioner] cs
        ON cs.Commissioner_Code = s.Commissioner_Code
    LEFT JOIN [Analytics].[tbl_Dim_Commissioner] cp
        ON cp.Commissioner_Code = p.Sub_ICB_Code
)
SELECT
    COUNT(*) AS Total_Practices,
    SUM(CASE WHEN Resolved_PCN_Code = 'UNK' THEN 1 ELSE 0 END) AS Unknown_PCN,
    SUM(CASE WHEN Resolved_SubICB_Code = 'UNK' THEN 1 ELSE 0 END) AS Unknown_SubICB,
    SUM(CASE WHEN Resolved_ICB_Code = 'UNK' THEN 1 ELSE 0 END) AS Unknown_ICB
FROM SourceResolved;
GO

-------------------------------------------------------------------------------
-- 6) Compare current dimension vs resolved mapping (current-row mismatches)
-------------------------------------------------------------------------------
;WITH SourceResolved AS (
    SELECT
        s.Practice_Code,
        ISNULL(NULLIF(s.PCN_Code, ''), 'UNK') AS Resolved_PCN_Code,
        ISNULL(
            NULLIF(p.Sub_ICB_Code, ''),
            CASE WHEN ISNULL(cs.Commissioner_Type, '') <> 'ICB' THEN NULLIF(s.Commissioner_Code, '') END,
            CASE WHEN ISNULL(cs.Commissioner_Type, '') <> 'ICB' THEN NULLIF(cs.SubICB_Code, '') END,
            'UNK'
        ) AS Resolved_SubICB_Code,
        ISNULL(
            NULLIF(s.ICB_Code, ''),
            CASE WHEN cs.Commissioner_Type = 'ICB' THEN NULLIF(s.Commissioner_Code, '') END,
            NULLIF(cs.ICB_Code, ''),
            NULLIF(cp.ICB_Code, ''),
            'UNK'
        ) AS Resolved_ICB_Code
    FROM [Analytics].[tbl_Staging_GP_Practice] s
    LEFT JOIN [Analytics].[tbl_Staging_PCN] p
        ON s.PCN_Code = p.PCN_Code
    LEFT JOIN [Analytics].[tbl_Dim_Commissioner] cs
        ON cs.Commissioner_Code = s.Commissioner_Code
    LEFT JOIN [Analytics].[tbl_Dim_Commissioner] cp
        ON cp.Commissioner_Code = p.Sub_ICB_Code
)
SELECT TOP (200)
    d.GPPractice_Code,
    d.PCN_Code AS Dim_PCN_Code,
    r.Resolved_PCN_Code AS Staging_Resolved_PCN_Code,
    d.SubICB_Code AS Dim_SubICB_Code,
    r.Resolved_SubICB_Code AS Staging_Resolved_SubICB_Code,
    d.ICB_Code AS Dim_ICB_Code,
    r.Resolved_ICB_Code AS Staging_Resolved_ICB_Code
FROM [Analytics].[tbl_Dim_GPPractice] d
JOIN SourceResolved r
    ON d.GPPractice_Code = r.Practice_Code
WHERE d.Is_Current = 1
  AND (
      ISNULL(d.PCN_Code, 'UNK') <> r.Resolved_PCN_Code OR
      ISNULL(d.SubICB_Code, 'UNK') <> r.Resolved_SubICB_Code OR
      ISNULL(d.ICB_Code, 'UNK') <> r.Resolved_ICB_Code
  )
ORDER BY d.GPPractice_Code;
GO

PRINT '========================================';
PRINT 'Validation Complete';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('[Analytics].[sp_Load_Ref_CF_Code_Lookup]', 'P') IS NOT NULL
    DROP PROCEDURE [Analytics].[sp_Load_Ref_CF_Code_Lookup];
GO

/**
Script Name:   25_sp_Load_Ref_CF_Code_Lookup.sql
Description:   One-time loader for Analytics CF code lookup from Data_Lab_SWL_CF.dbo.code_lookup.
               Skips load if target table already contains rows.
Author:        Sridhar Peddi
Created:       2026-01-26

Change Log:
  2026-01-26  Sridhar Peddi    Initial creation
**/
CREATE PROCEDURE [Analytics].[sp_Load_Ref_CF_Code_Lookup]
AS
BEGIN
    SET NOCOUNT ON;

    IF OBJECT_ID('[Analytics].[tbl_Ref_CF_Code_Lookup]', 'U') IS NULL
    BEGIN
        RAISERROR('Missing target table [Analytics].[tbl_Ref_CF_Code_Lookup]. Run 01e_Create_tbl_Ref_CF_Code_Lookup.sql first.', 16, 1);
        RETURN;
    END

    IF OBJECT_ID('[Data_Lab_SWL_CF].[dbo].[code_lookup]', 'U') IS NULL
    BEGIN
        RAISERROR('Missing source table [Data_Lab_SWL_CF].[dbo].[code_lookup]. Load legacy CF rules before running this procedure.', 16, 1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM [Analytics].[tbl_Ref_CF_Code_Lookup])
    BEGIN
        PRINT '[INFO] Analytics.tbl_Ref_CF_Code_Lookup already populated. Skipping load.';
        RETURN;
    END

    ;WITH SourceData AS (
        SELECT
            UPPER(REPLACE(REPLACE(LTRIM(RTRIM(lu.[code])), '.', ''), ' ', '')) AS [Code],
            LTRIM(RTRIM(lu.[code_type])) AS [Code_Type],
            TRY_CAST(lu.[segment] AS INT) AS [Segment_Score],
            NULLIF(LTRIM(RTRIM(lu.[segment_title])), '') AS [Segment_Title],
            NULLIF(LTRIM(RTRIM(lu.[description])), '') AS [Code_Description],
            NULLIF(LTRIM(RTRIM(lu.[sub_segment])), '') AS [Sub_Segment]
        FROM [Data_Lab_SWL_CF].[dbo].[code_lookup] lu
        WHERE lu.[code] IS NOT NULL
          AND lu.[code_type] IS NOT NULL
          AND TRY_CAST(lu.[segment] AS INT) IS NOT NULL
    ),
    Deduped AS (
        SELECT
            sd.*,
            ROW_NUMBER() OVER (
                PARTITION BY sd.[Code], sd.[Code_Type], sd.[Segment_Score]
                ORDER BY
                    CASE WHEN sd.[Segment_Title] IS NOT NULL THEN 0 ELSE 1 END,
                    CASE WHEN sd.[Code_Description] IS NOT NULL THEN 0 ELSE 1 END,
                    CASE WHEN sd.[Sub_Segment] IS NOT NULL THEN 0 ELSE 1 END
            ) AS RowNum
        FROM SourceData sd
    )
    INSERT INTO [Analytics].[tbl_Ref_CF_Code_Lookup] (
        [Code],
        [Code_Type],
        [Segment_Score],
        [Segment_Title],
        [Code_Description],
        [Sub_Segment],
        [Is_Active]
    )
    SELECT
        d.[Code],
        d.[Code_Type],
        d.[Segment_Score],
        d.[Segment_Title],
        d.[Code_Description],
        d.[Sub_Segment],
        CAST(1 AS BIT) AS [Is_Active]
    FROM Deduped d
    WHERE d.RowNum = 1;

    PRINT '[OK] Loaded Analytics.tbl_Ref_CF_Code_Lookup rows: ' + CAST(@@ROWCOUNT AS VARCHAR(20));
END
GO

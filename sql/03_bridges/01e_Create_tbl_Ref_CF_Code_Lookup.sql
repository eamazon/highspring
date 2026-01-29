USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating CF code lookup reference table';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

/**
Script Name:  01e_Create_tbl_Ref_CF_Code_Lookup.sql
Description:  Create and populate Analytics CF code lookup reference table
              from Data_Lab_SWL_CF.dbo.code_lookup.
Author:       Sridhar Peddi
Created:      2026-01-26

Change Log:
  2026-01-26  Sridhar Peddi    Initial creation
**/
IF OBJECT_ID('[Analytics].[tbl_Ref_CF_Code_Lookup]', 'U') IS NULL
BEGIN
    CREATE TABLE [Analytics].[tbl_Ref_CF_Code_Lookup] (
        [Code] VARCHAR(50) NOT NULL,
        [Code_Type] VARCHAR(20) NOT NULL,
        [Segment_Score] INT NOT NULL,
        [Segment_Title] VARCHAR(200) NULL,
        [Code_Description] VARCHAR(255) NULL,
        [Sub_Segment] VARCHAR(100) NULL,
        [Is_Active] BIT NOT NULL CONSTRAINT [DF_CF_Code_Lookup_IsActive] DEFAULT (1),
        [ETL_LoadDateTime] DATETIME2 NOT NULL CONSTRAINT [DF_CF_Code_Lookup_LoadDtm] DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT [PK_Ref_CF_Code_Lookup] PRIMARY KEY CLUSTERED ([Code], [Code_Type], [Segment_Score])
    ) ON [PRIMARY];
END
GO

IF OBJECT_ID('[Data_Lab_SWL_CF].[dbo].[code_lookup]', 'U') IS NULL
BEGIN
    RAISERROR('Missing source table [Data_Lab_SWL_CF].[dbo].[code_lookup]. Load legacy CF rules before running this script.', 16, 1);
    RETURN;
END
GO

IF EXISTS (SELECT 1 FROM [Analytics].[tbl_Ref_CF_Code_Lookup])
BEGIN
    PRINT '[INFO] [Analytics].[tbl_Ref_CF_Code_Lookup] already populated. Skipping reload.';
END
ELSE
BEGIN
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
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_Ref_CF_Code_Lookup_TypeCode'
      AND object_id = OBJECT_ID('[Analytics].[tbl_Ref_CF_Code_Lookup]')
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Ref_CF_Code_Lookup_TypeCode]
        ON [Analytics].[tbl_Ref_CF_Code_Lookup] ([Code_Type], [Code])
        INCLUDE ([Segment_Score], [Sub_Segment], [Is_Active]);
END
GO

PRINT '[OK] Created and loaded: [Analytics].[tbl_Ref_CF_Code_Lookup]';
GO

PRINT '';
PRINT '========================================';
PRINT 'CF code lookup reference table ready';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO

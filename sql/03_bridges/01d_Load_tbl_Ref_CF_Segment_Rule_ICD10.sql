USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Loading CF segmentation ICD10 rules';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

IF OBJECT_ID('[Analytics].[tbl_Ref_CF_Segment_Rule_ICD10]', 'U') IS NULL
BEGIN
    RAISERROR('Missing target table [Analytics].[tbl_Ref_CF_Segment_Rule_ICD10]. Run 01c_Create_tbl_Ref_CF_Segment_Rules.sql first.', 16, 1);
    RETURN;
END
GO

IF OBJECT_ID('[Analytics].[tbl_Ref_CF_Code_Lookup]', 'U') IS NULL
BEGIN
    RAISERROR('Missing source table [Analytics].[tbl_Ref_CF_Code_Lookup]. Run 01e_Create_tbl_Ref_CF_Code_Lookup.sql first.', 16, 1);
    RETURN;
END
GO

/**
Script Name:  01d_Load_tbl_Ref_CF_Segment_Rule_ICD10.sql
Description:  Load CF segmentation ICD10 rules from legacy CF code lookup.
              Rules are stored as LIKE patterns and used by CF bridge loaders.
Author:       Sridhar Peddi
Created:      2026-01-26

Change Log:
  2026-01-26  Sridhar Peddi    Initial creation
**/
BEGIN TRY
    DELETE FROM [Analytics].[tbl_Ref_CF_Segment_Rule_ICD10];

    INSERT INTO [Analytics].[tbl_Ref_CF_Segment_Rule_ICD10] (
        [Segment_Score],
        [ICD10_Like],
        [Is_Primary_Only],
        [Lookback_Months],
        [Rule_Notes],
        [Is_Active]
    )
    SELECT DISTINCT
        TRY_CAST(lu.[Segment_Score] AS INT) AS [Segment_Score],
        UPPER(REPLACE(REPLACE(LTRIM(RTRIM(lu.[Code])), '.', ''), ' ', '')) AS [ICD10_Like],
        CAST(0 AS BIT) AS [Is_Primary_Only],
        NULL AS [Lookback_Months],
        'Legacy CF code_lookup (ICD10)' AS [Rule_Notes],
        CAST(1 AS BIT) AS [Is_Active]
    FROM [Analytics].[tbl_Ref_CF_Code_Lookup] lu
    WHERE lu.[Code_Type] = 'ICD10'
      AND lu.[Code] IS NOT NULL
      AND TRY_CAST(lu.[Segment_Score] AS INT) BETWEEN 0 AND 8;

    IF NOT EXISTS (
        SELECT 1
        FROM [Analytics].[tbl_Ref_CF_Segment_Rule_ICD10]
        WHERE [Segment_Score] = 5
          AND [ICD10_Like] = 'C%'
    )
    BEGIN
        INSERT INTO [Analytics].[tbl_Ref_CF_Segment_Rule_ICD10] (
            [Segment_Score],
            [ICD10_Like],
            [Is_Primary_Only],
            [Lookback_Months],
            [Rule_Notes],
            [Is_Active]
        )
        VALUES (
            5,
            'C%',
            0,
            12,
            'Cancer ICD10 prefix rule (legacy CF logic)',
            1
        );
    END

    PRINT '[OK] CF ICD10 rules loaded: ' + CAST(@@ROWCOUNT AS VARCHAR(20));
END TRY
BEGIN CATCH
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    PRINT 'Error loading CF ICD10 rules: ' + @ErrorMessage;
    RAISERROR(@ErrorMessage, 16, 1);
END CATCH
GO

PRINT '';
PRINT '========================================';
PRINT 'CF ICD10 rules load completed';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO

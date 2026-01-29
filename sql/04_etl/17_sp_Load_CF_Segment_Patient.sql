/**
-- Script Name: 17_sp_Load_CF_Segment_Patient.sql
-- Description: Derive CF segmentation at patient level from ICD10 codes in Unified SUS (IP/OP).
--              DEPRECATED: Use sp_Load_Bridge_CF_Segment_Patient_Snapshot instead.
--              Stores results in tbl_Bridge_CF_Segment_Patient.
--              Large, temporal patient-level bridge (Power BI Premium use cases).
-- Author:      Sridhar Peddi
-- Created:     2026-01-09
-- Notes:       ICD10-only (IP/OP). Does NOT use HI.vw_CF_Segmentation.
-- Change Log:
-- 2026-01-09  Sridhar Peddi    Initial creation
-- 2026-01-26  Sridhar Peddi    Use Unified materialised tables (IP/OP) only
-- 2026-01-26  Sridhar Peddi    Rename to CF_Segment_Patient (clear intent)
-- 2026-01-26  Sridhar Peddi    Deprecated in favor of patient snapshot loader
**/

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('[Analytics].[sp_Load_CF_Segment_Patient]', 'P') IS NOT NULL
    DROP PROCEDURE [Analytics].[sp_Load_CF_Segment_Patient];
GO

CREATE PROCEDURE [Analytics].[sp_Load_CF_Segment_Patient]
    @AsAtDate DATE,
    @DefaultLookbackMonths INT = 24
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ValidFrom DATE = DATEFROMPARTS(YEAR(@AsAtDate), MONTH(@AsAtDate), 1);
    DECLARE @SnapshotEnd DATE = EOMONTH(@AsAtDate);
    DECLARE @LookbackStart DATE = DATEADD(MONTH, -@DefaultLookbackMonths, DATEADD(DAY, 1, @SnapshotEnd));
    DECLARE @RowsInserted INT = 0;
    DECLARE @BatchName VARCHAR(100) = 'Bridge_CF_Segment_Patient';
    DECLARE @BatchID INT = NULL;

    IF @DefaultLookbackMonths IS NULL OR @DefaultLookbackMonths <= 0
    BEGIN
        RAISERROR('DefaultLookbackMonths must be > 0', 16, 1);
        RETURN;
    END

    PRINT 'Loading CF Segments (Patient Grain)';
    PRINT '  AsAtDate: ' + CONVERT(VARCHAR(10), @AsAtDate, 120);
    PRINT '  ValidFrom: ' + CONVERT(VARCHAR(10), @ValidFrom, 120);
    PRINT '  LookbackStart: ' + CONVERT(VARCHAR(10), @LookbackStart, 120);
    PRINT '  SnapshotEnd: ' + CONVERT(VARCHAR(10), @SnapshotEnd, 120);

    BEGIN TRY
        EXEC [Analytics].[sp_Start_ETL_Batch]
            @BatchName = @BatchName,
            @BatchID = @BatchID OUTPUT;

    -- Close out current rows prior to this month
    UPDATE d
        SET d.Is_Current = 0,
            d.Valid_To = DATEADD(DAY, -1, @ValidFrom)
    FROM [Analytics].[tbl_Bridge_CF_Segment_Patient] d
    WHERE d.Segment_Type = 'CF_Segment'
      AND d.Is_Current = 1
      AND d.Valid_From < @ValidFrom;

    -- Reload this month
    DELETE FROM [Analytics].[tbl_Bridge_CF_Segment_Patient]
    WHERE Segment_Type = 'CF_Segment'
      AND Valid_From = @ValidFrom;

    ;WITH Rules AS (
        SELECT
            r.Rule_ID,
            r.Segment_Score,
            r.ICD10_Like,
            r.Is_Primary_Only,
            COALESCE(r.Lookback_Months, @DefaultLookbackMonths) AS Lookback_Months
        FROM [Analytics].[tbl_Ref_CF_Segment_Rule_ICD10] r
        WHERE r.Is_Active = 1
    ),
    -- Pull ICD10 diagnoses from Unified IP/OP materialised tables (patient-level segmentation).
    IPDiag AS (
        SELECT
            v.SK_PatientID,
            v.Start_Date_Hospital_Provider_Spell AS Activity_Date,
            UPPER(REPLACE(REPLACE(x.Diagnosis_Code, '.', ''), ' ', '')) AS Diagnosis_Code,
            x.Is_Primary
        FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active] v
        CROSS APPLY (VALUES
            (v.Primary_Diagnosis_Code, CAST(1 AS BIT)),
            (v.Secondary_Diagnosis_Code_1, CAST(0 AS BIT)),
            (v.Secondary_Diagnosis_Code_2, CAST(0 AS BIT)),
            (v.Secondary_Diagnosis_Code_3, CAST(0 AS BIT)),
            (v.Secondary_Diagnosis_Code_4, CAST(0 AS BIT)),
            (v.Secondary_Diagnosis_Code_5, CAST(0 AS BIT)),
            (v.Secondary_Diagnosis_Code_6, CAST(0 AS BIT)),
            (v.Secondary_Diagnosis_Code_7, CAST(0 AS BIT)),
            (v.Secondary_Diagnosis_Code_8, CAST(0 AS BIT)),
            (v.Secondary_Diagnosis_Code_9, CAST(0 AS BIT)),
            (v.Secondary_Diagnosis_Code_10, CAST(0 AS BIT)),
            (v.Secondary_Diagnosis_Code_11, CAST(0 AS BIT)),
            (v.Secondary_Diagnosis_Code_12, CAST(0 AS BIT))
        ) x(Diagnosis_Code, Is_Primary)
        WHERE v.Start_Date_Hospital_Provider_Spell >= @LookbackStart
          AND v.Start_Date_Hospital_Provider_Spell <= @SnapshotEnd
          AND x.Diagnosis_Code IS NOT NULL
          AND LTRIM(RTRIM(x.Diagnosis_Code)) <> ''
    ),
    OPDiag AS (
        SELECT
            v.SK_PatientID,
            v.Appointment_Date AS Activity_Date,
            UPPER(REPLACE(REPLACE(x.Diagnosis_Code, '.', ''), ' ', '')) AS Diagnosis_Code,
            x.Is_Primary
        FROM [Data_Lab_SWL].[Unified].[tbl_OP_EncounterDenormalised_Active] v
        CROSS APPLY (VALUES
            (v.Primary_Diagnosis_Code, CAST(1 AS BIT)),
            (v.Secondary_Diagnosis_Code_1, CAST(0 AS BIT)),
            (v.Secondary_Diagnosis_Code_2, CAST(0 AS BIT)),
            (v.Secondary_Diagnosis_Code_3, CAST(0 AS BIT)),
            (v.Secondary_Diagnosis_Code_4, CAST(0 AS BIT)),
            (v.Secondary_Diagnosis_Code_5, CAST(0 AS BIT)),
            (v.Secondary_Diagnosis_Code_6, CAST(0 AS BIT)),
            (v.Secondary_Diagnosis_Code_7, CAST(0 AS BIT)),
            (v.Secondary_Diagnosis_Code_8, CAST(0 AS BIT)),
            (v.Secondary_Diagnosis_Code_9, CAST(0 AS BIT)),
            (v.Secondary_Diagnosis_Code_10, CAST(0 AS BIT)),
            (v.Secondary_Diagnosis_Code_11, CAST(0 AS BIT)),
            (v.Secondary_Diagnosis_Code_12, CAST(0 AS BIT))
        ) x(Diagnosis_Code, Is_Primary)
        WHERE v.Appointment_Date >= @LookbackStart
          AND v.Appointment_Date <= @SnapshotEnd
          AND x.Diagnosis_Code IS NOT NULL
          AND LTRIM(RTRIM(x.Diagnosis_Code)) <> ''
    ),
    AllDiag AS (
        SELECT * FROM IPDiag
        UNION ALL
        SELECT * FROM OPDiag
    ),
    MatchedRules AS (
        SELECT
            d.SK_PatientID,
            r.Segment_Score
        FROM AllDiag d
        INNER JOIN Rules r
            ON d.Diagnosis_Code LIKE r.ICD10_Like
           AND (r.Is_Primary_Only = 0 OR d.Is_Primary = 1)
        WHERE d.Activity_Date >= DATEADD(MONTH, -r.Lookback_Months, DATEADD(DAY, 1, @SnapshotEnd))
          AND d.Activity_Date <= @SnapshotEnd
    ),
    PatientScore AS (
        SELECT
            m.SK_PatientID,
            MAX(m.Segment_Score) AS Segment_Score
        FROM MatchedRules m
        GROUP BY m.SK_PatientID
    ),
    PatientAll AS (
        SELECT DISTINCT v.SK_PatientID
        FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active] v
        UNION
        SELECT DISTINCT v.SK_PatientID
        FROM [Data_Lab_SWL].[Unified].[tbl_OP_EncounterDenormalised_Active] v
    )
    INSERT INTO [Analytics].[tbl_Bridge_CF_Segment_Patient] (
        [SK_PatientID],
        [Segment_Type],
        [Segment_Value],
        [Segment_Score],
        [Valid_From],
        [Valid_To],
        [Is_Current],
        [Source_System]
    )
    SELECT
        p.SK_PatientID,
        'CF_Segment' AS Segment_Type,
        COALESCE(s.Segment_Value, 'CF_Score_0') AS Segment_Value,
        COALESCE(ps.Segment_Score, 0) AS Segment_Score,
        @ValidFrom AS Valid_From,
        NULL AS Valid_To,
        CAST(1 AS BIT) AS Is_Current,
        'Derived_CF_Unified_IP_OP' AS Source_System
    FROM PatientAll p
    LEFT JOIN PatientScore ps
        ON ps.SK_PatientID = p.SK_PatientID
    LEFT JOIN [Analytics].[tbl_Ref_CF_Segment] s
        ON s.Segment_Score = COALESCE(ps.Segment_Score, 0);

    SET @RowsInserted = @@ROWCOUNT;

        EXEC [Analytics].[sp_Log_Table_Load]
            @BatchID = @BatchID,
            @TableName = 'Analytics.tbl_Bridge_CF_Segment_Patient',
            @LoadType = 'Full',
            @RowsAffected = @RowsInserted,
            @Status = 'Success';

        EXEC [Analytics].[sp_End_ETL_Batch]
            @BatchID = @BatchID,
            @Status = 'Success',
            @RowsInserted = @RowsInserted,
            @RowsUpdated = 0,
            @RowsDeleted = 0,
            @RowsFailed = 0,
            @ErrorMessage = NULL;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        PRINT 'Error Loading CF Segment Patient: ' + @ErrorMessage;
        IF @BatchID IS NOT NULL
        BEGIN
            EXEC [Analytics].[sp_Log_Table_Load]
                @BatchID = @BatchID,
                @TableName = 'Analytics.tbl_Bridge_CF_Segment_Patient',
                @LoadType = 'Full',
                @RowsAffected = 0,
                @RowsFailed = 1,
                @Status = 'Failed',
                @ErrorMessage = @ErrorMessage;

            EXEC [Analytics].[sp_End_ETL_Batch]
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

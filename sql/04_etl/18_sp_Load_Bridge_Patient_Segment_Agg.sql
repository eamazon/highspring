/**
-- Script Name: 18_sp_Load_Bridge_Patient_Segment_Agg.sql
-- Description: Build monthly aggregated CF segment counts for trending.
--              DEPRECATED: Use sp_Load_Bridge_CF_Segment_Patient_Snapshot instead.
--              Grain: Snapshot_Month + Segment_Type + Segment_Value.
-- Author:      Sridhar Peddi
-- Created:     2026-01-09
-- Notes:       ICD10-only (IP/OP). Does NOT use HI.vw_CF_Segmentation.
--              Populates only Segment_Type='CF_Segment' for now.
-- Change Log:
-- 2026-01-09  Sridhar Peddi    Initial creation
-- 2026-01-26  Sridhar Peddi    Use Unified materialised tables (IP/OP) only
-- 2026-01-26  Sridhar Peddi    Support month ranges in one execution
-- 2026-01-26  Sridhar Peddi    Deprecated in favor of patient snapshot loader
**/

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('[Analytics].[sp_Load_Bridge_Patient_Segment_Agg]', 'P') IS NOT NULL
    DROP PROCEDURE [Analytics].[sp_Load_Bridge_Patient_Segment_Agg];
GO

CREATE PROCEDURE [Analytics].[sp_Load_Bridge_Patient_Segment_Agg]
    @SnapshotMonth INT = NULL,     -- YYYYMM (single month)
    @FromMonth INT = NULL,         -- YYYYMM (range start)
    @ToMonth INT = NULL,           -- YYYYMM (range end)
    @DefaultLookbackMonths INT = 24
AS
BEGIN
    SET NOCOUNT ON;

    IF (@SnapshotMonth IS NULL AND (@FromMonth IS NULL OR @ToMonth IS NULL))
        OR (@SnapshotMonth IS NOT NULL AND (@FromMonth IS NOT NULL OR @ToMonth IS NOT NULL))
    BEGIN
        RAISERROR('Provide either @SnapshotMonth or @FromMonth/@ToMonth.', 16, 1);
        RETURN;
    END

    IF @DefaultLookbackMonths IS NULL OR @DefaultLookbackMonths <= 0
    BEGIN
        RAISERROR('DefaultLookbackMonths must be > 0', 16, 1);
        RETURN;
    END

    DECLARE @RowsInserted INT = 0;
    DECLARE @BatchName VARCHAR(100) = 'Bridge_Patient_Segment_Agg';
    DECLARE @BatchID INT = NULL;
    DECLARE @RunMonth INT;
    DECLARE @SnapshotYear INT;
    DECLARE @SnapshotMon INT;
    DECLARE @AsAtDate DATE;
    DECLARE @SnapshotEnd DATE;
    DECLARE @LookbackStart DATE;

    CREATE TABLE #SnapshotMonths (
        SnapshotMonth INT NOT NULL PRIMARY KEY
    );

    IF @SnapshotMonth IS NOT NULL
    BEGIN
        INSERT INTO #SnapshotMonths (SnapshotMonth)
        VALUES (@SnapshotMonth);
    END
    ELSE
    BEGIN
        IF @FromMonth > @ToMonth
        BEGIN
            RAISERROR('FromMonth must be <= ToMonth.', 16, 1);
            RETURN;
        END

        SET @RunMonth = @FromMonth;
        WHILE @RunMonth <= @ToMonth
        BEGIN
            INSERT INTO #SnapshotMonths (SnapshotMonth)
            VALUES (@RunMonth);

            SET @RunMonth = CASE
                WHEN RIGHT(@RunMonth, 2) = 12 THEN ((@RunMonth / 100) + 1) * 100 + 1
                ELSE @RunMonth + 1
            END;
        END
    END

    PRINT 'Loading Patient Segment Agg (CF_Segment)';
    PRINT '  DefaultLookbackMonths: ' + CONVERT(VARCHAR(10), @DefaultLookbackMonths);

    BEGIN TRY
        EXEC [Analytics].[sp_Start_ETL_Batch]
            @BatchName = @BatchName,
            @BatchID = @BatchID OUTPUT;

        DECLARE SnapshotCursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT SnapshotMonth FROM #SnapshotMonths ORDER BY SnapshotMonth;

        OPEN SnapshotCursor;
        FETCH NEXT FROM SnapshotCursor INTO @RunMonth;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @SnapshotYear = @RunMonth / 100;
            SET @SnapshotMon = @RunMonth % 100;

            IF @SnapshotYear < 2000 OR @SnapshotMon NOT BETWEEN 1 AND 12
            BEGIN
                RAISERROR('SnapshotMonth must be in YYYYMM format', 16, 1);
                CLOSE SnapshotCursor;
                DEALLOCATE SnapshotCursor;
                RETURN;
            END

            SET @AsAtDate = DATEFROMPARTS(@SnapshotYear, @SnapshotMon, 1);
            SET @SnapshotEnd = EOMONTH(@AsAtDate);
            SET @LookbackStart = DATEADD(MONTH, -@DefaultLookbackMonths, DATEADD(DAY, 1, @SnapshotEnd));

            DELETE FROM [Analytics].[tbl_Bridge_Patient_Segment_Agg]
            WHERE Snapshot_Month = @RunMonth
              AND Segment_Type = 'CF_Segment';

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
    ),
    PatientWithSegment AS (
        SELECT
            p.SK_PatientID,
            COALESCE(ps.Segment_Score, 0) AS Segment_Score
        FROM PatientAll p
        LEFT JOIN PatientScore ps
            ON ps.SK_PatientID = p.SK_PatientID
    )
    INSERT INTO [Analytics].[tbl_Bridge_Patient_Segment_Agg] (
        [Snapshot_Month],
        [Segment_Type],
        [Segment_Value],
        [Patient_Count],
        [Avg_Age_Years],
        [Pct_Core20],
        [Total_Cost_12M]
    )
    SELECT
        @RunMonth AS Snapshot_Month,
        'CF_Segment' AS Segment_Type,
        COALESCE(s.Segment_Value, 'CF_Score_0') AS Segment_Value,
        COUNT_BIG(1) AS Patient_Count,
        NULL AS Avg_Age_Years,
        NULL AS Pct_Core20,
        NULL AS Total_Cost_12M
    FROM PatientWithSegment pws
    LEFT JOIN [Analytics].[tbl_Ref_CF_Segment] s
        ON s.Segment_Score = pws.Segment_Score
    GROUP BY COALESCE(s.Segment_Value, 'CF_Score_0');

    SET @RowsInserted = @RowsInserted + @@ROWCOUNT;

            FETCH NEXT FROM SnapshotCursor INTO @RunMonth;
        END

        CLOSE SnapshotCursor;
        DEALLOCATE SnapshotCursor;

        EXEC [Analytics].[sp_Log_Table_Load]
            @BatchID = @BatchID,
            @TableName = 'Analytics.tbl_Bridge_Patient_Segment_Agg',
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
        PRINT 'Error Loading Bridge Patient Segment Agg: ' + @ErrorMessage;
        IF @BatchID IS NOT NULL
        BEGIN
            EXEC [Analytics].[sp_Log_Table_Load]
                @BatchID = @BatchID,
                @TableName = 'Analytics.tbl_Bridge_Patient_Segment_Agg',
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

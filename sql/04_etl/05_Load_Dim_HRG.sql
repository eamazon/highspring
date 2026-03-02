USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('[Analytics].[sp_Load_Dim_HRG]', 'P') IS NOT NULL
    DROP PROCEDURE [Analytics].[sp_Load_Dim_HRG];
GO

/**
Script Name:   05_Load_Dim_HRG.sql
Description:   ETL stored procedure to load Analytics.tbl_HRG from Analytics.tbl_Staging_HRG.
               Single-row-per-HRG SCD:
               - Valid_From = first release date where code appears
               - Valid_To   = day before next release when code disappears
               - Is_Current = 1 when code exists in latest release
Author:        Sridhar Peddi
Created:       2026-02-27
**/
CREATE PROCEDURE [Analytics].[sp_Load_Dim_HRG]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ProcessName VARCHAR(100) = 'Load_Dim_HRG';
    DECLARE @BatchID INT = NULL;
    DECLARE @TableName VARCHAR(100) = 'Analytics.tbl_HRG';
    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsUpdated INT = 0;
    DECLARE @RowsAffected INT = 0;
    DECLARE @LatestReleaseDate DATE = NULL;
    DECLARE @ErrorMessage NVARCHAR(4000);

    BEGIN TRY
        EXEC [Analytics].[sp_Start_ETL_Batch]
            @BatchName = @ProcessName,
            @BatchID = @BatchID OUTPUT;

        IF OBJECT_ID('[Analytics].[tbl_Staging_HRG]', 'U') IS NULL
        BEGIN
            RAISERROR('Missing staging table: [Analytics].[tbl_Staging_HRG].', 16, 1);
        END

        IF NOT EXISTS (SELECT 1 FROM [Analytics].[tbl_Staging_HRG])
        BEGIN
            RAISERROR('No rows found in [Analytics].[tbl_Staging_HRG].', 16, 1);
        END

        SELECT @LatestReleaseDate = MAX(Release_Date)
        FROM [Analytics].[tbl_Staging_HRG];

        DECLARE @MergeActions TABLE (Action NVARCHAR(10) NOT NULL);

        ;WITH StageNorm AS (
            SELECT
                LTRIM(RTRIM(HRGCode)) AS HRGCode,
                NULLIF(LTRIM(RTRIM(HRGDescription)), '') AS HRGDescription,
                NULLIF(LTRIM(RTRIM(Core_Or_Unbundled)), '') AS Core_Or_Unbundled,
                NULLIF(LTRIM(RTRIM(HRGSubchapterKey)), '') AS HRGSubchapterKey,
                NULLIF(LTRIM(RTRIM(HRGSubchapter)), '') AS HRGSubchapter,
                NULLIF(LTRIM(RTRIM(HRGChapterKey)), '') AS HRGChapterKey,
                NULLIF(LTRIM(RTRIM(HRGChapter)), '') AS HRGChapter,
                Release_Date,
                NULLIF(LTRIM(RTRIM(Source_URL)), '') AS Source_URL,
                Load_Timestamp
            FROM [Analytics].[tbl_Staging_HRG]
            WHERE NULLIF(LTRIM(RTRIM(HRGCode)), '') IS NOT NULL
        ),
        DistinctReleases AS (
            SELECT DISTINCT Release_Date
            FROM StageNorm
        ),
        CodeAgg AS (
            SELECT
                s.HRGCode,
                MIN(s.Release_Date) AS Valid_From,
                MAX(s.Release_Date) AS Last_Seen_Release_Date
            FROM StageNorm s
            GROUP BY s.HRGCode
        ),
        LatestCodeAttrs AS (
            SELECT
                s.HRGCode,
                s.HRGDescription,
                s.Core_Or_Unbundled,
                s.HRGSubchapterKey,
                s.HRGSubchapter,
                s.HRGChapterKey,
                s.HRGChapter,
                s.Source_URL,
                ROW_NUMBER() OVER (
                    PARTITION BY s.HRGCode
                    ORDER BY s.Release_Date DESC, s.Load_Timestamp DESC
                ) AS RN
            FROM StageNorm s
        ),
        NextRelease AS (
            SELECT
                a.HRGCode,
                MIN(r.Release_Date) AS NextReleaseDate
            FROM CodeAgg a
            LEFT JOIN DistinctReleases r
                ON r.Release_Date > a.Last_Seen_Release_Date
            GROUP BY a.HRGCode
        ),
        SourceSCD AS (
            SELECT
                a.HRGCode,
                l.HRGDescription,
                l.Core_Or_Unbundled,
                l.HRGSubchapterKey,
                l.HRGSubchapter,
                l.HRGChapterKey,
                l.HRGChapter,
                a.Last_Seen_Release_Date,
                l.Source_URL,
                a.Valid_From,
                CASE
                    WHEN a.Last_Seen_Release_Date = @LatestReleaseDate THEN NULL
                    WHEN n.NextReleaseDate IS NOT NULL THEN DATEADD(DAY, -1, n.NextReleaseDate)
                    ELSE NULL
                END AS Valid_To,
                CASE
                    WHEN a.Last_Seen_Release_Date = @LatestReleaseDate THEN 1
                    ELSE 0
                END AS Is_Current
            FROM CodeAgg a
            INNER JOIN LatestCodeAttrs l
                ON a.HRGCode = l.HRGCode
               AND l.RN = 1
            LEFT JOIN NextRelease n
                ON a.HRGCode = n.HRGCode
        )
        MERGE [Analytics].[tbl_HRG] AS Target
        USING SourceSCD AS Source
        ON Target.HRGCode = Source.HRGCode
        WHEN MATCHED AND (
            ISNULL(Target.HRGDescription, '') <> ISNULL(Source.HRGDescription, '') OR
            ISNULL(Target.Core_Or_Unbundled, '') <> ISNULL(Source.Core_Or_Unbundled, '') OR
            ISNULL(Target.HRGSubchapterKey, '') <> ISNULL(Source.HRGSubchapterKey, '') OR
            ISNULL(Target.HRGSubchapter, '') <> ISNULL(Source.HRGSubchapter, '') OR
            ISNULL(Target.HRGChapterKey, '') <> ISNULL(Source.HRGChapterKey, '') OR
            ISNULL(Target.HRGChapter, '') <> ISNULL(Source.HRGChapter, '') OR
            ISNULL(Target.Last_Seen_Release_Date, '1900-01-01') <> ISNULL(Source.Last_Seen_Release_Date, '1900-01-01') OR
            ISNULL(Target.Source_URL, '') <> ISNULL(Source.Source_URL, '') OR
            ISNULL(Target.Valid_From, '1900-01-01') <> ISNULL(Source.Valid_From, '1900-01-01') OR
            ISNULL(Target.Valid_To, '9999-12-31') <> ISNULL(Source.Valid_To, '9999-12-31') OR
            ISNULL(Target.Is_Current, 0) <> ISNULL(Source.Is_Current, 0)
        ) THEN
            UPDATE SET
                Target.HRGDescription = Source.HRGDescription,
                Target.Core_Or_Unbundled = Source.Core_Or_Unbundled,
                Target.HRGSubchapterKey = Source.HRGSubchapterKey,
                Target.HRGSubchapter = Source.HRGSubchapter,
                Target.HRGChapterKey = Source.HRGChapterKey,
                Target.HRGChapter = Source.HRGChapter,
                Target.Last_Seen_Release_Date = Source.Last_Seen_Release_Date,
                Target.Source_URL = Source.Source_URL,
                Target.Valid_From = Source.Valid_From,
                Target.Valid_To = Source.Valid_To,
                Target.Is_Current = Source.Is_Current,
                Target.Updated_Date = GETDATE(),
                Target.Updated_By = SUSER_SNAME()
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                HRGCode,
                HRGDescription,
                Core_Or_Unbundled,
                HRGSubchapterKey,
                HRGSubchapter,
                HRGChapterKey,
                HRGChapter,
                Last_Seen_Release_Date,
                Source_URL,
                Valid_From,
                Valid_To,
                Is_Current,
                Created_By
            )
            VALUES (
                Source.HRGCode,
                Source.HRGDescription,
                Source.Core_Or_Unbundled,
                Source.HRGSubchapterKey,
                Source.HRGSubchapter,
                Source.HRGChapterKey,
                Source.HRGChapter,
                Source.Last_Seen_Release_Date,
                Source.Source_URL,
                Source.Valid_From,
                Source.Valid_To,
                Source.Is_Current,
                SUSER_SNAME()
            )
        OUTPUT $action INTO @MergeActions;

        SELECT @RowsInserted = COUNT(*) FROM @MergeActions WHERE Action = 'INSERT';
        SELECT @RowsUpdated = COUNT(*) FROM @MergeActions WHERE Action = 'UPDATE';
        SET @RowsAffected = @RowsInserted + @RowsUpdated;

        EXEC [Analytics].[sp_Log_Table_Load]
            @BatchID = @BatchID,
            @TableName = @TableName,
            @LoadType = 'SCD Type 2 (single row per HRG code)',
            @RowsAffected = @RowsAffected,
            @Status = 'Success';

        EXEC [Analytics].[sp_End_ETL_Batch]
            @BatchID = @BatchID,
            @Status = 'Success',
            @RowsInserted = @RowsInserted,
            @RowsUpdated = @RowsUpdated,
            @RowsDeleted = 0,
            @RowsFailed = 0,
            @ErrorMessage = NULL;
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();

        IF @BatchID IS NOT NULL
        BEGIN
            EXEC [Analytics].[sp_Log_Table_Load]
                @BatchID = @BatchID,
                @TableName = @TableName,
                @LoadType = 'SCD Type 2 (single row per HRG code)',
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

PRINT '[OK] Created Procedure: [Analytics].[sp_Load_Dim_HRG]';
GO

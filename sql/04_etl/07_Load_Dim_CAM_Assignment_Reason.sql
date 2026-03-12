USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('[Analytics].[sp_Load_Dim_CAM_Assignment_Reason]', 'P') IS NOT NULL
    DROP PROCEDURE [Analytics].[sp_Load_Dim_CAM_Assignment_Reason];
GO

/**
Script Name:   07_Load_Dim_CAM_Assignment_Reason.sql
Description:   Loads CAM assignment reason dimension from CAM output and reference mappings.
Author:        Sridhar Peddi
Created:       2026-01-12 21:55

Change Log:
  2026-01-12  Sridhar Peddi    Initial creation
  2026-03-12  Sridhar Peddi    Preserve surrogate keys via upsert (update + insert new codes)
**/
CREATE PROCEDURE [Analytics].[sp_Load_Dim_CAM_Assignment_Reason]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @BatchName VARCHAR(100) = 'Load_Dim_CAM_Assignment_Reason';
    DECLARE @BatchID INT = NULL;
    DECLARE @TableName VARCHAR(100) = 'Analytics.tbl_Dim_CAM_Assignment_Reason';
    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsUpdated INT = 0;
    DECLARE @RowsDeleted INT = 0;
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ReasonSource SYSNAME = NULL;

    BEGIN TRY
        EXEC [Analytics].[sp_Start_ETL_Batch]
            @BatchName = @BatchName,
            @BatchID = @BatchID OUTPUT;

        PRINT 'Starting Load: [Analytics].[tbl_Dim_CAM_Assignment_Reason]';

        IF NOT EXISTS (
            SELECT 1
            FROM [Data_Lab_SWL].sys.tables t
            INNER JOIN [Data_Lab_SWL].sys.schemas s ON s.schema_id = t.schema_id
            WHERE s.name = 'CAM'
              AND t.name = 'tbl_CAM_Raw'
        )
        BEGIN
            RAISERROR('Source table [Data_Lab_SWL].[CAM].[tbl_CAM_Raw] not found.', 16, 1);
            RETURN;
        END

        IF EXISTS (
            SELECT 1
            FROM [Data_Lab_SWL_Live].sys.tables t
            INNER JOIN [Data_Lab_SWL_Live].sys.schemas s ON s.schema_id = t.schema_id
            WHERE s.name = 'Ref'
              AND t.name = 'tbl_CommissionerAssignmentReason'
        )
            SET @ReasonSource = 'Data_Lab_SWL_Live.Ref.tbl_CommissionerAssignmentReason';
        ELSE IF EXISTS (
            SELECT 1
            FROM [Data_Lab_SWL].sys.tables t
            INNER JOIN [Data_Lab_SWL].sys.schemas s ON s.schema_id = t.schema_id
            WHERE s.name = 'CAM_Ref'
              AND t.name = 'CommissionerAssignmentReason'
        )
            SET @ReasonSource = 'Data_Lab_SWL.CAM_Ref.CommissionerAssignmentReason';

        IF OBJECT_ID('tempdb..#PreparedAssignmentReason') IS NOT NULL
            DROP TABLE #PreparedAssignmentReason;

        CREATE TABLE #PreparedAssignmentReason
        (
            CAM_Assignment_Code VARCHAR(50) NOT NULL PRIMARY KEY,
            CAM_Assignment_Reason VARCHAR(255) NULL,
            Source_System VARCHAR(100) NOT NULL
        );

        IF @ReasonSource = 'Data_Lab_SWL_Live.Ref.tbl_CommissionerAssignmentReason'
        BEGIN
            ;WITH SourceRaw AS (
                SELECT DISTINCT
                    CAM_Assignment_Code = NULLIF(LTRIM(RTRIM(CAST([ReassignmentID] AS VARCHAR(50)))), ''),
                    CAM_Assignment_Reason = NULLIF(LTRIM(RTRIM(CAST([CAM_Assignment_Reason] AS VARCHAR(255)))), '')
                FROM [Data_Lab_SWL].[CAM].[tbl_CAM_Raw]
                WHERE [ReassignmentID] IS NOT NULL
            ),
            SourceRef AS (
                SELECT DISTINCT
                    CAM_Assignment_Code = NULLIF(LTRIM(RTRIM(CAST([CAM_Code] AS VARCHAR(50)))), ''),
                    CAM_Assignment_Reason = NULLIF(LTRIM(RTRIM(CAST([Commissioner Assignment Reason] AS VARCHAR(255)))), '')
                FROM [Data_Lab_SWL_Live].[Ref].[tbl_CommissionerAssignmentReason]
            ),
            SourceMerged AS (
                SELECT
                    CAM_Assignment_Code = COALESCE(r.CAM_Assignment_Code, f.CAM_Assignment_Code),
                    CAM_Assignment_Reason =
                        COALESCE(
                            r.CAM_Assignment_Reason,
                            f.CAM_Assignment_Reason,
                            CASE
                                WHEN COALESCE(r.CAM_Assignment_Code, f.CAM_Assignment_Code) = 'EXCL_VPP'
                                    THEN 'Excluded by local rule: commissioner VPP'
                                ELSE 'UNMAPPED_REASSIGNMENT'
                            END
                        ),
                    Source_System = CASE
                        WHEN r.CAM_Assignment_Code IS NOT NULL AND r.CAM_Assignment_Reason IS NOT NULL THEN 'CAM.tbl_CAM_Raw'
                        WHEN f.CAM_Assignment_Code IS NOT NULL THEN @ReasonSource
                        ELSE 'Derived'
                    END
                FROM SourceRaw r
                FULL OUTER JOIN SourceRef f
                    ON UPPER(LTRIM(RTRIM(r.CAM_Assignment_Code))) = UPPER(LTRIM(RTRIM(f.CAM_Assignment_Code)))
            ),
            DerivedSeeds AS (
                SELECT 'EXCL_VPP' AS CAM_Assignment_Code, 'Excluded by local rule: commissioner VPP' AS CAM_Assignment_Reason, 'Derived' AS Source_System
                UNION ALL
                SELECT 'UNMAPPED_REASSIGNMENT', 'Unmapped reassignment code (no reference reason found)', 'Derived'
            ),
            SourceFinal AS (
                SELECT CAM_Assignment_Code, CAM_Assignment_Reason, Source_System FROM SourceMerged
                UNION ALL
                SELECT CAM_Assignment_Code, CAM_Assignment_Reason, Source_System FROM DerivedSeeds
            ),
            Ranked AS (
                SELECT
                    s.CAM_Assignment_Code,
                    s.CAM_Assignment_Reason,
                    s.Source_System,
                    ROW_NUMBER() OVER (
                        PARTITION BY UPPER(LTRIM(RTRIM(s.CAM_Assignment_Code)))
                        ORDER BY
                            CASE s.Source_System
                                WHEN 'CAM.tbl_CAM_Raw' THEN 1
                                WHEN @ReasonSource THEN 2
                                ELSE 3
                            END,
                            LEN(ISNULL(s.CAM_Assignment_Reason, '')) DESC
                    ) AS rn
                FROM SourceFinal s
                WHERE s.CAM_Assignment_Code IS NOT NULL
            )
            INSERT INTO #PreparedAssignmentReason
            (
                CAM_Assignment_Code,
                CAM_Assignment_Reason,
                Source_System
            )
            SELECT
                r.CAM_Assignment_Code,
                r.CAM_Assignment_Reason,
                r.Source_System
            FROM Ranked r
            WHERE r.rn = 1;
        END
        ELSE IF @ReasonSource = 'Data_Lab_SWL.CAM_Ref.CommissionerAssignmentReason'
        BEGIN
            ;WITH SourceRaw AS (
                SELECT DISTINCT
                    CAM_Assignment_Code = NULLIF(LTRIM(RTRIM(CAST([ReassignmentID] AS VARCHAR(50)))), ''),
                    CAM_Assignment_Reason = NULLIF(LTRIM(RTRIM(CAST([CAM_Assignment_Reason] AS VARCHAR(255)))), '')
                FROM [Data_Lab_SWL].[CAM].[tbl_CAM_Raw]
                WHERE [ReassignmentID] IS NOT NULL
            ),
            SourceRef AS (
                SELECT DISTINCT
                    CAM_Assignment_Code = NULLIF(LTRIM(RTRIM(CAST([CAM_Code] AS VARCHAR(50)))), ''),
                    CAM_Assignment_Reason = NULLIF(LTRIM(RTRIM(CAST([Commissioner Assignment Reason] AS VARCHAR(255)))), '')
                FROM [Data_Lab_SWL].[CAM_Ref].[CommissionerAssignmentReason]
            ),
            SourceMerged AS (
                SELECT
                    CAM_Assignment_Code = COALESCE(r.CAM_Assignment_Code, f.CAM_Assignment_Code),
                    CAM_Assignment_Reason =
                        COALESCE(
                            r.CAM_Assignment_Reason,
                            f.CAM_Assignment_Reason,
                            CASE
                                WHEN COALESCE(r.CAM_Assignment_Code, f.CAM_Assignment_Code) = 'EXCL_VPP'
                                    THEN 'Excluded by local rule: commissioner VPP'
                                ELSE 'UNMAPPED_REASSIGNMENT'
                            END
                        ),
                    Source_System = CASE
                        WHEN r.CAM_Assignment_Code IS NOT NULL AND r.CAM_Assignment_Reason IS NOT NULL THEN 'CAM.tbl_CAM_Raw'
                        WHEN f.CAM_Assignment_Code IS NOT NULL THEN @ReasonSource
                        ELSE 'Derived'
                    END
                FROM SourceRaw r
                FULL OUTER JOIN SourceRef f
                    ON UPPER(LTRIM(RTRIM(r.CAM_Assignment_Code))) = UPPER(LTRIM(RTRIM(f.CAM_Assignment_Code)))
            ),
            DerivedSeeds AS (
                SELECT 'EXCL_VPP' AS CAM_Assignment_Code, 'Excluded by local rule: commissioner VPP' AS CAM_Assignment_Reason, 'Derived' AS Source_System
                UNION ALL
                SELECT 'UNMAPPED_REASSIGNMENT', 'Unmapped reassignment code (no reference reason found)', 'Derived'
            ),
            SourceFinal AS (
                SELECT CAM_Assignment_Code, CAM_Assignment_Reason, Source_System FROM SourceMerged
                UNION ALL
                SELECT CAM_Assignment_Code, CAM_Assignment_Reason, Source_System FROM DerivedSeeds
            ),
            Ranked AS (
                SELECT
                    s.CAM_Assignment_Code,
                    s.CAM_Assignment_Reason,
                    s.Source_System,
                    ROW_NUMBER() OVER (
                        PARTITION BY UPPER(LTRIM(RTRIM(s.CAM_Assignment_Code)))
                        ORDER BY
                            CASE s.Source_System
                                WHEN 'CAM.tbl_CAM_Raw' THEN 1
                                WHEN @ReasonSource THEN 2
                                ELSE 3
                            END,
                            LEN(ISNULL(s.CAM_Assignment_Reason, '')) DESC
                    ) AS rn
                FROM SourceFinal s
                WHERE s.CAM_Assignment_Code IS NOT NULL
            )
            INSERT INTO #PreparedAssignmentReason
            (
                CAM_Assignment_Code,
                CAM_Assignment_Reason,
                Source_System
            )
            SELECT
                r.CAM_Assignment_Code,
                r.CAM_Assignment_Reason,
                r.Source_System
            FROM Ranked r
            WHERE r.rn = 1;
        END
        ELSE
        BEGIN
            ;WITH SourceRaw AS (
                SELECT DISTINCT
                    CAM_Assignment_Code = NULLIF(LTRIM(RTRIM(CAST([ReassignmentID] AS VARCHAR(50)))), ''),
                    CAM_Assignment_Reason = NULLIF(LTRIM(RTRIM(CAST([CAM_Assignment_Reason] AS VARCHAR(255)))), '')
                FROM [Data_Lab_SWL].[CAM].[tbl_CAM_Raw]
                WHERE [ReassignmentID] IS NOT NULL
            ),
            DerivedSeeds AS (
                SELECT 'EXCL_VPP' AS CAM_Assignment_Code, 'Excluded by local rule: commissioner VPP' AS CAM_Assignment_Reason, 'Derived' AS Source_System
                UNION ALL
                SELECT 'UNMAPPED_REASSIGNMENT', 'Unmapped reassignment code (no reference reason found)', 'Derived'
            ),
            SourceFinal AS (
                SELECT
                    CAM_Assignment_Code,
                    CAM_Assignment_Reason = COALESCE(CAM_Assignment_Reason, 'UNMAPPED_REASSIGNMENT'),
                    Source_System = 'CAM.tbl_CAM_Raw'
                FROM SourceRaw
                UNION ALL
                SELECT CAM_Assignment_Code, CAM_Assignment_Reason, Source_System
                FROM DerivedSeeds
            ),
            Ranked AS (
                SELECT
                    s.CAM_Assignment_Code,
                    s.CAM_Assignment_Reason,
                    s.Source_System,
                    ROW_NUMBER() OVER (
                        PARTITION BY UPPER(LTRIM(RTRIM(s.CAM_Assignment_Code)))
                        ORDER BY
                            CASE s.Source_System
                                WHEN 'CAM.tbl_CAM_Raw' THEN 1
                                ELSE 2
                            END,
                            LEN(ISNULL(s.CAM_Assignment_Reason, '')) DESC
                    ) AS rn
                FROM SourceFinal s
                WHERE s.CAM_Assignment_Code IS NOT NULL
            )
            INSERT INTO #PreparedAssignmentReason
            (
                CAM_Assignment_Code,
                CAM_Assignment_Reason,
                Source_System
            )
            SELECT
                r.CAM_Assignment_Code,
                r.CAM_Assignment_Reason,
                r.Source_System
            FROM Ranked r
            WHERE r.rn = 1;
        END

        UPDATE d
        SET
            d.CAM_Assignment_Reason = p.CAM_Assignment_Reason,
            d.Source_System = p.Source_System,
            d.Updated_By = SUSER_SNAME(),
            d.Updated_Date = GETDATE()
        FROM [Analytics].[tbl_Dim_CAM_Assignment_Reason] d
        INNER JOIN #PreparedAssignmentReason p
            ON p.CAM_Assignment_Code = d.CAM_Assignment_Code
        WHERE d.SK_CAM_Assignment_ReasonID > 0;

        SET @RowsUpdated = @@ROWCOUNT;
        PRINT 'Rows Updated: ' + CAST(@RowsUpdated AS VARCHAR(20));

        INSERT INTO [Analytics].[tbl_Dim_CAM_Assignment_Reason]
        (
            CAM_Assignment_Code,
            CAM_Assignment_Reason,
            Source_System,
            Created_By,
            Created_Date
        )
        SELECT
            p.CAM_Assignment_Code,
            p.CAM_Assignment_Reason,
            p.Source_System,
            SUSER_SNAME(),
            GETDATE()
        FROM #PreparedAssignmentReason p
        WHERE NOT EXISTS (
            SELECT 1
            FROM [Analytics].[tbl_Dim_CAM_Assignment_Reason] d
            WHERE d.CAM_Assignment_Code = p.CAM_Assignment_Code
        );

        SET @RowsInserted = @@ROWCOUNT;
        PRINT 'Rows Inserted: ' + CAST(@RowsInserted AS VARCHAR(20));

        EXEC [Analytics].[sp_Log_Table_Load]
            @BatchID = @BatchID,
            @TableName = @TableName,
            @LoadType = 'Full',
            @RowsAffected = (@RowsInserted + @RowsUpdated),
            @Status = 'Success';

        EXEC [Analytics].[sp_End_ETL_Batch]
            @BatchID = @BatchID,
            @Status = 'Success',
            @RowsInserted = @RowsInserted,
            @RowsUpdated = @RowsUpdated,
            @RowsDeleted = @RowsDeleted,
            @RowsFailed = 0,
            @ErrorMessage = NULL;
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();
        PRINT 'Error Loading Dim_CAM_Assignment_Reason: ' + @ErrorMessage;
        IF @BatchID IS NOT NULL
        BEGIN
            EXEC [Analytics].[sp_Log_Table_Load]
                @BatchID = @BatchID,
                @TableName = @TableName,
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

PRINT '[OK] Created procedure: [Analytics].[sp_Load_Dim_CAM_Assignment_Reason]';
GO

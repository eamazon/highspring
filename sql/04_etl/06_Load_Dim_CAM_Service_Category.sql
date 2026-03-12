USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('[Analytics].[sp_Load_Dim_CAM_Service_Category]', 'P') IS NOT NULL
    DROP PROCEDURE [Analytics].[sp_Load_Dim_CAM_Service_Category];
GO

/**
Script Name:   06_Load_Dim_CAM_Service_Category.sql
Description:   Loads CAM service category dimension from Ref.tbl_Service_Category_Codes.
Author:        Sridhar Peddi
Created:       2026-01-12 21:55

Change Log:
  2026-01-12  Sridhar Peddi    Initial creation
  2026-03-12  Sridhar Peddi    Preserve surrogate keys via upsert (update + insert new codes)
**/
CREATE PROCEDURE [Analytics].[sp_Load_Dim_CAM_Service_Category]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @BatchName VARCHAR(100) = 'Load_Dim_CAM_Service_Category';
    DECLARE @BatchID INT = NULL;
    DECLARE @TableName VARCHAR(100) = 'Analytics.tbl_Dim_CAM_Service_Category';
    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsUpdated INT = 0;
    DECLARE @RowsAffected INT = 0;
    DECLARE @RowsDeleted INT = 0;
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @RefDb SYSNAME = NULL;

    BEGIN TRY
        EXEC [Analytics].[sp_Start_ETL_Batch]
            @BatchName = @BatchName,
            @BatchID = @BatchID OUTPUT;

        PRINT 'Starting Load: [Analytics].[tbl_Dim_CAM_Service_Category]';

        IF EXISTS (
            SELECT 1
            FROM [Data_Lab_SWL_Live].sys.tables t
            INNER JOIN [Data_Lab_SWL_Live].sys.schemas s ON s.schema_id = t.schema_id
            WHERE s.name = 'Ref' AND t.name = 'tbl_Service_Category_Codes'
        )
        BEGIN
            SET @RefDb = 'Data_Lab_SWL_Live';
        END
        ELSE IF EXISTS (
            SELECT 1
            FROM [Data_Lab_SWL].sys.tables t
            INNER JOIN [Data_Lab_SWL].sys.schemas s ON s.schema_id = t.schema_id
            WHERE s.name = 'Ref' AND t.name = 'tbl_Service_Category_Codes'
        )
        BEGIN
            SET @RefDb = 'Data_Lab_SWL';
        END
        ELSE
        BEGIN
            RAISERROR('Source table [Ref].[tbl_Service_Category_Codes] not found in either [Data_Lab_SWL_Live] or [Data_Lab_SWL].', 16, 1);
            RETURN;
        END

        IF OBJECT_ID('tempdb..#PreparedServiceCategory') IS NOT NULL
            DROP TABLE #PreparedServiceCategory;

        CREATE TABLE #PreparedServiceCategory
        (
            CAM_Service_Category VARCHAR(50) NOT NULL PRIMARY KEY,
            CAM_Service_Category_Description VARCHAR(255) NULL,
            CAM_Service_Category_Short_Description VARCHAR(255) NULL,
            Source_System VARCHAR(100) NOT NULL
        );

        IF @RefDb = 'Data_Lab_SWL_Live'
        BEGIN
            ;WITH Source AS (
                SELECT
                    CAM_Service_Category = CAST(src.ServiceCategoryCode AS VARCHAR(50)),
                    CAM_Service_Category_Description = MAX(NULLIF(LTRIM(RTRIM(src.ServiceCategoryDescription)), '')),
                    CAM_Service_Category_Short_Description = MAX(NULLIF(LTRIM(RTRIM(src.ShortDescription)), ''))
                FROM [Data_Lab_SWL_Live].[Ref].[tbl_Service_Category_Codes] src
                WHERE src.ServiceCategoryCode IS NOT NULL
                GROUP BY CAST(src.ServiceCategoryCode AS VARCHAR(50))
            )
            INSERT INTO #PreparedServiceCategory
            (
                CAM_Service_Category,
                CAM_Service_Category_Description,
                CAM_Service_Category_Short_Description,
                Source_System
            )
            SELECT
                s.CAM_Service_Category,
                s.CAM_Service_Category_Description,
                s.CAM_Service_Category_Short_Description,
                'Data_Lab_SWL_Live.Ref.tbl_Service_Category_Codes'
            FROM Source s
            WHERE s.CAM_Service_Category IS NOT NULL;
        END
        ELSE
        BEGIN
            ;WITH Source AS (
                SELECT
                    CAM_Service_Category = CAST(src.ServiceCategoryCode AS VARCHAR(50)),
                    CAM_Service_Category_Description = MAX(NULLIF(LTRIM(RTRIM(src.ServiceCategoryDescription)), '')),
                    CAM_Service_Category_Short_Description = MAX(NULLIF(LTRIM(RTRIM(src.ShortDescription)), ''))
                FROM [Data_Lab_SWL].[Ref].[tbl_Service_Category_Codes] src
                WHERE src.ServiceCategoryCode IS NOT NULL
                GROUP BY CAST(src.ServiceCategoryCode AS VARCHAR(50))
            )
            INSERT INTO #PreparedServiceCategory
            (
                CAM_Service_Category,
                CAM_Service_Category_Description,
                CAM_Service_Category_Short_Description,
                Source_System
            )
            SELECT
                s.CAM_Service_Category,
                s.CAM_Service_Category_Description,
                s.CAM_Service_Category_Short_Description,
                'Data_Lab_SWL.Ref.tbl_Service_Category_Codes'
            FROM Source s
            WHERE s.CAM_Service_Category IS NOT NULL;
        END

        UPDATE d
        SET
            d.CAM_Service_Category_Description = p.CAM_Service_Category_Description,
            d.CAM_Service_Category_Short_Description = p.CAM_Service_Category_Short_Description,
            d.Source_System = p.Source_System,
            d.Updated_By = SUSER_SNAME(),
            d.Updated_Date = GETDATE()
        FROM [Analytics].[tbl_Dim_CAM_Service_Category] d
        INNER JOIN #PreparedServiceCategory p
            ON p.CAM_Service_Category = d.CAM_Service_Category
        WHERE d.SK_CAM_Service_CategoryID > 0;

        SET @RowsUpdated = @@ROWCOUNT;
        PRINT 'Rows Updated: ' + CAST(@RowsUpdated AS VARCHAR(20));

        INSERT INTO [Analytics].[tbl_Dim_CAM_Service_Category]
        (
            CAM_Service_Category,
            CAM_Service_Category_Description,
            CAM_Service_Category_Short_Description,
            Source_System,
            Created_By,
            Created_Date
        )
        SELECT
            p.CAM_Service_Category,
            p.CAM_Service_Category_Description,
            p.CAM_Service_Category_Short_Description,
            p.Source_System,
            SUSER_SNAME(),
            GETDATE()
        FROM #PreparedServiceCategory p
        WHERE NOT EXISTS (
            SELECT 1
            FROM [Analytics].[tbl_Dim_CAM_Service_Category] d
            WHERE d.CAM_Service_Category = p.CAM_Service_Category
        );

        SET @RowsInserted = @@ROWCOUNT;
        PRINT 'Rows Inserted: ' + CAST(@RowsInserted AS VARCHAR(20));

        SET @RowsAffected = @RowsInserted + @RowsUpdated;

        EXEC [Analytics].[sp_Log_Table_Load]
            @BatchID = @BatchID,
            @TableName = @TableName,
            @LoadType = 'Full',
            @RowsAffected = @RowsAffected,
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
        PRINT 'Error Loading Dim_CAM_Service_Category: ' + @ErrorMessage;
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

PRINT '[OK] Created procedure: [Analytics].[sp_Load_Dim_CAM_Service_Category]';
GO

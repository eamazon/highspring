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
Description:   Loads CAM service category dimension from CAM_Ref.CommissionerAssignmentReason.
Author:        Sridhar Peddi
Created:       2026-01-12 21:55

Change Log:
  2026-01-12  Sridhar Peddi    Initial creation
**/
CREATE PROCEDURE [Analytics].[sp_Load_Dim_CAM_Service_Category]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @BatchName VARCHAR(100) = 'Load_Dim_CAM_Service_Category';
    DECLARE @BatchID INT = NULL;
    DECLARE @TableName VARCHAR(100) = 'Analytics.tbl_Dim_CAM_Service_Category';
    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsDeleted INT = 0;
    DECLARE @ErrorMessage NVARCHAR(4000);

    BEGIN TRY
        EXEC [Analytics].[sp_Start_ETL_Batch]
            @BatchName = @BatchName,
            @BatchID = @BatchID OUTPUT;

        PRINT 'Starting Load: [Analytics].[tbl_Dim_CAM_Service_Category]';

        IF NOT EXISTS (
            SELECT 1
            FROM [Data_Lab_SWL].sys.tables t
            INNER JOIN [Data_Lab_SWL].sys.schemas s ON s.schema_id = t.schema_id
            WHERE s.name = 'CAM_Ref'
              AND t.name = 'CommissionerAssignmentReason'
        )
        BEGIN
            RAISERROR('Source table [Data_Lab_SWL].[CAM_Ref].[CommissionerAssignmentReason] not found.', 16, 1);
            RETURN;
        END

        DELETE FROM [Analytics].[tbl_Dim_CAM_Service_Category]
        WHERE SK_CAM_Service_CategoryID > 0;

        SET @RowsDeleted = @@ROWCOUNT;
        PRINT 'Rows Deleted: ' + CAST(@RowsDeleted AS VARCHAR(20));

        ;WITH Source AS (
            SELECT DISTINCT
                CAM_Service_Category = NULLIF(LTRIM(RTRIM([Service Category])), '')
            FROM [Data_Lab_SWL].[CAM_Ref].[CommissionerAssignmentReason]
        )
        INSERT INTO [Analytics].[tbl_Dim_CAM_Service_Category]
        (
            CAM_Service_Category,
            Source_System,
            Created_By,
            Created_Date
        )
        SELECT
            s.CAM_Service_Category,
            'CAM_Ref.CommissionerAssignmentReason',
            SUSER_SNAME(),
            GETDATE()
        FROM Source s
        WHERE s.CAM_Service_Category IS NOT NULL;

        SET @RowsInserted = @@ROWCOUNT;
        PRINT 'Rows Inserted: ' + CAST(@RowsInserted AS VARCHAR(20));

        EXEC [Analytics].[sp_Log_Table_Load]
            @BatchID = @BatchID,
            @TableName = @TableName,
            @LoadType = 'Full',
            @RowsAffected = @RowsInserted,
            @Status = 'Success';

        EXEC [Analytics].[sp_End_ETL_Batch]
            @BatchID = @BatchID,
            @Status = 'Success',
            @RowsInserted = @RowsInserted,
            @RowsUpdated = 0,
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

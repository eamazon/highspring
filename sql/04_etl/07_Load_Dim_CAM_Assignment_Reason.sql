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
Description:   Loads CAM assignment reason dimension from CAM_Ref.CommissionerAssignmentReason.
Author:        Sridhar Peddi
Created:       2026-01-12 21:55

Change Log:
  2026-01-12  Sridhar Peddi    Initial creation
**/
CREATE PROCEDURE [Analytics].[sp_Load_Dim_CAM_Assignment_Reason]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @BatchName VARCHAR(100) = 'Load_Dim_CAM_Assignment_Reason';
    DECLARE @BatchID INT = NULL;
    DECLARE @TableName VARCHAR(100) = 'Analytics.tbl_Dim_CAM_Assignment_Reason';
    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsDeleted INT = 0;
    DECLARE @ErrorMessage NVARCHAR(4000);

    BEGIN TRY
        EXEC [Analytics].[sp_Start_ETL_Batch]
            @BatchName = @BatchName,
            @BatchID = @BatchID OUTPUT;

        PRINT 'Starting Load: [Analytics].[tbl_Dim_CAM_Assignment_Reason]';

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

        DELETE FROM [Analytics].[tbl_Dim_CAM_Assignment_Reason]
        WHERE SK_CAM_Assignment_ReasonID > 0;

        SET @RowsDeleted = @@ROWCOUNT;
        PRINT 'Rows Deleted: ' + CAST(@RowsDeleted AS VARCHAR(20));

        ;WITH Source AS (
            SELECT DISTINCT
                CAM_Assignment_Code = NULLIF(LTRIM(RTRIM([CAM_Code])), ''),
                CAM_Assignment_Reason = NULLIF(LTRIM(RTRIM([Commissioner Assignment Reason])), '')
            FROM [Data_Lab_SWL].[CAM_Ref].[CommissionerAssignmentReason]
        )
        INSERT INTO [Analytics].[tbl_Dim_CAM_Assignment_Reason]
        (
            CAM_Assignment_Code,
            CAM_Assignment_Reason,
            Source_System,
            Created_By,
            Created_Date
        )
        SELECT
            s.CAM_Assignment_Code,
            s.CAM_Assignment_Reason,
            'CAM_Ref.CommissionerAssignmentReason',
            SUSER_SNAME(),
            GETDATE()
        FROM Source s
        WHERE s.CAM_Assignment_Code IS NOT NULL;

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

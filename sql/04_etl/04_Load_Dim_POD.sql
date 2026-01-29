/**
Script Name:   04_Load_Dim_POD.sql
Description:   SQL object
Author:        Sridhar Peddi
Created:       2026-01-09

Change Log:
  2026-01-09  Sridhar Peddi    Initial creation
  2026-01-12  Sridhar Peddi    Add ETL batch/table logging
**/

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating sp_Load_Dim_POD';
PRINT '========================================';
GO

CREATE OR ALTER PROCEDURE [Analytics].[sp_Load_Dim_POD]
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ProcessName VARCHAR(100) = 'Load_Dim_POD';
    DECLARE @BatchID INT = NULL;
    DECLARE @TableName VARCHAR(100) = 'Analytics.tbl_Dim_POD';
    DECLARE @StartTime DATETIME2 = GETDATE();
    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsUpdated INT = 0;
    DECLARE @RowsAffected INT = 0;
    DECLARE @ErrorMessage NVARCHAR(4000);
    
    BEGIN TRY
        EXEC [Analytics].[sp_Start_ETL_Batch]
            @BatchName = @ProcessName,
            @BatchID = @BatchID OUTPUT;

        PRINT 'Batch ID: ' + CAST(@BatchID AS VARCHAR);
        PRINT '[INFO] Starting POD dimension load from staging...';
        
        -- MERGE from staging to dimension
        DECLARE @MergeActions TABLE (Action NVARCHAR(10) NOT NULL);

        MERGE [Analytics].[tbl_Dim_POD] AS Target
        USING [Analytics].[Staging_POD] AS Source
        ON Target.POD_Code = Source.POD_Code
        
        -- UPDATE existing records (SCD Type 1 - overwrite)
        WHEN MATCHED AND (
            Target.POD_Domain <> Source.POD_Domain OR
            Target.POD_Subcategory <> Source.POD_Subcategory OR
            Target.POD_Measure <> Source.POD_Measure OR
            Target.POD_Description <> Source.POD_Description
        ) THEN
            UPDATE SET
                POD_Domain = Source.POD_Domain,
                POD_Subcategory = Source.POD_Subcategory,
                POD_Measure = Source.POD_Measure,
                POD_Description = Source.POD_Description,
                Updated_Date = GETDATE(),
                Updated_By = SUSER_SNAME()
        
        -- INSERT new records
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (POD_Code, POD_Domain, POD_Subcategory, POD_Measure, POD_Description, Created_By)
            VALUES (Source.POD_Code, Source.POD_Domain, Source.POD_Subcategory, 
                Source.POD_Measure, Source.POD_Description, SUSER_SNAME())
        OUTPUT $action INTO @MergeActions;

        SELECT @RowsInserted = COUNT(*) FROM @MergeActions WHERE Action = 'INSERT';
        SELECT @RowsUpdated = COUNT(*) FROM @MergeActions WHERE Action = 'UPDATE';
        SET @RowsAffected = @RowsInserted + @RowsUpdated;
        
        PRINT '[OK] POD dimension load complete';
        PRINT '  Rows affected: ' + CAST(@RowsAffected AS VARCHAR);

        EXEC [Analytics].[sp_Log_Table_Load]
            @BatchID = @BatchID,
            @TableName = @TableName,
            @LoadType = 'SCD Type 1',
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
        
        PRINT '[ERROR] POD dimension load failed: ' + @ErrorMessage;
        
        IF @BatchID IS NOT NULL
        BEGIN
            EXEC [Analytics].[sp_Log_Table_Load]
                @BatchID = @BatchID,
                @TableName = @TableName,
                @LoadType = 'SCD Type 1',
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
        
        -- Re-raise error
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END CATCH
END
GO

PRINT '[OK] Created procedure: sp_Load_Dim_POD';
GO

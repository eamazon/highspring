

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('[Analytics].[sp_Load_Dim_PCN]', 'P') IS NOT NULL
    DROP PROCEDURE [Analytics].[sp_Load_Dim_PCN];
GO

/**
Script Name:   03_Load_Dim_PCN.sql
Description:   ETL Stored Procedure to load Dim_PCN from Dim_GPPractice
Author:        Sridhar Peddi
Created:       2026-01-02

Change Log:
  2026-01-02  Sridhar Peddi    Initial creation
  2026-01-12  Sridhar Peddi    Add ETL batch/table logging
  2026-01-27  Sridhar Peddi    Confirmed source is Dim_GPPractice (not staging)
**/
CREATE PROCEDURE [Analytics].[sp_Load_Dim_PCN]
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ProcessName VARCHAR(100) = 'Load_Dim_PCN';
    DECLARE @BatchID INT = NULL;
    DECLARE @TableName VARCHAR(100) = 'Analytics.tbl_Dim_PCN';
    DECLARE @StartTime DATETIME2 = GETDATE();
    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsUpdated INT = 0;
    DECLARE @RowsAffected INT = 0;
    DECLARE @PreRowCount INT = 0;
    DECLARE @PostRowCount INT = 0;
    DECLARE @ErrorMessage NVARCHAR(4000);
    
    PRINT '========================================';
    PRINT 'Starting Dimension Load: Dim_PCN';
    PRINT 'Timestamp: ' + CONVERT(VARCHAR, @StartTime, 121);
    PRINT '========================================';
    
    BEGIN TRY
        EXEC [Analytics].[sp_Start_ETL_Batch]
            @BatchName = @ProcessName,
            @BatchID = @BatchID OUTPUT;

        PRINT 'Batch ID: ' + CAST(@BatchID AS VARCHAR);

        SELECT @PreRowCount = COUNT(*) FROM [Analytics].[tbl_Dim_PCN];

        -- 1. Merge Dim_GPPractice-derived PCNs into Dimension
        DECLARE @MergeActions TABLE (Action NVARCHAR(10) NOT NULL);

        MERGE [Analytics].[tbl_Dim_PCN] AS Target
        USING (
            SELECT
                GP.PCN_Code,
                MAX(NULLIF(GP.PCN_Name, '')) AS PCN_Name,
                MAX(NULLIF(GP.ICB_Code, '')) AS ICB_Code,
                MAX(NULLIF(GP.ICB_Name, '')) AS ICB_Name,
                MAX(CASE WHEN GP.Is_Active = 1 THEN 1 ELSE 0 END) AS Is_Active
            FROM [Analytics].[tbl_Dim_GPPractice] GP
            WHERE GP.Is_Current = 1
              AND GP.PCN_Code IS NOT NULL
            GROUP BY GP.PCN_Code
        ) AS Source
        ON (Target.PCN_Code = Source.PCN_Code)
        
        -- Update existing records (SCD Type 1)
        WHEN MATCHED AND (
            ISNULL(Target.PCN_Name, '') <> ISNULL(Source.PCN_Name, '') OR
            ISNULL(Target.ICB_Code, '') <> ISNULL(Source.ICB_Code, '') OR
            ISNULL(Target.ICB_Name, '') <> ISNULL(Source.ICB_Name, '') OR
            ISNULL(Target.Is_Active, 1) <> ISNULL(Source.Is_Active, 1)
        ) THEN
            UPDATE SET
                Target.PCN_Name = Source.PCN_Name,
                Target.ICB_Code = Source.ICB_Code,
                Target.ICB_Name = Source.ICB_Name,
                Target.Is_Active = Source.Is_Active,
                Target.Updated_Date = GETDATE(),
                Target.Updated_By = SUSER_SNAME()
                
        -- Insert new records
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                PCN_Code,
                PCN_Name,
                ICB_Code,
                ICB_Name,
                Open_Date,
                Close_Date,
                Is_Active
            )
            VALUES (
                Source.PCN_Code,
                Source.PCN_Name,
                Source.ICB_Code,
                Source.ICB_Name,
                NULL, -- Open_Date
                NULL, -- Close_Date
                Source.Is_Active
            )
        OUTPUT $action INTO @MergeActions;

        PRINT 'Merge completed successfully.';

        SELECT @RowsInserted = COUNT(*) FROM @MergeActions WHERE Action = 'INSERT';
        SELECT @RowsUpdated = COUNT(*) FROM @MergeActions WHERE Action = 'UPDATE';
        SET @RowsAffected = @RowsInserted + @RowsUpdated;

        -- Ensure Unknown PCN exists for unmatched/unknown codes
        IF NOT EXISTS (SELECT 1 FROM [Analytics].[tbl_Dim_PCN] WHERE PCN_Code = 'UNK')
        BEGIN
            INSERT INTO [Analytics].[tbl_Dim_PCN] (
                PCN_Code,
                PCN_Name,
                ICB_Code,
                ICB_Name,
                Open_Date,
                Close_Date,
                Is_Active
            )
            VALUES (
                'UNK',
                'Unknown PCN',
                NULL,
                NULL,
                NULL,
                NULL,
                1
            );

            SET @RowsInserted = @RowsInserted + 1;
            SET @RowsAffected = @RowsAffected + 1;
        END

        -- Stability checks (key preservation + defaults)
        SELECT @PostRowCount = COUNT(*) FROM [Analytics].[tbl_Dim_PCN];
        IF @PostRowCount < @PreRowCount
        BEGIN
            RAISERROR('Dim_PCN row count decreased (possible truncation).', 16, 1);
        END

        IF NOT EXISTS (SELECT 1 FROM [Analytics].[tbl_Dim_PCN] WHERE PCN_Code = 'UNK')
        BEGIN
            RAISERROR('Dim_PCN default member missing (PCN_Code = UNK).', 16, 1);
        END

        IF EXISTS (
            SELECT PCN_Code
            FROM [Analytics].[tbl_Dim_PCN]
            WHERE Is_Current = 1
            GROUP BY PCN_Code
            HAVING COUNT(*) > 1
        )
        BEGIN
            RAISERROR('Dim_PCN has duplicate current PCN_Code values.', 16, 1);
        END

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
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR);
        PRINT 'Error Message: ' + @ErrorMessage;
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
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END CATCH
    
    PRINT '========================================';
    PRINT 'Completed Dimension Load: Dim_PCN';
    PRINT 'Timestamp: ' + CONVERT(VARCHAR, GETDATE(), 121);
    PRINT '========================================';
END
GO

PRINT '[OK] Created Procedure: [Analytics].[sp_Load_Dim_PCN]';
GO

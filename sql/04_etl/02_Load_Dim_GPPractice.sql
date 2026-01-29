

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('[Analytics].[sp_Load_Dim_GPPractice]', 'P') IS NOT NULL
    DROP PROCEDURE [Analytics].[sp_Load_Dim_GPPractice];
GO

/**
Script Name:   02_Load_Dim_GPPractice.sql
Description:   ETL Stored Procedure to load Dim_GPPractice from Staging (SCD Type 2)
Author:        Sridhar Peddi
Created:       2026-01-02

Change Log:
  2026-01-02  Sridhar Peddi    Initial creation
  2026-01-12  Sridhar Peddi    Add ETL batch/table logging
**/
CREATE PROCEDURE [Analytics].[sp_Load_Dim_GPPractice]
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ProcessName VARCHAR(100) = 'Load_Dim_GPPractice';
    DECLARE @BatchID INT = NULL;
    DECLARE @TableName VARCHAR(100) = 'Analytics.tbl_Dim_GPPractice';
    DECLARE @StartTime DATETIME2 = GETDATE();
    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsUpdated INT = 0;
    DECLARE @RowsAffected INT = 0;
    DECLARE @PreRowCount INT = 0;
    DECLARE @PostRowCount INT = 0;
    DECLARE @ErrorMessage NVARCHAR(4000);
    
    PRINT '========================================';
    PRINT 'Starting Dimension Load: Dim_GPPractice';
    PRINT 'Timestamp: ' + CONVERT(VARCHAR, @StartTime, 121);
    PRINT '========================================';
    
    BEGIN TRY
        EXEC [Analytics].[sp_Start_ETL_Batch]
            @BatchName = @ProcessName,
            @BatchID = @BatchID OUTPUT;

        PRINT 'Batch ID: ' + CAST(@BatchID AS VARCHAR);

        SELECT @PreRowCount = COUNT(*) FROM [Analytics].[tbl_Dim_GPPractice];

        -- 1. Identify Changes (New Records + Changed Records)
        -- Uses "Type 2" logic: If attribute changes, expire old record, insert new one.
        
        -- A) Expire existing records that have changed
        UPDATE Dim
        SET 
            Valid_To = DATEADD(DAY, -1, CAST(GETDATE() AS DATE)),
            Is_Current = 0,
            Updated_Date = GETDATE(),
            Updated_By = SUSER_SNAME()
        FROM [Analytics].[tbl_Dim_GPPractice] Dim
        JOIN [Analytics].[tbl_Staging_GP_Practice] Stg
            ON Dim.GPPractice_Code = Stg.Practice_Code
        WHERE Dim.Is_Current = 1
          AND (
              ISNULL(Dim.GPPractice_Name, '') <> ISNULL(Stg.Practice_Name, '') OR
              ISNULL(Dim.Practice_Category, '') <> ISNULL(Stg.Status, '') OR
              ISNULL(Dim.PCN_Code, '') <> ISNULL(Stg.PCN_Code, 'UNK') OR
              ISNULL(Dim.SubICB_Code, '') <> ISNULL(Stg.Commissioner_Code, 'UNK') OR -- Map Commissioner -> SubICB
              ISNULL(Dim.Address_Line1, '') <> ISNULL(Stg.Address_Line1, '') OR
              ISNULL(Dim.Postcode, '') <> ISNULL(Stg.Postcode, '') OR
              ISNULL(Dim.Contact_Telephone, '') <> ISNULL(Stg.Contact_Telephone, '') OR
              ISNULL(Dim.Prescribing_Setting, '') <> ISNULL(Stg.Prescribing_Setting, '') OR
              ISNULL(Dim.Org_Sub_Type, '') <> ISNULL(Stg.Org_Sub_Type, '')
          );

        SET @RowsUpdated = @@ROWCOUNT;
          
        -- B) Insert NEW records and NEW VERSIONS of changed records
        INSERT INTO [Analytics].[tbl_Dim_GPPractice] (
            GPPractice_Code,
            GPPractice_Name,
            Practice_Category,
            Prescribing_Setting,
            Org_Sub_Type,
            Address_Line1,
            Address_Line2,
            Address_Line3,
            Town,
            Postcode,
            Contact_Telephone,
            PCN_Code,
            PCN_Name,
            SubICB_Code,
            SubICB_Name,
            ICB_Code,
            ICB_Name,
            ICB_Grouping,
            ICB_Grouping_Sort,
            Registration_Status,
            Is_Active,
            Effective_From_Date,
            Effective_To_Date,
            Valid_From,
            Valid_To,
            Is_Current,
            Source_System,
            Created_By,
            Created_Date
        )
        SELECT 
            Stg.Practice_Code,
            Stg.Practice_Name,
            Stg.Status,
            Stg.Prescribing_Setting,
            Stg.Org_Sub_Type,
            Stg.Address_Line1,
            Stg.Address_Line2,
            Stg.Address_Line3,
            Stg.Town,
            Stg.Postcode,
            Stg.Contact_Telephone,
            ISNULL(Stg.PCN_Code, 'UNK'),
            ISNULL(Stg.PCN_Name, 'Unknown PCN'),
            ISNULL(Stg.Commissioner_Code, 'UNK'), -- Commissioner is the Sub-ICB  
            ISNULL(Stg.Commissioner_Name, 'Unknown Sub-ICB'),
            ISNULL(Stg.ICB_Code, 'UNK'),           -- ICB_Code from epraccur Column 4!
            ISNULL(Stg.ICB_Name, 'Unknown ICB'),   -- ICB_Name (may need enrichment)
            CASE 
                WHEN Stg.ICB_Code = 'QWE' THEN 'SWL ICB'  -- QWE is the actual SWL ICB code
                ELSE 'Other ICB'
            END,                                   -- ICB_Grouping
            CASE 
                WHEN Stg.ICB_Code = 'QWE' THEN 1
                ELSE 3
            END,                                   -- ICB_Grouping_Sort
            CASE WHEN Stg.ICB_Code = 'QWE' THEN 'SWL' ELSE 'Non-SWL' END,
            CASE WHEN Stg.Status = 'Active' THEN 1 ELSE 0 END,
            Stg.Open_Date,
            Stg.Close_Date,
            ISNULL(Stg.Open_Date, '1900-01-01'),  -- Valid_From
            '9999-12-31',                         -- Valid_To
            1,                                    -- Is_Current
            'NHS ODS',
            SUSER_SNAME(),
            GETDATE()
        FROM [Analytics].[tbl_Staging_GP_Practice] Stg
        LEFT JOIN [Analytics].[tbl_Dim_GPPractice] Dim
            ON Stg.Practice_Code = Dim.GPPractice_Code
            AND Dim.Is_Current = 1
        WHERE Dim.SK_GPPracticeID IS NULL; -- Record doesn't exist or was just expired

        SET @RowsInserted = @@ROWCOUNT;
        SET @RowsAffected = @RowsInserted + @RowsUpdated;
        
        PRINT 'SCD Type 2 Merge completed successfully.';

        -- Stability checks (key preservation + defaults)
        SELECT @PostRowCount = COUNT(*) FROM [Analytics].[tbl_Dim_GPPractice];
        IF @PostRowCount < @PreRowCount
        BEGIN
            RAISERROR('Dim_GPPractice row count decreased (possible truncation).', 16, 1);
        END

        IF (SELECT COUNT(*) FROM [Analytics].[tbl_Dim_GPPractice] WHERE SK_GPPracticeID IN (-1, -2, -3, -4)) < 4
        BEGIN
            RAISERROR('Dim_GPPractice default members missing (-1 to -4).', 16, 1);
        END

        IF EXISTS (
            SELECT GPPractice_Code
            FROM [Analytics].[tbl_Dim_GPPractice]
            WHERE Is_Current = 1
            GROUP BY GPPractice_Code
            HAVING COUNT(*) > 1
        )
        BEGIN
            RAISERROR('Dim_GPPractice has duplicate current GPPractice_Code values.', 16, 1);
        END

        EXEC [Analytics].[sp_Log_Table_Load]
            @BatchID = @BatchID,
            @TableName = @TableName,
            @LoadType = 'SCD Type 2',
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
                @LoadType = 'SCD Type 2',
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
    PRINT 'Completed Dimension Load: Dim_GPPractice';
    PRINT '========================================';
END
GO

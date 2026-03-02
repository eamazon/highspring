

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
  2026-03-02  Codex            Resolve ICB/Sub-ICB via Commissioner/PCN lookup and broaden SCD change detection
  2026-03-02  Codex            Restrict to current GP practices (Status=Active, Org_Sub_Type=B)
  2026-03-02  Codex            Enforce Prescribing_Setting=RO76 for real GP practices
  2026-03-02  Codex            Auto-seed missing default members (-1 to -4) when table pre-exists
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

        -- Ensure mandatory default members exist even when dimension table was
        -- created historically and skipped initial default inserts.
        IF (SELECT COUNT(*) FROM [Analytics].[tbl_Dim_GPPractice] WHERE SK_GPPracticeID IN (-1, -2, -3, -4)) < 4
        BEGIN
            SET IDENTITY_INSERT [Analytics].[tbl_Dim_GPPractice] ON;

            IF NOT EXISTS (SELECT 1 FROM [Analytics].[tbl_Dim_GPPractice] WHERE SK_GPPracticeID = -1 OR GPPractice_Code = 'UNKNOWN')
            BEGIN
                INSERT INTO [Analytics].[tbl_Dim_GPPractice]
                    (SK_GPPracticeID, GPPractice_Code, GPPractice_Name, Practice_Category,
                     Address_Line1, Postcode, Contact_Telephone,
                     PCN_Code, PCN_Name, SubICB_Code, SubICB_Name, ICB_Code, ICB_Name,
                     ICB_Grouping, ICB_Grouping_Sort, Registration_Status, Is_Active, Valid_From, Valid_To, Is_Current)
                VALUES
                    (-1, 'UNKNOWN', 'Unknown GP Practice', 'Unknown',
                     'Unknown Address', 'UNK', 'Unknown',
                     'UNKNOWN', 'Unknown PCN', 'UNKNOWN', 'Unknown Sub-ICB', 'UNK', 'Unknown ICB',
                     'Other ICB', 3, 'Non-SWL', 1, '1900-01-01', '9999-12-31', 1);
            END

            IF NOT EXISTS (SELECT 1 FROM [Analytics].[tbl_Dim_GPPractice] WHERE SK_GPPracticeID = -2 OR GPPractice_Code = 'V81997')
            BEGIN
                INSERT INTO [Analytics].[tbl_Dim_GPPractice]
                    (SK_GPPracticeID, GPPractice_Code, GPPractice_Name, Practice_Category,
                     Address_Line1, Postcode, Contact_Telephone,
                     PCN_Code, PCN_Name, SubICB_Code, SubICB_Name, ICB_Code, ICB_Name,
                     ICB_Grouping, ICB_Grouping_Sort, Registration_Status, Is_Active, Valid_From, Valid_To, Is_Current)
                VALUES
                    (-2, 'V81997', 'No Registered GP Practice', 'No Registered GP',
                     'Not Applicable', 'N/A', 'N/A',
                     'UNK', 'No PCN', 'UNK', 'No Sub-ICB', 'UNK', 'No ICB',
                     'Other ICB', 3, 'Non-SWL', 1, '1900-01-01', '9999-12-31', 1);
            END

            IF NOT EXISTS (SELECT 1 FROM [Analytics].[tbl_Dim_GPPractice] WHERE SK_GPPracticeID = -3 OR GPPractice_Code = 'V81998')
            BEGIN
                INSERT INTO [Analytics].[tbl_Dim_GPPractice]
                    (SK_GPPracticeID, GPPractice_Code, GPPractice_Name, Practice_Category,
                     Address_Line1, Postcode, Contact_Telephone,
                     PCN_Code, PCN_Name, SubICB_Code, SubICB_Name, ICB_Code, ICB_Name,
                     ICB_Grouping, ICB_Grouping_Sort, Registration_Status, Is_Active, Valid_From, Valid_To, Is_Current)
                VALUES
                    (-3, 'V81998', 'GP Practice Not Known', 'No Registered GP',
                     'Not Applicable', 'N/A', 'N/A',
                     'UNK', 'No PCN', 'UNK', 'No Sub-ICB', 'UNK', 'No ICB',
                     'Other ICB', 3, 'Non-SWL', 1, '1900-01-01', '9999-12-31', 1);
            END

            IF NOT EXISTS (SELECT 1 FROM [Analytics].[tbl_Dim_GPPractice] WHERE SK_GPPracticeID = -4 OR GPPractice_Code = 'V81999')
            BEGIN
                INSERT INTO [Analytics].[tbl_Dim_GPPractice]
                    (SK_GPPracticeID, GPPractice_Code, GPPractice_Name, Practice_Category,
                     Address_Line1, Postcode, Contact_Telephone,
                     PCN_Code, PCN_Name, SubICB_Code, SubICB_Name, ICB_Code, ICB_Name,
                     ICB_Grouping, ICB_Grouping_Sort, Registration_Status, Is_Active, Valid_From, Valid_To, Is_Current)
                VALUES
                    (-4, 'V81999', 'No Fixed Abode', 'No Registered GP',
                     'Not Applicable', 'N/A', 'N/A',
                     'UNK', 'No PCN', 'UNK', 'No Sub-ICB', 'UNK', 'No ICB',
                     'Other ICB', 3, 'Non-SWL', 1, '1900-01-01', '9999-12-31', 1);
            END

            SET IDENTITY_INSERT [Analytics].[tbl_Dim_GPPractice] OFF;
        END

        SELECT @PreRowCount = COUNT(*) FROM [Analytics].[tbl_Dim_GPPractice];

        IF OBJECT_ID('tempdb..#SourceResolved') IS NOT NULL
            DROP TABLE #SourceResolved;

        ;WITH SourceResolved AS (
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
                Stg.Open_Date,
                Stg.Close_Date,
                ISNULL(NULLIF(Stg.PCN_Code, ''), 'UNK') AS Resolved_PCN_Code,
                ISNULL(NULLIF(Stg.PCN_Name, ''), 'Unknown PCN') AS Resolved_PCN_Name,
                COALESCE(
                    NULLIF(Pcn.Sub_ICB_Code, ''),
                    CASE WHEN ISNULL(CommFromStg.Commissioner_Type, '') <> 'ICB' THEN NULLIF(Stg.Commissioner_Code, '') END,
                    CASE WHEN ISNULL(CommFromStg.Commissioner_Type, '') <> 'ICB' THEN NULLIF(CommFromStg.SubICB_Code, '') END,
                    'UNK'
                ) AS Resolved_SubICB_Code,
                COALESCE(
                    NULLIF(Pcn.Sub_ICB_Name, ''),
                    CASE WHEN ISNULL(CommFromStg.Commissioner_Type, '') <> 'ICB' THEN NULLIF(Stg.Commissioner_Name, '') END,
                    CASE WHEN ISNULL(CommFromStg.Commissioner_Type, '') <> 'ICB' THEN NULLIF(CommFromStg.SubICB_Name, '') END,
                    'Unknown Sub-ICB'
                ) AS Resolved_SubICB_Name,
                COALESCE(
                    NULLIF(Stg.ICB_Code, ''),
                    CASE WHEN CommFromStg.Commissioner_Type = 'ICB' THEN NULLIF(Stg.Commissioner_Code, '') END,
                    NULLIF(CommFromStg.ICB_Code, ''),
                    NULLIF(CommFromPcn.ICB_Code, ''),
                    'UNK'
                ) AS Resolved_ICB_Code,
                COALESCE(
                    NULLIF(Stg.ICB_Name, ''),
                    CASE WHEN CommFromStg.Commissioner_Type = 'ICB' THEN NULLIF(Stg.Commissioner_Name, '') END,
                    NULLIF(CommFromStg.ICB_Name, ''),
                    NULLIF(CommFromPcn.ICB_Name, ''),
                    'Unknown ICB'
                ) AS Resolved_ICB_Name
            FROM [Analytics].[tbl_Staging_GP_Practice] Stg
            LEFT JOIN [Analytics].[tbl_Staging_PCN] Pcn
                ON Stg.PCN_Code = Pcn.PCN_Code
            LEFT JOIN [Analytics].[tbl_Dim_Commissioner] CommFromStg
                ON CommFromStg.Commissioner_Code = Stg.Commissioner_Code
            LEFT JOIN [Analytics].[tbl_Dim_Commissioner] CommFromPcn
                ON CommFromPcn.Commissioner_Code = Pcn.Sub_ICB_Code
            WHERE
                ISNULL(Stg.Status, '') = 'Active'
                AND ISNULL(Stg.Org_Sub_Type, '') = 'B'
                AND ISNULL(Stg.Prescribing_Setting, '') = 'RO76'
        )
        SELECT
            Practice_Code,
            Practice_Name,
            Status,
            Prescribing_Setting,
            Org_Sub_Type,
            Address_Line1,
            Address_Line2,
            Address_Line3,
            Town,
            Postcode,
            Contact_Telephone,
            Open_Date,
            Close_Date,
            Resolved_PCN_Code,
            Resolved_PCN_Name,
            Resolved_SubICB_Code,
            Resolved_SubICB_Name,
            Resolved_ICB_Code,
            Resolved_ICB_Name
        INTO #SourceResolved
        FROM SourceResolved;

        -- Expire current rows that are no longer in the eligible source
        -- (not Active GP practices anymore or no longer present in staging).
        UPDATE Dim
        SET
            Valid_To = DATEADD(DAY, -1, CAST(GETDATE() AS DATE)),
            Is_Current = 0,
            Updated_Date = GETDATE(),
            Updated_By = SUSER_SNAME()
        FROM [Analytics].[tbl_Dim_GPPractice] Dim
        LEFT JOIN #SourceResolved Src
            ON Dim.GPPractice_Code = Src.Practice_Code
        WHERE
            Dim.Is_Current = 1
            AND Dim.SK_GPPracticeID > 0
            AND Src.Practice_Code IS NULL;

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
        JOIN #SourceResolved Src
            ON Dim.GPPractice_Code = Src.Practice_Code
        WHERE Dim.Is_Current = 1
          AND (
              ISNULL(Dim.GPPractice_Name, '') <> ISNULL(Src.Practice_Name, '') OR
              ISNULL(Dim.Practice_Category, '') <> ISNULL(Src.Status, '') OR
              ISNULL(Dim.PCN_Code, '') <> ISNULL(Src.Resolved_PCN_Code, 'UNK') OR
              ISNULL(Dim.PCN_Name, '') <> ISNULL(Src.Resolved_PCN_Name, 'Unknown PCN') OR
              ISNULL(Dim.SubICB_Code, '') <> ISNULL(Src.Resolved_SubICB_Code, 'UNK') OR
              ISNULL(Dim.SubICB_Name, '') <> ISNULL(Src.Resolved_SubICB_Name, 'Unknown Sub-ICB') OR
              ISNULL(Dim.ICB_Code, '') <> ISNULL(Src.Resolved_ICB_Code, 'UNK') OR
              ISNULL(Dim.ICB_Name, '') <> ISNULL(Src.Resolved_ICB_Name, 'Unknown ICB') OR
              ISNULL(Dim.Address_Line1, '') <> ISNULL(Src.Address_Line1, '') OR
              ISNULL(Dim.Address_Line2, '') <> ISNULL(Src.Address_Line2, '') OR
              ISNULL(Dim.Address_Line3, '') <> ISNULL(Src.Address_Line3, '') OR
              ISNULL(Dim.Town, '') <> ISNULL(Src.Town, '') OR
              ISNULL(Dim.Postcode, '') <> ISNULL(Src.Postcode, '') OR
              ISNULL(Dim.Contact_Telephone, '') <> ISNULL(Src.Contact_Telephone, '') OR
              ISNULL(Dim.Prescribing_Setting, '') <> ISNULL(Src.Prescribing_Setting, '') OR
              ISNULL(Dim.Org_Sub_Type, '') <> ISNULL(Src.Org_Sub_Type, '') OR
              ISNULL(Dim.Effective_From_Date, '1900-01-01') <> ISNULL(Src.Open_Date, '1900-01-01') OR
              ISNULL(Dim.Effective_To_Date, '9999-12-31') <> ISNULL(Src.Close_Date, '9999-12-31') OR
              ISNULL(Dim.Is_Active, 0) <> CASE WHEN Src.Status = 'Active' THEN 1 ELSE 0 END
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
            Src.Practice_Code,
            Src.Practice_Name,
            Src.Status,
            Src.Prescribing_Setting,
            Src.Org_Sub_Type,
            Src.Address_Line1,
            Src.Address_Line2,
            Src.Address_Line3,
            Src.Town,
            Src.Postcode,
            Src.Contact_Telephone,
            ISNULL(Src.Resolved_PCN_Code, 'UNK'),
            ISNULL(Src.Resolved_PCN_Name, 'Unknown PCN'),
            ISNULL(Src.Resolved_SubICB_Code, 'UNK'),
            ISNULL(Src.Resolved_SubICB_Name, 'Unknown Sub-ICB'),
            ISNULL(Src.Resolved_ICB_Code, 'UNK'),
            ISNULL(Src.Resolved_ICB_Name, 'Unknown ICB'),
            CASE 
                WHEN Src.Resolved_ICB_Code = 'QWE' THEN 'SWL ICB'  -- QWE is the actual SWL ICB code
                ELSE 'Other ICB'
            END,                                   -- ICB_Grouping
            CASE 
                WHEN Src.Resolved_ICB_Code = 'QWE' THEN 1
                ELSE 3
            END,                                   -- ICB_Grouping_Sort
            CASE WHEN Src.Resolved_ICB_Code = 'QWE' THEN 'SWL' ELSE 'Non-SWL' END,
            CASE WHEN Src.Status = 'Active' THEN 1 ELSE 0 END,
            Src.Open_Date,
            Src.Close_Date,
            ISNULL(Src.Open_Date, '1900-01-01'),  -- Valid_From
            '9999-12-31',                         -- Valid_To
            1,                                    -- Is_Current
            'NHS ODS',
            SUSER_SNAME(),
            GETDATE()
        FROM #SourceResolved Src
        LEFT JOIN [Analytics].[tbl_Dim_GPPractice] Dim
            ON Src.Practice_Code = Dim.GPPractice_Code
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
        BEGIN TRY
            SET IDENTITY_INSERT [Analytics].[tbl_Dim_GPPractice] OFF;
        END TRY
        BEGIN CATCH
            -- No-op: ensure original ETL error is returned.
        END CATCH
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

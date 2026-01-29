USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('[Analytics].[sp_Load_Dim_Patient]', 'P') IS NOT NULL
    DROP PROCEDURE [Analytics].[sp_Load_Dim_Patient];
GO

/**
Script Name:   08_Load_Dim_Patient.sql
Description:   Type 1 load for Dim_Patient using latest demographics from Unified SUS materialised tables.
               Attributes: LSOA, GP Practice, Gender, Ethnicity (current state only).
               Opt-in dimension: run this procedure explicitly when required.
Author:        Sridhar Peddi
Created:       2026-01-26

Change Log:
  2026-01-26  Sridhar Peddi    Initial creation
**/
CREATE PROCEDURE [Analytics].[sp_Load_Dim_Patient]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ProcessName VARCHAR(100) = 'Load_Dim_Patient';
    DECLARE @BatchID INT = NULL;
    DECLARE @TableName VARCHAR(100) = 'Analytics.tbl_Dim_Patient';
    DECLARE @StartTime DATETIME2 = GETDATE();
    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsUpdated INT = 0;
    DECLARE @RowsAffected INT = 0;
    DECLARE @ErrorMessage NVARCHAR(4000);

    PRINT '========================================';
    PRINT 'Starting Dimension Load: Dim_Patient (Type 1)';
    PRINT 'Timestamp: ' + CONVERT(VARCHAR, @StartTime, 121);
    PRINT '========================================';

    BEGIN TRY
        EXEC [Analytics].[sp_Start_ETL_Batch]
            @BatchName = @ProcessName,
            @BatchID = @BatchID OUTPUT;

        PRINT 'Batch ID: ' + CAST(@BatchID AS VARCHAR);

        DECLARE @MergeActions TABLE (ActionName NVARCHAR(10));

        ;WITH SourceUnion AS (
            SELECT
                TRY_CAST(SRC.SK_PatientID AS BIGINT) AS SK_PatientID,
                CAST(SRC.End_Date_Hospital_Provider_Spell AS DATE) AS Activity_Date,
                NULLIF(LTRIM(RTRIM(SRC.Gender_Code)), '') AS Gender_Code,
                NULLIF(LTRIM(RTRIM(SRC.Ethnic_Category_Code)), '') AS Ethnic_Category_Code,
                NULLIF(LTRIM(RTRIM(SRC.dv_LSOACode)), '') AS LSOA_Code,
                NULLIF(LTRIM(RTRIM(SRC.GP_Practice_Code_Original_Data)), '') AS GP_Practice_Code
            FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active] SRC
            WHERE SRC.SK_PatientID IS NOT NULL

            UNION ALL

            SELECT
                TRY_CAST(SRC.SK_PatientID AS BIGINT) AS SK_PatientID,
                CAST(SRC.Appointment_Date AS DATE) AS Activity_Date,
                NULLIF(LTRIM(RTRIM(SRC.Gender_Code)), '') AS Gender_Code,
                NULLIF(LTRIM(RTRIM(SRC.Ethnic_Category_Code)), '') AS Ethnic_Category_Code,
                NULLIF(LTRIM(RTRIM(SRC.dv_LSOA)), '') AS LSOA_Code,
                NULLIF(LTRIM(RTRIM(SRC.GP_Practice_Code_Original_Data)), '') AS GP_Practice_Code
            FROM [Data_Lab_SWL].[Unified].[tbl_OP_EncounterDenormalised_Active] SRC
            WHERE SRC.SK_PatientID IS NOT NULL

            UNION ALL

            SELECT
                TRY_CAST(SRC.SK_PatientID AS BIGINT) AS SK_PatientID,
                CAST(SRC.Arrival_Date AS DATE) AS Activity_Date,
                NULLIF(LTRIM(RTRIM(SRC.Gender_Code)), '') AS Gender_Code,
                NULLIF(LTRIM(RTRIM(SRC.Ethnic_Category_Code)), '') AS Ethnic_Category_Code,
                NULLIF(LTRIM(RTRIM(SRC.dv_LSOA)), '') AS LSOA_Code,
                NULLIF(LTRIM(RTRIM(COALESCE(SRC.GP_Practice_Code_Original_Data, SRC.GP_Practice_Code))), '') AS GP_Practice_Code
            FROM [Data_Lab_SWL].[Unified].[tbl_ED_EncounterDenormalised_Active] SRC
            WHERE SRC.SK_PatientID IS NOT NULL
        ),
        Ranked AS (
            SELECT
                SU.*,
                ROW_NUMBER() OVER (
                    PARTITION BY SU.SK_PatientID
                    ORDER BY COALESCE(SU.Activity_Date, CAST('1900-01-01' AS DATE)) DESC
                ) AS RowNum
            FROM SourceUnion SU
            WHERE SU.SK_PatientID IS NOT NULL
              AND SU.SK_PatientID > 0
        ),
        SourceLatest AS (
            SELECT
                SK_PatientID,
                Gender_Code,
                Ethnic_Category_Code,
                LSOA_Code,
                GP_Practice_Code
            FROM Ranked
            WHERE RowNum = 1
        ),
        SourceEnriched AS (
            SELECT
                S.SK_PatientID,
                S.Gender_Code,
                G.Gender AS Gender_Description,
                S.Ethnic_Category_Code,
                E.EthnicityDesc AS Ethnicity_Description,
                S.LSOA_Code,
                S.GP_Practice_Code,
                GP.GPPractice_Name,
                GP.PCN_Code,
                GP.ICB_Code
            FROM SourceLatest S
            LEFT JOIN [Analytics].[vw_Dim_Gender] G
                ON S.Gender_Code = G.GenderCode
            LEFT JOIN [Analytics].[vw_Dim_Ethnicity] E
                ON E.EthnicityCode =
                    CASE
                        WHEN LTRIM(RTRIM(S.Ethnic_Category_Code)) = '99' THEN '99'
                        WHEN LTRIM(RTRIM(S.Ethnic_Category_Code)) = 'Z' THEN 'Z'
                        ELSE LEFT(LTRIM(RTRIM(S.Ethnic_Category_Code)), 1)
                    END
            LEFT JOIN [Analytics].[tbl_Dim_GPPractice] GP
                ON S.GP_Practice_Code = GP.GPPractice_Code
               AND GP.Is_Current = 1
        )
        MERGE [Analytics].[tbl_Dim_Patient] AS T
        USING SourceEnriched AS S
            ON T.SK_PatientID = S.SK_PatientID
        WHEN MATCHED AND T.SK_PatientID <> -1 THEN
            UPDATE SET
                T.Gender_Code = S.Gender_Code,
                T.Gender_Description = S.Gender_Description,
                T.Ethnicity_Code = S.Ethnic_Category_Code,
                T.Ethnicity_Description = S.Ethnicity_Description,
                T.LSOA_Code = S.LSOA_Code,
                T.GP_Practice_Code = S.GP_Practice_Code,
                T.GP_Practice_Name = S.GPPractice_Name,
                T.PCN_Code = S.PCN_Code,
                T.ICB_Code = S.ICB_Code,
                T.ETL_LoadDateTime = GETDATE()
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                SK_PatientID,
                Gender_Code,
                Gender_Description,
                Ethnicity_Code,
                Ethnicity_Description,
                LSOA_Code,
                GP_Practice_Code,
                GP_Practice_Name,
                PCN_Code,
                ICB_Code,
                ETL_LoadDateTime
            )
            VALUES (
                S.SK_PatientID,
                S.Gender_Code,
                S.Gender_Description,
                S.Ethnic_Category_Code,
                S.Ethnicity_Description,
                S.LSOA_Code,
                S.GP_Practice_Code,
                S.GPPractice_Name,
                S.PCN_Code,
                S.ICB_Code,
                GETDATE()
            )
        OUTPUT $action INTO @MergeActions;

        SELECT @RowsInserted = COUNT(*) FROM @MergeActions WHERE ActionName = 'INSERT';
        SELECT @RowsUpdated = COUNT(*) FROM @MergeActions WHERE ActionName = 'UPDATE';
        SET @RowsAffected = @RowsInserted + @RowsUpdated;

        EXEC [Analytics].[sp_Log_Table_Load]
            @BatchID = @BatchID,
            @TableName = @TableName,
            @LoadType = 'Type 1 Merge',
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
                @LoadType = 'Type 1 Merge',
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
    PRINT 'Completed Dimension Load: Dim_Patient';
    PRINT '========================================';
END
GO

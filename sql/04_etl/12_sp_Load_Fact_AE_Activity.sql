

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('[Analytics].[sp_Load_Fact_AE_Activity]', 'P') IS NOT NULL
DROP PROCEDURE [Analytics].[sp_Load_Fact_AE_Activity];
GO

/**
Script Name:   12_sp_Load_Fact_AE_Activity.sql
Description:   ETL Procedure to load AE Activity Fact Table.
Author:        Sridhar Peddi
Created:       2026-01-09

Change Log:
  2026-01-09  Sridhar Peddi    Initial creation
  2026-01-09  Sridhar Peddi    Add date parameters for dev window control
**/
CREATE PROCEDURE [Analytics].[sp_Load_Fact_AE_Activity]
    @FromDate DATE = NULL,
    @ToDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ETL_Start DATETIME2 = CURRENT_TIMESTAMP;
    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsDeleted INT = 0;
    DECLARE @BatchName VARCHAR(100) = 'Fact_AE_Activity';
    DECLARE @BatchID INT = NULL;
    DECLARE @ToDateActual DATE = ISNULL(@ToDate, [Analytics].[fn_SUS_Published_Cutoff_Date](NULL));
    DECLARE @FromDateActual DATE;

    SET @ToDateActual = ISNULL(@ToDateActual, CAST(GETDATE() AS DATE));
    SET @FromDateActual = ISNULL(
        @FromDate,
        DATEADD(MONTH, -5, DATEFROMPARTS(YEAR(@ToDateActual), MONTH(@ToDateActual), 1))
    );

    IF @ToDateActual < @FromDateActual
    BEGIN
        RAISERROR('ToDate must be on or after FromDate.', 16, 1);
        RETURN;
    END

    BEGIN TRY
        EXEC [Analytics].[sp_Start_ETL_Batch]
            @BatchName = @BatchName,
            @BatchID = @BatchID OUTPUT;

        PRINT 'Starting Load: [Analytics].[tbl_Fact_AE_Activity]';
        PRINT 'Load window: ' + CONVERT(VARCHAR(10), @FromDateActual, 120)
            + ' to ' + CONVERT(VARCHAR(10), @ToDateActual, 120);

        ;WITH SourceKeys AS (
            SELECT DISTINCT SRC.SK_EncounterID
            FROM [Data_Lab_SWL].[Unified].[tbl_ED_EncounterDenormalised_Active] SRC
            WHERE SRC.Arrival_Date >= @FromDateActual
              AND SRC.Arrival_Date < DATEADD(DAY, 1, @ToDateActual)
        )
        DELETE f
        FROM [Analytics].[tbl_Fact_AE_Activity] f
        INNER JOIN SourceKeys s ON s.SK_EncounterID = f.SK_EncounterID;

        SET @RowsDeleted = @@ROWCOUNT;
        PRINT 'Rows Deleted (window): ' + CAST(@RowsDeleted AS VARCHAR(20));

        INSERT INTO [Analytics].[tbl_Fact_AE_Activity] (
            [SK_EncounterID],
            [SK_PatientID],
            [SK_DateArrivalID],
            [SK_DateDepartureID],
            [Arrival_Date],
            [Departure_Date],
            [SK_Age_BandID],
            [SK_GenderID],
            [SK_EthnicityID],
            [SK_ProviderID],
            [SK_LSOA_ID],
            [LSOA_Code],
            [SK_SpecialtyID],
            [SK_HRG_ID],
            [SK_DiagnosisID],
            [SK_ProcedureID],
            [SK_CommissionerID],
            [SK_GPPracticeID],
            [SK_PCN_ID],
            [SK_POD_ID],
            
            -- AE Specific
            [SK_Attendance_DisposalID],

            -- Measures
            [Attendances],
            [Time_In_Department_Mins],
            [Time_To_Initial_Assessment_Mins],
            [Total_Cost],
            
            -- Flags
            [Is_4Hour_Breach],
            [Is_12Hour_Breach],
            [Is_Admitted],

            -- Codes
            [Arrival_Mode_Code],
            [Attendance_Category_Code],
            [Referral_Source_Code],
            [Department_Type_Code],

            [ETL_LoadDateTime]
        )
        SELECT 
            SRC.SK_EncounterID AS [SK_EncounterID],
            ISNULL(SRC.SK_PatientID, -1) AS [SK_PatientID],
            ISNULL(D_Arr.SK_Date, -1) AS [SK_DateArrivalID],
            ISNULL(D_Dep.SK_Date, -1) AS [SK_DateDepartureID],
            COALESCE(CAST(SRC.Arrival_Date AS DATE), CAST('1900-01-01' AS DATE)) AS [Arrival_Date],
            TRY_CAST(SRC.EM_Departure_Date AS DATE) AS [Departure_Date],
            ISNULL(AB.Age, 255) AS [SK_Age_BandID],
            COALESCE(CAST(G.SK_GenderID AS INT), -1) AS [SK_GenderID],
            COALESCE(CAST(E.SK_EthnicityID AS INT), -1) AS [SK_EthnicityID],
            COALESCE(CAST(Pr.SK_ProviderID AS INT), -1) AS [SK_ProviderID],
            COALESCE(CAST(LSOA.SK_LSOA_ID AS INT), -1) AS [SK_LSOA_ID],
            NULLIF(LTRIM(RTRIM(SRC.dv_LSOA)), '') AS [LSOA_Code],
            
            -1 AS [SK_SpecialtyID],
            COALESCE(CAST(HRG.SK_HRGID AS INT), -1) AS [SK_HRG_ID],
            NULL AS [SK_DiagnosisID],
            NULL AS [SK_ProcedureID],
            
            COALESCE(CAST(Comm.SK_CommissionerID AS INT), -1) AS [SK_CommissionerID],
            COALESCE(CAST(GP.SK_GPPracticeID AS INT), -1) AS [SK_GPPracticeID],
            COALESCE(CAST(PCN.SK_PCNID AS INT), -1) AS [SK_PCN_ID],
            COALESCE(CAST(POD.SK_PodID AS INT), -1) AS [SK_POD_ID],

            -- AE Specific
            COALESCE(CAST(Disp.SK_AttendanceDisposalID AS INT), -1) AS [SK_Attendance_DisposalID],

            -- Measures
            1 AS [Attendances],
            TRY_CAST(SRC.EM_Duration_Time AS INT) AS [Time_In_Department_Mins],
            CASE
                WHEN SRC.dv_AE_Arrival_DateTime IS NOT NULL
                     AND SRC.dv_EM_Initial_Assessment_Date IS NOT NULL
                THEN DATEDIFF(MINUTE, SRC.dv_AE_Arrival_DateTime, SRC.dv_EM_Initial_Assessment_Date)
                ELSE NULL
            END AS [Time_To_Initial_Assessment_Mins],
            CAST(SRC.PbR_Final_Tariff AS DECIMAL(12,2)) AS [Total_Cost],

            -- Logic: Breach Flags
            CASE WHEN TRY_CAST(SRC.EM_Duration_Time AS INT) > 240 THEN 1 ELSE 0 END AS [Is_4Hour_Breach],
            CASE WHEN TRY_CAST(SRC.EM_Duration_Time AS INT) > 720 THEN 1 ELSE 0 END AS [Is_12Hour_Breach],
            CASE
                WHEN Disp.Attendance_Disposal_Description LIKE '%Admitted%' THEN 1
                ELSE 0
            END AS [Is_Admitted],

            -- Codes
            CAST(SRC.EM_Mode_of_Arrival AS VARCHAR(2)) AS [Arrival_Mode_Code],
            CAST(SRC.EM_Attendance_Category AS VARCHAR(2)) AS [Attendance_Category_Code],
            CAST(SRC.EM_Referral_Source AS VARCHAR(2)) AS [Referral_Source_Code],
            CAST(SRC.EM_Department_Type AS VARCHAR(2)) AS [Department_Type_Code],

            @ETL_Start AS [ETL_LoadDateTime]

    FROM [Data_Lab_SWL].[Unified].[tbl_ED_EncounterDenormalised_Active] SRC
    -- LEFT JOIN [Analytics].[tbl_Dim_Patient] P ON SRC.SK_PatientID = P.SK_PatientID
    LEFT JOIN [Analytics].[vw_Dim_Date] D_Arr ON CAST(SRC.Arrival_Date AS DATE) = D_Arr.FullDate
    LEFT JOIN [Analytics].[vw_Dim_Date] D_Dep ON CAST(SRC.EM_Departure_Date AS DATE) = D_Dep.FullDate
    LEFT JOIN [Analytics].[vw_Dim_Age_Band] AB ON SRC.Age_At_CDS_Activity_Date = AB.Age
    LEFT JOIN [Analytics].[vw_Dim_Gender] G ON SRC.Gender_Code = G.GenderCode
    LEFT JOIN [Analytics].[vw_Dim_Ethnicity] E
        ON E.EthnicityCode =
            CASE
                WHEN LTRIM(RTRIM(SRC.Ethnic_Category_Code)) = '99' THEN '99'
                WHEN LTRIM(RTRIM(SRC.Ethnic_Category_Code)) = 'Z' THEN 'Z'
                ELSE LEFT(LTRIM(RTRIM(SRC.Ethnic_Category_Code)), 1)
            END
    LEFT JOIN [Analytics].[vw_Dim_Provider] Pr ON SRC.Organisation_Code_Code_of_Provider = Pr.Provider_Code
    LEFT JOIN [Analytics].[vw_Dim_LSOA] LSOA
        ON LSOA.LSOA_Code = NULLIF(LTRIM(RTRIM(SRC.dv_LSOA)), '')

    LEFT JOIN [Analytics].[vw_Dim_HRG] HRG ON SRC.Core_HRG = HRG.HRGCode

    LEFT JOIN [Analytics].[tbl_Dim_Commissioner] Comm ON SRC.Organisation_Code_Code_of_Commissioner = Comm.Commissioner_Code
    LEFT JOIN [Analytics].[tbl_Dim_GPPractice] GP ON SRC.GP_Practice_Code_Original_Data = GP.GPPractice_Code
    LEFT JOIN [Analytics].[tbl_Dim_PCN] PCN ON GP.PCN_Code = PCN.PCN_Code
    LEFT JOIN [Analytics].[tbl_Dim_POD] POD ON POD.POD_Code = 'AE'

    LEFT JOIN [Analytics].[vw_Dim_Attendance_Disposal] Disp ON SRC.EM_Attendance_Disposal = Disp.Attendance_Disposal_Code

    WHERE SRC.Arrival_Date >= @FromDateActual
      AND SRC.Arrival_Date < DATEADD(DAY, 1, @ToDateActual)

        SET @RowsInserted = @@ROWCOUNT;
        PRINT 'Rows Inserted: ' + CAST(@RowsInserted AS VARCHAR(20));

        EXEC [Analytics].[sp_Log_Table_Load]
            @BatchID = @BatchID,
            @TableName = 'Analytics.tbl_Fact_AE_Activity',
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
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        PRINT 'Error Loading Fact AE: ' + @ErrorMessage;
        IF @BatchID IS NOT NULL
        BEGIN
            EXEC [Analytics].[sp_Log_Table_Load]
                @BatchID = @BatchID,
                @TableName = 'Analytics.tbl_Fact_AE_Activity',
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

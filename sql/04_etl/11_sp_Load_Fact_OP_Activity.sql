

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('[Analytics].[sp_Load_Fact_OP_Activity]', 'P') IS NOT NULL
DROP PROCEDURE [Analytics].[sp_Load_Fact_OP_Activity];
GO

/**
Script Name:   11_sp_Load_Fact_OP_Activity.sql
Description:   ETL Procedure to load Outpatient Activity Fact Table.
Author:        Sridhar Peddi
Created:       2026-01-09

Change Log:
  2026-01-09  Sridhar Peddi    Initial creation
  2026-01-09  Sridhar Peddi    Add date parameters for dev window control
  2026-01-26  Sridhar Peddi    Add Is_FirstAttendance flag
  2026-01-27  Sridhar Peddi    Deduplicate source and avoid @@ROWCOUNT after recovery
**/
CREATE PROCEDURE [Analytics].[sp_Load_Fact_OP_Activity]
    @FromDate DATE = NULL,
    @ToDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ETL_Start DATETIME2 = CURRENT_TIMESTAMP;
    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsDeleted INT = 0;
    DECLARE @RowsSkipped INT = 0;
    DECLARE @SourceRows INT = 0;
    DECLARE @BatchName VARCHAR(100) = 'Fact_OP_Activity';
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

        PRINT 'Starting Load: [Analytics].[tbl_Fact_OP_Activity]';
        PRINT 'Load window: ' + CONVERT(VARCHAR(10), @FromDateActual, 120)
            + ' to ' + CONVERT(VARCHAR(10), @ToDateActual, 120);

        IF OBJECT_ID('tempdb..#SourceFiltered') IS NOT NULL
            DROP TABLE #SourceFiltered;

        ;WITH SourceWindow AS (
            SELECT
                SRC.*,
                COALESCE(CAST(SRC.Appointment_Date AS DATE), CAST('1900-01-01' AS DATE)) AS Appointment_Date_Cast,
                TRY_CAST(SRC.Referral_Request_Received_Date AS DATE) AS Referral_Date,
                NULLIF(LTRIM(RTRIM(SRC.dv_LSOA)), '') AS LSOA_Code_Norm,
                NULLIF(LTRIM(RTRIM(SRC.GP_Practice_Code_Original_Data)), '') AS GP_Practice_Code_Norm,
                NULLIF(LTRIM(RTRIM(SRC.Treatment_Function_Code)), '') AS Treatment_Function_Code_Norm,
                NULLIF(LTRIM(RTRIM(SRC.Main_Specialty_Code)), '') AS Main_Specialty_Code_Norm,
                NULLIF(LTRIM(RTRIM(SRC.Source_of_Referral_for_Outpatients)), '') AS Referral_Source_Code_Norm,
                TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(SRC.Source_of_Referral_for_Outpatients)), '')) AS Referral_Source_Code_Int
            FROM [Data_Lab_SWL].[Unified].[tbl_OP_EncounterDenormalised_Active] SRC
            WHERE SRC.Appointment_Date >= @FromDateActual
              AND SRC.Appointment_Date < DATEADD(DAY, 1, @ToDateActual)
        ),
        SourceDeduped AS (
            SELECT
                SRC.*,
                ROW_NUMBER() OVER (
                    PARTITION BY SRC.SK_EncounterID, SRC.Appointment_Date_Cast
                    ORDER BY SRC.Appointment_Date DESC, SRC.Referral_Request_Received_Date DESC
                ) AS RowNum
            FROM SourceWindow SRC
        ),
        SourceFiltered AS (
            SELECT *
            FROM SourceDeduped
            WHERE RowNum = 1
        )
        SELECT *
        INTO #SourceFiltered
        FROM SourceFiltered;

        SELECT @SourceRows = COUNT(*) FROM #SourceFiltered;

        IF OBJECT_ID('tempdb..#Dim_Specialty_Map') IS NOT NULL
            DROP TABLE #Dim_Specialty_Map;
        SELECT
            ds.BK_SpecialtyCode,
            MIN(ds.SK_SpecialtyID) AS SK_SpecialtyID
        INTO #Dim_Specialty_Map
        FROM [Analytics].[vw_Dim_Specialty] ds
        WHERE ds.BK_SpecialtyCode IS NOT NULL
        GROUP BY ds.BK_SpecialtyCode;
        CREATE UNIQUE CLUSTERED INDEX IX_Dim_Specialty_Map_Code ON #Dim_Specialty_Map(BK_SpecialtyCode);

        IF OBJECT_ID('tempdb..#Dim_Referral_Source_Map_Norm') IS NOT NULL
            DROP TABLE #Dim_Referral_Source_Map_Norm;
        SELECT
            MIN(rs.SK_ReferralSourceID) AS SK_ReferralSourceID,
            NULLIF(LTRIM(RTRIM(rs.Referral_Source_Code)), '') AS Code_Norm
        INTO #Dim_Referral_Source_Map_Norm
        FROM [Analytics].[vw_Dim_Referral_Source] rs
        WHERE NULLIF(LTRIM(RTRIM(rs.Referral_Source_Code)), '') IS NOT NULL
        GROUP BY
            NULLIF(LTRIM(RTRIM(rs.Referral_Source_Code)), '');
        CREATE UNIQUE CLUSTERED INDEX IX_Dim_Referral_Source_Map_Norm ON #Dim_Referral_Source_Map_Norm(Code_Norm);

        IF OBJECT_ID('tempdb..#Dim_Referral_Source_Map_Int') IS NOT NULL
            DROP TABLE #Dim_Referral_Source_Map_Int;
        SELECT
            MIN(rs.SK_ReferralSourceID) AS SK_ReferralSourceID,
            TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(rs.Referral_Source_Code)), '')) AS Code_Int
        INTO #Dim_Referral_Source_Map_Int
        FROM [Analytics].[vw_Dim_Referral_Source] rs
        WHERE TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(rs.Referral_Source_Code)), '')) IS NOT NULL
        GROUP BY TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(rs.Referral_Source_Code)), ''));
        CREATE UNIQUE CLUSTERED INDEX IX_Dim_Referral_Source_Map_Int ON #Dim_Referral_Source_Map_Int(Code_Int);

        SELECT @RowsDeleted = COUNT(*)
        FROM [Analytics].[tbl_Fact_OP_Activity] f
        INNER JOIN #SourceFiltered s
            ON s.SK_EncounterID = f.SK_EncounterID
           AND s.Appointment_Date_Cast = f.Appointment_Date;

        DELETE f
        FROM [Analytics].[tbl_Fact_OP_Activity] f
        INNER JOIN #SourceFiltered s
            ON s.SK_EncounterID = f.SK_EncounterID
           AND s.Appointment_Date_Cast = f.Appointment_Date;
        PRINT 'Rows Deleted (window): ' + CAST(@RowsDeleted AS VARCHAR(20));

        DECLARE @InsertedKeys TABLE (SK_EncounterID BIGINT NOT NULL, Appointment_Date DATE NOT NULL);

        INSERT INTO [Analytics].[tbl_Fact_OP_Activity] (
            [SK_EncounterID],
            [SK_PatientID],
            [SK_DateAppointmentID],
            [SK_DateReferralID],
            [Appointment_Date],
            [Referral_Date],
            [SK_Age_BandID],
            [SK_GenderID],
            [SK_EthnicityID],
            [SK_ProviderID],
            [SK_LSOA_ID],
            [LSOA_Code],
            [SK_SpecialtyID],
            [SK_HRG_ID],
            [SK_ProcedureID],
            [SK_CommissionerID],
            [SK_GPPracticeID],
            [SK_PCN_ID],
            [SK_POD_ID],
            
            -- OP Specific
            [SK_Attendance_StatusID],
            [SK_Attendance_OutcomeID],
            [SK_Attendance_TypeID],
            [SK_DNA_IndicatorID],
            [SK_Priority_TypeID],
            [SK_Referral_SourceID],

            -- Measures
            [Appointments],
            [Total_Cost],
            [DNA_Count],
            [Is_FirstAttendance],
            [Referral_To_Appt_Days],
            [RTT_Wait_Weeks],

            -- Codes
            [Outcome_Code],
            [Priority_Code],
            [Clinic_Code],
            [Admin_Category_Code],

            [ETL_LoadDateTime]
        )
        OUTPUT inserted.SK_EncounterID, inserted.Appointment_Date INTO @InsertedKeys
        SELECT 
            SRC.SK_EncounterID AS [SK_EncounterID],
            ISNULL(SRC.SK_PatientID, -1) AS [SK_PatientID],
            ISNULL(D_Appt.SK_Date, -1) AS [SK_DateAppointmentID],
            ISNULL(D_Ref.SK_Date, -1) AS [SK_DateReferralID],
            SRC.Appointment_Date_Cast AS [Appointment_Date],
            SRC.Referral_Date AS [Referral_Date],
            ISNULL(AB.Age, -1) AS [SK_Age_BandID],
            COALESCE(CAST(G.SK_GenderID AS INT), -1) AS [SK_GenderID],
            COALESCE(CAST(E.SK_EthnicityID AS INT), -1) AS [SK_EthnicityID],
            COALESCE(CAST(Pr.SK_ProviderID AS INT), -1) AS [SK_ProviderID],
            COALESCE(CAST(LSOA.SK_LSOA_ID AS INT), -1) AS [SK_LSOA_ID],
            NULLIF(LTRIM(RTRIM(SRC.dv_LSOA)), '') AS [LSOA_Code],
            
            COALESCE(CAST(SpecTfc.SK_SpecialtyID AS INT), CAST(SpecMain.SK_SpecialtyID AS INT), -1) AS [SK_SpecialtyID],
            COALESCE(CAST(HRG.SK_HRGID AS INT), -1) AS [SK_HRG_ID],
            NULL AS [SK_ProcedureID],
            
            COALESCE(CAST(Comm.SK_CommissionerID AS INT), -1) AS [SK_CommissionerID],
            COALESCE(CAST(GP.SK_GPPracticeID AS INT), -1) AS [SK_GPPracticeID],
            COALESCE(CAST(PCN.SK_PCNID AS INT), -1) AS [SK_PCN_ID],
            COALESCE(CAST(POD.SK_PodID AS INT), -1) AS [SK_POD_ID],

            -- OP Specific
            COALESCE(CAST(AttStat.SK_AttendanceStatusID AS INT), -1) AS [SK_Attendance_StatusID],
            COALESCE(CAST(AttOut.SK_AttendanceOutcomeID AS INT), -1) AS [SK_Attendance_OutcomeID],
            COALESCE(CAST(AttTyp.SK_AttendanceTypeID AS INT), -1) AS [SK_Attendance_TypeID],
            COALESCE(CAST(DNA.SK_DNAIndicatorID AS INT), -1) AS [SK_DNA_IndicatorID],
            COALESCE(CAST(Prio.SK_PriorityTypeID AS INT), -1) AS [SK_Priority_TypeID],
            COALESCE(CAST(RefSrcNorm.SK_ReferralSourceID AS INT), CAST(RefSrcInt.SK_ReferralSourceID AS INT), -1) AS [SK_Referral_SourceID],

            -- Measures
            1 AS [Appointments],
            TRY_CAST(SRC.Pbr_Final_Tariff AS DECIMAL(12,2)) AS [Total_Cost],
            CASE WHEN SRC.Attended_Or_Did_Not_Attend IN ('3', 'DNA') THEN 1 ELSE 0 END AS [DNA_Count],
            CASE
                WHEN TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(SRC.First_Attendance)), '')) IN (1, 3) THEN 1
                ELSE 0
            END AS [Is_FirstAttendance],
            
            DATEDIFF(DAY, SRC.Referral_Request_Received_Date, SRC.Appointment_Date) AS [Referral_To_Appt_Days],
            CASE
                WHEN DATEDIFF(DAY, SRC.Referral_Request_Received_Date, SRC.Appointment_Date) BETWEEN 0 AND 6999
                    THEN TRY_CAST(DATEDIFF(DAY, SRC.Referral_Request_Received_Date, SRC.Appointment_Date) / 7.0 AS DECIMAL(5,2))
                ELSE NULL
            END AS [RTT_Wait_Weeks],

            -- Codes
            SRC.Outcome_of_Attendance AS [Outcome_Code],
            SRC.Priority_Type AS [Priority_Code],
            SRC.Clinic_Code AS [Clinic_Code],
            CAST(SRC.Administrative_Category AS VARCHAR(2)) AS [Admin_Category_Code],

            @ETL_Start AS [ETL_LoadDateTime]

        FROM #SourceFiltered SRC
        CROSS APPLY (
            SELECT [OP].[fn_GetPODType](
                SRC.Core_HRG,
                SRC.Attended_Or_Did_Not_Attend,
                SRC.First_Attendance,
                SRC.Main_Specialty_Code
            ) AS POD_Code
        ) PodCalc
        -- LEFT JOIN [Analytics].[tbl_Dim_Patient] P ON SRC.SK_PatientID = P.SK_PatientID
        LEFT JOIN [Analytics].[vw_Dim_Date] D_Appt ON CAST(SRC.Appointment_Date AS DATE) = D_Appt.FullDate
        LEFT JOIN [Analytics].[vw_Dim_Date] D_Ref ON CAST(SRC.Referral_Request_Received_Date AS DATE) = D_Ref.FullDate
        LEFT JOIN [Analytics].[vw_Dim_Age_Band] AB
            ON AB.Age =
                CASE
                    WHEN TRY_CONVERT(INT, SRC.Age) BETWEEN 0 AND 99
                        THEN TRY_CONVERT(INT, SRC.Age)
                    WHEN TRY_CONVERT(INT, SRC.Age) BETWEEN 100 AND 110
                        THEN 100
                    ELSE -1
                END
        LEFT JOIN [Analytics].[vw_Dim_Gender] G ON SRC.Gender_Code = G.GenderCode
        LEFT JOIN [Analytics].[vw_Dim_Ethnicity] E
            ON E.EthnicityCode =
                CASE
                    WHEN LTRIM(RTRIM(SRC.Ethnic_Category_Code)) = '99' THEN '99'
                    WHEN LTRIM(RTRIM(SRC.Ethnic_Category_Code)) = 'Z' THEN 'Z'
                    ELSE LEFT(LTRIM(RTRIM(SRC.Ethnic_Category_Code)), 1)
                END
        LEFT JOIN [Analytics].[vw_Dim_Provider] Pr
            ON Pr.Provider_Code =
                CASE
                    WHEN RIGHT(SRC.Organisation_Code_Code_of_Provider, 2) = '00'
                        THEN LEFT(SRC.Organisation_Code_Code_of_Provider, 3)
                    ELSE SRC.Organisation_Code_Code_of_Provider
                END
        LEFT JOIN [Analytics].[vw_Dim_LSOA] LSOA
            ON LSOA.LSOA_Code = SRC.LSOA_Code_Norm
        LEFT JOIN #Dim_Specialty_Map SpecTfc
            ON SpecTfc.BK_SpecialtyCode = SRC.Treatment_Function_Code_Norm
        LEFT JOIN #Dim_Specialty_Map SpecMain
            ON SpecMain.BK_SpecialtyCode = SRC.Main_Specialty_Code_Norm
        LEFT JOIN [Analytics].[vw_Dim_HRG] HRG ON SRC.Core_HRG = HRG.HRGCode
        
        LEFT JOIN [Analytics].[tbl_Dim_Commissioner] Comm
            ON Comm.Commissioner_Code =
                CASE
                    WHEN RIGHT(SRC.Organisation_Code_Code_of_Commissioner, 2) = '00'
                        THEN LEFT(SRC.Organisation_Code_Code_of_Commissioner, 3)
                    ELSE SRC.Organisation_Code_Code_of_Commissioner
                END
        LEFT JOIN [Analytics].[tbl_Dim_GPPractice] GP
            ON GP.GPPractice_Code = SRC.GP_Practice_Code_Norm
           AND GP.Is_Current = 1
        LEFT JOIN [Analytics].[tbl_Dim_PCN] PCN
            ON PCN.PCN_Code = GP.PCN_Code
           AND PCN.Is_Current = 1

        -- POD mapping (derived via OP.fn_GetPODType for materialised source tables)
        LEFT JOIN [Analytics].[tbl_Dim_POD] POD
            ON POD.POD_Code = UPPER(PodCalc.POD_Code)
           AND POD.POD_Dataset = 'OP'

        -- OP Specific Joins
        LEFT JOIN [Analytics].[vw_Dim_Attendance_Outcome] AttOut
            ON TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(SRC.Outcome_of_Attendance)), '')) =
               TRY_CONVERT(INT, AttOut.Attendance_Outcome_Code)
        LEFT JOIN [Analytics].[vw_Dim_Attendance_Status] AttStat
            ON NULLIF(LTRIM(RTRIM(SRC.Attended_Or_Did_Not_Attend)), '') =
               LTRIM(RTRIM(AttStat.Attendance_Status_Code))
        LEFT JOIN [Analytics].[vw_Dim_Attendance_Type] AttTyp
            ON TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(SRC.First_Attendance)), '')) =
               TRY_CONVERT(INT, AttTyp.Attendance_Type_Code)
        LEFT JOIN [Analytics].[vw_Dim_DNA_Indicator] DNA
            ON NULLIF(LTRIM(RTRIM(SRC.Attended_Or_Did_Not_Attend)), '') =
               LTRIM(RTRIM(DNA.DNA_Indicator_Code))
        LEFT JOIN [Analytics].[vw_Dim_Priority_Type] Prio
            ON TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(SRC.Priority_Type)), '')) =
               TRY_CONVERT(INT, Prio.Priority_Type_Code)
        LEFT JOIN #Dim_Referral_Source_Map_Norm RefSrcNorm
            ON RefSrcNorm.Code_Norm = SRC.Referral_Source_Code_Norm
        LEFT JOIN #Dim_Referral_Source_Map_Int RefSrcInt
            ON RefSrcInt.Code_Int = SRC.Referral_Source_Code_Int

        WHERE NOT EXISTS (
            SELECT 1
            FROM [Analytics].[tbl_Fact_OP_Activity] T
            WHERE T.SK_EncounterID = SRC.SK_EncounterID
              AND T.Appointment_Date = SRC.Appointment_Date_Cast
        )

        SELECT @RowsInserted = COUNT(*) FROM @InsertedKeys;
        SET @RowsSkipped = @SourceRows - @RowsInserted;
        PRINT 'Rows Inserted: ' + CAST(@RowsInserted AS VARCHAR(20));
        PRINT 'Rows Skipped (duplicate PK): ' + CAST(@RowsSkipped AS VARCHAR(20));

        EXEC [Analytics].[sp_Log_Table_Load]
            @BatchID = @BatchID,
            @TableName = 'Analytics.tbl_Fact_OP_Activity',
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
        PRINT 'Error Loading Fact OP: ' + @ErrorMessage;
        IF @ErrorMessage LIKE '%rowcount in the first query is not available%'
        BEGIN
            PRINT '[WARNING] Rowcount unavailable after connection recovery. Deriving counts from data and continuing.';

            ;WITH SourceWindow AS (
                SELECT
                    SRC.*,
                    COALESCE(CAST(SRC.Appointment_Date AS DATE), CAST('1900-01-01' AS DATE)) AS Appointment_Date_Cast
                FROM [Data_Lab_SWL].[Unified].[tbl_OP_EncounterDenormalised_Active] SRC
                WHERE SRC.Appointment_Date >= @FromDateActual
                  AND SRC.Appointment_Date < DATEADD(DAY, 1, @ToDateActual)
            ),
            SourceDeduped AS (
                SELECT
                    SRC.*,
                    ROW_NUMBER() OVER (
                        PARTITION BY SRC.SK_EncounterID, SRC.Appointment_Date_Cast
                        ORDER BY SRC.Appointment_Date DESC, SRC.Referral_Request_Received_Date DESC
                    ) AS RowNum
                FROM SourceWindow SRC
            ),
            SourceFiltered AS (
                SELECT *
                FROM SourceDeduped
                WHERE RowNum = 1
            )
            SELECT @SourceRows = COUNT(*) FROM SourceFiltered;

            SELECT @RowsInserted = COUNT(*)
            FROM [Analytics].[tbl_Fact_OP_Activity] f
            INNER JOIN SourceFiltered s
                ON s.SK_EncounterID = f.SK_EncounterID
               AND s.Appointment_Date_Cast = f.Appointment_Date;

            SET @RowsSkipped = @SourceRows - @RowsInserted;

            IF @BatchID IS NOT NULL
            BEGIN
                EXEC [Analytics].[sp_Log_Table_Load]
                    @BatchID = @BatchID,
                    @TableName = 'Analytics.tbl_Fact_OP_Activity',
                    @LoadType = 'Full',
                    @RowsAffected = @RowsInserted,
                    @RowsFailed = 0,
                    @Status = 'Warning',
                    @ErrorMessage = @ErrorMessage;

                EXEC [Analytics].[sp_End_ETL_Batch]
                    @BatchID = @BatchID,
                    @Status = 'Success',
                    @RowsInserted = @RowsInserted,
                    @RowsUpdated = 0,
                    @RowsDeleted = @RowsDeleted,
                    @RowsFailed = 0,
                    @ErrorMessage = @ErrorMessage;
            END

            RETURN;
        END
        IF @BatchID IS NOT NULL
        BEGIN
            EXEC [Analytics].[sp_Log_Table_Load]
                @BatchID = @BatchID,
                @TableName = 'Analytics.tbl_Fact_OP_Activity',
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

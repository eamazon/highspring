

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('[Analytics].[sp_Load_Fact_IP_Activity]', 'P') IS NOT NULL
DROP PROCEDURE [Analytics].[sp_Load_Fact_IP_Activity];
GO

/**
Script Name:   10_sp_Load_Fact_IP_Activity.sql
Description:   ETL Procedure to load Inpatient Activity Fact Table.
Author:        Sridhar Peddi
Created:       2026-01-09

Change Log:
  2026-01-09  Sridhar Peddi    Initial creation
  2026-01-09  Sridhar Peddi    Add date parameters for dev window control
  2026-01-27  Sridhar Peddi    Skip duplicate PK rows to allow load to complete
  2026-01-27  Sridhar Peddi    Avoid @@ROWCOUNT after connection recovery
**/
CREATE PROCEDURE [Analytics].[sp_Load_Fact_IP_Activity]
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
    DECLARE @BatchName VARCHAR(100) = 'Fact_IP_Activity';
    DECLARE @BatchID INT = NULL;
    DECLARE @ToDateActual DATE = ISNULL(@ToDate, [Analytics].[fn_SUS_Published_Cutoff_Date](NULL));
    DECLARE @FromDateActual DATE;
    DECLARE @NegativeLOSCount INT = 0;
    DECLARE @DuplicateKeyCount INT = 0;
    DECLARE @DQMessage NVARCHAR(4000);

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

        PRINT 'Starting Load: [Analytics].[tbl_Fact_IP_Activity]';
        PRINT 'Load window: ' + CONVERT(VARCHAR(10), @FromDateActual, 120)
            + ' to ' + CONVERT(VARCHAR(10), @ToDateActual, 120);

        SELECT @NegativeLOSCount = COUNT(1)
        FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active] SRC
        WHERE SRC.End_Date_Hospital_Provider_Spell >= @FromDateActual
          AND SRC.End_Date_Hospital_Provider_Spell < DATEADD(DAY, 1, @ToDateActual)
          AND TRY_CAST(SRC.dv_LengthOfStay_Gross AS INT) < 0;

        IF @NegativeLOSCount > 0
        BEGIN
            SET @DQMessage = 'Discarded ' + CAST(@NegativeLOSCount AS VARCHAR(20))
                + ' rows with negative Length_Of_Stay (dv_LengthOfStay_Gross).';
            PRINT @DQMessage;

            INSERT INTO [Analytics].[tbl_ETL_Error_Details] (
                Batch_ID,
                Load_ID,
                Source_Table,
                Target_Table,
                Failed_Row_Data,
                Business_Key,
                Error_Message,
                Error_Type
            )
            VALUES (
                @BatchID,
                NULL,
                'Data_Lab_SWL.Unified.tbl_IP_EncounterDenormalised_Active',
                'Analytics.tbl_Fact_IP_Activity',
                CONCAT('{"FromDate":"', CONVERT(VARCHAR(10), @FromDateActual, 120),
                       '","ToDate":"', CONVERT(VARCHAR(10), @ToDateActual, 120),
                       '","NegativeLOSCount":', @NegativeLOSCount, '}'),
                'NEGATIVE_LOS',
                @DQMessage,
                'DataQuality'
            );
        END

        SELECT @DuplicateKeyCount = SUM(d.DuplicateRows)
        FROM (
            SELECT COUNT(1) - 1 AS DuplicateRows
            FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active] SRC
            WHERE SRC.End_Date_Hospital_Provider_Spell >= @FromDateActual
              AND SRC.End_Date_Hospital_Provider_Spell < DATEADD(DAY, 1, @ToDateActual)
              AND (TRY_CAST(SRC.dv_LengthOfStay_Gross AS INT) IS NULL
                   OR TRY_CAST(SRC.dv_LengthOfStay_Gross AS INT) >= 0)
            GROUP BY SRC.SK_EncounterID,
                     COALESCE(CAST(SRC.End_Date_Hospital_Provider_Spell AS DATE), CAST('1900-01-01' AS DATE))
            HAVING COUNT(1) > 1
        ) d;

        IF @DuplicateKeyCount > 0
        BEGIN
            SET @DQMessage = 'Discarded ' + CAST(@DuplicateKeyCount AS VARCHAR(20))
                + ' duplicate rows for (SK_EncounterID, Discharge_Date).';
            PRINT @DQMessage;

            INSERT INTO [Analytics].[tbl_ETL_Error_Details] (
                Batch_ID,
                Load_ID,
                Source_Table,
                Target_Table,
                Failed_Row_Data,
                Business_Key,
                Error_Message,
                Error_Type
            )
            VALUES (
                @BatchID,
                NULL,
                'Data_Lab_SWL.Unified.tbl_IP_EncounterDenormalised_Active',
                'Analytics.tbl_Fact_IP_Activity',
                CONCAT('{"FromDate":"', CONVERT(VARCHAR(10), @FromDateActual, 120),
                       '","ToDate":"', CONVERT(VARCHAR(10), @ToDateActual, 120),
                       '","DuplicateKeyCount":', @DuplicateKeyCount, '}'),
                'DUPLICATE_PK',
                @DQMessage,
                'DataQuality'
            );
        END

        IF OBJECT_ID('tempdb..#SourceFiltered') IS NOT NULL
            DROP TABLE #SourceFiltered;

        ;WITH SourceWindow AS (
            SELECT
                SRC.*,
                COALESCE(CAST(SRC.Start_Date_Hospital_Provider_Spell AS DATE), CAST('1900-01-01' AS DATE)) AS Admission_Date,
                COALESCE(CAST(SRC.End_Date_Hospital_Provider_Spell AS DATE), CAST('1900-01-01' AS DATE)) AS Discharge_Date,
                TRY_CAST(SRC.dv_LengthOfStay_Gross AS INT) AS Length_Of_Stay
            FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active] SRC
            WHERE SRC.End_Date_Hospital_Provider_Spell >= @FromDateActual
              AND SRC.End_Date_Hospital_Provider_Spell < DATEADD(DAY, 1, @ToDateActual)
        ),
        SourceDeduped AS (
            SELECT
                SRC.*,
                ROW_NUMBER() OVER (
                    PARTITION BY SRC.SK_EncounterID, SRC.Discharge_Date
                    ORDER BY SRC.Start_Date_Hospital_Provider_Spell DESC, SRC.End_Date_Hospital_Provider_Spell DESC
                ) AS RowNum
            FROM SourceWindow SRC
            WHERE SRC.Length_Of_Stay IS NULL OR SRC.Length_Of_Stay >= 0
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

        SELECT @RowsDeleted = COUNT(*)
        FROM [Analytics].[tbl_Fact_IP_Activity] f
        INNER JOIN #SourceFiltered s
            ON s.SK_EncounterID = f.SK_EncounterID
           AND s.Discharge_Date = f.Discharge_Date;

        DELETE f
        FROM [Analytics].[tbl_Fact_IP_Activity] f
        INNER JOIN #SourceFiltered s
            ON s.SK_EncounterID = f.SK_EncounterID
           AND s.Discharge_Date = f.Discharge_Date;
        PRINT 'Rows Deleted (window): ' + CAST(@RowsDeleted AS VARCHAR(20));

        -- 2. Insert Logic
        DECLARE @InsertedKeys TABLE (SK_EncounterID BIGINT NOT NULL, Discharge_Date DATE NOT NULL);

        INSERT INTO [Analytics].[tbl_Fact_IP_Activity] (
            [SK_EncounterID],
            [SK_PatientID],
            [SK_DateAdmissionID],
            [SK_DateDischargeID],
            [Admission_Date],
            [Discharge_Date],
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
            
            -- IP Specific
            [SK_Admission_MethodID],
            [SK_Admission_SourceID],
            [SK_Discharge_MethodID],
            [SK_Discharge_DestinationID],
            [SK_IP_Patient_ClassificationID],

            -- Measures
            [Admissions],
            [Length_Of_Stay],
            [Total_Cost],
            [Delayed_Discharge_Days],
            [Excess_Bed_Days],
            [Excess_Bed_Days_Cost],
            [Palliative_Care_Days],
            [Rehab_Days],
            [Base_Tariff],
            [MFF_Multiplier],

            [ETL_LoadDateTime]
        )
        OUTPUT inserted.SK_EncounterID, inserted.Discharge_Date INTO @InsertedKeys
        SELECT 
            SRC.SK_EncounterID AS [SK_EncounterID],
            -- Dimensions (Use ISNULL to map to Unknown SK = -1 usually, or handle mapped logic)
            -- Assuming Dimensions have 'Unknown' row at SK=-1 or 0 handling via ISNULL
            ISNULL(SRC.SK_PatientID, -1) AS [SK_PatientID],
            ISNULL(D_Adm.SK_Date, -1) AS [SK_DateAdmissionID],
            ISNULL(D_Dis.SK_Date, -1) AS [SK_DateDischargeID],
            SRC.Admission_Date AS [Admission_Date],
            SRC.Discharge_Date AS [Discharge_Date],
            ISNULL(AB.Age, 255) AS [SK_Age_BandID],
            COALESCE(CAST(G.SK_GenderID AS INT), -1) AS [SK_GenderID],
            COALESCE(CAST(E.SK_EthnicityID AS INT), -1) AS [SK_EthnicityID],
            COALESCE(CAST(Pr.SK_ProviderID AS INT), -1) AS [SK_ProviderID],
            COALESCE(CAST(LSOA.SK_LSOA_ID AS INT), -1) AS [SK_LSOA_ID],
            NULLIF(LTRIM(RTRIM(SRC.dv_LSOACode)), '') AS [LSOA_Code],
            
            COALESCE(CAST(S.SK_SpecialtyID AS INT), -1) AS [SK_SpecialtyID],
            COALESCE(CAST(HRG.SK_HRGID AS INT), -1) AS [SK_HRG_ID],
            NULL AS [SK_DiagnosisID],
            NULL AS [SK_ProcedureID],
            
            COALESCE(CAST(Comm.SK_CommissionerID AS INT), -1) AS [SK_CommissionerID],
            COALESCE(CAST(GP.SK_GPPracticeID AS INT), -1) AS [SK_GPPracticeID],
            COALESCE(CAST(PCN.SK_PCNID AS INT), -1) AS [SK_PCN_ID],
            COALESCE(CAST(POD.SK_PodID AS INT), -1) AS [SK_POD_ID],

            -- IP Specific
            COALESCE(CAST(AdmMet.SK_AdmissionMethodID AS INT), -1) AS [SK_Admission_MethodID],
            COALESCE(CAST(AdmSrc.SK_AdmissionSourceID AS INT), -1) AS [SK_Admission_SourceID],
            COALESCE(CAST(DisMet.SK_DischargeMethodID AS INT), -1) AS [SK_Discharge_MethodID],
            COALESCE(CAST(DisDest.SK_DischargeDestinationID AS INT), -1) AS [SK_Discharge_DestinationID],
            COALESCE(CAST(PatClass.SK_PatientClassificationID AS INT), -1) AS [SK_IP_Patient_ClassificationID],

            -- Measures
            1 AS [Admissions],
            SRC.Length_Of_Stay AS [Length_Of_Stay],
            CAST(SRC.Pbr_Final_Tariff AS DECIMAL(12,2)) AS [Total_Cost],
            TRY_CAST(SRC.dv_DelayedDischargeDays AS INT) AS [Delayed_Discharge_Days],
            TRY_CAST(SRC.dv_ExcessBedDays AS INT) AS [Excess_Bed_Days],
            CAST(SRC.dv_ExcessBedDays_Cost AS DECIMAL(12,2)) AS [Excess_Bed_Days_Cost],
            TRY_CAST(SRC.dv_SpecialistPalliativeCareDays AS INT) AS [Palliative_Care_Days],
            TRY_CAST(SRC.dv_RehabDays AS INT) AS [Rehab_Days],
            CAST(SRC.dv_Base_Cost AS DECIMAL(12,2)) AS [Base_Tariff],
            CAST(SRC.dv_MFF_Index_Applied AS DECIMAL(5,4)) AS [MFF_Multiplier],

            @ETL_Start AS [ETL_LoadDateTime]

    FROM #SourceFiltered SRC
    CROSS APPLY (
        SELECT [Data_Lab_SWL].[IP].[GetPodType](
            SRC.Admission_Method_Hospital_Provider_Spell,
            SRC.Patient_Classification,
            SRC.Intended_Management,
            SRC.Admission_Date,
            SRC.Discharge_Date,
            SRC.Spell_Core_HRG
        ) AS POD_Code
    ) PodCalc

        -- LEFT JOIN [Analytics].[tbl_Dim_Patient] P ON SRC.SK_PatientID = P.SK_PatientID
        LEFT JOIN [Analytics].[vw_Dim_Date] D_Adm ON CAST(SRC.Start_Date_Hospital_Provider_Spell AS DATE) = D_Adm.FullDate
        LEFT JOIN [Analytics].[vw_Dim_Date] D_Dis ON CAST(SRC.End_Date_Hospital_Provider_Spell AS DATE) = D_Dis.FullDate
        LEFT JOIN [Analytics].[vw_Dim_Age_Band] AB ON SRC.Age_At_CDS_Activity_Date = AB.Age
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
            ON LSOA.LSOA_Code = NULLIF(LTRIM(RTRIM(SRC.dv_LSOACode)), '')

        LEFT JOIN [Analytics].[vw_Dim_Specialty] S ON SRC.Treatment_Function_Code = S.BK_SpecialtyCode
        LEFT JOIN [Analytics].[vw_Dim_HRG] HRG ON SRC.Spell_Core_HRG = HRG.HRGCode

        LEFT JOIN [Analytics].[tbl_Dim_Commissioner] Comm
            ON Comm.Commissioner_Code =
                CASE
                    WHEN RIGHT(SRC.Organisation_Code_Code_of_Commissioner, 2) = '00'
                        THEN LEFT(SRC.Organisation_Code_Code_of_Commissioner, 3)
                    ELSE SRC.Organisation_Code_Code_of_Commissioner
                END
        LEFT JOIN [Analytics].[tbl_Dim_GPPractice] GP
            ON SRC.GP_Practice_Code_Original_Data = GP.GPPractice_Code
           AND GP.Is_Current = 1
        LEFT JOIN [Analytics].[tbl_Dim_PCN] PCN
            ON GP.PCN_Code = PCN.PCN_Code
           AND PCN.Is_Current = 1

        -- POD mapping (derived via IP.GetPodType for materialised source tables)
        LEFT JOIN [Analytics].[tbl_Dim_POD] POD ON PodCalc.POD_Code = POD.POD_Code

        -- IP JOINS
        LEFT JOIN [Analytics].[vw_Dim_Admission_Method] AdmMet ON SRC.Admission_Method_Hospital_Provider_Spell = AdmMet.Admission_Method_Code
        LEFT JOIN [Analytics].[vw_Dim_Admission_Source] AdmSrc ON SRC.Source_of_Admission_Hospital_Provider_Spell = AdmSrc.Admission_Source_Code
        LEFT JOIN [Analytics].[vw_Dim_Discharge_Method] DisMet ON SRC.Discharge_Method_Hospital_Provider_Spell = DisMet.Discharge_Method_Code
        LEFT JOIN [Analytics].[vw_Dim_Discharge_Destination] DisDest ON SRC.Discharge_Destination_Hospital_Provider_Spell = DisDest.Discharge_Destination_Code
        LEFT JOIN [Analytics].[vw_Dim_IP_Patient_Classification] PatClass ON SRC.Patient_Classification = PatClass.Patient_Classification_Code

        WHERE NOT EXISTS (
            SELECT 1
            FROM [Analytics].[tbl_Fact_IP_Activity] T
            WHERE T.SK_EncounterID = SRC.SK_EncounterID
              AND T.Discharge_Date = SRC.Discharge_Date
        )

        SELECT @RowsInserted = COUNT(*) FROM @InsertedKeys;
        SET @RowsSkipped = @SourceRows - @RowsInserted;
        PRINT 'Rows Inserted: ' + CAST(@RowsInserted AS VARCHAR(20));
        PRINT 'Rows Skipped (duplicate PK): ' + CAST(@RowsSkipped AS VARCHAR(20));
        PRINT 'Load Complete.';

        EXEC [Analytics].[sp_Log_Table_Load]
            @BatchID = @BatchID,
            @TableName = 'Analytics.tbl_Fact_IP_Activity',
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
        PRINT 'Error Loading Fact IP: ' + @ErrorMessage;
        IF @ErrorMessage LIKE '%rowcount in the first query is not available%'
        BEGIN
            PRINT '[WARNING] Rowcount unavailable after connection recovery. Deriving counts from data and continuing.';

            ;WITH SourceWindow AS (
                SELECT
                    SRC.*,
                    COALESCE(CAST(SRC.Start_Date_Hospital_Provider_Spell AS DATE), CAST('1900-01-01' AS DATE)) AS Admission_Date,
                    COALESCE(CAST(SRC.End_Date_Hospital_Provider_Spell AS DATE), CAST('1900-01-01' AS DATE)) AS Discharge_Date,
                    TRY_CAST(SRC.dv_LengthOfStay_Gross AS INT) AS Length_Of_Stay
                FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active] SRC
                WHERE SRC.End_Date_Hospital_Provider_Spell >= @FromDateActual
                  AND SRC.End_Date_Hospital_Provider_Spell < DATEADD(DAY, 1, @ToDateActual)
            ),
            SourceDeduped AS (
                SELECT
                    SRC.*,
                    ROW_NUMBER() OVER (
                        PARTITION BY SRC.SK_EncounterID, SRC.Discharge_Date
                        ORDER BY SRC.Start_Date_Hospital_Provider_Spell DESC, SRC.End_Date_Hospital_Provider_Spell DESC
                    ) AS RowNum
                FROM SourceWindow SRC
                WHERE SRC.Length_Of_Stay IS NULL OR SRC.Length_Of_Stay >= 0
            ),
            SourceFiltered AS (
                SELECT *
                FROM SourceDeduped
                WHERE RowNum = 1
            )
            SELECT @SourceRows = COUNT(*) FROM SourceFiltered;

            SELECT @RowsInserted = COUNT(*)
            FROM [Analytics].[tbl_Fact_IP_Activity] f
            INNER JOIN SourceFiltered s
                ON s.SK_EncounterID = f.SK_EncounterID
               AND s.Discharge_Date = f.Discharge_Date;

            SET @RowsSkipped = @SourceRows - @RowsInserted;

            IF @BatchID IS NOT NULL
            BEGIN
                EXEC [Analytics].[sp_Log_Table_Load]
                    @BatchID = @BatchID,
                    @TableName = 'Analytics.tbl_Fact_IP_Activity',
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
                @TableName = 'Analytics.tbl_Fact_IP_Activity',
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

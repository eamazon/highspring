

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-------------------------------------------------------------------------------
-- Create stored procedure
-------------------------------------------------------------------------------

IF OBJECT_ID('[Analytics].[sp_Load_Dim_Commissioner]', 'P') IS NOT NULL
    DROP PROCEDURE [Analytics].[sp_Load_Dim_Commissioner];
GO

/**
Script Name:   01_Load_Dim_Commissioner.sql
Description:   ETL procedure to load/refresh Dim_Commissioner dimension from NHS ODS staging.
               Full reload pattern with SWL ICB attribution logic.
Author:        Sridhar Peddi
Created:       2026-01-02

Change Log:
  2026-01-02   Sridhar Peddi    Initial creation
  2026-01-28   Sridhar Peddi    Materialise SourcePrepared for reuse in update/insert
**/
CREATE PROCEDURE [Analytics].[sp_Load_Dim_Commissioner]
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @BatchID INT;
    DECLARE @TableName VARCHAR(100) = 'Dim_Commissioner';
    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsDeleted INT = 0;
    DECLARE @RowsUpdated INT = 0;
    DECLARE @RowsAffected INT = 0;
    DECLARE @ErrorMessage NVARCHAR(4000);
    
    BEGIN TRY
        -- Start ETL batch logging
        EXEC [Analytics].[sp_Start_ETL_Batch] 
            @BatchName = 'Load_Dim_Commissioner',
            @BatchID = @BatchID OUTPUT;
        
        PRINT '>>> Starting ETL: Load Dim_Commissioner';
        PRINT '    Start Time: ' + CONVERT(VARCHAR, GETDATE(), 120);
        PRINT '    Source: [Analytics].[tbl_Staging_NHS_ODS_Commissioner]';
        PRINT '    Batch ID: ' + CAST(@BatchID AS VARCHAR);
        PRINT '';
        
        -----------------------------------------------------------------------
        -- Upsert commissioners from ODS Staging (preserve surrogate keys)
        -----------------------------------------------------------------------

        IF OBJECT_ID('tempdb..#SourcePrepared') IS NOT NULL
            DROP TABLE #SourcePrepared;

        ;WITH SourcePrepared AS (
            SELECT DISTINCT
                S.Commissioner_Code,
                S.Commissioner_Name,
                -- Update SWL Flag Logic:
                -- 1. Is 36L (Sub-ICB Location)
                -- 2. Is QWE (Statutory Body)
                -- 3. Rolls up to 36L (Legacy CCGs via Successor)
                CASE 
                    WHEN S.Commissioner_Code IN ('36L', 'QWE') THEN 1 
                    WHEN S.Successor_Code = '36L' THEN 1
                    WHEN S.Parent_ICB_Code = 'QWE' THEN 1
                    ELSE 0 
                END AS Is_SWL_ICB,

                -- POD Team attribution (Preserve Legacy Mapping)
                ISNULL(P.SK_PODTeamID, 0) AS SK_PODTeamID,
                ISNULL(P.PODTeamCode, 'UNKNOWN') AS PODTeam_Code,
                ISNULL(P.PODTeamName, 'Unknown') AS PODTeam_Name,

                -- Sub-ICB structure
                CASE 
                    WHEN S.ODS_Role_Code = 'RO207' THEN S.Commissioner_Code
                    ELSE SUBSTRING(S.Commissioner_Code, 1, 3) 
                END AS SubICB_Code,

                CASE 
                    WHEN S.Parent_ICB_Name IS NOT NULL THEN S.Parent_ICB_Name
                    ELSE S.Commissioner_Name 
                END AS SubICB_Name,

                S.Commissioner_Name AS SubICB_Location_Name,

                -- Commissioner type derived from ODS Role and Name
                CASE 
                    WHEN S.ODS_Role_Code IN ('RO207', 'RO261') THEN 'ICB' 
                    WHEN S.Commissioner_Code = '36L' THEN 'ICB' 
                    WHEN S.ODS_Role_Code = 'RO98' AND S.Commissioner_Name LIKE '%ICB%' THEN 'Sub-ICB'
                    WHEN S.Commissioner_Name LIKE '%HUB%' THEN 'Commissioning Hub'
                    WHEN S.Commissioner_Name LIKE '%CCG%' THEN 'CCG (Legacy)'
                    ELSE 'Other'
                END AS Commissioner_Type,

                -- Transition Date (from ODS or hardcoded for known 2022 transition)
                COALESCE(S.Transition_Date, CASE 
                    WHEN S.Commissioner_Code = '36L' THEN CAST('2022-07-01' AS DATE)
                    ELSE NULL
                END) AS Transition_Date,

                S.ODS_Role_Code,

                -- Legacy name tracking
                CASE 
                    WHEN S.Commissioner_Code = '36L' THEN 'NHS South West London CCG'
                    ELSE NULL
                END AS Legacy_Commissioner_Name,

                -- ICB Hierarchy Logic (The "Parent" Entity)
                COALESCE(
                    CASE WHEN S.ODS_Role_Code IN ('RO207', 'RO261') THEN S.Commissioner_Code END,
                    S.Parent_ICB_Code,
                    S.Successor_Code
                ) AS ICB_Code,

                -- Resolve Name for that Code
                COALESCE(
                    CASE WHEN S.ODS_Role_Code IN ('RO207', 'RO261') THEN S.Commissioner_Name END,
                    S.Parent_ICB_Name,
                    Succ.Commissioner_Name,
                    'Unknown ICB'
                ) AS ICB_Name,

                -- Dates
                ISNULL(S.Operational_Start_Date, '1900-01-01') AS Valid_From,
                COALESCE(
                    CASE WHEN S.Status != 'Active' THEN S.Operational_End_Date END, 
                    '9999-12-31'
                ) AS Valid_To,
                CASE WHEN S.Status = 'Active' THEN 1 ELSE 0 END AS Is_Current
            FROM [Analytics].[tbl_Staging_NHS_ODS_Commissioner] AS S
            LEFT JOIN [Analytics].[tbl_Staging_NHS_ODS_Commissioner] AS Succ
                ON S.Successor_Code = Succ.Commissioner_Code
            LEFT JOIN [Dictionary].[dbo].[Commissioner] AS LC 
                ON S.Commissioner_Code = LC.CommissionerCode
            LEFT JOIN [Dictionary].[dbo].[PracticeMatrixNational] AS M 
                ON LC.SK_CommissionerID = M.SK_CommissionerID
            LEFT JOIN [Dictionary].[dbo].[PODTeams] AS P 
                ON M.SK_PODTeamID = P.SK_PODTeamID
        )
        SELECT
            Commissioner_Code,
            Commissioner_Name,
            Is_SWL_ICB,
            SK_PODTeamID,
            PODTeam_Code,
            PODTeam_Name,
            SubICB_Code,
            SubICB_Name,
            SubICB_Location_Name,
            Commissioner_Type,
            Transition_Date,
            ODS_Role_Code,
            Legacy_Commissioner_Name,
            ICB_Code,
            ICB_Name,
            Valid_From,
            Valid_To,
            Is_Current
        INTO #SourcePrepared
        FROM SourcePrepared;

        UPDATE dim
        SET
            dim.Commissioner_Name = src.Commissioner_Name,
            dim.Is_SWL_ICB = src.Is_SWL_ICB,
            dim.SK_PODTeamID = src.SK_PODTeamID,
            dim.PODTeam_Code = src.PODTeam_Code,
            dim.PODTeam_Name = src.PODTeam_Name,
            dim.SubICB_Code = src.SubICB_Code,
            dim.SubICB_Name = src.SubICB_Name,
            dim.SubICB_Location_Name = src.SubICB_Location_Name,
            dim.Commissioner_Type = src.Commissioner_Type,
            dim.Transition_Date = src.Transition_Date,
            dim.ODS_Role_Code = src.ODS_Role_Code,
            dim.Legacy_Commissioner_Name = src.Legacy_Commissioner_Name,
            dim.ICB_Code = src.ICB_Code,
            dim.ICB_Name = src.ICB_Name,
            dim.Valid_From = src.Valid_From,
            dim.Valid_To = src.Valid_To,
            dim.Is_Current = src.Is_Current,
            dim.Source_System = 'NHS_ODS_API',
            dim.Updated_By = SUSER_SNAME(),
            dim.Updated_Date = GETDATE()
        FROM [Analytics].[tbl_Dim_Commissioner] dim
        INNER JOIN #SourcePrepared src
            ON dim.Commissioner_Code = src.Commissioner_Code;

        SET @RowsUpdated = @@ROWCOUNT;
        PRINT '    Updated ' + CAST(@RowsUpdated AS VARCHAR) + ' commissioner records';

        INSERT INTO [Analytics].[tbl_Dim_Commissioner]
        (
            Commissioner_Code,
            Commissioner_Name,
            Is_SWL_ICB,
            SK_PODTeamID,
            PODTeam_Code,
            PODTeam_Name,
            SubICB_Code,
            SubICB_Name,
            SubICB_Location_Name,
            Commissioner_Type,
            Transition_Date,
            ODS_Role_Code,
            Legacy_Commissioner_Name,
            ICB_Code,
            ICB_Name,
            Valid_From,
            Valid_To,
            Is_Current,
            Source_System,
            Created_By,
            Created_Date
        )
        SELECT
            src.Commissioner_Code,
            src.Commissioner_Name,
            src.Is_SWL_ICB,
            src.SK_PODTeamID,
            src.PODTeam_Code,
            src.PODTeam_Name,
            src.SubICB_Code,
            src.SubICB_Name,
            src.SubICB_Location_Name,
            src.Commissioner_Type,
            src.Transition_Date,
            src.ODS_Role_Code,
            src.Legacy_Commissioner_Name,
            src.ICB_Code,
            src.ICB_Name,
            src.Valid_From,
            src.Valid_To,
            src.Is_Current,
            'NHS_ODS_API' AS Source_System,
            SUSER_SNAME() AS Created_By,
            GETDATE() AS Created_Date
        FROM #SourcePrepared src
        LEFT JOIN [Analytics].[tbl_Dim_Commissioner] dim
            ON dim.Commissioner_Code = src.Commissioner_Code
        WHERE dim.Commissioner_Code IS NULL;

        SET @RowsInserted = @@ROWCOUNT;
        PRINT '    Inserted ' + CAST(@RowsInserted AS VARCHAR) + ' commissioner records';
        
        -----------------------------------------------------------------------
        -- Update Processed Flag in Staging
        -----------------------------------------------------------------------
        UPDATE [Analytics].[tbl_Staging_NHS_ODS_Commissioner]
        SET Is_Processed = 1,
            Process_Date = GETDATE()
        WHERE Is_Processed = 0;
        
        -- Log table load
        SET @RowsAffected = @RowsInserted + @RowsUpdated;
        EXEC [Analytics].[sp_Log_Table_Load]
            @BatchID = @BatchID,
            @TableName = @TableName,
            @RowsAffected = @RowsAffected,
            @Status = 'Success',
            @LoadType = 'Full Refresh';
        
        -- End ETL batch (Success)
        EXEC [Analytics].[sp_End_ETL_Batch]
            @BatchID = @BatchID,
            @Status = 'Success',
            @RowsInserted = @RowsInserted,
            @RowsUpdated = @RowsUpdated,
            @RowsDeleted = @RowsDeleted;
        
        PRINT '';
        PRINT '[OK] ETL Complete: Dim_Commissioner loaded successfully from ODS Staging';
        PRINT '     Total commissioners: ' + CAST(@RowsInserted AS VARCHAR);
        
    END TRY
    BEGIN CATCH
        -- Capture error details
        SET @ErrorMessage = ERROR_MESSAGE();
        
        PRINT '[FAIL] ETL Failed: ' + @ErrorMessage;
        
        -- Log error
        IF @BatchID IS NOT NULL
        BEGIN
            EXEC [Analytics].[sp_End_ETL_Batch]
                @BatchID = @BatchID,
                @Status = 'Failed',
                @ErrorMessage = @ErrorMessage;
        END
        
        -- Re-raise error
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END CATCH
END
GO

PRINT '[OK] Created procedure: [Analytics].[sp_Load_Dim_Commissioner]';
GO

PRINT '';
PRINT 'Usage:';
PRINT '  EXEC [Analytics].[sp_Load_Dim_Commissioner];';
PRINT '';
PRINT 'Notes:';
PRINT '  - Uses TRUNCATE/RELOAD pattern (SCD Type 1)';
PRINT '  - Preserves default members (SK = -1, -2)';
PRINT '  - Integrates with ETL logging framework';
PRINT '  - Sub-ICB mapping is placeholder - may need refinement based on actual data';
PRINT '';
GO

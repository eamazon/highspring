USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('[Analytics].[sp_Load_Dim_LSOA]', 'P') IS NOT NULL
    DROP PROCEDURE [Analytics].[sp_Load_Dim_LSOA];
GO

/**
Script Name:   05_Load_Dim_LSOA.sql
Description:   ETL procedure to load Dim_LSOA from [ref].[tbl_LSOA_ICB_CA_LocalAuthority].
Author:        Sridhar Peddi
Created:       2026-01-12

Change Log:
  2026-01-12  Sridhar Peddi    Initial creation
  2026-01-27  Sridhar Peddi    Join IMD 2019 supplementary indices (IDACI, IDAOPI)
**/
CREATE PROCEDURE [Analytics].[sp_Load_Dim_LSOA]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @BatchName VARCHAR(100) = 'Load_Dim_LSOA';
    DECLARE @BatchID INT = NULL;
    DECLARE @TableName VARCHAR(100) = 'Analytics.tbl_Dim_LSOA';
    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsUpdated INT = 0;
    DECLARE @RowsAffected INT = 0;
    DECLARE @RowsDeleted INT = 0;
    DECLARE @ErrorMessage NVARCHAR(4000);

    BEGIN TRY
        EXEC [Analytics].[sp_Start_ETL_Batch]
            @BatchName = @BatchName,
            @BatchID = @BatchID OUTPUT;

        PRINT 'Starting Load: [Analytics].[tbl_Dim_LSOA]';

        IF NOT EXISTS (
            SELECT 1
            FROM [Data_Lab_SWL].sys.tables t
            INNER JOIN [Data_Lab_SWL].sys.schemas s ON s.schema_id = t.schema_id
            WHERE s.name = 'ref'
              AND t.name = 'tbl_LSOA_ICB_CA_LocalAuthority'
        )
        BEGIN
            RAISERROR('Source table [Data_Lab_SWL].[ref].[tbl_LSOA_ICB_CA_LocalAuthority] not found.', 16, 1);
            RETURN;
        END

        IF OBJECT_ID('[Analytics].[tbl_Staging_LSOA_IMD2019]', 'U') IS NULL
        BEGIN
            RAISERROR('Staging table [Analytics].[tbl_Staging_LSOA_IMD2019] not found.', 16, 1);
            RETURN;
        END

        IF OBJECT_ID('tempdb..#PreparedLSOA') IS NOT NULL
            DROP TABLE #PreparedLSOA;

        CREATE TABLE #PreparedLSOA
        (
            LSOA_Code VARCHAR(9) NOT NULL PRIMARY KEY,
            LSOA_Name VARCHAR(100) NULL,
            SubICB_Code VARCHAR(50) NULL,
            SubICB_Hierarchy_Code VARCHAR(50) NULL,
            SubICB_Name VARCHAR(100) NULL,
            ICB_Code VARCHAR(50) NULL,
            ICB_Hierarchy_Code VARCHAR(50) NULL,
            ICB_Name VARCHAR(150) NULL,
            CancerAlliance_Code VARCHAR(50) NULL,
            CancerAlliance_Name VARCHAR(100) NULL,
            LocalAuthority_Code VARCHAR(50) NULL,
            LocalAuthority_Name VARCHAR(100) NULL,
            IMD_Year SMALLINT NULL,
            IMD_Rank INT NULL,
            IMD_Decile TINYINT NULL,
            IDACI_Score DECIMAL(9,6) NULL,
            IDACI_Rank INT NULL,
            IDACI_Decile TINYINT NULL,
            IDAOPI_Score DECIMAL(9,6) NULL,
            IDAOPI_Rank INT NULL,
            IDAOPI_Decile TINYINT NULL
        );

        ;WITH Source AS (
            SELECT
                LSOA_Code = NULLIF(LTRIM(RTRIM(LSOA21Code)), ''),
                LSOA_Name = NULLIF(LTRIM(RTRIM(LSOA21Name)), ''),
                SubICB_Code = NULLIF(LTRIM(RTRIM(SubICBLocation24Code)), ''),
                SubICB_Hierarchy_Code = NULLIF(LTRIM(RTRIM(SubICBLocation24HierarchyCode)), ''),
                SubICB_Name = NULLIF(LTRIM(RTRIM(SubICBLocation24Name)), ''),
                ICB_Code = NULLIF(LTRIM(RTRIM(ICB24Code)), ''),
                ICB_Hierarchy_Code = NULLIF(LTRIM(RTRIM(ICB24HierarchyCode)), ''),
                ICB_Name = NULLIF(LTRIM(RTRIM(ICB24Name)), ''),
                CancerAlliance_Code = NULLIF(LTRIM(RTRIM(CancerAlliance24Code)), ''),
                CancerAlliance_Name = NULLIF(LTRIM(RTRIM(CancerAlliance24Name)), ''),
                LocalAuthority_Code = NULLIF(LTRIM(RTRIM(LocalAuthority24Code)), ''),
                LocalAuthority_Name = NULLIF(LTRIM(RTRIM(LocalAuthority24Name)), '')
            FROM [Data_Lab_SWL].[ref].[tbl_LSOA_ICB_CA_LocalAuthority]
        ),
        Imd AS (
            SELECT
                LSOA_Code = NULLIF(LTRIM(RTRIM(LSOA_Code)), ''),
                LSOA_Name = NULLIF(LTRIM(RTRIM(LSOA_Name)), ''),
                LocalAuthority_District_Code = NULLIF(LTRIM(RTRIM(LocalAuthority_District_Code)), ''),
                LocalAuthority_District_Name = NULLIF(LTRIM(RTRIM(LocalAuthority_District_Name)), ''),
                IMD_Rank,
                IMD_Decile,
                IDACI_Score,
                IDACI_Rank,
                IDACI_Decile,
                IDAOPI_Score,
                IDAOPI_Rank,
                IDAOPI_Decile
            FROM [Analytics].[tbl_Staging_LSOA_IMD2019]
        )
        INSERT INTO #PreparedLSOA
        (
            LSOA_Code,
            LSOA_Name,
            SubICB_Code,
            SubICB_Hierarchy_Code,
            SubICB_Name,
            ICB_Code,
            ICB_Hierarchy_Code,
            ICB_Name,
            CancerAlliance_Code,
            CancerAlliance_Name,
            LocalAuthority_Code,
            LocalAuthority_Name,
            IMD_Year,
            IMD_Rank,
            IMD_Decile,
            IDACI_Score,
            IDACI_Rank,
            IDACI_Decile,
            IDAOPI_Score,
            IDAOPI_Rank,
            IDAOPI_Decile
        )
        SELECT
            s.LSOA_Code,
            COALESCE(MAX(s.LSOA_Name), 'Unknown LSOA'),
            COALESCE(MAX(s.SubICB_Code), 'UNK'),
            COALESCE(MAX(s.SubICB_Hierarchy_Code), 'UNK'),
            COALESCE(MAX(s.SubICB_Name), 'Unknown Sub-ICB'),
            COALESCE(MAX(s.ICB_Code), 'UNK'),
            COALESCE(MAX(s.ICB_Hierarchy_Code), 'UNK'),
            COALESCE(MAX(s.ICB_Name), 'Unknown ICB'),
            COALESCE(MAX(s.CancerAlliance_Code), 'UNK'),
            COALESCE(MAX(s.CancerAlliance_Name), 'Unknown Cancer Alliance'),
            COALESCE(MAX(s.LocalAuthority_Code), 'UNK'),
            COALESCE(MAX(s.LocalAuthority_Name), 'Unknown Local Authority'),
            2019,
            MAX(imd.IMD_Rank),
            MAX(imd.IMD_Decile),
            MAX(imd.IDACI_Score),
            MAX(imd.IDACI_Rank),
            MAX(imd.IDACI_Decile),
            MAX(imd.IDAOPI_Score),
            MAX(imd.IDAOPI_Rank),
            MAX(imd.IDAOPI_Decile)
        FROM Source s
        LEFT JOIN Imd imd
            ON imd.LSOA_Code = s.LSOA_Code
        WHERE s.LSOA_Code IS NOT NULL
        GROUP BY s.LSOA_Code;

        UPDATE d
        SET
            d.LSOA_Name = p.LSOA_Name,
            d.SubICB_Code = p.SubICB_Code,
            d.SubICB_Hierarchy_Code = p.SubICB_Hierarchy_Code,
            d.SubICB_Name = p.SubICB_Name,
            d.ICB_Code = p.ICB_Code,
            d.ICB_Hierarchy_Code = p.ICB_Hierarchy_Code,
            d.ICB_Name = p.ICB_Name,
            d.CancerAlliance_Code = p.CancerAlliance_Code,
            d.CancerAlliance_Name = p.CancerAlliance_Name,
            d.LocalAuthority_Code = p.LocalAuthority_Code,
            d.LocalAuthority_Name = p.LocalAuthority_Name,
            d.IMD_Year = p.IMD_Year,
            d.IMD_Rank = p.IMD_Rank,
            d.IMD_Decile = p.IMD_Decile,
            d.IDACI_Score = p.IDACI_Score,
            d.IDACI_Rank = p.IDACI_Rank,
            d.IDACI_Decile = p.IDACI_Decile,
            d.IDAOPI_Score = p.IDAOPI_Score,
            d.IDAOPI_Rank = p.IDAOPI_Rank,
            d.IDAOPI_Decile = p.IDAOPI_Decile,
            d.Source_System = 'ref.tbl_LSOA_ICB_CA_LocalAuthority',
            d.Updated_By = SUSER_SNAME(),
            d.Updated_Date = GETDATE()
        FROM [Analytics].[tbl_Dim_LSOA] d
        INNER JOIN #PreparedLSOA p
            ON p.LSOA_Code = d.LSOA_Code
        WHERE d.SK_LSOA_ID > 0;

        SET @RowsUpdated = @@ROWCOUNT;
        PRINT 'Rows Updated: ' + CAST(@RowsUpdated AS VARCHAR(20));

        INSERT INTO [Analytics].[tbl_Dim_LSOA]
        (
            LSOA_Code,
            LSOA_Name,
            SubICB_Code,
            SubICB_Hierarchy_Code,
            SubICB_Name,
            ICB_Code,
            ICB_Hierarchy_Code,
            ICB_Name,
            CancerAlliance_Code,
            CancerAlliance_Name,
            LocalAuthority_Code,
            LocalAuthority_Name,
            IMD_Year,
            IMD_Rank,
            IMD_Decile,
            IDACI_Score,
            IDACI_Rank,
            IDACI_Decile,
            IDAOPI_Score,
            IDAOPI_Rank,
            IDAOPI_Decile,
            Source_System,
            Created_By,
            Created_Date
        )
        SELECT
            p.LSOA_Code,
            p.LSOA_Name,
            p.SubICB_Code,
            p.SubICB_Hierarchy_Code,
            p.SubICB_Name,
            p.ICB_Code,
            p.ICB_Hierarchy_Code,
            p.ICB_Name,
            p.CancerAlliance_Code,
            p.CancerAlliance_Name,
            p.LocalAuthority_Code,
            p.LocalAuthority_Name,
            p.IMD_Year,
            p.IMD_Rank,
            p.IMD_Decile,
            p.IDACI_Score,
            p.IDACI_Rank,
            p.IDACI_Decile,
            p.IDAOPI_Score,
            p.IDAOPI_Rank,
            p.IDAOPI_Decile,
            'ref.tbl_LSOA_ICB_CA_LocalAuthority',
            SUSER_SNAME(),
            GETDATE()
        FROM #PreparedLSOA p
        WHERE NOT EXISTS (
            SELECT 1
            FROM [Analytics].[tbl_Dim_LSOA] d
            WHERE d.LSOA_Code = p.LSOA_Code
        );

        SET @RowsInserted = @@ROWCOUNT;
        PRINT 'Rows Inserted: ' + CAST(@RowsInserted AS VARCHAR(20));

        SET @RowsAffected = @RowsInserted + @RowsUpdated;

        EXEC [Analytics].[sp_Log_Table_Load]
            @BatchID = @BatchID,
            @TableName = @TableName,
            @LoadType = 'Full',
            @RowsAffected = @RowsAffected,
            @Status = 'Success';

        EXEC [Analytics].[sp_End_ETL_Batch]
            @BatchID = @BatchID,
            @Status = 'Success',
            @RowsInserted = @RowsInserted,
            @RowsUpdated = @RowsUpdated,
            @RowsDeleted = @RowsDeleted,
            @RowsFailed = 0,
            @ErrorMessage = NULL;
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();
        PRINT 'Error Loading Dim_LSOA: ' + @ErrorMessage;
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

PRINT '[OK] Created procedure: [Analytics].[sp_Load_Dim_LSOA]';
GO

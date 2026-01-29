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

        DELETE FROM [Analytics].[tbl_Dim_LSOA]
        WHERE SK_LSOA_ID > 0;

        SET @RowsDeleted = @@ROWCOUNT;
        PRINT 'Rows Deleted: ' + CAST(@RowsDeleted AS VARCHAR(20));

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
            s.LSOA_Code,
            MAX(s.LSOA_Name),
            MAX(s.SubICB_Code),
            MAX(s.SubICB_Hierarchy_Code),
            MAX(s.SubICB_Name),
            MAX(s.ICB_Code),
            MAX(s.ICB_Hierarchy_Code),
            MAX(s.ICB_Name),
            MAX(s.CancerAlliance_Code),
            MAX(s.CancerAlliance_Name),
            MAX(s.LocalAuthority_Code),
            MAX(s.LocalAuthority_Name),
            CASE
                WHEN MAX(imd.IDACI_Score) IS NULL AND MAX(imd.IDAOPI_Score) IS NULL THEN NULL
                ELSE 2019
            END,
            MAX(imd.IMD_Rank),
            MAX(imd.IMD_Decile),
            MAX(imd.IDACI_Score),
            MAX(imd.IDACI_Rank),
            MAX(imd.IDACI_Decile),
            MAX(imd.IDAOPI_Score),
            MAX(imd.IDAOPI_Rank),
            MAX(imd.IDAOPI_Decile),
            'ref.tbl_LSOA_ICB_CA_LocalAuthority',
            SUSER_SNAME(),
            GETDATE()
        FROM Source s
        LEFT JOIN Imd imd
            ON imd.LSOA_Code = s.LSOA_Code
        WHERE s.LSOA_Code IS NOT NULL
        GROUP BY s.LSOA_Code;

        SET @RowsInserted = @@ROWCOUNT;
        PRINT 'Rows Inserted: ' + CAST(@RowsInserted AS VARCHAR(20));

        EXEC [Analytics].[sp_Log_Table_Load]
            @BatchID = @BatchID,
            @TableName = @TableName,
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

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating Staging Table: tbl_Staging_LSOA_IMD2019';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

IF OBJECT_ID('[Analytics].[tbl_Staging_LSOA_IMD2019]', 'U') IS NOT NULL
BEGIN
    PRINT 'Table [Analytics].[tbl_Staging_LSOA_IMD2019] already exists. Dropping...';
    DROP TABLE [Analytics].[tbl_Staging_LSOA_IMD2019];
END
GO

/**
Script Name:   07_Create_Staging_LSOA_IMD2019.sql
Description:   Staging table for LSOA IMD 2019 supplementary indices (IDACI, IDAOPI).
Author:        Sridhar Peddi
Created:       2026-01-27

Change Log:
  2026-01-27  Sridhar Peddi    Initial creation
**/
CREATE TABLE [Analytics].[tbl_Staging_LSOA_IMD2019]
(
    LSOA_Code VARCHAR(9) NOT NULL,
    LSOA_Name VARCHAR(255) NULL,
    LocalAuthority_District_Code VARCHAR(9) NULL,
    LocalAuthority_District_Name VARCHAR(255) NULL,
    IMD_Rank INT NULL,
    IMD_Decile TINYINT NULL,
    IDACI_Score DECIMAL(9,6) NULL,
    IDACI_Rank INT NULL,
    IDACI_Decile TINYINT NULL,
    IDAOPI_Score DECIMAL(9,6) NULL,
    IDAOPI_Rank INT NULL,
    IDAOPI_Decile TINYINT NULL,
    Load_Dtm DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    Source_File NVARCHAR(260) NULL,
    CONSTRAINT PK_Staging_LSOA_IMD2019 PRIMARY KEY NONCLUSTERED (LSOA_Code)
) ON [PRIMARY];
GO

PRINT '[OK] Created table: [Analytics].[tbl_Staging_LSOA_IMD2019]';
GO

PRINT '========================================';
PRINT 'Staging Table Creation Complete';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

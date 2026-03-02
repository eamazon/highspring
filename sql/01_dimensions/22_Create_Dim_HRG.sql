

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating tbl_HRG and vw_Dim_HRG';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

-- Drop old naming conventions
IF OBJECT_ID('[Analytics].[Dim_HRG]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[Dim_HRG] already exists. Dropping...';
    DROP VIEW [Analytics].[Dim_HRG];
END
GO

IF OBJECT_ID('[Analytics].[tbl_Dim_HRG]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[tbl_Dim_HRG] already exists. Dropping...';
    DROP VIEW [Analytics].[tbl_Dim_HRG];
END
GO

IF OBJECT_ID('[Analytics].[vw_Dim_HRG]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[vw_Dim_HRG] already exists. Dropping...';
    DROP VIEW [Analytics].[vw_Dim_HRG];
END
GO

IF OBJECT_ID('[Analytics].[tbl_HRG]', 'U') IS NOT NULL
BEGIN
    PRINT 'Table [Analytics].[tbl_HRG] already exists. Dropping...';
    DROP TABLE [Analytics].[tbl_HRG];
END
GO

/**
Script Name:   22_Create_Dim_HRG.sql
Description:   Healthcare Resource Group (HRG) dimension table + view.
               Sourced from NHS annual HRG code-to-group releases (via staging + ETL).
               Single-row-per-code SCD with Valid_From/Valid_To derived from release chronology.
Author:        Sridhar Peddi
Created:       2026-01-09

Change Log:
  2026-01-09   Sridhar Peddi    Initial creation
  2026-02-27   Codex            Replace Dictionary dependency with Analytics.tbl_HRG (SCD-ready)
**/
CREATE TABLE [Analytics].[tbl_HRG]
(
    SK_HRGID INT IDENTITY(1,1) NOT NULL,
    HRGCode VARCHAR(20) NOT NULL,
    HRGDescription VARCHAR(500) NULL,
    Core_Or_Unbundled VARCHAR(30) NULL,
    HRGSubchapterKey VARCHAR(20) NULL,
    HRGSubchapter VARCHAR(255) NULL,
    HRGChapterKey VARCHAR(20) NULL,
    HRGChapter VARCHAR(255) NULL,
    Last_Seen_Release_Date DATE NOT NULL,
    Source_URL VARCHAR(500) NULL,
    Valid_From DATE NOT NULL DEFAULT '1900-01-01',
    Valid_To DATE NULL,
    Is_Current BIT NOT NULL DEFAULT 1,
    Created_Date DATETIME2 NOT NULL DEFAULT GETDATE(),
    Updated_Date DATETIME2 NULL,
    Created_By VARCHAR(100) NULL DEFAULT SUSER_SNAME(),
    Updated_By VARCHAR(100) NULL,
    CONSTRAINT PK_tbl_HRG PRIMARY KEY NONCLUSTERED (SK_HRGID),
    CONSTRAINT UQ_tbl_HRG_Code UNIQUE NONCLUSTERED (HRGCode)
);
GO

CREATE NONCLUSTERED INDEX IX_tbl_HRG_Code_Current
    ON [Analytics].[tbl_HRG](HRGCode, Is_Current)
    INCLUDE (SK_HRGID, HRGDescription, HRGChapterKey, HRGSubchapterKey, Valid_From, Valid_To);
GO

CREATE NONCLUSTERED INDEX IX_tbl_HRG_Release
    ON [Analytics].[tbl_HRG](Last_Seen_Release_Date)
    INCLUDE (HRGCode, Is_Current, Valid_From, Valid_To);
GO

SET IDENTITY_INSERT [Analytics].[tbl_HRG] ON;
INSERT INTO [Analytics].[tbl_HRG]
(
    SK_HRGID, HRGCode, HRGDescription, Core_Or_Unbundled,
    HRGSubchapterKey, HRGSubchapter, HRGChapterKey, HRGChapter,
    Last_Seen_Release_Date, Source_URL, Valid_From, Valid_To,
    Is_Current, Created_By
)
VALUES
(
    -1, 'UNKNOWN', 'Unknown HRG', NULL,
    NULL, 'Unknown', NULL, 'Unknown',
    '1900-01-01', NULL, '1900-01-01', NULL,
    1, SUSER_SNAME()
);
SET IDENTITY_INSERT [Analytics].[tbl_HRG] OFF;
GO

CREATE VIEW [Analytics].[vw_Dim_HRG] AS
SELECT
      CAST([SK_HRGID] AS INT) AS [SK_HRGID],
      [HRGCode],
      [HRGDescription],
      [HRGChapterKey],
      [HRGChapter],
      [HRGSubchapterKey],
      [HRGSubchapter],
      [Valid_From],
      [Valid_To],
      [Is_Current],
      
      -- Short description for Power BI
      LEFT([HRGDescription], 50) AS [HRG_Short]
      
FROM [Analytics].[tbl_HRG];
GO

PRINT '[OK] Created view: [Analytics].[vw_Dim_HRG]';
PRINT '     Source: [Analytics].[tbl_HRG] (SCD Current Rows)';
GO

PRINT '';
PRINT 'Validation: Sample data from view';
SELECT TOP 5 * FROM [Analytics].[vw_Dim_HRG];
GO

PRINT '';
PRINT '========================================';
PRINT 'vw_Dim_HRG VIEW Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating Staging Table: tbl_Staging_HRG';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

IF OBJECT_ID('[Analytics].[tbl_Staging_HRG]', 'U') IS NOT NULL
BEGIN
    PRINT 'Table [Analytics].[tbl_Staging_HRG] already exists. Dropping...';
    DROP TABLE [Analytics].[tbl_Staging_HRG];
END
GO

CREATE TABLE [Analytics].[tbl_Staging_HRG]
(
    HRGCode VARCHAR(20) NOT NULL,
    HRGDescription VARCHAR(500) NULL,
    Core_Or_Unbundled VARCHAR(30) NULL,
    HRGSubchapterKey VARCHAR(20) NULL,
    HRGSubchapter VARCHAR(255) NULL,
    HRGChapterKey VARCHAR(20) NULL,
    HRGChapter VARCHAR(255) NULL,
    Release_Date DATE NOT NULL,
    Source_URL VARCHAR(500) NULL,
    Load_Timestamp DATETIME2 NOT NULL DEFAULT GETDATE()
);
GO

CREATE NONCLUSTERED INDEX IX_Staging_HRG_CodeRelease
    ON [Analytics].[tbl_Staging_HRG](HRGCode, Release_Date);
GO

PRINT '[OK] Created table: [Analytics].[tbl_Staging_HRG]';
PRINT '[OK] Created index: IX_Staging_HRG_CodeRelease';
PRINT '========================================';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

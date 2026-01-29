USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating Staging Table: tbl_Staging_PCN_Relationships';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

IF OBJECT_ID('[Analytics].[tbl_Staging_PCN_Relationships]', 'U') IS NOT NULL
BEGIN
    PRINT 'Table [Analytics].[tbl_Staging_PCN_Relationships] already exists. Dropping...';
    DROP TABLE [Analytics].[tbl_Staging_PCN_Relationships];
END
GO

/**
Script Name:   10_Create_Staging_PCN_Relationships.sql
Description:   Staging table for PCN core partner relationships (GP practice ↔ PCN).
Author:        Sridhar Peddi
Created:       2026-01-27

Change Log:
  2026-01-27  Sridhar Peddi    Initial creation
**/
CREATE TABLE [Analytics].[tbl_Staging_PCN_Relationships]
(
    Partner_Organisation_Code VARCHAR(10) NOT NULL,
    Partner_Name VARCHAR(255) NULL,
    Practice_Parent_SubICB_Code VARCHAR(10) NULL,
    Practice_Parent_SubICB_Name VARCHAR(255) NULL,
    PCN_Code VARCHAR(12) NULL,
    PCN_Name VARCHAR(255) NULL,
    PCN_Parent_SubICB_Code VARCHAR(10) NULL,
    PCN_Parent_SubICB_Name VARCHAR(255) NULL,
    Relationship_Start_Date DATE NULL,
    Relationship_End_Date DATE NULL,
    SubICB_Match_Flag VARCHAR(10) NULL,
    Load_Dtm DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    Source_File NVARCHAR(260) NULL,
    CONSTRAINT PK_Staging_PCN_Relationships PRIMARY KEY NONCLUSTERED (Partner_Organisation_Code)
) ON [PRIMARY];
GO

PRINT '[OK] Created table: [Analytics].[tbl_Staging_PCN_Relationships]';
GO

PRINT '========================================';
PRINT 'Staging Table Creation Complete';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

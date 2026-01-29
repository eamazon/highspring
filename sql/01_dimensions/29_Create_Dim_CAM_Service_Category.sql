USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating Dim_CAM_Service_Category';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

IF OBJECT_ID('[Analytics].[Dim_CAM_Service_Category]', 'U') IS NOT NULL
BEGIN
    PRINT 'Table [Analytics].[Dim_CAM_Service_Category] already exists. Dropping...';
    DROP TABLE [Analytics].[Dim_CAM_Service_Category];
END
GO

IF OBJECT_ID('[Analytics].[tbl_Dim_CAM_Service_Category]', 'U') IS NOT NULL
BEGIN
    PRINT 'Table [Analytics].[tbl_Dim_CAM_Service_Category] already exists. Dropping...';
    DROP TABLE [Analytics].[tbl_Dim_CAM_Service_Category];
END
GO

/**
Script Name:   29_Create_Dim_CAM_Service_Category.sql
Description:   CAM service category dimension for filtering commissioner attribution outputs.
Author:        Sridhar Peddi
Created:       2026-01-12 21:55

Change Log:
  2026-01-12  Sridhar Peddi    Initial creation
**/
CREATE TABLE [Analytics].[tbl_Dim_CAM_Service_Category]
(
    SK_CAM_Service_CategoryID INT IDENTITY(1,1) NOT NULL,
    CAM_Service_Category VARCHAR(50) NOT NULL,

    Source_System VARCHAR(100) NULL DEFAULT 'CAM_Ref.CommissionerAssignmentReason',
    Created_By VARCHAR(128) NULL DEFAULT SYSTEM_USER,
    Created_Date DATETIME2 NOT NULL DEFAULT GETDATE(),
    Updated_By VARCHAR(128) NULL,
    Updated_Date DATETIME2 NULL,

    CONSTRAINT [PK_Dim_CAM_Service_Category]
        PRIMARY KEY NONCLUSTERED ([SK_CAM_Service_CategoryID] ASC),
    CONSTRAINT [UQ_Dim_CAM_Service_Category]
        UNIQUE NONCLUSTERED ([CAM_Service_Category])
) ON [PRIMARY];
GO

CREATE CLUSTERED COLUMNSTORE INDEX [CCI_Dim_CAM_Service_Category]
    ON [Analytics].[tbl_Dim_CAM_Service_Category];
GO

PRINT '[OK] Created table: [Analytics].[tbl_Dim_CAM_Service_Category]';
GO

SET IDENTITY_INSERT [Analytics].[tbl_Dim_CAM_Service_Category] ON;

INSERT INTO [Analytics].[tbl_Dim_CAM_Service_Category]
    (SK_CAM_Service_CategoryID, CAM_Service_Category)
VALUES
    (-1, 'UNKNOWN');

SET IDENTITY_INSERT [Analytics].[tbl_Dim_CAM_Service_Category] OFF;

PRINT '[OK] Inserted default "Unknown" member (SK_CAM_Service_CategoryID = -1)';
GO

PRINT '';
PRINT '========================================';
PRINT 'Dim_CAM_Service_Category Creation Complete';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO

USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating Dim_CAM_Assignment_Reason';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

IF OBJECT_ID('[Analytics].[Dim_CAM_Assignment_Reason]', 'U') IS NOT NULL
BEGIN
    PRINT 'Table [Analytics].[Dim_CAM_Assignment_Reason] already exists. Dropping...';
    DROP TABLE [Analytics].[Dim_CAM_Assignment_Reason];
END
GO

IF OBJECT_ID('[Analytics].[tbl_Dim_CAM_Assignment_Reason]', 'U') IS NOT NULL
BEGIN
    PRINT 'Table [Analytics].[tbl_Dim_CAM_Assignment_Reason] already exists. Dropping...';
    DROP TABLE [Analytics].[tbl_Dim_CAM_Assignment_Reason];
END
GO

/**
Script Name:   30_Create_Dim_CAM_Assignment_Reason.sql
Description:   CAM assignment reason dimension (CAM_Code -> descriptive reason).
Author:        Sridhar Peddi
Created:       2026-01-12 21:55

Change Log:
  2026-01-12  Sridhar Peddi    Initial creation
**/
CREATE TABLE [Analytics].[tbl_Dim_CAM_Assignment_Reason]
(
    SK_CAM_Assignment_ReasonID INT IDENTITY(1,1) NOT NULL,
    CAM_Assignment_Code VARCHAR(50) NOT NULL,
    CAM_Assignment_Reason VARCHAR(255) NULL,

    Source_System VARCHAR(100) NULL DEFAULT 'CAM_Ref.CommissionerAssignmentReason',
    Created_By VARCHAR(128) NULL DEFAULT SYSTEM_USER,
    Created_Date DATETIME2 NOT NULL DEFAULT GETDATE(),
    Updated_By VARCHAR(128) NULL,
    Updated_Date DATETIME2 NULL,

    CONSTRAINT [PK_Dim_CAM_Assignment_Reason]
        PRIMARY KEY NONCLUSTERED ([SK_CAM_Assignment_ReasonID] ASC),
    CONSTRAINT [UQ_Dim_CAM_Assignment_Reason]
        UNIQUE NONCLUSTERED ([CAM_Assignment_Code])
) ON [PRIMARY];
GO

CREATE CLUSTERED COLUMNSTORE INDEX [CCI_Dim_CAM_Assignment_Reason]
    ON [Analytics].[tbl_Dim_CAM_Assignment_Reason];
GO

PRINT '[OK] Created table: [Analytics].[tbl_Dim_CAM_Assignment_Reason]';
GO

SET IDENTITY_INSERT [Analytics].[tbl_Dim_CAM_Assignment_Reason] ON;

INSERT INTO [Analytics].[tbl_Dim_CAM_Assignment_Reason]
    (SK_CAM_Assignment_ReasonID, CAM_Assignment_Code, CAM_Assignment_Reason)
VALUES
    (-1, 'UNKNOWN', 'Unknown Assignment Reason');

SET IDENTITY_INSERT [Analytics].[tbl_Dim_CAM_Assignment_Reason] OFF;

PRINT '[OK] Inserted default "Unknown" member (SK_CAM_Assignment_ReasonID = -1)';
GO

PRINT '';
PRINT '========================================';
PRINT 'Dim_CAM_Assignment_Reason Creation Complete';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO

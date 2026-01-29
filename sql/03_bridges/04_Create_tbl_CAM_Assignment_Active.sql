USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating tbl_CAM_Assignment_Active TABLE';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

/**
Script Name:   04_Create_tbl_CAM_Assignment_Active.sql
Description:   Precomputed CAM assignment outputs for fast fact enrichment.
Author:        Sridhar Peddi
Created:       2026-01-15

Notes:
- Create-if-missing only. Do NOT drop.
- Activity_Date stores Discharge_Date for IP and Appointment_Date for OP.
**/
IF OBJECT_ID('[Analytics].[tbl_CAM_Assignment_Active]', 'U') IS NULL
BEGIN
    CREATE TABLE [Analytics].[tbl_CAM_Assignment_Active] (
        [SK_EncounterID] BIGINT NOT NULL,
        [Dataset] VARCHAR(2) NOT NULL, -- IP / OP
        [Activity_Date] DATE NOT NULL,

        [CAM_Assignment_Code] VARCHAR(50) NULL,
        [CAM_Commissioner_Code] VARCHAR(20) NULL,
        [CAM_Service_Category] VARCHAR(50) NULL,
        [CAM_Assignment_Reason] VARCHAR(255) NULL,
        [Commissioner_Variance] BIT NULL,
        [Service_Category_Variance] BIT NULL,

        [SK_CAM_CommissionerID] INT NOT NULL DEFAULT (-1),
        [SK_CAM_Service_CategoryID] INT NOT NULL DEFAULT (-1),
        [SK_CAM_Assignment_ReasonID] INT NOT NULL DEFAULT (-1),

        [ETL_LoadDateTime] DATETIME2 NOT NULL DEFAULT CURRENT_TIMESTAMP,
        [ETL_UpdateDateTime] DATETIME2 NULL,

        CONSTRAINT [PK_CAM_Assignment_Active] PRIMARY KEY CLUSTERED ([SK_EncounterID] ASC, [Dataset] ASC)
    );
END
GO

IF OBJECT_ID('[Analytics].[tbl_CAM_Assignment_Active]', 'U') IS NOT NULL
    AND NOT EXISTS (
        SELECT 1
        FROM sys.indexes
        WHERE name = 'IX_CAM_Assignment_Active_ActivityDate'
          AND object_id = OBJECT_ID('[Analytics].[tbl_CAM_Assignment_Active]')
    )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_CAM_Assignment_Active_ActivityDate]
        ON [Analytics].[tbl_CAM_Assignment_Active] ([Activity_Date], [Dataset])
        INCLUDE ([SK_EncounterID]);
END
GO

PRINT '[OK] Created table: [Analytics].[tbl_CAM_Assignment_Active]';
PRINT '========================================';
GO

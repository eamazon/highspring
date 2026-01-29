USE [Data_Lab_SWL];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating tbl_CAM_Raw TABLE';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

/**
Script Name:   [CAM].[tbl_CAM_Raw].sql
Description:   Precomputed CAM assignment outputs (weekly refresh).
Author:        Sridhar Peddi
Created:       2026-01-15

Notes:
- Create-if-missing only. Do NOT drop.
- Activity_Date stores DischargeDate for IP and AppointmentDate for OP.
**/
IF OBJECT_ID('[CAM].[tbl_CAM_Raw]', 'U') IS NULL
BEGIN
    CREATE TABLE [CAM].[tbl_CAM_Raw] (
        [RecordIdentifier] BIGINT NOT NULL,
        [Dataset] VARCHAR(2) NOT NULL,
        [Provider_Code] VARCHAR(20) NULL,
        [GP_Practice_Code] VARCHAR(20) NULL,
        [CAM_Commissioner_Code] VARCHAR(20) NULL,
        [CAM_Service_Category] VARCHAR(50) NULL,
        [CAM_Assignment_Reason] VARCHAR(255) NULL,
        [ReassignmentID] VARCHAR(50) NULL,
        [Commissioner_Variance] BIT NULL,
        [Service_Category_Variance] BIT NULL,
        [AdmissionDate] DATE NULL,
        [DischargeDate] DATE NULL,
        [Activity_Date] AS (
            CASE WHEN [Dataset] = 'IP' THEN [DischargeDate] ELSE [AdmissionDate] END
        ) PERSISTED,
        [Financial_Year] VARCHAR(9) NOT NULL,
        [ETL_LoadDateTime] DATETIME2 NOT NULL DEFAULT CURRENT_TIMESTAMP,

        CONSTRAINT [PK_CAM_Raw] PRIMARY KEY CLUSTERED ([RecordIdentifier] ASC, [Dataset] ASC)
    );
END
GO

IF OBJECT_ID('[CAM].[tbl_CAM_Raw]', 'U') IS NOT NULL
    AND NOT EXISTS (
        SELECT 1
        FROM sys.indexes
        WHERE name = 'IX_CAM_Raw_ActivityDate'
          AND object_id = OBJECT_ID('[CAM].[tbl_CAM_Raw]')
    )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_CAM_Raw_ActivityDate]
        ON [CAM].[tbl_CAM_Raw] ([Activity_Date], [Dataset])
        INCLUDE ([CAM_Commissioner_Code], [CAM_Service_Category], [Provider_Code]);
END
GO

PRINT '[OK] Created table: [CAM].[tbl_CAM_Raw]';
PRINT '========================================';
GO

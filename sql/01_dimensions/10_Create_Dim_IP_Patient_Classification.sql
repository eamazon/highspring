USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating Dim_IP_Patient_Classification VIEW';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

IF OBJECT_ID('[Analytics].[vw_Dim_IP_Patient_Classification]', 'V') IS NOT NULL
BEGIN
    PRINT 'View [Analytics].[vw_Dim_IP_Patient_Classification] already exists. Dropping...';
    DROP VIEW [Analytics].[vw_Dim_IP_Patient_Classification];
END
GO

/**
Script Name:   10_Create_Dim_IP_Patient_Classification.sql
Description:   Inpatient patient classification (Ordinary/Day Case/Regular Attender/Maternity).
               Defines admission category for IP activity categorization and tariff application.
               Supports casemix analysis and day case rate monitoring.
Author:        Sridhar Peddi
Created:       2026-01-06

Change Log:
  2026-01-06   Sridhar Peddi    Initial creation
**/
CREATE VIEW [Analytics].[vw_Dim_IP_Patient_Classification] AS
SELECT
    CAST([SK_PatientClassificationID] AS INT) AS [SK_PatientClassificationID],
    [BK_PatientClassificationCode] AS Patient_Classification_Code,
    [PatientClassificationName] AS Patient_Classification_Description
FROM [Dictionary].[dbo].[PatientClassification];
GO

PRINT '[OK] Created view: [Analytics].[vw_Dim_IP_Patient_Classification]';
PRINT '     Source: [Dictionary].[dbo].[PatientClassification]';
GO

PRINT '';
PRINT 'Validation: Sample data from view';
SELECT TOP 5
    Patient_Classification_Code,
    Patient_Classification_Description
FROM [Analytics].[vw_Dim_IP_Patient_Classification]
ORDER BY Patient_Classification_Code;
GO

PRINT '';
PRINT '========================================';
PRINT 'Dim_IP_Patient_Classification VIEW Created';
PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
PRINT '';
GO

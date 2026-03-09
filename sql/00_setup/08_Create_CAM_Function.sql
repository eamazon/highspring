USE [Data_Lab_SWL_Live];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '========================================';
PRINT 'Creating fn_CommissionerAssignment FUNCTION (Deprecated Wrapper)';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '========================================';
GO

IF OBJECT_ID('[Analytics].[fn_CommissionerAssignment]', 'IF') IS NOT NULL
    DROP FUNCTION [Analytics].[fn_CommissionerAssignment];
GO

/**
Script Name:   08_Create_CAM_Function.sql
Description:   DEPRECATED compatibility wrapper for CAM commissioner assignment output.
               Returns precomputed rows from [Data_Lab_SWL].[CAM].[tbl_CAM_Raw].
Author:        Sridhar Peddi
Created:       2026-01-12 21:45

Change Log:
  2026-01-12  Sridhar Peddi    Initial function creation with inline CAM rules
  2026-03-04  Sridhar Peddi    Deprecate inline rule engine; wrapper now reads CAM.tbl_CAM_Raw
**/
CREATE FUNCTION [Analytics].[fn_CommissionerAssignment]
(
    @FinancialYear VARCHAR(9) = '2025/2026',
    @ProviderCode VARCHAR(10) = NULL,
    @FromDate DATE = NULL,
    @ToDate DATE = NULL
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        c.[RecordIdentifier],
        c.[GP_Practice_Code],
        CAST(NULL AS VARCHAR(20)) AS [CCG_Code],
        CAST(NULL AS VARCHAR(20)) AS [Residence_Code],
        c.[Provider_Code],
        CAST(NULL AS VARCHAR(20)) AS [Current_Commissioner_Code],
        CAST(NULL AS VARCHAR(50)) AS [Current_Service_Category],
        CAST(NULL AS VARCHAR(50)) AS [Current_Service_Code],
        c.[ReassignmentID],
        c.[CAM_Commissioner_Code],
        c.[CAM_Service_Category],
        c.[CAM_Assignment_Reason] AS [Commissioner Assignment Reason],
        CAST(NULL AS DECIMAL(18,2)) AS [TotalCost],
        c.[AdmissionDate],
        c.[DischargeDate],
        CAST(NULL AS VARCHAR(50)) AS [Activity_Type],
        c.[Dataset],
        c.[Commissioner_Variance],
        c.[Service_Category_Variance]
    FROM [Data_Lab_SWL].[CAM].[tbl_CAM_Raw] c
    WHERE c.[Financial_Year] = @FinancialYear
      AND (@ProviderCode IS NULL OR c.[Provider_Code] = @ProviderCode)
      AND (@FromDate IS NULL OR c.[Activity_Date] >= @FromDate)
      AND (@ToDate IS NULL OR c.[Activity_Date] <= @ToDate)
);
GO

PRINT '[OK] Created function: [Analytics].[fn_CommissionerAssignment]';
PRINT '     Note: Deprecated wrapper over [Data_Lab_SWL].[CAM].[tbl_CAM_Raw]';
GO

-- Mark function as deprecated in object metadata for discoverability in SSMS/ADS.
IF EXISTS (
    SELECT 1
    FROM sys.extended_properties ep
    WHERE ep.class = 1
      AND ep.name = N'DEPRECATED'
      AND ep.major_id = OBJECT_ID(N'[Analytics].[fn_CommissionerAssignment]')
      AND ep.minor_id = 0
)
BEGIN
    EXEC sys.sp_updateextendedproperty
        @name = N'DEPRECATED',
        @value = N'Compatibility wrapper only. Use CAM raw pipeline: Analytics.sp_Compute_CAM_Raw -> CAM.tbl_CAM_Raw -> Analytics.sp_Load_CAM_Assignment_Active.',
        @level0type = N'SCHEMA', @level0name = N'Analytics',
        @level1type = N'FUNCTION', @level1name = N'fn_CommissionerAssignment';
END
ELSE
BEGIN
    EXEC sys.sp_addextendedproperty
        @name = N'DEPRECATED',
        @value = N'Compatibility wrapper only. Use CAM raw pipeline: Analytics.sp_Compute_CAM_Raw -> CAM.tbl_CAM_Raw -> Analytics.sp_Load_CAM_Assignment_Active.',
        @level0type = N'SCHEMA', @level0name = N'Analytics',
        @level1type = N'FUNCTION', @level1name = N'fn_CommissionerAssignment';
END
GO

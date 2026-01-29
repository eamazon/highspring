USE [msdb];
GO

/**
Script Name:   10_Create_SQLAgent_Jobs.sql
Description:   SQL Agent job template for HighSpring upstream refresh + CAM/ERF precompute.
Author:        Sridhar Peddi
Created:       2026-01-15

Notes:
- This script is a template. Update @JobName, @ScheduleName, and @Enabled as needed.
- Steps 1-4 run against Data_Lab_SWL.
- Steps 5-6 run against Data_Lab_SWL_Live.
**/

DECLARE @JobName SYSNAME = N'HighSpring_Weekly_Refresh';
DECLARE @ScheduleName SYSNAME = N'HighSpring_Weekly_Refresh_Mon_1830';
DECLARE @Enabled BIT = 0;

IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = @JobName)
BEGIN
    PRINT 'Job already exists: ' + @JobName;
    RETURN;
END

EXEC msdb.dbo.sp_add_job
    @job_name = @JobName,
    @enabled = @Enabled,
    @description = N'HighSpring weekly refresh: Unified SUS + OpPlan + CAM/ERF precompute.',
    @owner_login_name = SUSER_SNAME();

EXEC msdb.dbo.sp_add_jobstep
    @job_name = @JobName,
    @step_name = N'Refresh Unified OP',
    @subsystem = N'TSQL',
    @database_name = N'Data_Lab_SWL',
    @command = N'EXEC [Unified].[sp_Refresh_Active_OP] 0;',
    @on_success_action = 3;

EXEC msdb.dbo.sp_add_jobstep
    @job_name = @JobName,
    @step_name = N'Refresh Unified IP',
    @subsystem = N'TSQL',
    @database_name = N'Data_Lab_SWL',
    @command = N'EXEC [Unified].[sp_Refresh_Active_IP] 12;',
    @on_success_action = 3;

EXEC msdb.dbo.sp_add_jobstep
    @job_name = @JobName,
    @step_name = N'Refresh Unified ED',
    @subsystem = N'TSQL',
    @database_name = N'Data_Lab_SWL',
    @command = N'EXEC [Unified].[sp_Refresh_Active_ED] 12;',
    @on_success_action = 3;

EXEC msdb.dbo.sp_add_jobstep
    @job_name = @JobName,
    @step_name = N'Refresh Operating Plan Metrics',
    @subsystem = N'TSQL',
    @database_name = N'Data_Lab_SWL',
    @command = N'
DECLARE @FinYearStart CHAR(4) =
    CASE WHEN MONTH(GETDATE()) >= 4 THEN CONVERT(CHAR(4), YEAR(GETDATE()))
         ELSE CONVERT(CHAR(4), YEAR(GETDATE()) - 1) END;
DECLARE @JobDescription VARCHAR(250) =
    CONCAT(''SQL Agent Weekly Operating Plan Refresh - '',
           CONVERT(VARCHAR(16), GETDATE(), 120),
           '' ('', DATENAME(WEEKDAY, GETDATE()), '')'');
EXEC [SWL].[sp_OperatingPlan_Metrics_UfS] @FinYearStart, @JobDescription;',
    @on_success_action = 3;

EXEC msdb.dbo.sp_add_jobstep
    @job_name = @JobName,
    @step_name = N'Precompute OpPlan Active',
    @subsystem = N'TSQL',
    @database_name = N'Data_Lab_SWL_Live',
    @command = N'
DECLARE @FinYearStart CHAR(4) =
    CASE WHEN MONTH(GETDATE()) >= 4 THEN CONVERT(CHAR(4), YEAR(GETDATE()))
         ELSE CONVERT(CHAR(4), YEAR(GETDATE()) - 1) END;
EXEC [Analytics].[sp_Load_OpPlan_Active]
    @FinYearStart = @FinYearStart,
    @FromDate = NULL,
    @ToDate = NULL;',
    @on_success_action = 3;

EXEC msdb.dbo.sp_add_jobstep
    @job_name = @JobName,
    @step_name = N'Compute CAM Raw Assignments',
    @subsystem = N'TSQL',
    @database_name = N'Data_Lab_SWL_Live',
    @command = N'
DECLARE @FinYearStart CHAR(4) =
    CASE WHEN MONTH(GETDATE()) >= 4 THEN CONVERT(CHAR(4), YEAR(GETDATE()))
         ELSE CONVERT(CHAR(4), YEAR(GETDATE()) - 1) END;
EXEC [Analytics].[sp_Compute_CAM_Raw]
    @FinYearStart = @FinYearStart,
    @FinancialYear = NULL,
    @ProviderCode = NULL,
    @FromDate = NULL,
    @ToDate = NULL;',
    @on_success_action = 3;

EXEC msdb.dbo.sp_add_jobstep
    @job_name = @JobName,
    @step_name = N'Precompute CAM Assignment Active',
    @subsystem = N'TSQL',
    @database_name = N'Data_Lab_SWL_Live',
    @command = N'
DECLARE @FinYearStart CHAR(4) =
    CASE WHEN MONTH(GETDATE()) >= 4 THEN CONVERT(CHAR(4), YEAR(GETDATE()))
         ELSE CONVERT(CHAR(4), YEAR(GETDATE()) - 1) END;
EXEC [Analytics].[sp_Load_CAM_Assignment_Active]
    @FinYearStart = @FinYearStart,
    @FinancialYear = NULL,
    @ProviderCode = NULL,
    @FromDate = NULL,
    @ToDate = NULL;',
    @on_success_action = 3;

EXEC msdb.dbo.sp_add_jobstep
    @job_name = @JobName,
    @step_name = N'Precompute ERF Repriced Active',
    @subsystem = N'TSQL',
    @database_name = N'Data_Lab_SWL_Live',
    @command = N'
DECLARE @FinYearStart CHAR(4) =
    CASE WHEN MONTH(GETDATE()) >= 4 THEN CONVERT(CHAR(4), YEAR(GETDATE()))
         ELSE CONVERT(CHAR(4), YEAR(GETDATE()) - 1) END;
EXEC [Analytics].[sp_Load_ERF_Repriced_Active]
    @FinYearStart = @FinYearStart,
    @FromDate = NULL,
    @ToDate = NULL;',
    @on_success_action = 1;

EXEC msdb.dbo.sp_add_jobschedule
    @job_name = @JobName,
    @name = @ScheduleName,
    @enabled = @Enabled,
    @freq_type = 8,
    @freq_interval = 2,
    @active_start_time = 183000;

EXEC msdb.dbo.sp_add_jobserver
    @job_name = @JobName;
GO

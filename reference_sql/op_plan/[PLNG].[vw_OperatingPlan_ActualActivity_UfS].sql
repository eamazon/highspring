USE [Data_Lab_SWL]
GO

/****** Object:  View [PLNG].[vw_OperatingPlan_ActualActivity_UfS]    Script Date: 26/01/2026 11:32:59 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




















/**
*--------------------------Change Log------------------------------------------------------------------------------------------
* 21/06/2024 - Sridhar Peddi - Initial Creation
* 21/06/2024 - Sridhar Peddi - Changes to the version
*------------------------------------------------------------------------------------------------------------------------------
*/
ALTER   VIEW  [PLNG].[vw_OperatingPlan_ActualActivity_UfS]
AS
--Adjusted Working Adjustment for the previous years, for the base reference year standardise previou years months. For example if April 2024 has 20 days and April 2019 has 22 reduce the days of April 19 by multiplying with the factor
with AdjYears as (
select FinancialYear, EOMONTH(CAST(CAST(YearMonth AS VARCHAR(8))  as DATE)) as MonthEnding, Factor from [SWL].[fn_StandardiseFY_WorkingDays]('2017/2018','2025/2026')
UNION ALL 
select FinancialYear, EOMONTH(CAST(CAST(YearMonth AS VARCHAR(8))  as DATE)) as MonthEnding, Factor from [SWL].[fn_StandardiseFY_WorkingDays]('2018/2019','2025/2026')
UNION ALL 
select FinancialYear, EOMONTH(CAST(CAST(YearMonth AS VARCHAR(8))  as DATE)) as MonthEnding, Factor from [SWL].[fn_StandardiseFY_WorkingDays]('2019/2020','2025/2026')
UNION ALL 
select FinancialYear, EOMONTH(CAST(CAST(YearMonth AS VARCHAR(8))  as DATE)) as MonthEnding, Factor from [SWL].[fn_StandardiseFY_WorkingDays]('2020/2021','2025/2026')
UNION ALL
select FinancialYear, EOMONTH(CAST(CAST(YearMonth AS VARCHAR(8))  as DATE)) as MonthEnding, Factor from [SWL].[fn_StandardiseFY_WorkingDays]('2021/2022','2025/2026')
UNION ALL
select FinancialYear, EOMONTH(CAST(CAST(YearMonth AS VARCHAR(8))  as DATE)) as MonthEnding, Factor from [SWL].[fn_StandardiseFY_WorkingDays]('2022/2023','2025/2026')
UNION ALL 
select FinancialYear, EOMONTH(CAST(CAST(YearMonth AS VARCHAR(8))  as DATE)) as MonthEnding, Factor from [SWL].[fn_StandardiseFY_WorkingDays]('2023/2024','2025/2026')
UNION ALL 
select FinancialYear, EOMONTH(CAST(CAST(YearMonth AS VARCHAR(8))  as DATE)) as MonthEnding, Factor from [SWL].[fn_StandardiseFY_WorkingDays]('2024/2025','2025/2026')
UNION ALL 
select FinancialYear, EOMONTH(CAST(CAST(YearMonth AS VARCHAR(8))  as DATE)) as MonthEnding, Factor from [SWL].[fn_StandardiseFY_WorkingDays]('2025/2026','2025/2026')
),
--Get hold of the latest version of the data (for example the current year will have multiple versions, each month will have a different version, pick only the latest
maxversion as (
	SELECT a.DataType, a.Id, a.FinancialYear  FROM [PLNG].[tbl_OpPlan_Load_Log_UfS] a
	INNER JOIN (
	select [DataType], [FinancialYear],  MAX([Version]) as [Version]
	from [PLNG].[tbl_OpPlan_Load_Log_UfS] 
	Where JobStatus = 1
	group by [DataType], [FinancialYear]) B on a.DataType = B.DataType and a.FinancialYear = B.FinancialYear and a.Version = B.Version 
	WHERE a.JobStatus =1
)

select
	CONCAT(RTRIM(LTRIM(OrgCode)),'_', a.PlanningRef,'_', a.MeasureId,'_',FiscalCalendarMonthNumber) AS [KEY],
	[ActualValue] as ActualValue,
	[ActualValue] * Factor  as Activity_Incl_WDAdj,
	REPLACE(d.FiscalCalendarYearName,'-','/20') AS dv_FinYear,  
	FiscalCalendarMonthNumber as dv_FinMonth,
	[OrgCode] AS Provider_Code,
	CASE WHEN Category = 'Diagnostic Tests' THEN 'Diagnostic'
     WHEN ShortName = 'Outpatient procedures' THEN 'OutpatientProcedures'
	 WHEN ShortName IN('Day Case Children','Ordinary Children') THEN 'Elective (<18)'
	 ELSE Category END AS POD,
	[PlanningRef] AS POD_Code,
	MeasureName AS [POD Description],
	CASE WHEN MetricID = 1059 THEN 'OutpatientAttendances'
     WHEN MetricID = 1066 THEN 'First (Spec Acute)'
	 WHEN MetricID = 1067 THEN 'Follow (Spec Acute)'
	 WHEN MetricID = 1043 THEN '0 LoS'
	 WHEN MetricID = 1010 THEN 'Imaging'
	 WHEN MetricID = 1016 THEN 'Audio'
	 WHEN MetricID = 1178 THEN 'First'
	 WHEN MetricID = 1179 THEN 'Follow'
	 WHEN MetricID = 1044 THEN '1+ LoS'
	 WHEN MetricID = 1117 THEN '1'
	 WHEN MetricID = 1118 THEN '3'
	 WHEN MetricID = 1062 THEN 'OP Procedures'
	 WHEN MetricID = 1038 THEN 'Daycase'
	 WHEN MetricID = 1039 THEN 'Ordinary'
	 WHEN MetricID = 1040 THEN 'Daycase (<18)'
	 WHEN MetricID = 1041 THEN 'Ordinary (<18)'
	 WHEN MetricID = 1063 THEN 'FA without procedure'
	 WHEN MetricID = 1081 THEN 'FU without procedure)'
	 ELSE SubCategory END AS [Type],
	null AS NHSE_TFC,
	CommissionedBy AS Commissioner,
	a.MeasureId,
	[PlanningRef],
	[Version], -- there should be only the latest version for each financial year
	LogId,
	a.MonthEnding,a.[DataAtInclusionPoint]
 from [Data_Lab_SWL].[PLNG].[tbl_OpPlan_ActualActivity_UfS] a
inner join [Dictionary].[dbo].[Dates] d on d.[FullDate] = MonthEnding
left join AdjYears ay ON ay.FinancialYear = REPLACE(d.FiscalCalendarYearName,'-','/20') and ay.MonthEnding = a.MonthEnding
left join  [IM].[tbl_Metrics_Catalogue] m WITH (NOLOCK) ON m.MetricId = a.MeasureId
--[Data_Lab_SWL_Dev].[SWL].[OperatingPlan_2425_KeyMapping] K ON a.MeasureId = K.MeasureId
INNER JOIN maxversion lv on lv.Id = a.LogId
WHERE MeasureId NOT IN ( 1046,1047,1152,1153) -- this is to help bring in only A&E type 1&3 FA 06/06/2025
GO



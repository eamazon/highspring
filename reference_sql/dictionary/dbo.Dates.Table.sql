USE [Dictionary]
GO
/****** Object:  Table [dbo].[Dates]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Dates](
	[SK_Date] [int] NOT NULL,
	[FullDate] [date] NOT NULL,
	[Day] [smallint] NOT NULL,
	[DateSuffix] [char](2) NOT NULL,
	[DayOfWeek] [varchar](9) NOT NULL,
	[DayOfWeekNumber] [tinyint] NOT NULL,
	[DayOfYearNumber] [smallint] NOT NULL,
	[WeekOfYearNumber] [tinyint] NOT NULL,
	[ISOWeekOfYearNumber] [tinyint] NOT NULL,
	[WeekOfMonthNumber] [tinyint] NOT NULL,
	[CalendarMonthNumber] [tinyint] NOT NULL,
	[CalendarMonthName] [varchar](30) NOT NULL,
	[CalendarQuarterNumber] [tinyint] NOT NULL,
	[CalendarQuarterName] [varchar](6) NOT NULL,
	[CalendarYearNumber] [smallint] NOT NULL,
	[FiscalCalendarMonthNumber] [tinyint] NOT NULL,
	[FiscalCalendarMonthName] [varchar](30) NOT NULL,
	[FiscalCalendarQuarterNumber] [tinyint] NOT NULL,
	[FiscalCalendarQuarterName] [varchar](6) NOT NULL,
	[FiscalCalendarYearNumber] [smallint] NOT NULL,
	[FiscalCalendarYearName] [char](7) NOT NULL,
	[IsWeekend] [bit] NOT NULL,
	[IsEndOfMonth] [bit] NOT NULL,
	[IsEndOfYear] [bit] NOT NULL,
	[IsEndOfFiscalYear] [bit] NOT NULL,
	[DayOfFiscalYearNumber] [smallint] NOT NULL,
	[WeekOfFiscalYearNumber] [tinyint] NOT NULL,
	[IsEndOfWeek] [bit] NOT NULL,
	[IsEndOfQuarter] [bit] NOT NULL,
	[StartOfWeekDate] [date] NOT NULL,
	[StartOfMonthDate] [date] NOT NULL,
	[StartOfQuarterDate] [date] NOT NULL,
	[StartOfYearDate] [date] NOT NULL,
	[StartOfFiscalYearDate] [date] NOT NULL,
	[EndOfWeekDate] [date] NOT NULL,
	[EndOfMonthDate] [date] NOT NULL,
	[EndOfQuarterDate] [date] NOT NULL,
	[EndOfYearDate] [date] NOT NULL,
	[EndOfFiscalYearDate] [date] NOT NULL,
	[ISODayOfWeekNumber] [tinyint] NOT NULL,
	[IsLeapYear] [bit] NOT NULL,
	[ISOWeekOfFiscalYearNumber] [tinyint] NOT NULL,
	[StartOfISOWeekDate] [date] NOT NULL,
	[EndOfISOWeekDate] [date] NOT NULL,
	[ISOWeekOfMonthNumber] [tinyint] NOT NULL,
	[IsEndOfISOWeek] [bit] NOT NULL,
	[FiscalCalendarQuarterNameQ] [char](2) NOT NULL,
	[CalendarQuarterNameQ] [char](2) NOT NULL,
	[CalendarQuarterNameYQ] [char](7) NOT NULL,
	[FiscalCalendarQuarterNameYQ] [char](10) NOT NULL,
	[DayName] [varchar](20) NOT NULL,
	[DayOfQuarterNumber] [tinyint] NOT NULL,
	[FiscalCalendarMonthNameM] [varchar](3) NOT NULL,
	[FiscalCalendarMonthNameYM] [varchar](11) NOT NULL,
 CONSTRAINT [PK_dbo_Dates] PRIMARY KEY CLUSTERED 
(
	[SK_Date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

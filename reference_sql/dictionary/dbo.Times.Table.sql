USE [Dictionary]
GO
/****** Object:  Table [dbo].[Times]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Times](
	[SK_Time] [smallint] NOT NULL,
	[FullTime] [time](0) NOT NULL,
	[FullTime12H] [char](8) NOT NULL,
	[Hours] [tinyint] NOT NULL,
	[Hours12H] [tinyint] NOT NULL,
	[Minutes] [tinyint] NOT NULL,
	[TimeSuffex] [char](2) NOT NULL,
	[IsMorning] [bit] NOT NULL,
	[HoursName] [char](5) NOT NULL,
	[Hours12HName] [char](5) NOT NULL,
	[QuarterOfDay] [tinyint] NOT NULL,
	[QuarterOfDayName] [varchar](25) NOT NULL,
	[QuarterOfDayNameShort] [varchar](10) NOT NULL,
	[QuarterOfHour] [tinyint] NOT NULL,
	[QuarterOfHourName] [varchar](25) NOT NULL,
	[QuarterOfHourShort] [varchar](10) NOT NULL,
 CONSTRAINT [PK_dbo_Times] PRIMARY KEY CLUSTERED 
(
	[SK_Time] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

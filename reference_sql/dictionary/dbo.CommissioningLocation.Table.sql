USE [Dictionary]
GO
/****** Object:  Table [dbo].[CommissioningLocation]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CommissioningLocation](
	[SK_CCGLocationId] [smallint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[CommissionerCode] [varchar](10) NOT NULL,
	[CommissioningRegionCode] [varchar](3) NOT NULL,
	[CommissioningRegion] [varchar](255) NOT NULL,
	[LocalAreaTeamCode] [varchar](3) NOT NULL,
	[LocalAreaTeam] [varchar](255) NOT NULL,
	[CommissioningCounty] [varchar](50) NOT NULL,
	[CommissioningCountry] [varchar](100) NOT NULL,
	[DateCreated] [smalldatetime] NOT NULL,
	[DateUpdated] [smalldatetime] NOT NULL,
	[StartDate]  AS (CONVERT([date],[DateCreated])),
	[EndDate]  AS (CONVERT([date],NULL)),
 CONSTRAINT [PK_dbo_CommissioningLocation] PRIMARY KEY NONCLUSTERED 
(
	[SK_CCGLocationId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

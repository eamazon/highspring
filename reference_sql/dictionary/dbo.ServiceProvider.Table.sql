USE [Dictionary]
GO
/****** Object:  Table [dbo].[ServiceProvider]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ServiceProvider](
	[SK_ServiceProviderID] [int] IDENTITY(100,1) NOT FOR REPLICATION NOT NULL,
	[ServiceProviderCode] [varchar](10) NULL,
	[ServiceProviderName] [varchar](100) NULL,
	[ServiceProviderType] [tinyint] NULL,
	[SK_PostcodeID] [int] NULL,
	[StartDate] [date] NULL,
	[EndDate] [date] NULL,
	[DateCreated] [smalldatetime] NULL,
	[DateUpdated] [smalldatetime] NULL,
	[SK_ServiceProviderGroupID] [int] NULL,
	[IsActive] [bit] NOT NULL,
	[IsMainSite] [bit] NOT NULL,
	[IsTestOrganisation] [bit] NOT NULL,
	[IsDormant] [bit] NOT NULL,
	[ServiceProviderFullCode]  AS (case when len([ServiceProviderCode])=(5) AND right([ServiceProviderCode],(2))='00' AND ([ServiceProviderType]=(13) OR [ServiceProviderType]=(9) OR [ServiceProviderType]=(3)) then left([ServiceProviderCode],(3)) else [ServiceProviderCode] end) PERSISTED,
 CONSTRAINT [PK_dbo_ServiceProvider] PRIMARY KEY CLUSTERED 
(
	[SK_ServiceProviderID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_dbo_ServiceProvider_BK] UNIQUE NONCLUSTERED 
(
	[ServiceProviderCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

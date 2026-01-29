USE [Dictionary]
GO
/****** Object:  Table [dbo].[ServiceProviderGroup]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ServiceProviderGroup](
	[SK_ServiceProviderGroupID] [int] NOT NULL,
	[ServiceProviderGroupName] [varchar](100) NULL,
	[ServiceProviderGroupCode] [varchar](15) NULL,
	[SK_ServiceProviderTypeID] [tinyint] NULL,
	[StartDate] [date] NULL,
	[EndDate] [date] NULL,
	[IsTestOrganisation] [bit] NOT NULL,
 CONSTRAINT [PK_dbo_ServiceProviderGroup] PRIMARY KEY CLUSTERED 
(
	[SK_ServiceProviderGroupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

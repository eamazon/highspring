USE [Dictionary]
GO
/****** Object:  Table [dbo].[Commissioner]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Commissioner](
	[SK_CommissionerID] [smallint] IDENTITY(10,1) NOT FOR REPLICATION NOT NULL,
	[CommissionerName] [varchar](255) NULL,
	[CommissionerType] [tinyint] NULL,
	[CommissionerCode] [varchar](10) NULL,
	[StartDate] [date] NULL,
	[EndDate] [date] NULL,
	[DateCreated] [smalldatetime] NULL,
	[DateUpdated] [smalldatetime] NULL,
	[SK_ServiceProviderGroupID] [int] NULL,
	[IsCustomer] [bit] NOT NULL,
	[IsTestOrganisation] [bit] NOT NULL,
 CONSTRAINT [PK_dbo_Commissioner] PRIMARY KEY CLUSTERED 
(
	[SK_CommissionerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_dbo_Commissioner_BK] UNIQUE NONCLUSTERED 
(
	[CommissionerCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_dbo_Commissioner_SK_ServiceProviderGroupID] UNIQUE NONCLUSTERED 
(
	[SK_ServiceProviderGroupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

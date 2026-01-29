USE [Dictionary]
GO
/****** Object:  Table [dbo].[ServiceProviderHierarchy]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ServiceProviderHierarchy](
	[SK_ServiceProviderGroupID] [int] NOT NULL,
	[SK_ServiceProviderGroupParentID] [int] NULL,
	[Level] [tinyint] NULL,
	[DateCreated] [smalldatetime] NOT NULL,
	[DateUpdated] [smalldatetime] NOT NULL,
 CONSTRAINT [PK_dbo_ServiceProviderHierarchy] PRIMARY KEY NONCLUSTERED 
(
	[SK_ServiceProviderGroupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

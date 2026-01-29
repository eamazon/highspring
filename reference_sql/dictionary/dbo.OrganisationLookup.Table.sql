USE [Dictionary]
GO
/****** Object:  Table [dbo].[OrganisationLookup]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OrganisationLookup](
	[SK_OrganisationID] [int] NOT NULL,
	[SK_CommissionerID] [smallint] NULL,
	[SK_ServiceProviderID] [int] NULL,
	[SK_ServiceProviderGroupID] [int] NULL,
	[SK_Organisation_ID]  AS ([SK_OrganisationID]),
 CONSTRAINT [PK_dbo_OrganisationLookup] PRIMARY KEY CLUSTERED 
(
	[SK_OrganisationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

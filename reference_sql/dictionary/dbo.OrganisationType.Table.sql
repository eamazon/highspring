USE [Dictionary]
GO
/****** Object:  Table [dbo].[OrganisationType]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OrganisationType](
	[SK_OrganisationTypeID] [tinyint] NOT NULL,
	[OrganisationType] [varchar](150) NOT NULL,
	[ShortOrganisationType] [varchar](75) NULL,
	[CodeAllocatedBy] [varchar](100) NULL,
	[IsOrganisationCode] [bit] NOT NULL,
	[IsLocationCode] [bit] NOT NULL,
	[SK_ServiceProviderTypeID] [tinyint] NULL,
 CONSTRAINT [PK_dbo_OrganisationType] PRIMARY KEY CLUSTERED 
(
	[SK_OrganisationTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

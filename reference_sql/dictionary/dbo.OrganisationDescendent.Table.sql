USE [Dictionary]
GO
/****** Object:  Table [dbo].[OrganisationDescendent]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OrganisationDescendent](
	[SK_OrganisationID_Root] [int] NOT NULL,
	[OrganisationCode_Root] [varchar](15) NOT NULL,
	[OrganisationPrimaryRole_Root] [varchar](5) NULL,
	[SK_OrganisationID_Parent] [int] NOT NULL,
	[OrganisationCode_Parent] [varchar](15) NOT NULL,
	[OrganisationPrimaryRole_Parent] [varchar](5) NULL,
	[SK_OrganisationID_Child] [int] NOT NULL,
	[OrganisationCode_Child] [varchar](15) NOT NULL,
	[OrganisationPrimaryRole_Child] [varchar](5) NULL,
	[RelationshipType] [varchar](5) NOT NULL,
	[RelationshipStartDate] [date] NOT NULL,
	[RelationshipEndDate] [date] NOT NULL,
	[Path] [varchar](500) NOT NULL,
	[Depth] [tinyint] NOT NULL,
	[PathStartDate] [date] NOT NULL,
	[PathEndDate] [date] NOT NULL,
	[DateAdded] [date] NOT NULL,
	[DateUpdated] [date] NOT NULL,
 CONSTRAINT [PK_dbo_OrganisationDescendent] PRIMARY KEY CLUSTERED 
(
	[Path] ASC,
	[PathStartDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

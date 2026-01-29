USE [Dictionary]
GO
/****** Object:  Table [dbo].[PODTeams]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PODTeams](
	[SK_PODTeamID] [tinyint] NOT NULL,
	[PODTeamCode] [varchar](255) NULL,
	[PODTeamName] [varchar](50) NULL,
	[SK_ServiceProviderGroupID] [int] NULL,
	[IsTestOrganisation] [bit] NOT NULL,
	[Region] [varchar](50) NULL,
 CONSTRAINT [PK_dbo_PODTeams] PRIMARY KEY CLUSTERED 
(
	[SK_PODTeamID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

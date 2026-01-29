USE [Dictionary]
GO
/****** Object:  Table [dbo].[PODCommissioners]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PODCommissioners](
	[SK_CommissionerID] [smallint] NOT NULL,
	[SK_PODTeamID] [tinyint] NOT NULL,
	[SK_PCTID] [smallint] NOT NULL,
	[SK_OrganisationID_Commissioner] [int] NULL,
 CONSTRAINT [PK_PODCommissioners] PRIMARY KEY CLUSTERED 
(
	[SK_CommissionerID] ASC,
	[SK_PODTeamID] ASC,
	[SK_PCTID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

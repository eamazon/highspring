USE [Dictionary]
GO
/****** Object:  Table [IP].[LastEpisodeInSpellIndicator]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [IP].[LastEpisodeInSpellIndicator](
	[SK_LastEpisodeInSpellIndicatorID] [tinyint] NOT NULL,
	[BK_LastEpisodeInSpellIndicator] [char](2) NOT NULL,
	[LastEpisodeInSpellIndicator] [varchar](100) NOT NULL,
 CONSTRAINT [PK_IP_LastEpisodeInSpellIndicator] PRIMARY KEY CLUSTERED 
(
	[SK_LastEpisodeInSpellIndicatorID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_IP_LastEpisodeInSpellIndicator] UNIQUE NONCLUSTERED 
(
	[BK_LastEpisodeInSpellIndicator] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

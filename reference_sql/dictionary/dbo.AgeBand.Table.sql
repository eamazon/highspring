USE [Dictionary]
GO
/****** Object:  Table [dbo].[AgeBand]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AgeBand](
	[SK_AgeBandID] [tinyint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[BK_AgeBand] [varchar](10) NOT NULL,
	[AgeBandStarts] [smallint] NOT NULL,
	[AgeBandEnds] [smallint] NOT NULL,
	[CreatedDateTime] [smalldatetime] NOT NULL,
	[LastUpdateDateTime] [smalldatetime] NOT NULL,
 CONSTRAINT [PK_dbo_AgeBand] PRIMARY KEY CLUSTERED 
(
	[SK_AgeBandID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

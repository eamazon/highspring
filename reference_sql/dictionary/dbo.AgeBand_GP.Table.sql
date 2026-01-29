USE [Dictionary]
GO
/****** Object:  Table [dbo].[AgeBand_GP]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AgeBand_GP](
	[SK_AgeBandGPID] [tinyint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[BK_AgeBandGP] [varchar](10) NOT NULL,
	[AgeBandStarts] [smallint] NOT NULL,
	[AgeBandEnds] [smallint] NOT NULL,
	[CreatedDateTime] [smalldatetime] NOT NULL,
	[LastUpdateDateTime] [smalldatetime] NOT NULL,
	[SK_AgeBandID]  AS ([SK_AgeBandGPID]),
	[BK_AgeBand]  AS ([BK_AgeBandGP]),
 CONSTRAINT [PK_dbo_AgeBand_GP] PRIMARY KEY CLUSTERED 
(
	[SK_AgeBandGPID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

USE [Dictionary]
GO
/****** Object:  Table [dbo].[ReadCodes]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReadCodes](
	[SK_ReadCodeID] [int] IDENTITY(100,1) NOT FOR REPLICATION NOT NULL,
	[ReadCode] [varchar](20) NOT NULL,
	[Term] [varchar](200) NOT NULL,
	[SnomedCTCode] [bigint] NOT NULL,
	[InNationalDataset] [bit] NOT NULL,
	[DateCreated] [smalldatetime] NOT NULL,
	[DateUpdated] [smalldatetime] NOT NULL,
	[IsSensitive] [bit] NOT NULL,
	[SK_ReadCodeParentID] [int] NULL,
	[SK_BNFChapterID] [int] NULL,
	[IsReadV2] [bit] NULL,
	[IsCTV3] [bit] NULL,
	[ReadCodeAlt] [char](5) NULL,
	[SK_ReadCodeParentID_ReadV2] [int] NULL,
	[SK_ReadCodeParentID_CTV3] [int] NULL,
	[MatchesReadCodeRegex] [bit] NULL,
 CONSTRAINT [PK_dbo_ReadCodes] PRIMARY KEY CLUSTERED 
(
	[SK_ReadCodeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_dbo_ReadCodes] UNIQUE NONCLUSTERED 
(
	[ReadCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

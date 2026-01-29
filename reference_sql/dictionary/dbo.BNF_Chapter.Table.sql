USE [Dictionary]
GO
/****** Object:  Table [dbo].[BNF_Chapter]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BNF_Chapter](
	[SK_BNFChapterID] [int] NOT NULL,
	[SK_BNFChapterParentID] [int] NULL,
	[Chapter_Code] [varchar](10) NOT NULL,
	[Chapter_Code_Alt] [varchar](7) NOT NULL,
	[Chapter_Code_Alt_Pad]  AS (isnull(CONVERT([char](7),left([Chapter_Code_Alt]+'00000',(7))),'0000000')),
	[Chapter_Name] [varchar](150) NOT NULL,
	[Chapter_Path] [varchar](500) NOT NULL,
	[Chapter_Path_Depth] [tinyint] NOT NULL,
	[IsOfficialBNF] [bit] NOT NULL,
	[URL] [varchar](500) NULL,
	[DateCreated] [smalldatetime] NOT NULL,
	[DateUpdated] [smalldatetime] NOT NULL,
 CONSTRAINT [PK_dbo_BNF_Chapter] PRIMARY KEY NONCLUSTERED 
(
	[SK_BNFChapterID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_dbo_BNF_Chapter] UNIQUE CLUSTERED 
(
	[Chapter_Code_Alt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

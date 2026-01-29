USE [Dictionary]
GO
/****** Object:  Table [dbo].[HRG]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HRG](
	[SK_HRGID] [smallint] NOT NULL,
	[HRGCode] [varchar](10) NULL,
	[HRGDescription] [varchar](255) NULL,
	[HRGChapterKey] [varchar](2) NULL,
	[HRGChapter] [varchar](255) NULL,
	[HRGSubchapterKey] [varchar](2) NULL,
	[HRGSubchapter] [varchar](255) NULL,
	[HRG_Version] [varchar](3) NULL,
	[DateCreated] [smalldatetime] NULL,
	[DateUpdated] [smalldatetime] NULL,
 CONSTRAINT [PK_HRG] PRIMARY KEY CLUSTERED 
(
	[SK_HRGID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_HRG] UNIQUE NONCLUSTERED 
(
	[HRGCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

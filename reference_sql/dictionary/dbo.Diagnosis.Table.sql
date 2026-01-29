USE [Dictionary]
GO
/****** Object:  Table [dbo].[Diagnosis]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Diagnosis](
	[SK_DiagnosisID] [smallint] NOT NULL,
	[Code] [varchar](5) NOT NULL,
	[AltCode] [varchar](6) NOT NULL,
	[Description] [varchar](255) NULL,
	[ShortDescription] [varchar](255) NULL,
	[Modifiers] [varchar](255) NULL,
	[Chapter_Number] [tinyint] NULL,
	[Chapter] [varchar](255) NULL,
	[SubChapter] [varchar](255) NULL,
	[Gender_Mask] [tinyint] NULL,
	[Min_Age] [tinyint] NULL,
	[Max_Age] [tinyint] NULL,
	[DateCreated] [smalldatetime] NULL,
	[DateUpdated] [smalldatetime] NULL,
	[SubChapterCode] [char](7) NULL,
	[SubChapter2] [varchar](255) NULL,
	[SubChapter2Code] [char](7) NULL,
	[SubChapter3] [varchar](255) NULL,
	[SubChapter3Code] [char](7) NULL,
 CONSTRAINT [PK_dbo_Diagnosis] PRIMARY KEY CLUSTERED 
(
	[SK_DiagnosisID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_dbo_Diagnosis_AltCode] UNIQUE NONCLUSTERED 
(
	[AltCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_dbo_Diagnosis_Code] UNIQUE NONCLUSTERED 
(
	[Code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

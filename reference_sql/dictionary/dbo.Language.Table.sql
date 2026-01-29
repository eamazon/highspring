USE [Dictionary]
GO
/****** Object:  Table [dbo].[Language]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Language](
	[SK_LanguageID] [smallint] IDENTITY(10,1) NOT FOR REPLICATION NOT NULL,
	[LanguageSpoken] [varchar](100) NULL,
	[CDSCode] [varchar](5) NULL,
	[Read2Code] [varchar](20) NULL,
	[DateCreated] [smalldatetime] NULL,
	[DateUpdated] [smalldatetime] NULL,
 CONSTRAINT [PK_Language] PRIMARY KEY CLUSTERED 
(
	[SK_LanguageID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

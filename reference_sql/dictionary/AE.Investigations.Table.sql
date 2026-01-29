USE [Dictionary]
GO
/****** Object:  Table [AE].[Investigations]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [AE].[Investigations](
	[SK_InvestigationID] [tinyint] NOT NULL,
	[InvestigationCode] [varchar](6) NOT NULL,
	[InvestigationDescription] [varchar](100) NOT NULL,
 CONSTRAINT [PK_AE_Investigations] PRIMARY KEY CLUSTERED 
(
	[SK_InvestigationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

USE [Dictionary]
GO
/****** Object:  Table [dbo].[OverseasVisitorStatusClassification]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OverseasVisitorStatusClassification](
	[SK_OverseasVisitorStatusClassificationID] [tinyint] NOT NULL,
	[BK_OverseasVisitorStatusClassification] [char](2) NOT NULL,
	[OverseasVisitorStatusClassification] [varchar](200) NOT NULL,
 CONSTRAINT [PK_dbo_OverseasVisitorStatusClassification] PRIMARY KEY CLUSTERED 
(
	[SK_OverseasVisitorStatusClassificationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_dbo_OverseasVisitorStatusClassification] UNIQUE NONCLUSTERED 
(
	[BK_OverseasVisitorStatusClassification] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

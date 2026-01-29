USE [Dictionary]
GO
/****** Object:  Table [dbo].[Age]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Age](
	[SK_AgeID] [tinyint] NOT NULL,
	[Age] [varchar](11) NOT NULL,
	[SK_AgeBandID] [tinyint] NOT NULL,
	[SK_AgeBandGPID] [tinyint] NOT NULL,
 CONSTRAINT [PK_dbo_Age] PRIMARY KEY CLUSTERED 
(
	[SK_AgeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

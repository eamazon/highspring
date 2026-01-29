USE [Dictionary]
GO
/****** Object:  Table [dbo].[CostBand]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CostBand](
	[SK_CostBandID] [tinyint] NOT NULL,
	[CostBandLabel] [varchar](10) NOT NULL,
	[CostBandStart] [int] NOT NULL,
	[CostBandEnd] [int] NOT NULL,
 CONSTRAINT [PK_dbo_CostBand] PRIMARY KEY CLUSTERED 
(
	[SK_CostBandID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

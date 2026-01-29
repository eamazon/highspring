USE [Dictionary]
GO
/****** Object:  Table [dbo].[RTTPeriodStatus]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RTTPeriodStatus](
	[SK_RTTPeriodStatusID] [tinyint] NOT NULL,
	[BK_RTTPeriodStatusCode] [varchar](2) NOT NULL,
	[RTTPeriodStatusCategory] [varchar](250) NULL,
	[RTTPeriodStatusDescription] [varchar](350) NOT NULL,
	[Notes] [varchar](1000) NULL,
 CONSTRAINT [PK_dbo_RTTPeriodStatus] PRIMARY KEY CLUSTERED 
(
	[SK_RTTPeriodStatusID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_dbo_RTTPeriodStatus] UNIQUE NONCLUSTERED 
(
	[BK_RTTPeriodStatusCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

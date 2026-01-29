USE [Dictionary]
GO
/****** Object:  Table [dbo].[CarerSupportIndicator]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CarerSupportIndicator](
	[SK_CarerSupportIndicatorID] [tinyint] NOT NULL,
	[BK_CarerSupportIndicator] [char](2) NOT NULL,
	[CarerSupportIndicator] [varchar](100) NOT NULL,
 CONSTRAINT [PK_dbo_CarerSupportIndicator] PRIMARY KEY CLUSTERED 
(
	[SK_CarerSupportIndicatorID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_dbo_CarerSupportIndicator] UNIQUE NONCLUSTERED 
(
	[BK_CarerSupportIndicator] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

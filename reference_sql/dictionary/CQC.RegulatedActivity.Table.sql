USE [Dictionary]
GO
/****** Object:  Table [CQC].[RegulatedActivity]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [CQC].[RegulatedActivity](
	[SK_RegulatedActivityID] [tinyint] NOT NULL,
	[RegulatedActivityCode] [varchar](5) NOT NULL,
	[RegulatedActivityName] [varchar](200) NOT NULL,
 CONSTRAINT [PK_CQC_RegulatedActivity] PRIMARY KEY CLUSTERED 
(
	[SK_RegulatedActivityID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_CQC_RegulatedActivity_Code] UNIQUE NONCLUSTERED 
(
	[RegulatedActivityCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

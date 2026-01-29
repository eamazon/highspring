USE [Dictionary]
GO
/****** Object:  Table [OP].[DNAIndicators]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [OP].[DNAIndicators](
	[SK_DNAIndicatorID] [tinyint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[BK_DNACode] [varchar](2) NOT NULL,
	[DNAIndicatorDesc] [varchar](100) NOT NULL,
	[DNAIndicatorStatus] [varchar](10) NOT NULL,
	[DateCreated] [smalldatetime] NOT NULL,
	[DateUpdated] [smalldatetime] NULL,
 CONSTRAINT [PK_OP_DNAIndicators] PRIMARY KEY CLUSTERED 
(
	[SK_DNAIndicatorID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

USE [Dictionary]
GO
/****** Object:  Table [OP].[PriorityType]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [OP].[PriorityType](
	[SK_PriorityTypeID] [tinyint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[BK_PriorityTypeCode] [varchar](2) NOT NULL,
	[PriorityTypeDesc] [varchar](20) NULL,
	[DateCreated] [smalldatetime] NULL,
	[DateUpdated] [smalldatetime] NULL,
 CONSTRAINT [PK_OP_PriorityType] PRIMARY KEY CLUSTERED 
(
	[SK_PriorityTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

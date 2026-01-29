USE [Dictionary]
GO
/****** Object:  Table [dbo].[OperationStatus]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OperationStatus](
	[SK_OperationStatusID] [tinyint] NOT NULL,
	[BK_OperationStatus] [varchar](2) NOT NULL,
	[OperationStatus] [varchar](200) NOT NULL,
 CONSTRAINT [PK_dbo_OperationStatus] PRIMARY KEY CLUSTERED 
(
	[SK_OperationStatusID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_dbo_OperationStatus] UNIQUE NONCLUSTERED 
(
	[BK_OperationStatus] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

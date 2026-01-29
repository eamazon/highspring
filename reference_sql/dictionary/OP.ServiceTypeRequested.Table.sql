USE [Dictionary]
GO
/****** Object:  Table [OP].[ServiceTypeRequested]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [OP].[ServiceTypeRequested](
	[SK_ServiceTypeRequestedID] [tinyint] NOT NULL,
	[BK_ServiceTypeRequestedCode] [varchar](2) NOT NULL,
	[ServiceTypeRequestedDescription] [varchar](250) NULL,
 CONSTRAINT [PK_OP_ServiceTypeRequested] PRIMARY KEY CLUSTERED 
(
	[SK_ServiceTypeRequestedID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_OP_ServiceTypeRequested] UNIQUE NONCLUSTERED 
(
	[BK_ServiceTypeRequestedCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

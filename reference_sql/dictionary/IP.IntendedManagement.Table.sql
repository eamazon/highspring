USE [Dictionary]
GO
/****** Object:  Table [IP].[IntendedManagement]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [IP].[IntendedManagement](
	[SK_IntendedManagementID] [tinyint] NOT NULL,
	[BK_IntendedManagementCode] [varchar](2) NOT NULL,
	[IntendedManagementDescription] [varchar](250) NOT NULL,
 CONSTRAINT [PK_IP_IntendedManagement] PRIMARY KEY CLUSTERED 
(
	[SK_IntendedManagementID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_IP_IntendedManagement] UNIQUE NONCLUSTERED 
(
	[BK_IntendedManagementCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

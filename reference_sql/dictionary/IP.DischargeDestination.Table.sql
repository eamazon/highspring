USE [Dictionary]
GO
/****** Object:  Table [IP].[DischargeDestination]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [IP].[DischargeDestination](
	[SK_DischargeDestinationID] [tinyint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[BK_DischargeDestinationCode] [varchar](5) NULL,
	[DischargeDestinationName] [varchar](255) NULL,
 CONSTRAINT [PK_IP_DischargeDestination] PRIMARY KEY CLUSTERED 
(
	[SK_DischargeDestinationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

USE [Dictionary]
GO
/****** Object:  Table [IP].[DischargeMethod]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [IP].[DischargeMethod](
	[SK_DischargeMethodID] [tinyint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[BK_DischargeMethodCode] [varchar](5) NULL,
	[DischargeMethodName] [varchar](255) NULL,
 CONSTRAINT [PK_IP_DischargeMethod] PRIMARY KEY CLUSTERED 
(
	[SK_DischargeMethodID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

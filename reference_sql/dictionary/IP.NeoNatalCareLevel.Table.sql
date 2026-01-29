USE [Dictionary]
GO
/****** Object:  Table [IP].[NeoNatalCareLevel]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [IP].[NeoNatalCareLevel](
	[SK_NeoNatalCareLevelID] [tinyint] IDENTITY(0,1) NOT FOR REPLICATION NOT NULL,
	[NeoNatalCareCode] [varchar](4) NULL,
	[ShortCareDescription] [varchar](200) NULL,
	[LongCareDescription] [varchar](600) NULL,
 CONSTRAINT [PK_IP_NeoNatalCareLevel] PRIMARY KEY CLUSTERED 
(
	[SK_NeoNatalCareLevelID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

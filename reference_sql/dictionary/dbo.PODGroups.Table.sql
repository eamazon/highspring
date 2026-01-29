USE [Dictionary]
GO
/****** Object:  Table [dbo].[PODGroups]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PODGroups](
	[SK_PodGroupID] [smallint] NOT NULL,
	[PodDisplay] [varchar](100) NULL,
	[PodDataset] [varchar](100) NULL,
	[PodMainGroup] [varchar](100) NULL,
	[PodSubGroup] [varchar](100) NULL,
	[DateCreated] [smalldatetime] NULL,
	[DateUpdated] [smalldatetime] NULL,
 CONSTRAINT [PK_PodGroups] PRIMARY KEY CLUSTERED 
(
	[SK_PodGroupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

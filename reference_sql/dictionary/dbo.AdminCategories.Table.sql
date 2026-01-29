USE [Dictionary]
GO
/****** Object:  Table [dbo].[AdminCategories]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AdminCategories](
	[SK_AdminCategoryID] [smallint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[BK_AdminCategoryCode] [char](2) NOT NULL,
	[AdminCategoryName] [varchar](50) NOT NULL,
	[AdminCategoryFullName] [varchar](350) NOT NULL,
	[DateCreated] [smalldatetime] NOT NULL,
	[DateUpdated] [smalldatetime] NOT NULL,
	[BK_AdminCategoryCode_TinyInt]  AS (CONVERT([tinyint],[BK_AdminCategoryCode])),
 CONSTRAINT [PK_AdminCategories] PRIMARY KEY CLUSTERED 
(
	[SK_AdminCategoryID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

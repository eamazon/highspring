USE [Dictionary]
GO
/****** Object:  Table [dbo].[EthnicityCode]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EthnicityCode](
	[SK_EthnicityID] [tinyint] NOT NULL,
	[EthnicityCodeType] [varchar](25) NOT NULL,
	[EthnicCategoryCode] [varchar](2) NULL,
	[EthnicGroupCode] [char](1) NULL,
	[ICCode] [char](3) NULL,
	[PDSEthnicCategoryCode] [varchar](2) NULL,
	[ReadCode] [varchar](5) NULL,
	[SDECode] [char](2) NULL,
	[Description] [varchar](200) NOT NULL,
	[Priority] [tinyint] NOT NULL,
	[Snomed] [bigint] NULL,
 CONSTRAINT [PK_dbo_EthnicityCode] PRIMARY KEY NONCLUSTERED 
(
	[EthnicityCodeType] ASC,
	[Description] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

USE [Dictionary]
GO
/****** Object:  Table [dbo].[Ethnicity]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Ethnicity](
	[SK_EthnicityID] [smallint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[BK_EthnicityCode] [varchar](25) NULL,
	[EthnicityHESCode] [varchar](1) NULL,
	[EthnicityCodeType] [varchar](25) NULL,
	[EthnicityCombinedCode] [varchar](4) NULL,
	[EthnicityDesc] [varchar](150) NULL,
	[EthnicityDesc2] [varchar](150) NULL,
	[EthnicityDescRead] [varchar](150) NULL,
	[DateStart] [date] NULL,
	[DateEnd] [date] NULL,
	[DateLastUpdate] [date] NULL,
 CONSTRAINT [PK_Ethnicity] PRIMARY KEY CLUSTERED 
(
	[SK_EthnicityID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

USE [Dictionary]
GO
/****** Object:  Table [dbo].[ONSCodeEquivalent]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ONSCodeEquivalent](
	[Geography_Code] [varchar](9) NOT NULL,
	[Geography_Name] [varchar](255) NULL,
	[Geography_Name_Welsh] [varchar](255) NULL,
	[ONS_Geography_Code] [varchar](10) NULL,
	[ONS_Geography_Name] [varchar](255) NULL,
	[DCLG_Geography_Code] [varchar](10) NULL,
	[DCLG_Geography_Name] [varchar](255) NULL,
	[DH_Geography_Code] [varchar](10) NULL,
	[DH_Geography_Name] [varchar](255) NULL,
	[Scottish_Geography_Code] [varchar](10) NULL,
	[Scottish_Geography_Name] [varchar](255) NULL,
	[NI_Geography_Code] [varchar](10) NULL,
	[NI_Geography_Name] [varchar](255) NULL,
	[WG_Geography_Code] [varchar](10) NULL,
	[WG_Geography_Name] [varchar](255) NULL,
	[WG_Geography_Name_Welsh] [varchar](255) NULL,
	[Entity_Code] [varchar](3) NOT NULL,
	[Status] [varchar](10) NOT NULL,
	[Date_Of_Introduction] [date] NOT NULL,
	[Date_Of_Termination] [date] NULL,
	[Created_Date] [datetime] NOT NULL,
	[Import_Date] [datetime] NOT NULL,
 CONSTRAINT [PK_dbo_ONSCodeEquivalent] PRIMARY KEY CLUSTERED 
(
	[Geography_Code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

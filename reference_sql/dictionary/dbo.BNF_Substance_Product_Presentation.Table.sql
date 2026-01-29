USE [Dictionary]
GO
/****** Object:  Table [dbo].[BNF_Substance_Product_Presentation]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BNF_Substance_Product_Presentation](
	[SK_BNFID] [int] NOT NULL,
	[SK_BNFParentID] [int] NOT NULL,
	[SK_BNFChapterID] [int] NOT NULL,
	[TypeNum] [tinyint] NOT NULL,
	[Type]  AS (case [TypeNum] when (1) then 'Substance' when (2) then 'Product' when (3) then 'Presentation' else 'N/A' end),
	[Code] [varchar](15) NOT NULL,
	[Name] [varchar](150) NOT NULL,
	[Path] [varchar](500) NOT NULL,
	[Path_Depth] [tinyint] NOT NULL,
	[IsSubstance]  AS (isnull(CONVERT([bit],case when [TypeNum]=(1) then (1) else (0) end),(0))),
	[IsProduct]  AS (isnull(CONVERT([bit],case when [TypeNum]=(2) then (1) else (0) end),(0))),
	[IsPresentation]  AS (isnull(CONVERT([bit],case when [TypeNum]=(3) then (1) else (0) end),(0))),
	[DateCreated] [smalldatetime] NOT NULL,
	[DateUpdated] [smalldatetime] NOT NULL,
	[IsGeneric] [bit] NOT NULL,
	[SK_BNFID_GenericEquivalent] [int] NULL,
 CONSTRAINT [PK_dbo_BNF_Substance_Product_Presentation] PRIMARY KEY NONCLUSTERED 
(
	[SK_BNFID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_dbo_BNF_Substance_Product_Presentation_Code] UNIQUE CLUSTERED 
(
	[Code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

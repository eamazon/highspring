USE [Dictionary]
GO
/****** Object:  Table [dbo].[OutputArea]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OutputArea](
	[SK_OutputAreaID] [int] IDENTITY(10,1) NOT FOR REPLICATION NOT NULL,
	[SK_OutputAreaParentID] [int] NULL,
	[CensusYear] [smallint] NOT NULL,
	[OACode] [char](9) NOT NULL,
	[OAName] [varchar](200) NOT NULL,
	[OAType] [char](1) NOT NULL,
	[GeoEasting] [int] NULL,
	[GeoNorthing] [int] NULL,
	[GeoLatitude] [float] NULL,
	[GeoLongitude] [float] NULL,
	[GeoCentroid] [geometry] NULL,
	[PopEasting] [int] NULL,
	[PopNorthing] [int] NULL,
	[PopLatitude] [float] NULL,
	[PopLongitude] [float] NULL,
	[PopCentroid] [geometry] NULL,
	[OAShape] [geometry] NULL,
	[TownsendScore] [float] NULL,
 CONSTRAINT [PK_dbo_OutputArea] PRIMARY KEY CLUSTERED 
(
	[SK_OutputAreaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

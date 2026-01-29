USE [Dictionary]
GO
/****** Object:  Table [dbo].[Wards]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Wards](
	[SK_WardID] [int] IDENTITY(10,1) NOT FOR REPLICATION NOT NULL,
	[WardCode] [char](9) NOT NULL,
	[WardName] [varchar](100) NULL,
	[GeoCentroid] [geometry] NULL,
	[WardShape] [geometry] NULL,
	[DateCreated] [smalldatetime] NULL,
	[DateUpdated] [smalldatetime] NULL,
 CONSTRAINT [PK_dbo_Wards] PRIMARY KEY CLUSTERED 
(
	[SK_WardID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_dbo_Wards] UNIQUE NONCLUSTERED 
(
	[WardCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

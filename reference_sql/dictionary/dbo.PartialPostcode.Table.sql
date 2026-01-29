USE [Dictionary]
GO
/****** Object:  Table [dbo].[PartialPostcode]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PartialPostcode](
	[SK_PartialPostcode] [smallint] IDENTITY(10,1) NOT FOR REPLICATION NOT NULL,
	[Postcode] [varchar](6) NOT NULL,
	[Longitude] [float] NULL,
	[Latitude] [float] NULL,
	[DateCreated] [smalldatetime] NOT NULL,
	[DateUpdated] [smalldatetime] NOT NULL,
 CONSTRAINT [PK_dbo_PartialPostcode] PRIMARY KEY NONCLUSTERED 
(
	[SK_PartialPostcode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_dbo_PartialPostcode] UNIQUE CLUSTERED 
(
	[Postcode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

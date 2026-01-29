USE [Dictionary]
GO
/****** Object:  Table [dbo].[SUSTariffTypes]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SUSTariffTypes](
	[SK_TariffTypeID] [tinyint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[BK_TariffType] [varchar](5) NOT NULL,
	[TariffDescription] [varchar](50) NOT NULL,
	[DateCreated] [smalldatetime] NOT NULL,
	[DateUpdated] [smalldatetime] NOT NULL,
 CONSTRAINT [PK_dbo_SUSTariffTypes] PRIMARY KEY CLUSTERED 
(
	[SK_TariffTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_dbo_SUSTariffTypes] UNIQUE NONCLUSTERED 
(
	[BK_TariffType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

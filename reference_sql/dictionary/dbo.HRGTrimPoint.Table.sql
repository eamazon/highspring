USE [Dictionary]
GO
/****** Object:  Table [dbo].[HRGTrimPoint]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HRGTrimPoint](
	[SK_HRGID] [smallint] NOT NULL,
	[SK_TariffTypeID] [tinyint] NOT NULL,
	[FiscalYear] [char](7) NOT NULL,
	[IsElectiveStay] [bit] NOT NULL,
	[TrimPointDays] [int] NOT NULL,
 CONSTRAINT [PK_dbo_HRGTrimPoints] PRIMARY KEY CLUSTERED 
(
	[SK_HRGID] ASC,
	[FiscalYear] ASC,
	[SK_TariffTypeID] ASC,
	[IsElectiveStay] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

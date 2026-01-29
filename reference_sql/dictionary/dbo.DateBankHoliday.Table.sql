USE [Dictionary]
GO
/****** Object:  Table [dbo].[DateBankHoliday]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DateBankHoliday](
	[SK_Date]  AS (CONVERT([int],CONVERT([varchar],[FullDate],(112)))) PERSISTED NOT NULL,
	[FullDate] [date] NOT NULL,
	[Holiday] [varchar](100) NOT NULL,
	[InEnglandAndWales] [bit] NOT NULL,
	[InNorthernIreland] [bit] NOT NULL,
	[InScotland] [bit] NOT NULL,
 CONSTRAINT [PK_dbo_DateBankHoliday] PRIMARY KEY CLUSTERED 
(
	[SK_Date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_dbo_DateBankHoliday] UNIQUE NONCLUSTERED 
(
	[FullDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

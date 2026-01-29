USE [Dictionary]
GO
/****** Object:  Table [dbo].[UnitConversion]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UnitConversion](
	[SK_UnitID_Source] [smallint] NOT NULL,
	[SK_UnitID_Target] [smallint] NOT NULL,
	[Subtrahend] [float] NOT NULL,
	[Multiplier] [float] NOT NULL,
	[Divisor] [float] NOT NULL,
	[Addend] [float] NOT NULL,
 CONSTRAINT [PK_dbo_UnitConversion] PRIMARY KEY CLUSTERED 
(
	[SK_UnitID_Source] ASC,
	[SK_UnitID_Target] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

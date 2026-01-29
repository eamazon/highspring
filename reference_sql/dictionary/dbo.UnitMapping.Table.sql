USE [Dictionary]
GO
/****** Object:  Table [dbo].[UnitMapping]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UnitMapping](
	[SK_UnitID] [smallint] NOT NULL,
	[UnitLabel] [varchar](60) NOT NULL,
 CONSTRAINT [PK_dbo_UnitMapping] PRIMARY KEY CLUSTERED 
(
	[UnitLabel] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

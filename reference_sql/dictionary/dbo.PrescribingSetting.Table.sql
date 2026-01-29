USE [Dictionary]
GO
/****** Object:  Table [dbo].[PrescribingSetting]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PrescribingSetting](
	[SK_PrescribingSettingID] [tinyint] NOT NULL,
	[BK_PrescribingSetting] [varchar](2) NOT NULL,
	[PrescribingSetting] [varchar](50) NOT NULL,
 CONSTRAINT [PK_dbo_PrescribingSetting] PRIMARY KEY CLUSTERED 
(
	[SK_PrescribingSettingID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_dbo_PrescribingSetting_BK] UNIQUE NONCLUSTERED 
(
	[BK_PrescribingSetting] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

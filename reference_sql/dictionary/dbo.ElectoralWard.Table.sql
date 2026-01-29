USE [Dictionary]
GO
/****** Object:  Table [dbo].[ElectoralWard]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ElectoralWard](
	[SK_ElectoralWardID] [int] NOT NULL,
	[CountryCode] [varchar](1) NULL,
	[CountryName] [varchar](16) NULL,
	[National_Grouping_Code] [varchar](9) NULL,
	[Health_Board_Local_Health_Board_Strategic_Authority_Name] [varchar](100) NULL,
	[High_Level_Health_Authority_Code] [varchar](9) NULL,
	[Local_Health_Board_Code_Wales] [varchar](9) NULL,
	[Local_Health_Board_Name] [varchar](100) NULL,
	[ONS_LA_UA_Code_old] [varchar](4) NULL,
	[ONS_LA_UA_Code_9char] [varchar](9) NULL,
	[Ward_Name] [varchar](100) NULL,
	[ONS_Ward_Code_old] [varchar](6) NULL,
	[ONS_Ward_Code_9char] [varchar](9) NOT NULL,
	[SK_ElectoralWard_ID]  AS ([SK_ElectoralWardID]),
	[IsActive] [bit] NOT NULL,
 CONSTRAINT [PK_ElectoralWard] PRIMARY KEY CLUSTERED 
(
	[SK_ElectoralWardID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_ElectoralWard] UNIQUE NONCLUSTERED 
(
	[ONS_Ward_Code_9char] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

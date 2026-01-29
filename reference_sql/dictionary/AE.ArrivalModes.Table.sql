USE [Dictionary]
GO
/****** Object:  Table [AE].[ArrivalModes]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [AE].[ArrivalModes](
	[SK_ArrivalModeID] [tinyint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[BK_ArrivalMode] [varchar](10) NOT NULL,
	[ArrivalModeDescription] [varchar](100) NULL,
	[DateCreated] [smalldatetime] NULL,
	[DateUpdated] [smalldatetime] NULL,
	[CreatedDateTime] [smalldatetime] NOT NULL,
	[LastUpdateDateTime] [smalldatetime] NOT NULL,
 CONSTRAINT [PK_AE_ArrivalModes] PRIMARY KEY CLUSTERED 
(
	[SK_ArrivalModeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [AE].[ArrivalModes] ADD  CONSTRAINT [DF__ArrivalMo__Creat__2E9E2C8B]  DEFAULT (getdate()) FOR [CreatedDateTime]
GO
ALTER TABLE [AE].[ArrivalModes] ADD  CONSTRAINT [DF__ArrivalMo__LastU__2F9250C4]  DEFAULT (getdate()) FOR [LastUpdateDateTime]
GO

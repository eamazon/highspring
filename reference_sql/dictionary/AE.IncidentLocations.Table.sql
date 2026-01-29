USE [Dictionary]
GO
/****** Object:  Table [AE].[IncidentLocations]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [AE].[IncidentLocations](
	[SK_IncidentLocationID] [tinyint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[BK_IncidentLocation] [varchar](10) NOT NULL,
	[IncidentLocations] [varchar](50) NULL,
	[DateCreated] [smalldatetime] NULL,
	[DateUpdated] [smalldatetime] NULL,
 CONSTRAINT [PK_AE_IncidentLocations] PRIMARY KEY CLUSTERED 
(
	[SK_IncidentLocationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

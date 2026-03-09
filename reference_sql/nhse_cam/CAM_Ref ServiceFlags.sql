--USE [NHSE_Sandbox_Internal]  --Change this database name as appropriate
--GO

/****** Object:  Table [CAM_Ref].[ServiceFlags]    Script Date: 15/04/2025 08:04:32 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (
		SELECT * FROM INFORMATION_SCHEMA.TABLES
		WHERE TABLE_NAME = 'ServiceFlags' AND TABLE_SCHEMA = 'CAM_Ref')

		DROP TABLE [CAM_Ref].[ServiceFlags]

		CREATE TABLE [CAM_Ref].[ServiceFlags](
			[NHSE_ServiceCategory] [varchar](2) NOT NULL,
			[Armed Forces Flag] [smallint] NULL,
			[Public Health Flag] [smallint] NULL,
			[Health In Justice Flag] [smallint] NULL,
		PRIMARY KEY CLUSTERED 
		(
			[NHSE_ServiceCategory] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
		) ON [PRIMARY]
GO

INSERT INTO [CAM_Ref].[ServiceFlags]([NHSE_ServiceCategory],[Armed Forces Flag],[Public Health Flag],[Health In Justice Flag]) VALUES('61',1,0,0)
INSERT INTO [CAM_Ref].[ServiceFlags]([NHSE_ServiceCategory],[Armed Forces Flag],[Public Health Flag],[Health In Justice Flag]) VALUES('71',0,0,1)
INSERT INTO [CAM_Ref].[ServiceFlags]([NHSE_ServiceCategory],[Armed Forces Flag],[Public Health Flag],[Health In Justice Flag]) VALUES('75',0,0,1)
INSERT INTO [CAM_Ref].[ServiceFlags]([NHSE_ServiceCategory],[Armed Forces Flag],[Public Health Flag],[Health In Justice Flag]) VALUES('81',0,1,0)
INSERT INTO [CAM_Ref].[ServiceFlags]([NHSE_ServiceCategory],[Armed Forces Flag],[Public Health Flag],[Health In Justice Flag]) VALUES('85',0,1,0)
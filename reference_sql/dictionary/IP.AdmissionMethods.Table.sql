USE [Dictionary]
GO
/****** Object:  Table [IP].[AdmissionMethods]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [IP].[AdmissionMethods](
	[SK_AdmissionMethodID] [tinyint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[BK_AdmissionMethodCode] [varchar](5) NOT NULL,
	[AdmissionMethodName] [varchar](35) NULL,
	[AdmissionMethodGroup] [varchar](80) NULL,
	[AdmissionMethodMethodFullName] [varchar](500) NULL,
	[DateCreated] [smalldatetime] NOT NULL,
	[DateUpdated] [smalldatetime] NULL,
 CONSTRAINT [PK_IP_AdmissionMethods] PRIMARY KEY CLUSTERED 
(
	[SK_AdmissionMethodID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

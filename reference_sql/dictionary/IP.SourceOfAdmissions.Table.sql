USE [Dictionary]
GO
/****** Object:  Table [IP].[SourceOfAdmissions]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [IP].[SourceOfAdmissions](
	[SK_SourceOfAdmissionID] [tinyint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[BK_SourceOfAdmissionCode] [varchar](2) NOT NULL,
	[SourceOfAdmissionName] [varchar](50) NOT NULL,
	[SourceOfAdmissionFullName] [varchar](500) NOT NULL,
	[DateCreated] [smalldatetime] NOT NULL,
	[DateUpdated] [smalldatetime] NULL,
 CONSTRAINT [PK_IP_SourceOfAdmissions] PRIMARY KEY CLUSTERED 
(
	[SK_SourceOfAdmissionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

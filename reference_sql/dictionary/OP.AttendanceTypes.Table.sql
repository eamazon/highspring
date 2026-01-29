USE [Dictionary]
GO
/****** Object:  Table [OP].[AttendanceTypes]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [OP].[AttendanceTypes](
	[SK_AttendanceType] [tinyint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[BK_AttendanceTypeCode] [varchar](2) NOT NULL,
	[AttendantType] [varchar](10) NOT NULL,
	[AttendantTypeDesc] [varchar](75) NOT NULL,
	[DateCreated] [smalldatetime] NOT NULL,
	[DateUpdated] [smalldatetime] NULL,
 CONSTRAINT [PK_OP_AttendanceTypes] PRIMARY KEY CLUSTERED 
(
	[SK_AttendanceType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

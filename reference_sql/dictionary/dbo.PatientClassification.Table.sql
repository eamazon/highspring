USE [Dictionary]
GO
/****** Object:  Table [dbo].[PatientClassification]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PatientClassification](
	[SK_PatientClassificationID] [tinyint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[BK_PatientClassificationCode] [char](1) NULL,
	[PatientClassificationName] [varchar](255) NULL,
	[PatientClassificationFullName] [varchar](max) NULL,
 CONSTRAINT [PK__PatientC__7EFF974AF12437F8] PRIMARY KEY CLUSTERED 
(
	[SK_PatientClassificationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

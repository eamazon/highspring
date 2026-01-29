USE [Dictionary]
GO
/****** Object:  Table [OP].[MedicalStaffTypeSeeingPatient]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [OP].[MedicalStaffTypeSeeingPatient](
	[SK_MedicalStaffTypeID] [tinyint] NOT NULL,
	[BK_MedicalStaffTypeID] [varchar](2) NOT NULL,
	[MedicalStaffTypeSeeingPatient] [varchar](100) NOT NULL,
 CONSTRAINT [PK_MedicalStaffTypeSeeingPatient] PRIMARY KEY CLUSTERED 
(
	[SK_MedicalStaffTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

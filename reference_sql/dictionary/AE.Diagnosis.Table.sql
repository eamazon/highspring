USE [Dictionary]
GO
/****** Object:  Table [AE].[Diagnosis]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [AE].[Diagnosis](
	[SK_AEDiagnosisID] [smallint] IDENTITY(10,1) NOT FOR REPLICATION NOT NULL,
	[BK_CombinedDiagnosisCode] [char](6) NOT NULL,
	[DiagnosisCode] [char](2) NOT NULL,
	[DiagnosisDesc] [varchar](100) NOT NULL,
	[SubAnalysisCode] [char](1) NOT NULL,
	[SubAnalysisDesc] [varchar](100) NOT NULL,
	[AnatomicalAreaCode] [char](2) NOT NULL,
	[AnatomicalAreaDesc] [varchar](50) NOT NULL,
	[AnatomicalAreaGroup] [varchar](50) NOT NULL,
	[AnatomicalSideCode] [char](1) NOT NULL,
	[AnatomicalSideDesc] [varchar](20) NOT NULL,
	[HasSubAnalysis] [bit] NOT NULL,
	[SK_DiagnosisID]  AS ([SK_AEDiagnosisID]),
 CONSTRAINT [PK_AE_Diagnosis] PRIMARY KEY CLUSTERED 
(
	[SK_AEDiagnosisID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_AE_Diagnosis_BK] UNIQUE NONCLUSTERED 
(
	[BK_CombinedDiagnosisCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_AE_Diagnosis_Parts] UNIQUE NONCLUSTERED 
(
	[DiagnosisCode] ASC,
	[SubAnalysisCode] ASC,
	[AnatomicalAreaCode] ASC,
	[AnatomicalSideCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

USE [Dictionary]
GO
/****** Object:  Table [AE].[Treatments]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [AE].[Treatments](
	[SK_TreatmentID] [smallint] NOT NULL,
	[TreatmentCodeFull] [char](3) NOT NULL,
	[TreatmentCode] [char](2) NOT NULL,
	[TreatmentDesc] [varchar](100) NOT NULL,
	[SubAnalysisCode] [char](1) NOT NULL,
	[SubAnalysisDesc] [varchar](100) NOT NULL,
	[HasSubAnalysis] [bit] NOT NULL,
 CONSTRAINT [PK_AE_Treatments] PRIMARY KEY CLUSTERED 
(
	[SK_TreatmentID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [PK_UQ_Treatments_Full] UNIQUE NONCLUSTERED 
(
	[TreatmentCodeFull] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [PK_UQ_Treatments_Split] UNIQUE NONCLUSTERED 
(
	[TreatmentCode] ASC,
	[SubAnalysisCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

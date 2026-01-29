USE [Dictionary]
GO
/****** Object:  Table [dbo].[Specialties]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Specialties](
	[SK_SpecialtyID] [smallint] NOT NULL,
	[BK_SpecialtyCode] [varchar](10) NOT NULL,
	[SpecialtyName] [varchar](75) NOT NULL,
	[SpecialtyCategory] [varchar](75) NOT NULL,
	[IsTreatmentFunction] [bit] NULL,
	[IsMainSpecialty] [bit] NULL,
	[DateCreated] [smalldatetime] NOT NULL,
	[DateUpdated] [smalldatetime] NULL,
	[MainSpecialtyDescription] [varchar](75) NULL,
	[TreatmentFunctionDescription] [varchar](75) NULL,
 CONSTRAINT [PK_dbo_Specialties] PRIMARY KEY CLUSTERED 
(
	[SK_SpecialtyID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_dbo_Specialties] UNIQUE NONCLUSTERED 
(
	[BK_SpecialtyCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

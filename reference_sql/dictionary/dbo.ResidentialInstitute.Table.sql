USE [Dictionary]
GO
/****** Object:  Table [dbo].[ResidentialInstitute]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ResidentialInstitute](
	[SK_ResidentialInstituteID] [int] NOT NULL,
	[Cipher] [varchar](3) NOT NULL,
	[ResidentialInstituteCode] [varchar](2) NOT NULL,
	[ResidentialInstituteName] [varchar](100) NULL,
	[AttractsGlobalSumUplift] [bit] NOT NULL,
	[SK_OrganisationID] [int] NULL,
	[DateCreated] [smalldatetime] NOT NULL,
	[DateUpdated] [smalldatetime] NOT NULL,
 CONSTRAINT [PK_dbo_ResidentialInstitute] PRIMARY KEY NONCLUSTERED 
(
	[SK_ResidentialInstituteID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_dbo_ResidentialInstitute] UNIQUE CLUSTERED 
(
	[Cipher] ASC,
	[ResidentialInstituteCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

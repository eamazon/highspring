USE [Dictionary]
GO
/****** Object:  Table [dbo].[OrganisationMatrixPractice]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OrganisationMatrixPractice](
	[SK_OrganisationID_Practice] [int] NOT NULL,
	[SK_OrganisationID_Network] [int] NOT NULL,
	[SK_OrganisationID_Commissioner] [int] NULL,
	[SK_OrganisationID_STP] [int] NULL,
 CONSTRAINT [PK_dbo_OrganisationMatrixPractice] PRIMARY KEY CLUSTERED 
(
	[SK_OrganisationID_Practice] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

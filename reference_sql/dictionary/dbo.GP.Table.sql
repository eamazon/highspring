USE [Dictionary]
GO
/****** Object:  Table [dbo].[GP]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GP](
	[SK_GPID] [int] NOT NULL,
	[GP_Code] [varchar](8) NOT NULL,
	[GP_Name] [varchar](255) NULL,
	[Contact_Telephone_Number] [varchar](20) NULL,
	[SK_OrganisationID_NationalGrouping] [int] NULL,
	[SK_OrganisationID_HealthAuthority] [int] NULL,
	[SK_OrganisationID_CurrentCareOrg] [int] NULL,
	[SK_PostcodeID] [int] NULL,
	[StartDate] [date] NULL,
	[EndDate] [date] NULL,
	[SK_OrganisationID_ParentOrg] [int] NULL,
	[Join_Parent_Date] [date] NULL,
	[Left_Parent_Date] [date] NULL,
	[FirstCreated] [smalldatetime] NOT NULL,
	[LastUpdated] [smalldatetime] NOT NULL,
	[SK_GP_ID]  AS ([SK_GPID]),
	[SK_NationalGrouping_ID]  AS ([SK_OrganisationID_NationalGrouping]),
	[SK_HealthAuthority_ID]  AS ([SK_OrganisationID_HealthAuthority]),
	[SK_CurrentCareOrg_ID]  AS ([SK_OrganisationID_CurrentCareOrg]),
	[SK_Postcode_ID]  AS ([SK_PostcodeID]),
	[SK_ParentOrg_ID]  AS ([SK_OrganisationID_ParentOrg]),
	[GMC_GivenName] [varchar](255) NULL,
	[GMC_Surname] [varchar](255) NULL,
	[GMC_ReferenceNumber] [varchar](10) NULL,
 CONSTRAINT [PK_dbo_GP] PRIMARY KEY CLUSTERED 
(
	[SK_GPID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_dbo_GP] UNIQUE NONCLUSTERED 
(
	[GP_Code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

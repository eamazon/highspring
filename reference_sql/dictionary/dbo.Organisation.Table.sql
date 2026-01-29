USE [Dictionary]
GO
/****** Object:  Table [dbo].[Organisation]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Organisation](
	[SK_OrganisationID] [int] NOT NULL,
	[Organisation_Code] [varchar](10) NOT NULL,
	[Organisation_Name] [varchar](255) NULL,
	[SK_OrganisationTypeID] [tinyint] NOT NULL,
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
	[SK_PrescribingSettingID] [tinyint] NULL,
	[SK_OrganisationStatusID] [tinyint] NULL,
	[Address_Line_1] [varchar](255) NULL,
	[Address_Line_2] [varchar](255) NULL,
	[Address_Line_3] [varchar](255) NULL,
	[Address_Line_4] [varchar](255) NULL,
	[Address_Line_5] [varchar](255) NULL,
	[SK_Organisation_ID]  AS ([SK_OrganisationID]),
	[SK_OrganisationType_ID]  AS ([SK_OrganisationTypeID]),
	[SK_NationalGrouping_ID]  AS ([SK_OrganisationID_NationalGrouping]),
	[SK_HealthAuthority_ID]  AS ([SK_OrganisationID_HealthAuthority]),
	[SK_CurrentCareOrg_ID]  AS ([SK_OrganisationID_CurrentCareOrg]),
	[SK_Postcode_ID]  AS ([SK_PostcodeID]),
	[SK_ParentOrg_ID]  AS ([SK_OrganisationID_ParentOrg]),
	[SK_PrescribingSetting_ID]  AS ([SK_PrescribingSettingID]),
	[Country] [varchar](50) NULL,
	[CodeAssignedBy] [varchar](255) NULL,
	[UPRN] [varchar](12) NULL,
	[LastChangeDate] [date] NULL,
	[OrganisationPrimaryRole] [varchar](5) NULL,
	[StartDate_Legal] [date] NULL,
	[EndDate_Legal] [date] NULL,
	[StartDate_Operational] [date] NULL,
	[EndDate_Operational] [date] NULL,
	[Status] [varchar](20) NULL,
 CONSTRAINT [PK_dbo_Organisation] PRIMARY KEY CLUSTERED 
(
	[SK_OrganisationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'The Surrogate Key (SK) column is the Primary Key for this table and uniquely identifies each record.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Organisation', @level2type=N'COLUMN',@level2name=N'SK_OrganisationID'
GO

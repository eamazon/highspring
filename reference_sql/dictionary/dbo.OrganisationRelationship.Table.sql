USE [Dictionary]
GO
/****** Object:  Table [dbo].[OrganisationRelationship]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OrganisationRelationship](
	[SK_OrganisationID] [int] NOT NULL,
	[SK_OrganisationID_Target] [int] NOT NULL,
	[TargetRelationshipType] [nvarchar](255) NOT NULL,
	[TargetPrimaryRoleType] [nvarchar](50) NOT NULL,
	[LegalStartDate] [date] NULL,
	[LegalEndDate] [date] NULL,
	[OperationalStartDate] [date] NULL,
	[OperationalEndDate] [date] NULL,
	[TargetAssignedBy] [nvarchar](25) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[StartDate]  AS (coalesce([LegalStartDate],[OperationalStartDate])) PERSISTED NOT NULL,
	[EndDate] [date] NULL,
	[UniqueRelationshipID] [bigint] NOT NULL,
 CONSTRAINT [PK_dbo_OrganisationRelationship] PRIMARY KEY CLUSTERED 
(
	[SK_OrganisationID] ASC,
	[SK_OrganisationID_Target] ASC,
	[TargetRelationshipType] ASC,
	[TargetPrimaryRoleType] ASC,
	[StartDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

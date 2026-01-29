USE [Dictionary]
GO
/****** Object:  Table [dbo].[OrganisationRole]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OrganisationRole](
	[SK_OrganisationID] [int] NOT NULL,
	[RoleType] [varchar](5) NOT NULL,
	[LegalStartDate] [date] NULL,
	[LegalEndDate] [date] NULL,
	[OperationalStartDate] [date] NULL,
	[OperationalEndDate] [date] NULL,
	[IsPrimaryRole] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[StartDate]  AS (coalesce([LegalStartDate],[OperationalStartDate])) PERSISTED NOT NULL,
	[EndDate]  AS (coalesce([LegalEndDate],[OperationalEndDate])) PERSISTED,
	[UniqueRoleID] [bigint] NOT NULL,
 CONSTRAINT [PK_dbo_OrganisationRole] PRIMARY KEY CLUSTERED 
(
	[SK_OrganisationID] ASC,
	[RoleType] ASC,
	[StartDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

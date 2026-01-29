USE [Dictionary]
GO
/****** Object:  Table [dbo].[OrganisationSuccessor]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OrganisationSuccessor](
	[SK_OrganisationID] [int] NOT NULL,
	[SK_OrganisationID_Successor] [int] NOT NULL,
	[Succession_Effective_Date] [date] NOT NULL,
	[SK_OrganisationID_FinalSuccessor] [int] NULL,
	[UniqueKey]  AS ((CONVERT([binary](3),reverse(CONVERT([binary](3),[Succession_Effective_Date])))+CONVERT([binary](4),[SK_OrganisationID]))+CONVERT([binary](4),[SK_OrganisationID_Successor])) PERSISTED NOT NULL,
	[SuccessorType] [varchar](25) NULL,
	[SuccessorPrimaryRoleType] [varchar](10) NULL,
	[SuccessorAssignedBy] [varchar](25) NULL,
	[UniqueSuccessorID] [bigint] NOT NULL,
 CONSTRAINT [PK_dbo_OrganisationSuccessor] PRIMARY KEY NONCLUSTERED 
(
	[UniqueKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_dbo_OrganisationSuccessor] UNIQUE CLUSTERED 
(
	[Succession_Effective_Date] ASC,
	[SK_OrganisationID] ASC,
	[SK_OrganisationID_Successor] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

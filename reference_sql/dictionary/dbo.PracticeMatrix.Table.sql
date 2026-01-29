USE [Dictionary]
GO
/****** Object:  Table [dbo].[PracticeMatrix]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PracticeMatrix](
	[SK_ServiceProviderID] [int] NOT NULL,
	[SK_ServiceProviderGroupID] [int] NOT NULL,
	[SK_ServiceProviderOrgID] [int] NULL,
	[SK_NetworkID] [int] NOT NULL,
	[SK_CommissionerID] [smallint] NOT NULL,
	[SK_CommissionerGroupID] [int] NOT NULL,
	[SK_CommissionerOrgID] [int] NULL,
	[SK_PODTeamID] [tinyint] NOT NULL,
	[SK_PODTeamGroupID] [int] NOT NULL,
	[SK_STPID] [smallint] NULL,
	[SK_STPGroupID] [int] NULL,
	[SK_PCTID] [smallint] NULL,
	[SK_CCGLocationID] [smallint] NULL,
	[IsPracticeActive] [bit] NOT NULL,
	[IsPracticeDormant] [bit] NOT NULL,
	[DateCreated] [smalldatetime] NOT NULL,
	[DateUpdated] [smalldatetime] NOT NULL,
	[NetworkCount] [tinyint] NOT NULL,
	[HasGPExtract] [bit] NOT NULL,
 CONSTRAINT [PK_dbo_PracticeMatrix] PRIMARY KEY NONCLUSTERED 
(
	[SK_ServiceProviderID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

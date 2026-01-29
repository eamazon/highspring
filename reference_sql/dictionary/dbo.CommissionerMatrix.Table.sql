USE [Dictionary]
GO
/****** Object:  Table [dbo].[CommissionerMatrix]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CommissionerMatrix](
	[SK_CommissionerID] [smallint] NOT NULL,
	[SK_CommissionerGroupID] [int] NOT NULL,
	[SK_CommissionerOrgID] [int] NULL,
	[SK_PODTeamID] [tinyint] NOT NULL,
	[SK_PODTeamGroupID] [int] NOT NULL,
	[SK_STPID] [smallint] NULL,
	[SK_STPGroupID] [int] NULL,
	[SK_PCTID] [smallint] NULL,
	[DateCreated] [smalldatetime] NOT NULL,
	[DateUpdated] [smalldatetime] NOT NULL,
	[NumberOfPractices] [tinyint] NOT NULL,
 CONSTRAINT [PK_dbo_CommissionerMatrix] PRIMARY KEY NONCLUSTERED 
(
	[SK_CommissionerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

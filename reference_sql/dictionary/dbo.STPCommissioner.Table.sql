USE [Dictionary]
GO
/****** Object:  Table [dbo].[STPCommissioner]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[STPCommissioner](
	[SK_STPID] [smallint] NOT NULL,
	[SK_CommissionerID] [smallint] NOT NULL,
	[SK_OrganisationID_Commissioner] [int] NOT NULL,
	[DateCreated] [smalldatetime] NOT NULL,
	[DateUpdated] [smalldatetime] NOT NULL,
	[SK_OrganisationID_STP] [int] NULL,
 CONSTRAINT [PK_dbo_STPCommissioner] PRIMARY KEY CLUSTERED 
(
	[SK_CommissionerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

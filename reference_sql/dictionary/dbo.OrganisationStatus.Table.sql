USE [Dictionary]
GO
/****** Object:  Table [dbo].[OrganisationStatus]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OrganisationStatus](
	[SK_OrganisationStatusID] [tinyint] NOT NULL,
	[BK_OrganisationStatus] [char](1) NULL,
	[OrganisationStatus] [varchar](50) NOT NULL,
 CONSTRAINT [PK_dbo_OrganisationStatus] PRIMARY KEY CLUSTERED 
(
	[SK_OrganisationStatusID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_dbo_OrganisationStatus_BK] UNIQUE NONCLUSTERED 
(
	[BK_OrganisationStatus] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

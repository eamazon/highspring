USE [Dictionary]
GO
/****** Object:  Table [dbo].[OrganisationFormerName]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OrganisationFormerName](
	[SK_OrganisationID] [int] NOT NULL,
	[Organisation_Name] [varchar](255) NOT NULL,
	[StartDate] [date] NOT NULL,
	[EndDate] [date] NULL,
 CONSTRAINT [PK_dbo_OrganisationFormerName] PRIMARY KEY CLUSTERED 
(
	[SK_OrganisationID] ASC,
	[StartDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

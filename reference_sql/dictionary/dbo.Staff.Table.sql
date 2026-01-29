USE [Dictionary]
GO
/****** Object:  Table [dbo].[Staff]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Staff](
	[SK_StaffID] [int] NOT NULL,
	[SK_ServiceProviderID] [int] NULL,
	[SK_OrganisationTypeID] [tinyint] NULL,
	[FirstName] [varchar](100) NULL,
	[Surname] [varchar](100) NULL,
	[LocalStaffRole] [varchar](100) NULL,
	[StaffCode] [varchar](10) NULL,
	[DateCreated] [smalldatetime] NULL,
	[DateUpdated] [smalldatetime] NULL,
 CONSTRAINT [PK_Staff] PRIMARY KEY CLUSTERED 
(
	[SK_StaffID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

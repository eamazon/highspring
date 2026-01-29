USE [Dictionary]
GO
/****** Object:  Table [dbo].[ConsultantProvider]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ConsultantProvider](
	[SK_ConsultantID] [int] NOT NULL,
	[SK_ServiceProviderID] [int] NOT NULL,
	[SK_SpecialtyID] [smallint] NOT NULL,
	[StartDate] [date] NULL,
	[EndDate] [date] NULL,
	[DateCreated] [smalldatetime] NULL,
	[DateUpdated] [smalldatetime] NULL,
 CONSTRAINT [PK_ConsultantProvider] PRIMARY KEY CLUSTERED 
(
	[SK_ConsultantID] ASC,
	[SK_ServiceProviderID] ASC,
	[SK_SpecialtyID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

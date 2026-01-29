USE [Dictionary]
GO
/****** Object:  Table [dbo].[ServiceProviderTypes]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ServiceProviderTypes](
	[SK_ServiceProviderTypeID] [tinyint] NOT NULL,
	[ServiceProviderTypeDescription] [varchar](100) NULL,
 CONSTRAINT [PK_ServiceProviderTypes] PRIMARY KEY CLUSTERED 
(
	[SK_ServiceProviderTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

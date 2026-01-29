USE [Dictionary]
GO
/****** Object:  Table [AE].[DepartmentNames]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [AE].[DepartmentNames](
	[SK_DepartmentNamesID] [tinyint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[BK_DepartmentNameID] [varchar](10) NOT NULL,
	[DepartmentNamesDescription] [varchar](50) NOT NULL,
	[DateCreated] [smalldatetime] NULL,
	[DateUpdated] [smalldatetime] NULL,
 CONSTRAINT [PK_AE_DepartmentNames] PRIMARY KEY CLUSTERED 
(
	[SK_DepartmentNamesID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

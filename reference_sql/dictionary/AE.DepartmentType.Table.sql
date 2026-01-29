USE [Dictionary]
GO
/****** Object:  Table [AE].[DepartmentType]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [AE].[DepartmentType](
	[SK_DepartmentTypeID] [tinyint] NOT NULL,
	[BK_DepartmentTypeCode] [varchar](2) NULL,
	[DepartmentTypeDescription] [varchar](500) NULL,
	[DateCreated] [smalldatetime] NOT NULL,
	[DateUpdated] [smalldatetime] NOT NULL,
 CONSTRAINT [PK_AE_DepartmentType] PRIMARY KEY CLUSTERED 
(
	[SK_DepartmentTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

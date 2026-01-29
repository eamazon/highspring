USE [Dictionary]
GO
/****** Object:  Table [dbo].[Procedure]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Procedure](
	[SK_ProcedureCode] [smallint] NOT NULL,
	[Code] [varchar](4) NOT NULL,
	[Alt_Code] [varchar](5) NULL,
	[Category] [varchar](255) NULL,
	[Description] [varchar](255) NULL,
	[Status_Of_Operation] [varchar](2) NULL,
	[Sex_Absolute] [varchar](1) NULL,
	[Sex_Scrutiny] [varchar](1) NULL,
	[Method_Of_Delivery_Code] [varchar](1) NULL,
	[OPCS_Version] [numeric](5, 2) NULL,
	[IsOnlySecondaryCode] [bit] NULL,
	[IsOnlyFemales] [bit] NULL,
	[IsOnlyMales] [bit] NULL,
	[IsMainlyFemales] [bit] NULL,
	[IsMainlyMales] [bit] NULL,
	[DateCreated] [smalldatetime] NULL,
	[DateUpdated] [smalldatetime] NULL,
	[Chapter] [varchar](255) NULL,
 CONSTRAINT [PK_Procedure] PRIMARY KEY CLUSTERED 
(
	[SK_ProcedureCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_Procedure] UNIQUE NONCLUSTERED 
(
	[Code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

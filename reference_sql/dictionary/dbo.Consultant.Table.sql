USE [Dictionary]
GO
/****** Object:  Table [dbo].[Consultant]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Consultant](
	[SK_ConsultantID] [int] NOT NULL,
	[GMCCode] [varchar](8) NOT NULL,
	[Surname] [varchar](100) NULL,
	[Initials] [varchar](5) NULL,
	[GMCName] [varchar](110) NULL,
	[SexCode] [tinyint] NULL,
	[Specialty_Function_Code] [varchar](3) NULL,
	[Location_Organisation_Code] [varchar](5) NULL,
	[DateCreated] [smalldatetime] NULL,
	[DateUpdated] [smalldatetime] NULL,
 CONSTRAINT [PK_Consultant] PRIMARY KEY CLUSTERED 
(
	[SK_ConsultantID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

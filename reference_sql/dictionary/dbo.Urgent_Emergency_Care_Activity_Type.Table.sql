USE [Dictionary]
GO
/****** Object:  Table [dbo].[Urgent_Emergency_Care_Activity_Type]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Urgent_Emergency_Care_Activity_Type](
	[SK_Urgent_Emergency_Care_Activity_Type_ID] [tinyint] NOT NULL,
	[BK_Urgent_Emergency_Care_Activity_Type_Code] [varchar](2) NULL,
	[Urgent_Emergency_Care_Activity_Type_Description] [varchar](500) NULL,
	[DateCreated] [smalldatetime] NOT NULL,
	[DateUpdated] [smalldatetime] NOT NULL,
 CONSTRAINT [PK_Urgent_Emergency_Care_Activity_Type] PRIMARY KEY CLUSTERED 
(
	[SK_Urgent_Emergency_Care_Activity_Type_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

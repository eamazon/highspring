USE [Dictionary]
GO
/****** Object:  Table [IP].[FirstRegularDayOrNightAdmission]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [IP].[FirstRegularDayOrNightAdmission](
	[SK_FirstRegularDayOrNightAdmissionID] [tinyint] NOT NULL,
	[BK_FirstRegularDayOrNightAdmission] [char](2) NOT NULL,
	[FirstRegularDayOrNightAdmission] [varchar](100) NOT NULL,
 CONSTRAINT [PK_IP_FirstRegularDayOrNightAdmission] PRIMARY KEY CLUSTERED 
(
	[SK_FirstRegularDayOrNightAdmissionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_IP_FirstRegularDayOrNightAdmission] UNIQUE NONCLUSTERED 
(
	[BK_FirstRegularDayOrNightAdmission] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

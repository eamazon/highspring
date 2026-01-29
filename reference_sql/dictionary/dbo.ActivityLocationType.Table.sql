USE [Dictionary]
GO
/****** Object:  Table [dbo].[ActivityLocationType]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ActivityLocationType](
	[SK_ActivityLocationTypeID] [tinyint] NOT NULL,
	[BK_ActivityLocationTypeCode] [varchar](3) NOT NULL,
	[ActivityLocationTypeCategory] [varchar](200) NULL,
	[ActivityLocationTypeDescription] [varchar](200) NULL,
	[DateCreated] [date] NOT NULL,
	[DateUpdated] [date] NOT NULL,
 CONSTRAINT [PK_dbo_ActivityLocationType] PRIMARY KEY CLUSTERED 
(
	[SK_ActivityLocationTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_dbo_ActivityLocationType] UNIQUE NONCLUSTERED 
(
	[BK_ActivityLocationTypeCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

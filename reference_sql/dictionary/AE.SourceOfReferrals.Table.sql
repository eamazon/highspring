USE [Dictionary]
GO
/****** Object:  Table [AE].[SourceOfReferrals]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [AE].[SourceOfReferrals](
	[SK_SourceOfReferralID] [tinyint] NOT NULL,
	[BK_SourceOfReferral] [varchar](2) NOT NULL,
	[SourceOfReferral] [varchar](100) NOT NULL,
	[DateCreated] [smalldatetime] NOT NULL,
	[DateUpdated] [smalldatetime] NOT NULL,
 CONSTRAINT [PK_AE_SourceOfReferrals] PRIMARY KEY CLUSTERED 
(
	[SK_SourceOfReferralID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

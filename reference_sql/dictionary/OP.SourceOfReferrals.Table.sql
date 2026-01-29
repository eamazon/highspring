USE [Dictionary]
GO
/****** Object:  Table [OP].[SourceOfReferrals]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [OP].[SourceOfReferrals](
	[SK_SourceOfReferral] [tinyint] NOT NULL,
	[BK_SourceOfReferralCode] [varchar](2) NOT NULL,
	[ReferralType] [varchar](255) NOT NULL,
	[ReferralGroup] [varchar](15) NULL,
	[DateCreated] [smalldatetime] NOT NULL,
	[DateUpdated] [smalldatetime] NOT NULL,
 CONSTRAINT [PK_OP_SourceOfReferrals] PRIMARY KEY CLUSTERED 
(
	[SK_SourceOfReferral] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

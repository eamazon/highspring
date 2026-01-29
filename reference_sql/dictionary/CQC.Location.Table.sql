USE [Dictionary]
GO
/****** Object:  Table [CQC].[Location]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [CQC].[Location](
	[locationId] [varchar](15) NOT NULL,
	[providerId] [varchar](15) NULL,
	[organisationType] [varchar](50) NULL,
	[type] [varchar](50) NULL,
	[name] [varchar](255) NULL,
	[alsoKnownAs] [varchar](255) NULL,
	[registrationStatus] [varchar](50) NULL,
	[registrationDate] [date] NULL,
	[deregistrationDate] [date] NULL,
	[registeredManagerAbsentDate] [date] NULL,
	[numberOfBeds] [int] NULL,
	[website] [varchar](255) NULL,
	[postalAddressLine1] [varchar](100) NULL,
	[postalAddressLine2] [varchar](100) NULL,
	[postalAddressTownCity] [varchar](100) NULL,
	[postalAddressCounty] [varchar](100) NULL,
	[region] [varchar](100) NULL,
	[postalCode] [varchar](12) NULL,
	[mainPhoneNumber] [varchar](25) NULL,
	[constituency] [varchar](100) NULL,
	[localAuthority] [varchar](100) NULL,
	[publicationDate] [date] NULL,
	[reportDate] [date] NULL,
	[overallRating] [varchar](255) NULL,
	[overallReportDate] [date] NULL,
	[overallReportLinkId] [varchar](50) NULL,
	[lastInspection] [date] NULL,
	[brandId] [varchar](5) NULL,
	[brandName] [varchar](255) NULL,
	[onspdCcgCode] [varchar](9) NULL,
	[onspdCcgName] [varchar](255) NULL,
	[odsCode] [varchar](9) NULL,
	[uprn] [varchar](12) NULL,
	[odsCcgCode] [varchar](3) NULL,
	[odsCcgName] [varchar](255) NULL,
	[onspdLatitude] [numeric](18, 12) NULL,
	[onspdLongitude] [numeric](18, 12) NULL,
	[inspectionDirectorate] [varchar](50) NULL,
	[careHome] [varchar](1) NULL,
	[API_Call_Date] [datetime] NOT NULL,
	[URL] [varchar](255) NOT NULL,
	[onspdIcbCode] [varchar](9) NULL,
	[onspdIcbName] [varchar](255) NULL,
	[dormancy] [varchar](1) NULL,
	[islDateAdded] [datetime2](0) NULL,
	[islDateUpdated] [datetime2](0) NULL,
 CONSTRAINT [PK_CQC_Location] PRIMARY KEY CLUSTERED 
(
	[locationId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

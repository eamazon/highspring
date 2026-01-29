USE [Dictionary]
GO
/****** Object:  Table [dbo].[Postcode]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Postcode](
	[SK_PostcodeID] [int] NOT NULL,
	[Postcode_8_chars] [char](8) NOT NULL,
	[Postcode_single_space_e_Gif] [varchar](8) NOT NULL,
	[Postcode_no_space]  AS (CONVERT([varchar](7),replace([Postcode_8_chars],' ',''))) PERSISTED,
	[Date_of_Introduction] [date] NULL,
	[Date_of_Termination] [date] NULL,
	[Grid_Ref_Easting] [varchar](4) NULL,
	[Grid_Ref_Northing] [varchar](5) NULL,
	[Local_Authority_District_Unitary_Authority] [varchar](9) NULL,
	[Electoral_Ward_or_Division] [varchar](9) NULL,
	[Strategic_Health_Authority] [varchar](3) NULL,
	[Primary_Care_Organisation] [varchar](9) NULL,
	[yr1998_Ward_Code] [varchar](6) NULL,
	[Old_PCT] [varchar](3) NULL,
	[yr2001_LSOA] [varchar](9) NULL,
	[yr2001_MSOA] [varchar](9) NULL,
	[yr2011_OA] [varchar](9) NULL,
	[yr2011_LSOA] [varchar](9) NULL,
	[yr2011_MSOA] [varchar](9) NULL,
	[Latitude] [decimal](10, 6) NULL,
	[Longitude] [decimal](10, 6) NULL,
	[FirstCreated] [smalldatetime] NOT NULL,
	[LastUpdated] [smalldatetime] NOT NULL,
	[GOR_Code] [varchar](9) NULL,
	[Postcode_Usertype] [bit] NULL,
	[Area_Team_Code] [varchar](3) NULL,
	[Postcode]  AS ([Postcode_8_chars]),
	[LSOA]  AS ([yr2011_LSOA]),
	[MSOA]  AS ([yr2011_MSOA]),
	[SK_PseudoPostcodeID] [int] NOT NULL,
	[SK_Postcode_ID]  AS ([SK_PostcodeID]),
 CONSTRAINT [PK_dbo_Postcode] PRIMARY KEY CLUSTERED 
(
	[SK_PostcodeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_dbo_Postcode] UNIQUE NONCLUSTERED 
(
	[Postcode_8_chars] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

USE [Dictionary]
GO
/****** Object:  Table [dbo].[SLAM_PODGroup]    Script Date: 08/01/2026 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SLAM_PODGroup](
	[SK_SLAMPODGroupID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[Trust_Code] [varchar](5) NOT NULL,
	[POD_Code] [varchar](100) NOT NULL,
	[CSU_POD_Code] [varchar](100) NULL,
	[SLAMHRGCode] [varchar](100) NOT NULL,
	[SLAMSpecCode] [varchar](100) NOT NULL,
	[PBR_NPBR] [varchar](5) NOT NULL,
	[SBSCostCentre] [varchar](100) NULL,
	[AdHoc_Code] [varchar](100) NOT NULL,
	[CCG_Code] [varchar](3) NOT NULL,
	[Site_Code] [varchar](25) NOT NULL,
	[Phasing] [varchar](25) NULL,
	[DateCreated] [smalldatetime] NULL,
	[BeginMonth] [tinyint] NULL,
	[EndMonth] [tinyint] NOT NULL,
	[BeginYear] [smallint] NULL,
	[EndYear] [smallint] NOT NULL,
 CONSTRAINT [PK_dbo_SLAM_PODGroup] PRIMARY KEY CLUSTERED 
(
	[Trust_Code] ASC,
	[POD_Code] ASC,
	[SLAMHRGCode] ASC,
	[SLAMSpecCode] ASC,
	[PBR_NPBR] ASC,
	[AdHoc_Code] ASC,
	[CCG_Code] ASC,
	[Site_Code] ASC,
	[EndMonth] ASC,
	[EndYear] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

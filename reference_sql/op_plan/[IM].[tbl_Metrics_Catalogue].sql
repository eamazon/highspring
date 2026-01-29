USE [Data_Lab_SWL]
GO

/****** Object:  Table [IM].[tbl_Metrics_Catalogue]    Script Date: 01/01/2026 17:23:30 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [IM].[tbl_Metrics_Catalogue](
	[MetricId] [int] IDENTITY(1000,1) NOT NULL,
	[MetricName] [varchar](256) NULL,
	[MetricDescription] [varchar](256) NULL,
	[Category] [varchar](125) NULL,
	[SubCategory] [varchar](256) NULL,
	[ShortName] [varchar](256) NULL,
	[NHSEMetricId] [int] NULL,
	[ParentMetricId] [int] NULL,
	[Scope] [varchar](125) NULL,
	[IsActive] [bit] NULL,
	[ValidFromDate] [date] NULL,
	[ValidToDate] [date] NULL,
	[UniqueReference] [varchar](125) NULL,
	[OldPlanningRef] [varchar](25) NULL,
	[DataSourceId] [smallint] NULL,
	[CreatedDate] [datetime] NULL,
	[CreatedBy] [varchar](256) NULL,
	[UnitOfMeasure] [varchar](20) NULL,
	[MetricTypeId] [int] NULL,
	[FrequencyTypeId] [int] NULL,
	[ModifiedDate] [datetime] NULL,
	[ModifiedBy] [varchar](128) NULL,
PRIMARY KEY CLUSTERED 
(
	[MetricId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [IM].[tbl_Metrics_Catalogue] ADD  DEFAULT (getdate()) FOR [CreatedDate]
GO

ALTER TABLE [IM].[tbl_Metrics_Catalogue] ADD  DEFAULT (suser_sname()) FOR [CreatedBy]
GO

ALTER TABLE [IM].[tbl_Metrics_Catalogue]  WITH CHECK ADD  CONSTRAINT [FK_MetricsCatalogue_FrequencyType] FOREIGN KEY([FrequencyTypeId])
REFERENCES [IM].[tbl_Frequency] ([FrequencyId])
GO

ALTER TABLE [IM].[tbl_Metrics_Catalogue] CHECK CONSTRAINT [FK_MetricsCatalogue_FrequencyType]
GO

ALTER TABLE [IM].[tbl_Metrics_Catalogue]  WITH CHECK ADD  CONSTRAINT [FK_MetricsCatalogue_MetricTypes] FOREIGN KEY([MetricTypeId])
REFERENCES [IM].[tbl_Metric_Types] ([MetricTypeId])
GO

ALTER TABLE [IM].[tbl_Metrics_Catalogue] CHECK CONSTRAINT [FK_MetricsCatalogue_MetricTypes]
GO



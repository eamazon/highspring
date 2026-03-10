CREATE TABLE [Ref].[tbl_Service_Category_Codes](
	[Id] [int] NOT NULL,
	[ServiceCategoryCode] [int] NOT NULL,
	[ServiceCategoryDescription] [varchar](255) NULL,
	[ShortDescription] [varchar](9) NOT NULL,
	[DateAdded] [datetime] NULL,
	[AddedBy] [nvarchar](100) NULL
) ON [PRIMARY]
GO
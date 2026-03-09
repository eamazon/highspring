
/****** Object:  Table [CAM_Ref].[CommissionerAssignmentReason]    Script Date: 15/04/2025 08:04:32 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (
		SELECT * FROM INFORMATION_SCHEMA.TABLES
		WHERE TABLE_NAME = 'CommissionerAssignmentReason' AND TABLE_SCHEMA = 'CAM_Ref')

		DROP TABLE [CAM_Ref].[CommissionerAssignmentReason]

		CREATE TABLE [CAM_Ref].[CommissionerAssignmentReason](
			[CAM_Code] [varchar](50) NOT NULL,
			[Comm] [nvarchar](255) NULL,
			[Commissioner Assignment Reason] [nvarchar](255) NULL,
			[Service Category] [nvarchar](2) NULL,
		PRIMARY KEY CLUSTERED 
		(
			[CAM_Code] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
		) ON [PRIMARY]
GO

INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00L_C_5_1','00L','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00L_C_6_1','00L','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00L_C_6_2','00L','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00L_C_6_3','00L','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00L_D_1','00L','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00L_D_2','00L','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00L_D_3','00L','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00N_C_5_1','00N','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00N_C_6_1','00N','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00N_C_6_2','00N','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00N_C_6_3','00N','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00N_D_1','00N','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00N_D_2','00N','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00N_D_3','00N','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00P_C_5_1','00P','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00P_C_6_1','00P','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00P_C_6_2','00P','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00P_C_6_3','00P','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00P_D_1','00P','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00P_D_2','00P','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00P_D_3','00P','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00Q_C_5_1','00Q','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00Q_C_6_1','00Q','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00Q_C_6_2','00Q','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00Q_C_6_3','00Q','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00Q_D_1','00Q','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00Q_D_2','00Q','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00Q_D_3','00Q','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00R_C_5_1','00R','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00R_C_6_1','00R','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00R_C_6_2','00R','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00R_C_6_3','00R','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00R_D_1','00R','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00R_D_2','00R','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00R_D_3','00R','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00T_C_5_1','00T','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00T_C_6_1','00T','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00T_C_6_2','00T','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00T_C_6_3','00T','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00T_D_1','00T','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00T_D_2','00T','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00T_D_3','00T','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00V_C_5_1','00V','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00V_C_6_1','00V','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00V_C_6_2','00V','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00V_C_6_3','00V','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00V_D_1','00V','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00V_D_2','00V','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00V_D_3','00V','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00X_C_5_1','00X','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00X_C_6_1','00X','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00X_C_6_2','00X','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00X_C_6_3','00X','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00X_D_1','00X','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00X_D_2','00X','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00X_D_3','00X','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00Y_C_5_1','00Y','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00Y_C_6_1','00Y','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00Y_C_6_2','00Y','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00Y_C_6_3','00Y','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00Y_D_1','00Y','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00Y_D_2','00Y','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('00Y_D_3','00Y','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01A_C_5_1','01A','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01A_C_6_1','01A','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01A_C_6_2','01A','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01A_C_6_3','01A','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01A_D_1','01A','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01A_D_2','01A','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01A_D_3','01A','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01D_C_5_1','01D','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01D_C_6_1','01D','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01D_C_6_2','01D','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01D_C_6_3','01D','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01D_D_1','01D','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01D_D_2','01D','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01D_D_3','01D','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01E_C_5_1','01E','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01E_C_6_1','01E','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01E_C_6_2','01E','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01E_C_6_3','01E','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01E_D_1','01E','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01E_D_2','01E','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01E_D_3','01E','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01F_C_5_1','01F','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01F_C_6_1','01F','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01F_C_6_2','01F','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01F_C_6_3','01F','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01F_D_1','01F','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01F_D_2','01F','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01F_D_3','01F','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01G_C_5_1','01G','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01G_C_6_1','01G','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01G_C_6_2','01G','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01G_C_6_3','01G','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01G_D_1','01G','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01G_D_2','01G','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01G_D_3','01G','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01H_C_5_1','01H','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01H_C_6_1','01H','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01H_C_6_2','01H','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01H_C_6_3','01H','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01H_D_1','01H','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01H_D_2','01H','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01H_D_3','01H','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01J_C_5_1','01J','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01J_C_6_1','01J','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01J_C_6_2','01J','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01J_C_6_3','01J','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01J_D_1','01J','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01J_D_2','01J','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01J_D_3','01J','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01K_C_5_1','01K','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01K_C_6_1','01K','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01K_C_6_2','01K','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01K_C_6_3','01K','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01K_D_1','01K','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01K_D_2','01K','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01K_D_3','01K','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01T_C_5_1','01T','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01T_C_6_1','01T','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01T_C_6_2','01T','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01T_C_6_3','01T','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01T_D_1','01T','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01T_D_2','01T','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01T_D_3','01T','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01V_C_5_1','01V','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01V_C_6_1','01V','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01V_C_6_2','01V','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01V_C_6_3','01V','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01V_D_1','01V','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01V_D_2','01V','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01V_D_3','01V','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01W_C_5_1','01W','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01W_C_6_1','01W','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01W_C_6_2','01W','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01W_C_6_3','01W','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01W_D_1','01W','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01W_D_2','01W','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01W_D_3','01W','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01X_C_5_1','01X','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01X_C_6_1','01X','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01X_C_6_2','01X','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01X_C_6_3','01X','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01X_D_1','01X','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01X_D_2','01X','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01X_D_3','01X','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01Y_C_5_1','01Y','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01Y_C_6_1','01Y','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01Y_C_6_2','01Y','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01Y_C_6_3','01Y','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01Y_D_1','01Y','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01Y_D_2','01Y','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('01Y_D_3','01Y','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02A_C_5_1','02A','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02A_C_6_1','02A','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02A_C_6_2','02A','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02A_C_6_3','02A','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02A_D_1','02A','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02A_D_2','02A','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02A_D_3','02A','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02E_C_5_1','02E','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02E_C_6_1','02E','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02E_C_6_2','02E','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02E_C_6_3','02E','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02E_D_1','02E','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02E_D_2','02E','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02E_D_3','02E','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02G_C_5_1','02G','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02G_C_6_1','02G','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02G_C_6_2','02G','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02G_C_6_3','02G','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02G_D_1','02G','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02G_D_2','02G','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02G_D_3','02G','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02H_C_5_1','02H','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02H_C_6_1','02H','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02H_C_6_2','02H','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02H_C_6_3','02H','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02H_D_1','02H','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02H_D_2','02H','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02H_D_3','02H','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02M_C_5_1','02M','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02M_C_6_1','02M','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02M_C_6_2','02M','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02M_C_6_3','02M','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02M_D_1','02M','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02M_D_2','02M','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02M_D_3','02M','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02P_C_5_1','02P','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02P_C_6_1','02P','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02P_C_6_2','02P','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02P_C_6_3','02P','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02P_D_1','02P','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02P_D_2','02P','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02P_D_3','02P','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02Q_C_5_1','02Q','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02Q_C_6_1','02Q','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02Q_C_6_2','02Q','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02Q_C_6_3','02Q','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02Q_D_1','02Q','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02Q_D_2','02Q','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02Q_D_3','02Q','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02T_C_5_1','02T','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02T_C_6_1','02T','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02T_C_6_2','02T','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02T_C_6_3','02T','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02T_D_1','02T','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02T_D_2','02T','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02T_D_3','02T','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02X_C_5_1','02X','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02X_C_6_1','02X','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02X_C_6_2','02X','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02X_C_6_3','02X','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02X_D_1','02X','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02X_D_2','02X','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02X_D_3','02X','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02Y_C_5_1','02Y','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02Y_C_6_1','02Y','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02Y_C_6_2','02Y','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02Y_C_6_3','02Y','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02Y_D_1','02Y','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02Y_D_2','02Y','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('02Y_D_3','02Y','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03F_C_5_1','03F','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03F_C_6_1','03F','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03F_C_6_2','03F','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03F_C_6_3','03F','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03F_D_1','03F','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03F_D_2','03F','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03F_D_3','03F','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03H_C_5_1','03H','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03H_C_6_1','03H','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03H_C_6_2','03H','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03H_C_6_3','03H','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03H_D_1','03H','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03H_D_2','03H','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03H_D_3','03H','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03K_C_5_1','03K','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03K_C_6_1','03K','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03K_C_6_2','03K','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03K_C_6_3','03K','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03K_D_1','03K','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03K_D_2','03K','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03K_D_3','03K','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03L_C_5_1','03L','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03L_C_6_1','03L','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03L_C_6_2','03L','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03L_C_6_3','03L','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03L_D_1','03L','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03L_D_2','03L','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03L_D_3','03L','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03N_C_5_1','03N','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03N_C_6_1','03N','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03N_C_6_2','03N','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03N_C_6_3','03N','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03N_D_1','03N','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03N_D_2','03N','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03N_D_3','03N','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03Q_C_5_1','03Q','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03Q_C_6_1','03Q','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03Q_C_6_2','03Q','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03Q_C_6_3','03Q','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03Q_D_1','03Q','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03Q_D_2','03Q','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03Q_D_3','03Q','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03R_C_5_1','03R','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03R_C_6_1','03R','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03R_C_6_2','03R','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03R_C_6_3','03R','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03R_D_1','03R','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03R_D_2','03R','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03R_D_3','03R','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03W_C_5_1','03W','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03W_C_6_1','03W','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03W_C_6_2','03W','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03W_C_6_3','03W','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03W_D_1','03W','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03W_D_2','03W','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('03W_D_3','03W','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('04C_C_5_1','04C','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('04C_C_6_1','04C','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('04C_C_6_2','04C','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('04C_C_6_3','04C','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('04C_D_1','04C','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('04C_D_2','04C','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('04C_D_3','04C','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('04V_C_5_1','04V','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('04V_C_6_1','04V','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('04V_C_6_2','04V','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('04V_C_6_3','04V','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('04V_D_1','04V','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('04V_D_2','04V','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('04V_D_3','04V','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('04Y_C_5_1','04Y','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('04Y_C_6_1','04Y','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('04Y_C_6_2','04Y','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('04Y_C_6_3','04Y','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('04Y_D_1','04Y','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('04Y_D_2','04Y','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('04Y_D_3','04Y','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('05D_C_5_1','05D','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('05D_C_6_1','05D','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('05D_C_6_2','05D','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('05D_C_6_3','05D','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('05D_D_1','05D','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('05D_D_2','05D','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('05D_D_3','05D','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('05G_C_5_1','05G','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('05G_C_6_1','05G','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('05G_C_6_2','05G','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('05G_C_6_3','05G','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('05G_D_1','05G','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('05G_D_2','05G','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('05G_D_3','05G','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('05Q_C_5_1','05Q','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('05Q_C_6_1','05Q','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('05Q_C_6_2','05Q','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('05Q_C_6_3','05Q','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('05Q_D_1','05Q','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('05Q_D_2','05Q','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('05Q_D_3','05Q','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('05V_C_5_1','05V','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('05V_C_6_1','05V','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('05V_C_6_2','05V','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('05V_C_6_3','05V','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('05V_D_1','05V','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('05V_D_2','05V','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('05V_D_3','05V','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('05W_C_5_1','05W','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('05W_C_6_1','05W','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('05W_C_6_2','05W','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('05W_C_6_3','05W','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('05W_D_1','05W','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('05W_D_2','05W','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('05W_D_3','05W','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06H_C_5_1','06H','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06H_C_6_1','06H','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06H_C_6_2','06H','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06H_C_6_3','06H','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06H_D_1','06H','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06H_D_2','06H','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06H_D_3','06H','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06K_C_5_1','06K','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06K_C_6_1','06K','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06K_C_6_2','06K','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06K_C_6_3','06K','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06K_D_1','06K','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06K_D_2','06K','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06K_D_3','06K','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06L_C_5_1','06L','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06L_C_6_1','06L','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06L_C_6_2','06L','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06L_C_6_3','06L','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06L_D_1','06L','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06L_D_2','06L','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06L_D_3','06L','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06N_C_5_1','06N','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06N_C_6_1','06N','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06N_C_6_2','06N','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06N_C_6_3','06N','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06N_D_1','06N','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06N_D_2','06N','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06N_D_3','06N','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06Q_C_5_1','06Q','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06Q_C_6_1','06Q','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06Q_C_6_2','06Q','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06Q_C_6_3','06Q','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06Q_D_1','06Q','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06Q_D_2','06Q','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06Q_D_3','06Q','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06T_C_5_1','06T','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06T_C_6_1','06T','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06T_C_6_2','06T','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06T_C_6_3','06T','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06T_D_1','06T','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06T_D_2','06T','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('06T_D_3','06T','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('07G_C_5_1','07G','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('07G_C_6_1','07G','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('07G_C_6_2','07G','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('07G_C_6_3','07G','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('07G_D_1','07G','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('07G_D_2','07G','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('07G_D_3','07G','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('07H_C_5_1','07H','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('07H_C_6_1','07H','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('07H_C_6_2','07H','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('07H_C_6_3','07H','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('07H_D_1','07H','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('07H_D_2','07H','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('07H_D_3','07H','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('07K_C_5_1','07K','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('07K_C_6_1','07K','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('07K_C_6_2','07K','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('07K_C_6_3','07K','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('07K_D_1','07K','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('07K_D_2','07K','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('07K_D_3','07K','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('09D_C_5_1','09D','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('09D_C_6_1','09D','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('09D_C_6_2','09D','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('09D_C_6_3','09D','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('09D_D_1','09D','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('09D_D_2','09D','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('09D_D_3','09D','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('10Q_C_5_1','10Q','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('10Q_C_6_1','10Q','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('10Q_C_6_2','10Q','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('10Q_C_6_3','10Q','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('10Q_D_1','10Q','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('10Q_D_2','10Q','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('10Q_D_3','10Q','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('10R_C_5_1','10R','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('10R_C_6_1','10R','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('10R_C_6_2','10R','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('10R_C_6_3','10R','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('10R_D_1','10R','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('10R_D_2','10R','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('10R_D_3','10R','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('11J_C_5_1','11J','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('11J_C_6_1','11J','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('11J_C_6_2','11J','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('11J_C_6_3','11J','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('11J_D_1','11J','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('11J_D_2','11J','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('11J_D_3','11J','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('11M_C_5_1','11M','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('11M_C_6_1','11M','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('11M_C_6_2','11M','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('11M_C_6_3','11M','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('11M_D_1','11M','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('11M_D_2','11M','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('11M_D_3','11M','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('11N_C_5_1','11N','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('11N_C_6_1','11N','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('11N_C_6_2','11N','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('11N_C_6_3','11N','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('11N_D_1','11N','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('11N_D_2','11N','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('11N_D_3','11N','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('11X_C_5_1','11X','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('11X_C_6_1','11X','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('11X_C_6_2','11X','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('11X_C_6_3','11X','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('11X_D_1','11X','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('11X_D_2','11X','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('11X_D_3','11X','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('12F_C_5_1','12F','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('12F_C_6_1','12F','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('12F_C_6_2','12F','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('12F_C_6_3','12F','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('12F_D_1','12F','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('12F_D_2','12F','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('12F_D_3','12F','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('13Q_J_1','13Q','J - Commissioner identified as Armed Forces therefore National Code of 13Q assigned','61')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('13R_C_0b_1','13R','C-0b - Commissioner assigned by GP Practice Responsibility (subICB)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('13R_C_0b_2','13R','C-0b - Commissioner assigned by GP Practice Responsibility (ICB)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('13R_C_0b_3','13R','C-0b - Commissioner assigned by Residence Responsibility (subICB)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('13R_C_0b_4','13R','C-0b - Commissioner assigned by Residence Responsibility (ICB)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('13R_C_0b_5','13R','C-0b - Commissioner assigned by Provider Host subICB location','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('13R_C_2_1','13R','C-2 - Commissioner assigned by Provider Host subICB location','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('13R_C_6_4','13R','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(NOT delegated)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('13R_C_6_5','13R','C-6 - Commissioner assigned by GP Practice Responsibility (ICB)(NOT delegated)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('13R_C_6_6','13R','C-6 - Commissioner assigned by Residence Responsibility (subICB)(NOT delegated)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('13R_C_6_7','13R','C-6 - Commissioner assigned by Residence Responsibility (ICB)(NOT delegated)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('13R_C_6_8','13R','C-6 - Commissioner assigned by Provider host subICB location (NOT delegated)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('13T_C_5_1','13T','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('13T_C_6_1','13T','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('13T_C_6_2','13T','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('13T_C_6_3','13T','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('13T_D_1','13T','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('13T_D_2','13T','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('13T_D_3','13T','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14A_C_0b_1','14A','C-0b - Commissioner assigned by GP Practice Responsibility (subICB)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14A_C_0b_2','14A','C-0b - Commissioner assigned by GP Practice Responsibility (ICB)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14A_C_0b_3','14A','C-0b - Commissioner assigned by Residence Responsibility (subICB)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14A_C_0b_4','14A','C-0b - Commissioner assigned by Residence Responsibility (ICB)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14A_C_0b_5','14A','C-0b - Commissioner assigned by Provider Host subICB location','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14A_C_2_1','14A','C-2 - Commissioner assigned by Provider Host subICB location','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14A_C_6_4','14A','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(NOT delegated)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14A_C_6_5','14A','C-6 - Commissioner assigned by GP Practice Responsibility (ICB)(NOT delegated)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14A_C_6_6','14A','C-6 - Commissioner assigned by Residence Responsibility (subICB)(NOT delegated)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14A_C_6_7','14A','C-6 - Commissioner assigned by Residence Responsibility (ICB)(NOT delegated)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14A_C_6_8','14A','C-6 - Commissioner assigned by Provider host subICB location (NOT delegated)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14E_C_0b_1','14E','C-0b - Commissioner assigned by GP Practice Responsibility (subICB)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14E_C_0b_2','14E','C-0b - Commissioner assigned by GP Practice Responsibility (ICB)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14E_C_0b_3','14E','C-0b - Commissioner assigned by Residence Responsibility (subICB)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14E_C_0b_4','14E','C-0b - Commissioner assigned by Residence Responsibility (ICB)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14E_C_0b_5','14E','C-0b - Commissioner assigned by Provider Host subICB location','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14E_C_2_1','14E','C-2 - Commissioner assigned by Provider Host subICB location','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14E_C_6_4','14E','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(NOT delegated)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14E_C_6_5','14E','C-6 - Commissioner assigned by GP Practice Responsibility (ICB)(NOT delegated)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14E_C_6_6','14E','C-6 - Commissioner assigned by Residence Responsibility (subICB)(NOT delegated)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14E_C_6_7','14E','C-6 - Commissioner assigned by Residence Responsibility (ICB)(NOT delegated)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14E_C_6_8','14E','C-6 - Commissioner assigned by Provider host subICB location (NOT delegated)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14F_C_0b_1','14F','C-0b - Commissioner assigned by GP Practice Responsibility (subICB)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14F_C_0b_2','14F','C-0b - Commissioner assigned by GP Practice Responsibility (ICB)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14F_C_0b_3','14F','C-0b - Commissioner assigned by Residence Responsibility (subICB)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14F_C_0b_4','14F','C-0b - Commissioner assigned by Residence Responsibility (ICB)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14F_C_0b_5','14F','C-0b - Commissioner assigned by Provider Host subICB location','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14F_C_2_1','14F','C-2 - Commissioner assigned by Provider Host subICB location','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14F_C_6_4','14F','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(NOT delegated)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14F_C_6_5','14F','C-6 - Commissioner assigned by GP Practice Responsibility (ICB)(NOT delegated)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14F_C_6_6','14F','C-6 - Commissioner assigned by Residence Responsibility (subICB)(NOT delegated)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14F_C_6_7','14F','C-6 - Commissioner assigned by Residence Responsibility (ICB)(NOT delegated)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14F_C_6_8','14F','C-6 - Commissioner assigned by Provider host subICB location (NOT delegated)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14G_C_0b_1','14G','C-0b - Commissioner assigned by GP Practice Responsibility (subICB)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14G_C_0b_2','14G','C-0b - Commissioner assigned by GP Practice Responsibility (ICB)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14G_C_0b_3','14G','C-0b - Commissioner assigned by Residence Responsibility (subICB)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14G_C_0b_4','14G','C-0b - Commissioner assigned by Residence Responsibility (ICB)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14G_C_0b_5','14G','C-0b - Commissioner assigned by Provider Host subICB location','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14G_C_2_1','14G','C-2 - Commissioner assigned by Provider Host subICB location','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14G_C_6_4','14G','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(NOT delegated)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14G_C_6_5','14G','C-6 - Commissioner assigned by GP Practice Responsibility (ICB)(NOT delegated)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14G_C_6_6','14G','C-6 - Commissioner assigned by Residence Responsibility (subICB)(NOT delegated)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14G_C_6_7','14G','C-6 - Commissioner assigned by Residence Responsibility (ICB)(NOT delegated)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14G_C_6_8','14G','C-6 - Commissioner assigned by Provider host subICB location (NOT delegated)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14L_C_5_1','14L','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14L_C_6_1','14L','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14L_C_6_2','14L','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14L_C_6_3','14L','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14L_D_1','14L','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14L_D_2','14L','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14L_D_3','14L','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14M_E_1','14M','E - Commissioner assigned by GP Practice','71')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14Q_E_1','14Q','E - Commissioner assigned by GP Practice','71')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14R_E_1','14R','E - Commissioner assigned by GP Practice','71')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14T_E_1','14T','E - Commissioner assigned by GP Practice','71')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14Y_C_5_1','14Y','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14Y_C_6_1','14Y','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14Y_C_6_2','14Y','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14Y_C_6_3','14Y','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14Y_D_1','14Y','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14Y_D_2','14Y','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('14Y_D_3','14Y','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15A_C_5_1','15A','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15A_C_6_1','15A','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15A_C_6_2','15A','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15A_C_6_3','15A','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15A_D_1','15A','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15A_D_2','15A','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15A_D_3','15A','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15C_C_5_1','15C','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15C_C_6_1','15C','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15C_C_6_2','15C','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15C_C_6_3','15C','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15C_D_1','15C','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15C_D_2','15C','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15C_D_3','15C','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15E_C_5_1','15E','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15E_C_6_1','15E','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15E_C_6_2','15E','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15E_C_6_3','15E','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15E_D_1','15E','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15E_D_2','15E','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15E_D_3','15E','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15F_C_5_1','15F','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15F_C_6_1','15F','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15F_C_6_2','15F','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15F_C_6_3','15F','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15F_D_1','15F','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15F_D_2','15F','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15F_D_3','15F','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15M_C_5_1','15M','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15M_C_6_1','15M','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15M_C_6_2','15M','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15M_C_6_3','15M','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15M_D_1','15M','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15M_D_2','15M','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15M_D_3','15M','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15N_C_5_1','15N','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15N_C_6_1','15N','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15N_C_6_2','15N','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15N_C_6_3','15N','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15N_D_1','15N','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15N_D_2','15N','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('15N_D_3','15N','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('16C_C_5_1','16C','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('16C_C_6_1','16C','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('16C_C_6_2','16C','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('16C_C_6_3','16C','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('16C_D_1','16C','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('16C_D_2','16C','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('16C_D_3','16C','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('18C_C_5_1','18C','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('18C_C_6_1','18C','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('18C_C_6_2','18C','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('18C_C_6_3','18C','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('18C_D_1','18C','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('18C_D_2','18C','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('18C_D_3','18C','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('26A_C_5_1','26A','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('26A_C_6_1','26A','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('26A_C_6_2','26A','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('26A_C_6_3','26A','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('26A_D_1','26A','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('26A_D_2','26A','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('26A_D_3','26A','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('27D_C_5_1','27D','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('27D_C_6_1','27D','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('27D_C_6_2','27D','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('27D_C_6_3','27D','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('27D_D_1','27D','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('27D_D_2','27D','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('27D_D_3','27D','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('27T_C_0b_1','27T','C-0b - Commissioner assigned by GP Practice Responsibility (subICB)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('27T_C_0b_2','27T','C-0b - Commissioner assigned by GP Practice Responsibility (ICB)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('27T_C_0b_3','27T','C-0b - Commissioner assigned by Residence Responsibility (subICB)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('27T_C_0b_4','27T','C-0b - Commissioner assigned by Residence Responsibility (ICB)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('27T_C_0b_5','27T','C-0b - Commissioner assigned by Provider Host subICB location','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('27T_C_2_1','27T','C-2 - Commissioner assigned by Provider Host subICB location','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('27T_C_6_4','27T','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(NOT delegated)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('27T_C_6_5','27T','C-6 - Commissioner assigned by GP Practice Responsibility (ICB)(NOT delegated)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('27T_C_6_6','27T','C-6 - Commissioner assigned by Residence Responsibility (subICB)(NOT delegated)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('27T_C_6_7','27T','C-6 - Commissioner assigned by Residence Responsibility (ICB)(NOT delegated)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('27T_C_6_8','27T','C-6 - Commissioner assigned by Provider host subICB location (NOT delegated)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('32T_E_1','32T','E - Commissioner assigned by GP Practice','71')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('36J_C_5_1','36J','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('36J_C_6_1','36J','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('36J_C_6_2','36J','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('36J_C_6_3','36J','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('36J_D_1','36J','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('36J_D_2','36J','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('36J_D_3','36J','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('36L_C_5_1','36L','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('36L_C_6_1','36L','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('36L_C_6_2','36L','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('36L_C_6_3','36L','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('36L_D_1','36L','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('36L_D_2','36L','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('36L_D_3','36L','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('42D_C_5_1','42D','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('42D_C_6_1','42D','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('42D_C_6_2','42D','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('42D_C_6_3','42D','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('42D_D_1','42D','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('42D_D_2','42D','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('42D_D_3','42D','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('52R_C_5_1','52R','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('52R_C_6_1','52R','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('52R_C_6_2','52R','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('52R_C_6_3','52R','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('52R_D_1','52R','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('52R_D_2','52R','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('52R_D_3','52R','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('70F_C_5_1','70F','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('70F_C_6_1','70F','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('70F_C_6_2','70F','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('70F_C_6_3','70F','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('70F_D_1','70F','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('70F_D_2','70F','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('70F_D_3','70F','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('71E_C_5_1','71E','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('71E_C_6_1','71E','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('71E_C_6_2','71E','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('71E_C_6_3','71E','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('71E_D_1','71E','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('71E_D_2','71E','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('71E_D_3','71E','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('72Q_C_5_1','72Q','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('72Q_C_6_1','72Q','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('72Q_C_6_2','72Q','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('72Q_C_6_3','72Q','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('72Q_D_1','72Q','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('72Q_D_2','72Q','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('72Q_D_3','72Q','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('76A_E_1','76A','E - Commissioner assigned by GP Practice','71')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('78H_C_5_1','78H','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('78H_C_6_1','78H','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('78H_C_6_2','78H','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('78H_C_6_3','78H','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('78H_D_1','78H','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('78H_D_2','78H','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('78H_D_3','78H','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('84H_C_5_1','84H','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('84H_C_6_1','84H','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('84H_C_6_2','84H','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('84H_C_6_3','84H','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('84H_D_1','84H','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('84H_D_2','84H','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('84H_D_3','84H','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('85J_C_0b_1','85J','C-0b - Commissioner assigned by GP Practice Responsibility (subICB)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('85J_C_0b_2','85J','C-0b - Commissioner assigned by GP Practice Responsibility (ICB)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('85J_C_0b_3','85J','C-0b - Commissioner assigned by Residence Responsibility (subICB)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('85J_C_0b_4','85J','C-0b - Commissioner assigned by Residence Responsibility (ICB)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('85J_C_0b_5','85J','C-0b - Commissioner assigned by Provider Host subICB location','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('85J_C_2_1','85J','C-2 - Commissioner assigned by Provider Host subICB location','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('85J_C_6_4','85J','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(NOT delegated)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('85J_C_6_5','85J','C-6 - Commissioner assigned by GP Practice Responsibility (ICB)(NOT delegated)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('85J_C_6_6','85J','C-6 - Commissioner assigned by Residence Responsibility (subICB)(NOT delegated)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('85J_C_6_7','85J','C-6 - Commissioner assigned by Residence Responsibility (ICB)(NOT delegated)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('85J_C_6_8','85J','C-6 - Commissioner assigned by Provider host subICB location (NOT delegated)','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('91Q_C_5_1','91Q','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('91Q_C_6_1','91Q','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('91Q_C_6_2','91Q','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('91Q_C_6_3','91Q','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('91Q_D_1','91Q','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('91Q_D_2','91Q','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('91Q_D_3','91Q','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('92A_C_5_1','92A','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('92A_C_6_1','92A','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('92A_C_6_2','92A','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('92A_C_6_3','92A','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('92A_D_1','92A','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('92A_D_2','92A','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('92A_D_3','92A','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('92G_C_5_1','92G','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('92G_C_6_1','92G','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('92G_C_6_2','92G','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('92G_C_6_3','92G','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('92G_D_1','92G','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('92G_D_2','92G','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('92G_D_3','92G','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('93C_C_5_1','93C','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('93C_C_6_1','93C','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('93C_C_6_2','93C','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('93C_C_6_3','93C','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('93C_D_1','93C','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('93C_D_2','93C','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('93C_D_3','93C','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('97R_C_5_1','97R','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('97R_C_6_1','97R','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('97R_C_6_2','97R','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('97R_C_6_3','97R','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('97R_D_1','97R','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('97R_D_2','97R','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('97R_D_3','97R','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('97T_E_1','97T','E - Commissioner assigned by GP Practice','71')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('99A_C_5_1','99A','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('99A_C_6_1','99A','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('99A_C_6_2','99A','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('99A_C_6_3','99A','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('99A_D_1','99A','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('99A_D_2','99A','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('99A_D_3','99A','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('99C_C_5_1','99C','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('99C_C_6_1','99C','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('99C_C_6_2','99C','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('99C_C_6_3','99C','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('99C_D_1','99C','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('99C_D_2','99C','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('99C_D_3','99C','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('99E_C_5_1','99E','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('99E_C_6_1','99E','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('99E_C_6_2','99E','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('99E_C_6_3','99E','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('99E_D_1','99E','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('99E_D_2','99E','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('99E_D_3','99E','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('99F_C_5_1','99F','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('99F_C_6_1','99F','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('99F_C_6_2','99F','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('99F_C_6_3','99F','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('99F_D_1','99F','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('99F_D_2','99F','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('99F_D_3','99F','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('99G_C_5_1','99G','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('99G_C_6_1','99G','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('99G_C_6_2','99G','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('99G_C_6_3','99G','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('99G_D_1','99G','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('99G_D_2','99G','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('99G_D_3','99G','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('A3A8R_C_5_1','A3A8R','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('A3A8R_C_6_1','A3A8R','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('A3A8R_C_6_2','A3A8R','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('A3A8R_C_6_3','A3A8R','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('A3A8R_D_1','A3A8R','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('A3A8R_D_2','A3A8R','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('A3A8R_D_3','A3A8R','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('B2M3M_C_5_1','B2M3M','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('B2M3M_C_6_1','B2M3M','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('B2M3M_C_6_2','B2M3M','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('B2M3M_C_6_3','B2M3M','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('B2M3M_D_1','B2M3M','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('B2M3M_D_2','B2M3M','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('B2M3M_D_3','B2M3M','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('C_0b_X',NULL,'C-0b - Unable to determine Commissioning Hub for Specialised services in Scope for Delegation but not suitable','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('C_2_X',NULL,'C-2 - Unable to determine Commissioning Hub for Specialised services NOT in Scope for Delegation','21')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('C_5_X',NULL,'C-5 -Unable to determine GREEN services Commissioner',NULL)
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('D_X',NULL,'D - Unable to determine sub-ICB Dental Commissioner','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('D2P2L_C_5_1','D2P2L','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('D2P2L_C_6_1','D2P2L','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('D2P2L_C_6_2','D2P2L','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('D2P2L_C_6_3','D2P2L','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('D2P2L_D_1','D2P2L','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('D2P2L_D_2','D2P2L','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('D2P2L_D_3','D2P2L','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('D4U1Y_C_5_1','D4U1Y','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('D4U1Y_C_6_1','D4U1Y','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('D4U1Y_C_6_2','D4U1Y','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('D4U1Y_C_6_3','D4U1Y','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('D4U1Y_D_1','D4U1Y','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('D4U1Y_D_2','D4U1Y','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('D4U1Y_D_3','D4U1Y','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('D9Y0V_C_5_1','D9Y0V','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('D9Y0V_C_6_1','D9Y0V','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('D9Y0V_C_6_2','D9Y0V','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('D9Y0V_C_6_3','D9Y0V','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('D9Y0V_D_1','D9Y0V','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('D9Y0V_D_2','D9Y0V','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('D9Y0V_D_3','D9Y0V','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('E_X',NULL,'E - Unable to assigned Health in Justice Commissioner','71')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('F_X',NULL,'F - Unable to determine Public Health Commissioner','81')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('M1J4Y_C_5_1','M1J4Y','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('M1J4Y_C_6_1','M1J4Y','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('M1J4Y_C_6_2','M1J4Y','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('M1J4Y_C_6_3','M1J4Y','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('M1J4Y_D_1','M1J4Y','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('M1J4Y_D_2','M1J4Y','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('M1J4Y_D_3','M1J4Y','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('M2L0M_C_5_1','M2L0M','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('M2L0M_C_6_1','M2L0M','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('M2L0M_C_6_2','M2L0M','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('M2L0M_C_6_3','M2L0M','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('M2L0M_D_1','M2L0M','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('M2L0M_D_2','M2L0M','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('M2L0M_D_3','M2L0M','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('MH_Delegated',NULL,'Mental Health - Delegated service','26')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('MH_Non_Delegated',NULL,'Mental Health - Non delegated service','22')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('W2U3Z_C_5_1','W2U3Z','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('W2U3Z_C_6_1','W2U3Z','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('W2U3Z_C_6_2','W2U3Z','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('W2U3Z_C_6_3','W2U3Z','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('W2U3Z_D_1','W2U3Z','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('W2U3Z_D_2','W2U3Z','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('W2U3Z_D_3','W2U3Z','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('X',NULL,'Unable to assign Commissioner',NULL)
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('X2C4Y_C_5_1','X2C4Y','C-5 - Responsible sub-ICB Location','12')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('X2C4Y_C_6_1','X2C4Y','C-6 - Commissioner assigned by GP Practice Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('X2C4Y_C_6_2','X2C4Y','C-6 - Commissioner assigned by Residence Responsibility (subICB)(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('X2C4Y_C_6_3','X2C4Y','C-6 - Commissioner assigned by Provider host subICB location(delegated)','25')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('X2C4Y_D_1','X2C4Y','D - Commissioner assigned by GP Practice Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('X2C4Y_D_2','X2C4Y','D - Commissioner assigned by Residence Responsibility (subICB)','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('X2C4Y_D_3','X2C4Y','D - Commissioner assigned by Provider Host subICB location','55')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('Y56_F_1','Y56','F - Commissioner assigned by GP Practice Responsibility (subICB)','81')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('Y56_F_2','Y56','F - Commissioner assigned by GP Practice Responsibility (ICB)','81')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('Y56_F_3','Y56','F - Commissioner assigned by Residence Responsibility (subICB)','81')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('Y56_F_4','Y56','F - Commissioner assigned by Residence Responsibility (ICB)','81')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('Y56_F_5','Y56','F - Commissioner assigned by Provider Host subICB location','81')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('Y58_F_1','Y58','F - Commissioner assigned by GP Practice Responsibility (subICB)','81')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('Y58_F_2','Y58','F - Commissioner assigned by GP Practice Responsibility (ICB)','81')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('Y58_F_3','Y58','F - Commissioner assigned by Residence Responsibility (subICB)','81')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('Y58_F_4','Y58','F - Commissioner assigned by Residence Responsibility (ICB)','81')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('Y58_F_5','Y58','F - Commissioner assigned by Provider Host subICB location','81')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('Y59_F_1','Y59','F - Commissioner assigned by GP Practice Responsibility (subICB)','81')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('Y59_F_2','Y59','F - Commissioner assigned by GP Practice Responsibility (ICB)','81')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('Y59_F_3','Y59','F - Commissioner assigned by Residence Responsibility (subICB)','81')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('Y59_F_4','Y59','F - Commissioner assigned by Residence Responsibility (ICB)','81')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('Y59_F_5','Y59','F - Commissioner assigned by Provider Host subICB location','81')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('Y60_F_1','Y60','F - Commissioner assigned by GP Practice Responsibility (subICB)','81')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('Y60_F_2','Y60','F - Commissioner assigned by GP Practice Responsibility (ICB)','81')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('Y60_F_3','Y60','F - Commissioner assigned by Residence Responsibility (subICB)','81')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('Y60_F_4','Y60','F - Commissioner assigned by Residence Responsibility (ICB)','81')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('Y60_F_5','Y60','F - Commissioner assigned by Provider Host subICB location','81')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('Y61_F_1','Y61','F - Commissioner assigned by GP Practice Responsibility (subICB)','81')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('Y61_F_2','Y61','F - Commissioner assigned by GP Practice Responsibility (ICB)','81')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('Y61_F_3','Y61','F - Commissioner assigned by Residence Responsibility (subICB)','81')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('Y61_F_4','Y61','F - Commissioner assigned by Residence Responsibility (ICB)','81')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('Y61_F_5','Y61','F - Commissioner assigned by Provider Host subICB location','81')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('Y62_F_1','Y62','F - Commissioner assigned by GP Practice Responsibility (subICB)','81')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('Y62_F_2','Y62','F - Commissioner assigned by GP Practice Responsibility (ICB)','81')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('Y62_F_3','Y62','F - Commissioner assigned by Residence Responsibility (subICB)','81')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('Y62_F_4','Y62','F - Commissioner assigned by Residence Responsibility (ICB)','81')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('Y62_F_5','Y62','F - Commissioner assigned by Provider Host subICB location','81')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('Y63_F_1','Y63','F - Commissioner assigned by GP Practice Responsibility (subICB)','81')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('Y63_F_2','Y63','F - Commissioner assigned by GP Practice Responsibility (ICB)','81')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('Y63_F_3','Y63','F - Commissioner assigned by Residence Responsibility (subICB)','81')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('Y63_F_4','Y63','F - Commissioner assigned by Residence Responsibility (ICB)','81')
INSERT INTO [CAM_Ref].[CommissionerAssignmentReason]([CAM_Code],[Comm],[Commissioner Assignment Reason],[Service Category]) VALUES
           ('Y63_F_5','Y63','F - Commissioner assigned by Provider Host subICB location','81')

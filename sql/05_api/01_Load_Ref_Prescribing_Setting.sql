-------------------------------------------------------------------------------
-- Reference Table: Prescribing Setting / Role Mapping
-- Maps NHS ODS role IDs to prescribing setting descriptions
-- Auto-generated from prescribing_roles.csv
-------------------------------------------------------------------------------

USE [Data_Lab_SWL_Live];
GO

IF OBJECT_ID('[Analytics].[Ref_Prescribing_Setting]', 'U') IS NOT NULL
BEGIN
    PRINT 'Table [Analytics].[Ref_Prescribing_Setting] already exists. Dropping...';
    DROP TABLE [Analytics].[Ref_Prescribing_Setting];
END
GO

CREATE TABLE [Analytics].[Ref_Prescribing_Setting]
(
    Role_ID VARCHAR(20) NOT NULL,         -- e.g. RO76, RO87 and RO80
    Setting_Code INT NULL,                -- Numeric prescribing setting code from CSV
    Setting_Description VARCHAR(255) NOT NULL,
    CONSTRAINT PK_Ref_Prescribing_Setting PRIMARY KEY (Role_ID)
);
GO

PRINT '[OK] Created table: [Analytics].[Ref_Prescribing_Setting]';
GO

-- Insert reference data
INSERT INTO [Analytics].[Ref_Prescribing_Setting] (Role_ID, Setting_Code, Setting_Description) VALUES ('RO72', 0, 'Other');
INSERT INTO [Analytics].[Ref_Prescribing_Setting] (Role_ID, Setting_Code, Setting_Description) VALUES ('RO87', 1, 'WIC Practice');
INSERT INTO [Analytics].[Ref_Prescribing_Setting] (Role_ID, Setting_Code, Setting_Description) VALUES ('RO80', 2, 'OOH Practice');
INSERT INTO [Analytics].[Ref_Prescribing_Setting] (Role_ID, Setting_Code, Setting_Description) VALUES ('RO87 and RO80', 3, 'WIC + OOH Practice');
INSERT INTO [Analytics].[Ref_Prescribing_Setting] (Role_ID, Setting_Code, Setting_Description) VALUES ('RO76', 4, 'GP Practice');
INSERT INTO [Analytics].[Ref_Prescribing_Setting] (Role_ID, Setting_Code, Setting_Description) VALUES ('RO255', 8, 'Public Health Service');
INSERT INTO [Analytics].[Ref_Prescribing_Setting] (Role_ID, Setting_Code, Setting_Description) VALUES ('RO247', 9, 'Community Health Service');
INSERT INTO [Analytics].[Ref_Prescribing_Setting] (Role_ID, Setting_Code, Setting_Description) VALUES ('RO250', 10, 'Hospital Service');
INSERT INTO [Analytics].[Ref_Prescribing_Setting] (Role_ID, Setting_Code, Setting_Description) VALUES ('RO252', 11, 'Optometry Service');
INSERT INTO [Analytics].[Ref_Prescribing_Setting] (Role_ID, Setting_Code, Setting_Description) VALUES ('RO259', 12, 'Urgent & Emergency Care');
INSERT INTO [Analytics].[Ref_Prescribing_Setting] (Role_ID, Setting_Code, Setting_Description) VALUES ('RO249', 13, 'Hospice');
INSERT INTO [Analytics].[Ref_Prescribing_Setting] (Role_ID, Setting_Code, Setting_Description) VALUES ('RO246', 14, 'Care Home / Nursing Home');
INSERT INTO [Analytics].[Ref_Prescribing_Setting] (Role_ID, Setting_Code, Setting_Description) VALUES ('RO245', 15, 'Border Force');
INSERT INTO [Analytics].[Ref_Prescribing_Setting] (Role_ID, Setting_Code, Setting_Description) VALUES ('RO260', 16, 'Young Offender Institution');
INSERT INTO [Analytics].[Ref_Prescribing_Setting] (Role_ID, Setting_Code, Setting_Description) VALUES ('RO257', 17, 'Secure Training Centre');
INSERT INTO [Analytics].[Ref_Prescribing_Setting] (Role_ID, Setting_Code, Setting_Description) VALUES ('RO256', 18, 'Secure Children''s Home');
INSERT INTO [Analytics].[Ref_Prescribing_Setting] (Role_ID, Setting_Code, Setting_Description) VALUES ('RO251', 19, 'Immigration Removal Centre');
INSERT INTO [Analytics].[Ref_Prescribing_Setting] (Role_ID, Setting_Code, Setting_Description) VALUES ('RO248', 20, 'Court');
INSERT INTO [Analytics].[Ref_Prescribing_Setting] (Role_ID, Setting_Code, Setting_Description) VALUES ('RO254', 21, 'Police Custody');
INSERT INTO [Analytics].[Ref_Prescribing_Setting] (Role_ID, Setting_Code, Setting_Description) VALUES ('RO258', 22, 'Sexual Assault Referral Centre (SARC)');
INSERT INTO [Analytics].[Ref_Prescribing_Setting] (Role_ID, Setting_Code, Setting_Description) VALUES ('RO253', 24, 'Other – Justice Estate');
INSERT INTO [Analytics].[Ref_Prescribing_Setting] (Role_ID, Setting_Code, Setting_Description) VALUES ('RO82', 25, 'Prison');
INSERT INTO [Analytics].[Ref_Prescribing_Setting] (Role_ID, Setting_Code, Setting_Description) VALUES ('RO321', 26, 'Primary Care Network');
INSERT INTO [Analytics].[Ref_Prescribing_Setting] (Role_ID, Setting_Code, Setting_Description) VALUES ('RO323', 27, 'Independent Pharmacy Prescriber Pathfinder');
GO

PRINT '[OK] Inserted ' + CAST(@@ROWCOUNT AS VARCHAR) + ' prescribing role reference records';
GO

CREATE NONCLUSTERED INDEX IX_Ref_Prescribing_Setting_Code
    ON [Analytics].[Ref_Prescribing_Setting](Setting_Code)
    INCLUDE (Setting_Description);
GO

PRINT '[OK] Created index: IX_Ref_Prescribing_Setting_Code';
GO

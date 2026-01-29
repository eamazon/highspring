#!/usr/bin/env python3
"""
Parse prescribing_roles.csv and generate SQL INSERT statements for reference table.
"""

import csv

INPUT_CSV = "/home/speddi/dev/icb/sustabular/sql/analytics_platform/05_api/raw_inspection/prescribing_roles.csv"
OUTPUT_SQL = "/home/speddi/dev/icb/sustabular/sql/analytics_platform/03_static_data/01_Load_Ref_Prescribing_Setting.sql"

def sql_escape(value):
    """Escape single quotes for SQL"""
    if value is None or value == '':
        return 'NULL'
    return "'" + str(value).replace("'", "''") + "'"

print(f">>> Parsing {INPUT_CSV}")

with open(INPUT_CSV, 'r', encoding='utf-8') as infile, \
     open(OUTPUT_SQL, 'w', encoding='utf-8') as outfile:
    
    reader = csv.DictReader(infile)
    
    # Write header
    outfile.write("""-------------------------------------------------------------------------------
-- Reference Table: Prescribing Setting / Role Mapping
-- Maps NHS ODS Role IDs to prescribing setting descriptions
-- Source: NHS Digital ODS API
-- Auto-generated from prescribing_roles.csv
-------------------------------------------------------------------------------

USE [Data_Lab_SWL_Live];
GO

-- Drop existing table if exists
IF OBJECT_ID('[Analytics].[Ref_Prescribing_Setting]', 'U') IS NOT NULL
BEGIN
    PRINT 'Table [Analytics].[Ref_Prescribing_Setting] already exists. Dropping...';
    DROP TABLE [Analytics].[Ref_Prescribing_Setting];
END
GO

-- Create reference table
CREATE TABLE [Analytics].[Ref_Prescribing_Setting]
(
    Role_ID VARCHAR(10) NOT NULL,
    Setting_Code VARCHAR(5) NULL,           -- Legacy code (0, 1, 2, 3, 4)
    Setting_Description VARCHAR(255) NOT NULL,
    
    CONSTRAINT PK_Ref_Prescribing_Setting PRIMARY KEY (Role_ID)
);
GO

PRINT '[OK] Created table: [Analytics].[Ref_Prescribing_Setting]';
GO

-- Insert reference data
""")
    
    row_count = 0
    for row in reader:
        role_id = sql_escape(row.get('role_id', ''))
        setting_code = sql_escape(row.get('prescribing_setting', ''))
        setting_desc = sql_escape(row.get('setting_desc', ''))
        
        if setting_code == 'NULL' or setting_code == "''":
            setting_code = 'NULL'
        
        outfile.write(f"INSERT INTO [Analytics].[Ref_Prescribing_Setting] (Role_ID, Setting_Code, Setting_Description) VALUES ({role_id}, {setting_code}, {setting_desc});\n")
        row_count += 1
    
    outfile.write("""GO

PRINT '[OK] Inserted ' + CAST(@@ROWCOUNT AS VARCHAR) + ' prescribing role reference records';
GO

-- Create index for lookups
CREATE NONCLUSTERED INDEX IX_Ref_Prescribing_Setting_Code
    ON [Analytics].[Ref_Prescribing_Setting](Setting_Code)
    INCLUDE (Setting_Description);
GO

PRINT '[OK] Created index: IX_Ref_Prescribing_Setting_Code';
GO

-- Display summary
PRINT '';
PRINT '========================================';
PRINT 'Prescribing Setting Reference Table Complete';
PRINT '========================================';
PRINT '';
SELECT 
    COUNT(*) AS Total_Roles,
    COUNT(CASE WHEN Setting_Code IS NOT NULL THEN 1 END) AS With_Legacy_Code
FROM [Analytics].[Ref_Prescribing_Setting];
GO

PRINT '';
PRINT 'Sample Records:';
SELECT TOP 10
    Role_ID,
    Setting_Code,
    Setting_Description
FROM [Analytics].[Ref_Prescribing_Setting]
ORDER BY Role_ID;
GO
""")

print(f">>> Generated {OUTPUT_SQL}")
print(f">>> Rows: {row_count}")

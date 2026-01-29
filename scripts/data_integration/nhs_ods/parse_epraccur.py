#!/usr/bin/env python3
"""
Parse epraccur.csv and generate SQL INSERT statements for staging table.
Column mapping per NHS Digital specification (ignoring NULL columns 19-23, 25, 27).
"""

import csv
import sys
from datetime import datetime

# Input/Output
INPUT_CSV = "/home/speddi/dev/icb/sustabular/sql/analytics_platform/05_api/raw_inspection/epraccur.csv"
OUTPUT_SQL = f"/home/speddi/dev/icb/sustabular/sql/analytics_platform/05_api/gp_practices_epraccur_{datetime.now().strftime('%Y%m%d_%H%M%S')}.sql"

# Column indices (0-based) - mapping to staging table
COLUMN_MAP = {
    0: 'Practice_Code',           # Organisation Code
    1: 'Practice_Name',           # Name
    2: 'NHSER_Code',              # National Grouping
    3: 'ICB_Code',                # High Level Health Geography (THIS IS THE KEY FIELD!)
    4: 'Address_Line1',           # Address Line 1
    5: 'Address_Line2',           # Address Line 2
    6: 'Address_Line3',           # Address Line 3
    7: 'Town',                    # Address Line 4
    8: 'County',                  # Address Line 5 (legacy, often empty)
    9: 'Postcode',                # Postcode
    10: 'Open_Date',              # Legal Start Date
    11: 'Close_Date',             # Legal End Date
    12: 'Status',                 # Status Name (ACTIVE/INACTIVE/etc)
    13: 'Org_Sub_Type',           # Organisation Sub-Type Code (B/Z)
    14: 'Commissioner_Code',      # Commissioner (Sub ICB Location)
    15: 'Join_Provider_Date',     # Join Provider/Purchaser Date
    16: 'Left_Provider_Date',     # Left Provider/Purchaser Date
    17: 'Contact_Telephone',      # Contact Telephone Number
    # Skip 18-22 (NULL columns and Amended Record Indicator)
    23: 'Provider_Purchaser',     # Provider/Purchaser
    # Skip 24 (NULL)
    25: 'Prescribing_Setting',    # Prescribing Setting
    # Skip 26 (NULL)
}

def sql_escape(value):
    """Escape single quotes for SQL"""
    if value is None or value == '':
        return 'NULL'
    return "'" + str(value).replace("'", "''") + "'"

def parse_date(date_str):
    """Convert YYYYMMDD to SQL date format or NULL"""
    if not date_str or date_str == '':
        return 'NULL'
    try:
        # Format: YYYYMMDD
        return f"'{date_str[0:4]}-{date_str[4:6]}-{date_str[6:8]}'"
    except:
        return 'NULL'

print(f">>> Parsing {INPUT_CSV}")

with open(INPUT_CSV, 'r', encoding='utf-8') as infile, \
     open(OUTPUT_SQL, 'w', encoding='utf-8') as outfile:
    
    reader = csv.reader(infile)
    
    # Write header
    outfile.write("-- Generated GP Practice data from epraccur.csv\n")
    outfile.write(f"-- Generated: {datetime.now()}\n")
    outfile.write(f"-- Source: NHS Digital ODS epraccur report\n\n")
    outfile.write("USE [Data_Lab_SWL_Live];\nGO\n\n")
    outfile.write("-- Truncate before insert\n")
    outfile.write("TRUNCATE TABLE [Analytics].[tbl_Staging_GP_Practice];\nGO\n\n")
    
    row_count = 0
    batch_size = 1000
    
    for row in reader:
        if len(row) < 26:
            continue
            
        # Extract values by column index
        values = []
        values.append(sql_escape(row[0]))   # Practice_Code
        values.append(sql_escape(row[1]))   # Practice_Name
        values.append(sql_escape(row[12]))  # Status
        values.append(sql_escape(row[25]))  # Prescribing_Setting
        values.append(sql_escape(row[13]))  # Org_Sub_Type
        values.append(sql_escape(row[4]))   # Address_Line1
        values.append(sql_escape(row[5]))   # Address_Line2
        values.append(sql_escape(row[6]))   # Address_Line3
        values.append(sql_escape(row[7]))   # Town
        values.append(sql_escape(row[9]))   # Postcode
        values.append(sql_escape(row[17]))  # Contact_Telephone
        values.append('NULL')               # PCN_Code (not in epraccur)
        values.append('NULL')               # PCN_Name (not in epraccur)
        values.append(sql_escape(row[14]))  # Commissioner_Code (Sub-ICB)
        values.append('NULL')               # Commissioner_Name (will need lookup)
        values.append(sql_escape(row[3]))   # ICB_Code (COLUMN 4 - THE KEY!)
        values.append('NULL')               # ICB_Name (will need lookup)
        values.append(parse_date(row[10]))  # Open_Date
        values.append(parse_date(row[11]))  # Close_Date
        
        # Write INSERT
        if row_count % batch_size == 0:
            if row_count > 0:
                outfile.write("GO\n\n")
        
        outfile.write(f"INSERT INTO [Analytics].[tbl_Staging_GP_Practice] VALUES ({', '.join(values)});\n")
        row_count += 1
    
    outfile.write("GO\n")

print(f">>> Generated {OUTPUT_SQL}")
print(f">>> Rows: {row_count}")

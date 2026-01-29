#!/usr/bin/env python3
"""
Parse epcn.csv (PCN master data) and generate SQL INSERT statements.
Column mapping per NHS Digital specification.
"""

import csv
from datetime import datetime

INPUT_CSV = "/home/speddi/dev/icb/sustabular/sql/analytics_platform/05_api/raw_inspection/epcn.csv"
OUTPUT_SQL = f"/home/speddi/dev/icb/sustabular/sql/analytics_platform/05_api/pcn_master_{datetime.now().strftime('%Y%m%d_%H%M%S')}.sql"

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
        return f"'{date_str[0:4]}-{date_str[4:6]}-{date_str[6:8]}'"
    except:
        return 'NULL'

print(f">>> Parsing {INPUT_CSV}")

with open(INPUT_CSV, 'r', encoding='utf-8') as infile, \
     open(OUTPUT_SQL, 'w', encoding='utf-8') as outfile:
    
    reader = csv.reader(infile)
    
    # Write header
    outfile.write("-- Generated PCN Master data from epcn.csv\n")
    outfile.write(f"-- Generated: {datetime.now()}\n")
    outfile.write(f"-- Source: NHS Digital ODS epcn report\n\n")
    outfile.write("USE [Data_Lab_SWL_Live];\nGO\n\n")
    outfile.write("-- Truncate before insert\n")
    outfile.write("TRUNCATE TABLE [Analytics].[tbl_Staging_PCN];\nGO\n\n")
    
    row_count = 0
    batch_size = 1000
    
    for row in reader:
        if len(row) < 12:
            continue
            
        # Map columns per NHS Digital spec
        pcn_code = sql_escape(row[0])              # Col 1: PCN Code
        pcn_name = sql_escape(row[1])              # Col 2: PCN Name
        sub_icb_code = sql_escape(row[2])          # Col 3: Current Sub ICB Location Code
        sub_icb_name = sql_escape(row[3])          # Col 4: Sub ICB Location Name
        open_date = parse_date(row[4])             # Col 5: Open Date
        close_date = parse_date(row[5])            # Col 6: Close Date
        address1 = sql_escape(row[6])              # Col 7: Address Line 1
        address2 = sql_escape(row[7])              # Col 8: Address Line 2
        address3 = sql_escape(row[8])              # Col 9: Address Line 3
        town = sql_escape(row[9])                  # Col 10: Town
        county = sql_escape(row[10])               # Col 11: County (legacy)
        postcode = sql_escape(row[11])             # Col 12: Postcode
        
        # Write INSERT (matching tbl_Staging_PCN schema)
        if row_count % batch_size == 0:
            if row_count > 0:
                outfile.write("GO\n\n")
        
        # Schema: PCN_Code, PCN_Name, Sub_ICB_Code, Sub_ICB_Name, Open_Date, Close_Date, Address1-3, Town, Postcode
        outfile.write(f"INSERT INTO [Analytics].[tbl_Staging_PCN] VALUES ({pcn_code}, {pcn_name}, {sub_icb_code}, {sub_icb_name}, {open_date}, {close_date}, {address1}, {address2}, {address3}, {town}, {postcode});\n")
        row_count += 1
    
    outfile.write("GO\n")

print(f">>> Generated {OUTPUT_SQL}")
print(f">>> Rows: {row_count}")

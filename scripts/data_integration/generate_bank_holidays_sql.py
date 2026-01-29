#!/usr/bin/env python3
"""
generate_bank_holidays_sql.py

Purpose: Fetch UK Bank Holidays from gov.uk API and generate SQL INSERT statements
Source: https://www.gov.uk/bank-holidays.json
Frequency: Run annually to generate new SQL for next year
Output: SQL file that can be executed manually

Usage:
    python generate_bank_holidays_sql.py
    python generate_bank_holidays_sql.py --year 2028

Dependencies:
    pip install requests
"""

import requests
import argparse
import sys
from datetime import datetime

# Configuration
API_URL = "https://www.gov.uk/bank-holidays.json"
DB_SCHEMA = "Analytics"
DB_TABLE = "tbl_Bank_Holidays"


def fetch_bank_holidays_from_api():
    """Fetch bank holidays from UK Government API."""
    print(f"Fetching bank holidays from {API_URL}...")
    
    try:
        response = requests.get(API_URL, timeout=10)
        response.raise_for_status()
        data = response.json()
        
        # Extract England and Wales bank holidays
        england_holidays = data.get('england-and-wales', {}).get('events', [])
        
        print(f"✓ Fetched {len(england_holidays)} bank holidays from API")
        return england_holidays
        
    except requests.exceptions.RequestException as e:
        print(f"✗ Error fetching from API: {e}")
        sys.exit(1)


def categorize_holiday_type(title):
    """Categorize holiday type based on title."""
    title_lower = title.lower()
    
    if 'new year' in title_lower:
        return 'New Year'
    elif 'easter' in title_lower or 'good friday' in title_lower:
        return 'Easter'
    elif 'christmas' in title_lower or 'boxing' in title_lower:
        return 'Christmas'
    else:
        return 'Other'


def generate_sql_full_refresh(holidays):
    """Generate SQL for full table refresh."""
    sql_lines = []
    
    sql_lines.append("/*")
    sql_lines.append(f" * Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    sql_lines.append(f" * Source: {API_URL}")
    sql_lines.append(f" * Records: {len(holidays)}")
    sql_lines.append(" */")
    sql_lines.append("")
    sql_lines.append("USE [Data_Lab_SWL_Live];")
    sql_lines.append("GO")
    sql_lines.append("")
    sql_lines.append(f"-- Truncate existing data")
    sql_lines.append(f"TRUNCATE TABLE [{DB_SCHEMA}].[{DB_TABLE}];")
    sql_lines.append("GO")
    sql_lines.append("")
    sql_lines.append(f"-- Insert all bank holidays")
    sql_lines.append(f"INSERT INTO [{DB_SCHEMA}].[{DB_TABLE}]")
    sql_lines.append("    (Bank_Holiday_Date, Bank_Holiday_Name, Holiday_Type, Year, Notes)")
    sql_lines.append("VALUES")
    
    # Generate INSERT values
    for i, holiday in enumerate(holidays):
        date = holiday['date']
        title = holiday['title'].replace("'", "''")  # Escape single quotes
        notes = holiday.get('notes', '').replace("'", "''")
        year = int(date.split('-')[0])
        holiday_type = categorize_holiday_type(title)
        
        comma = "," if i < len(holidays) - 1 else ";"
        notes_sql = f"'{notes}'" if notes else "NULL"
        
        sql_lines.append(f"    ('{date}', '{title}', '{holiday_type}', {year}, {notes_sql}){comma}")
    
    sql_lines.append("GO")
    sql_lines.append("")
    sql_lines.append("-- Validation")
    sql_lines.append(f"SELECT Year, COUNT(*) AS Holiday_Count")
    sql_lines.append(f"FROM [{DB_SCHEMA}].[{DB_TABLE}]")
    sql_lines.append("GROUP BY Year")
    sql_lines.append("ORDER BY Year DESC;")
    sql_lines.append("GO")
    
    return "\n".join(sql_lines)


def generate_sql_for_year(holidays, target_year):
    """Generate SQL for specific year only."""
    year_holidays = [h for h in holidays if h['date'].startswith(str(target_year))]
    
    if not year_holidays:
        print(f"✗ No holidays found for year {target_year}")
        sys.exit(1)
    
    sql_lines = []
    
    sql_lines.append("/*")
    sql_lines.append(f" * Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    sql_lines.append(f" * Source: {API_URL}")
    sql_lines.append(f" * Year: {target_year}")
    sql_lines.append(f" * Records: {len(year_holidays)}")
    sql_lines.append(" */")
    sql_lines.append("")
    sql_lines.append("USE [Data_Lab_SWL_Live];")
    sql_lines.append("GO")
    sql_lines.append("")
    sql_lines.append(f"-- Delete existing {target_year} holidays (if any)")
    sql_lines.append(f"DELETE FROM [{DB_SCHEMA}].[{DB_TABLE}]")
    sql_lines.append(f"WHERE Year = {target_year};")
    sql_lines.append("GO")
    sql_lines.append("")
    sql_lines.append(f"PRINT 'Deleted ' + CAST(@@ROWCOUNT AS VARCHAR) + ' existing records for {target_year}';")
    sql_lines.append("GO")
    sql_lines.append("")
    sql_lines.append(f"-- Insert {target_year} bank holidays")
    sql_lines.append(f"INSERT INTO [{DB_SCHEMA}].[{DB_TABLE}]")
    sql_lines.append("    (Bank_Holiday_Date, Bank_Holiday_Name, Holiday_Type, Year, Notes)")
    sql_lines.append("VALUES")
    
    # Generate INSERT values
    for i, holiday in enumerate(year_holidays):
        date = holiday['date']
        title = holiday['title'].replace("'", "''")
        notes = holiday.get('notes', '').replace("'", "''")
        holiday_type = categorize_holiday_type(title)
        
        comma = "," if i < len(year_holidays) - 1 else ";"
        notes_sql = f"'{notes}'" if notes else "NULL"
        
        sql_lines.append(f"    ('{date}', '{title}', '{holiday_type}', {target_year}, {notes_sql}){comma}")
    
    sql_lines.append("GO")
    sql_lines.append("")
    sql_lines.append(f"PRINT 'Inserted ' + CAST(@@ROWCOUNT AS VARCHAR) + ' holidays for {target_year}';")
    sql_lines.append("GO")
    
    return "\n".join(sql_lines)


def main():
    parser = argparse.ArgumentParser(description="Generate SQL for UK Bank Holidays")
    parser.add_argument(
        '--year',
        type=int,
        help='Generate SQL for specific year only (default: all years)'
    )
    parser.add_argument(
        '--output',
        type=str,
        help='Output SQL file (default: print to console)'
    )
    
    args = parser.parse_args()
    
    # Fetch holidays from API
    holidays = fetch_bank_holidays_from_api()
    
    # Generate SQL
    if args.year:
        sql_output = generate_sql_for_year(holidays, args.year)
        default_filename = f"bank_holidays_{args.year}.sql"
    else:
        sql_output = generate_sql_full_refresh(holidays)
        default_filename = "bank_holidays_all.sql"
    
    # Output
    if args.output:
        output_file = args.output
    else:
        output_file = f"../../sql/analytics_platform/05_api/{default_filename}"
    
    # Write to file
    with open(output_file, 'w') as f:
        f.write(sql_output)
    
    print(f"\n✓ Generated SQL file: {output_file}")
    print(f"  Records: {len([h for h in holidays if not args.year or h['date'].startswith(str(args.year))])}")
    print(f"\nTo deploy: Execute the SQL file in SQL Server Management Studio or Azure Data Studio")


if __name__ == "__main__":
    main()

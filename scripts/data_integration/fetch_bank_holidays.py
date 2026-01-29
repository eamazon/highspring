#!/usr/bin/env python3
"""
fetch_bank_holidays.py

Purpose: Fetch UK Bank Holidays from gov.uk API and load into Analytics.tbl_Bank_Holidays
Source: https://www.gov.uk/bank-holidays.json
Frequency: Run annually to add new year's holidays
Database: Data_Lab_SWL_Live
Schema: Analytics

Usage:
    python fetch_bank_holidays.py --mode refresh
    python fetch_bank_holidays.py --mode append --year 2028

Dependencies:
    pip install requests pyodbc python-dotenv
"""

import requests
import pyodbc
import argparse
import sys
from datetime import datetime
from typing import List, Dict
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configuration
API_URL = "https://www.gov.uk/bank-holidays.json"
DB_SERVER = os.getenv("DB_SERVER", "localhost")
DB_NAME = os.getenv("DB_NAME", "Data_Lab_SWL_Live")
DB_SCHEMA = "Analytics"
DB_TABLE = "tbl_Bank_Holidays"


def fetch_bank_holidays_from_api() -> List[Dict]:
    """
    Fetch bank holidays from UK Government API.
    
    Returns:
        List of bank holiday dictionaries with date, title, notes
    """
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


def categorize_holiday_type(title: str) -> str:
    """
    Categorize holiday type based on title.
    
    Args:
        title: Holiday name
        
    Returns:
        Category: 'New Year', 'Easter', 'Christmas', or 'Other'
    """
    title_lower = title.lower()
    
    if 'new year' in title_lower:
        return 'New Year'
    elif 'easter' in title_lower or 'good friday' in title_lower:
        return 'Easter'
    elif 'christmas' in title_lower or 'boxing' in title_lower:
        return 'Christmas'
    else:
        return 'Other'


def get_db_connection():
    """
    Create database connection using Windows Authentication or SQL Auth.
    
    Returns:
        pyodbc connection object
    """
    try:
        # Try Windows Authentication first
        conn_str = (
            f"DRIVER={{ODBC Driver 17 for SQL Server}};"
            f"SERVER={DB_SERVER};"
            f"DATABASE={DB_NAME};"
            f"Trusted_Connection=yes;"
        )
        
        conn = pyodbc.connect(conn_str)
        print(f"✓ Connected to {DB_NAME} on {DB_SERVER}")
        return conn
        
    except pyodbc.Error as e:
        # Fallback to SQL Authentication if env vars provided
        username = os.getenv("DB_USERNAME")
        password = os.getenv("DB_PASSWORD")
        
        if username and password:
            conn_str = (
                f"DRIVER={{ODBC Driver 17 for SQL Server}};"
                f"SERVER={DB_SERVER};"
                f"DATABASE={DB_NAME};"
                f"UID={username};"
                f"PWD={password};"
            )
            try:
                conn = pyodbc.connect(conn_str)
                print(f"✓ Connected to {DB_NAME} on {DB_SERVER} (SQL Auth)")
                return conn
            except pyodbc.Error as e2:
                print(f"✗ Database connection failed: {e2}")
                sys.exit(1)
        else:
            print(f"✗ Database connection failed: {e}")
            print("  Set DB_USERNAME and DB_PASSWORD environment variables for SQL Auth")
            sys.exit(1)


def refresh_all_holidays(conn, holidays: List[Dict]):
    """
    Truncate and reload all bank holidays.
    
    Args:
        conn: Database connection
        holidays: List of holiday dictionaries
    """
    cursor = conn.cursor()
    
    print(f"\nRefresh mode: Truncating [{DB_SCHEMA}].[{DB_TABLE}]...")
    cursor.execute(f"TRUNCATE TABLE [{DB_SCHEMA}].[{DB_TABLE}];")
    
    print(f"Inserting {len(holidays)} bank holidays...")
    
    insert_count = 0
    for holiday in holidays:
        date = holiday['date']
        title = holiday['title']
        notes = holiday.get('notes', '')
        year = int(date.split('-')[0])
        holiday_type = categorize_holiday_type(title)
        
        # Insert record
        cursor.execute(f"""
            INSERT INTO [{DB_SCHEMA}].[{DB_TABLE}] 
                (Bank_Holiday_Date, Bank_Holiday_Name, Holiday_Type, Year, Notes)
            VALUES (?, ?, ?, ?, ?)
        """, date, title, holiday_type, year, notes if notes else None)
        
        insert_count += 1
    
    conn.commit()
    print(f"✓ Inserted {insert_count} bank holidays")


def append_new_year_holidays(conn, holidays: List[Dict], target_year: int):
    """
    Append bank holidays for a specific year.
    
    Args:
        conn: Database connection
        holidays: List of holiday dictionaries
        target_year: Year to add holidays for
    """
    cursor = conn.cursor()
    
    # Filter holidays for target year
    year_holidays = [h for h in holidays if h['date'].startswith(str(target_year))]
    
    if not year_holidays:
        print(f"✗ No holidays found for year {target_year}")
        return
    
    print(f"\nAppend mode: Adding {len(year_holidays)} holidays for {target_year}...")
    
    # Check if year already exists
    cursor.execute(f"""
        SELECT COUNT(*) FROM [{DB_SCHEMA}].[{DB_TABLE}]
        WHERE Year = ?
    """, target_year)
    
    existing_count = cursor.fetchone()[0]
    
    if existing_count > 0:
        print(f"⚠ Warning: {existing_count} holidays already exist for {target_year}")
        response = input("Delete existing and re-add? (y/n): ")
        if response.lower() == 'y':
            cursor.execute(f"""
                DELETE FROM [{DB_SCHEMA}].[{DB_TABLE}]
                WHERE Year = ?
            """, target_year)
            print(f"✓ Deleted {cursor.rowcount} existing records")
        else:
            print("Cancelled.")
            return
    
    # Insert new holidays
    insert_count = 0
    for holiday in year_holidays:
        date = holiday['date']
        title = holiday['title']
        notes = holiday.get('notes', '')
        holiday_type = categorize_holiday_type(title)
        
        cursor.execute(f"""
            INSERT INTO [{DB_SCHEMA}].[{DB_TABLE}] 
                (Bank_Holiday_Date, Bank_Holiday_Name, Holiday_Type, Year, Notes)
            VALUES (?, ?, ?, ?, ?)
        """, date, title, holiday_type, target_year, notes if notes else None)
        
        insert_count += 1
    
    conn.commit()
    print(f"✓ Inserted {insert_count} holidays for {target_year}")


def show_summary(conn):
    """
    Display summary of loaded bank holidays.
    
    Args:
        conn: Database connection
    """
    cursor = conn.cursor()
    
    print("\n" + "="*50)
    print("Bank Holidays Summary")
    print("="*50)
    
    # Count by year
    cursor.execute(f"""
        SELECT Year, COUNT(*) AS Count
        FROM [{DB_SCHEMA}].[{DB_TABLE}]
        GROUP BY Year
        ORDER BY Year DESC
    """)
    
    for row in cursor.fetchall():
        print(f"  {row[0]}: {row[1]} holidays")
    
    # Total
    cursor.execute(f"SELECT COUNT(*) FROM [{DB_SCHEMA}].[{DB_TABLE}]")
    total = cursor.fetchone()[0]
    print(f"\nTotal: {total} bank holidays")


def main():
    parser = argparse.ArgumentParser(description="Fetch UK Bank Holidays from gov.uk API")
    parser.add_argument(
        '--mode',
        choices=['refresh', 'append'],
        default='refresh',
        help='refresh: Replace all holidays | append: Add new year'
    )
    parser.add_argument(
        '--year',
        type=int,
        help='Year to add holidays for (append mode only)'
    )
    
    args = parser.parse_args()
    
    # Validate arguments
    if args.mode == 'append' and not args.year:
        print("✗ Error: --year required for append mode")
        sys.exit(1)
    
    # Fetch holidays from API
    holidays = fetch_bank_holidays_from_api()
    
    # Connect to database
    conn = get_db_connection()
    
    try:
        if args.mode == 'refresh':
            refresh_all_holidays(conn, holidays)
        else:
            append_new_year_holidays(conn, holidays, args.year)
        
        # Show summary
        show_summary(conn)
        
    finally:
        conn.close()
        print("\n✓ Database connection closed")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
NHS ODS PCN Fetcher
Fetches Primary Care Network (PCN) data including ICB linkage
"""

import urllib.request
import json
import csv
import io
import sys
from datetime import datetime

def fetch_pcn_data():
    """Fetch PCN data from NHS ODS CSV API"""
    url = "https://www.odsdatasearchandexport.nhs.uk/api/getReport?report=epcn"
    
    print(f"Fetching PCN data from NHS ODS...")
    
    try:
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req, timeout=120) as response:
            csv_text = response.read().decode('utf-8')
        
        # CSV has no headers - define them based on observed data
        headers = [
            'PCN_Code', 'PCN_Name', 'ICB_Code', 'ICB_Name',
            'Open_Date', 'Close_Date',
            'Address_Line1', 'Address_Line2', 'Address_Line3',
            'Town', 'County', 'Postcode'
        ]
        
        reader = csv.DictReader(io.StringIO(csv_text), fieldnames=headers)
        records = []
        
        for row in reader:
            records.append({
                'PCN_Code': row['PCN_Code'].strip('"'),
                'PCN_Name': row['PCN_Name'].strip('"'),
                'ICB_Code': row['ICB_Code'].strip('"'),
                'ICB_Name': row['ICB_Name'].strip('"'),
                'Open_Date': row['Open_Date'].strip('"'),
                'Close_Date': row['Close_Date'].strip('"'),
                'Postcode': row['Postcode'].strip('"'),
                'Town': row['Town'].strip('"'),
                'Fetch_Date': datetime.now().isoformat()
            })
        
        print(f"  ✓ Fetched {len(records)} PCNs")
        return records
        
    except Exception as e:
        print(f"  ✗ Error: {e}")
        return []

def generate_sql(records, table='[Analytics].[tbl_Staging_PCN]', batch_size=1000):
    """Generate SQL INSERT statements using multi-row VALUES batches"""
    
    lines = [
        f"-- PCN Data from NHS ODS CSV API",
        f"-- Generated: {datetime.now().isoformat()}",
        f"-- Total Records: {len(records)}",
        "",
        f"TRUNCATE TABLE {table};",
        ""
    ]
    
    def fmt(val):
        if not val or val == '':
            return "NULL"
        escaped = str(val).replace("'", "''")
        return f"'{escaped}'"

    cols = "PCN_Code, PCN_Name, ICB_Code, ICB_Name, Open_Date, Close_Date, Postcode, Town"
    for i in range(0, len(records), batch_size):
        chunk = records[i:i + batch_size]
        lines.append(f"INSERT INTO {table} ({cols}) VALUES")
        values = []
        for r in chunk:
            values.append(
                "("
                f"{fmt(r['PCN_Code'])}, {fmt(r['PCN_Name'])}, "
                f"{fmt(r['ICB_Code'])}, {fmt(r['ICB_Name'])}, "
                f"{fmt(r['Open_Date'])}, {fmt(r['Close_Date'])}, "
                f"{fmt(r['Postcode'])}, {fmt(r['Town'])}"
                ")"
            )
        lines.append(",\n".join(values) + ";")
    
    return "\n".join(lines)

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Fetch PCN data from NHS ODS')
    parser.add_argument('--output', choices=['sql', 'json'], default='sql')
    parser.add_argument('--batch-size', type=int, default=1000, help='Rows per INSERT batch (SQL output only)')
    
    args = parser.parse_args()
    
    print(f"\n{'='*70}")
    print("NHS PCN Fetcher")
    print(f"{'='*70}\n")
    
    records = fetch_pcn_data()
    
    if not records:
        print("No records fetched!")
        return 1
    
    # Summary
    swl_pcns = [r for r in records if r['ICB_Code'] == '36L']
    print(f"\nDataset Summary:")
    print(f"  Total PCNs: {len(records)}")
    print(f"  SWL PCNs (36L): {len(swl_pcns)}")
    
    # Output
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    
    if args.output == 'sql':
        filename = f"nhs_pcn_complete_{timestamp}.sql"
        content = generate_sql(records, batch_size=args.batch_size)
    else:
        filename = f"nhs_pcn_complete_{timestamp}.json"
        content = json.dumps(records, indent=2)
    
    with open(filename, 'w') as f:
        f.write(content)
    
    print(f"\n[OK] Saved to: {filename}")
    print(f"\n{'='*70}\n")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""
NHS ODS GP Practice Fetcher - CSV Report API
Uses the simpler ODS Data Search and Export API instead of FHIR
"""

import urllib.request
import json
import csv
import io
import sys
from datetime import datetime

def fetch_gp_practices_csv(report='epraccur', changes_since=None):
    """
    Fetch GP practices using CSV report API
    
    Args:
        report: Report name ('epraccur' for current GP practices)
        changes_since: Optional date in YYYY-MM-DD format for changes only
    
    Returns:
        List of dicts with GP practice data
    """
    base_url = "https://www.odsdatasearchandexport.nhs.uk/api/getReport"
    
    if changes_since:
        url = f"{base_url}?report={report}&lastChangeStart={changes_since}"
    else:
        url = f"{base_url}?report={report}"
    
    print(f"Fetching GP practices from NHS ODS CSV API...")
    print(f"URL: {url}\n")
    
    try:
        req = urllib.request.Request(url)
        
        with urllib.request.urlopen(req, timeout=120) as response:
            csv_text = response.read().decode('utf-8')
        
        if not csv_text:
            print(f"No data returned for report: {report}")
            return []
        
        # CSV has no headers - define them based on ODS schema
        # Based on: https://www.odsdatasearchandexport.nhs.uk
        headers = [
            'Organisation_Code', 'Name', 'National_Grouping', 'High_Level_Health_Geography',
            'Address_Line1', 'Address_Line2', 'Address_Line3', 'Address_Line4', 'Address_Line5',
            'Postcode', 'Open_Date', 'Close_Date', 'Status_Code', 'Organisation_SubType_Code',
            'Commissioner_Code', 'Join_Provider_Date', 'Left_Provider_Date', 'Contact_Telephone',
            'Null1', 'Null2', 'Null3', 'Amended_Record_Indicator', 'Null4',
            'Provider_Code', 'Null5', 'Role_Code', 'Null6'
        ]
        
        # Parse CSV with custom headers
        lines = csv_text.strip().split('\n')
        reader = csv.DictReader(io.StringIO(csv_text), fieldnames=headers)
        records = list(reader)
        
        print(f"✓ Successfully fetched {len(records)} GP practices\n")
        return records
        
    except Exception as e:
        print(f"✗ Error fetching data: {e}")
        return []

def parse_gp_record(row):
    """Convert CSV row to standardized dictionary"""
    return {
        'Practice_Code': row.get('Organisation_Code', '').strip('"'),
        'Practice_Name': row.get('Name', '').strip('"'),
        'Status': row.get('Status_Code', '').strip('"'),
        'Open_Date': row.get('Open_Date', '').strip('"'),
        'Close_Date': row.get('Close_Date', '').strip('"'),
        'Postcode': row.get('Postcode', '').strip('"'),
        'Address_Line1': row.get('Address_Line1', '').strip('"'),
        'Address_Line2': row.get('Address_Line2', '').strip('"'),
        'Address_Line3': row.get('Address_Line3', '').strip('"'),
        'Town': row.get('Address_Line4', '').strip('"'),
        'County': row.get('Address_Line5', '').strip('"'),
        'Commissioner_Code': row.get('Commissioner_Code', '').strip('"'),
        'Commissioner_Name': None,
        'ICB_Code': None,
        'ICB_Name': None,
        'PCN_Code': None,
        'PCN_Name': None,
        'Contact_Telephone': row.get('Contact_Telephone', '').strip('"'),
        'Prescribing_Setting': row.get('Prescribing_Setting', '').strip('"'),
        'Org_Sub_Type': row.get('Org_Sub_Type', '').strip('"'),
        'National_Grouping': row.get('National_Grouping', '').strip('"'),
        'High_Level_Health_Geography': row.get('High_Level_Health_Geography', '').strip('"'),
        'Fetch_Date': datetime.now().isoformat()
    }

def generate_sql(records, table='[Analytics].[tbl_Staging_GP_Practice]', batch_size=1000):
    """Generate SQL INSERT statements using multi-row VALUES batches"""
    
    lines = [
        f"-- GP Practice Data from NHS ODS CSV API",
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

    cols = ("Practice_Code, Practice_Name, Status, Prescribing_Setting, Org_Sub_Type, "
            "Address_Line1, Address_Line2, Address_Line3, Town, Postcode, Contact_Telephone, "
            "PCN_Code, PCN_Name, Commissioner_Code, Commissioner_Name, ICB_Code, ICB_Name, "
            "Open_Date, Close_Date")
    for i in range(0, len(records), batch_size):
        chunk = records[i:i + batch_size]
        lines.append(f"INSERT INTO {table} ({cols}) VALUES")
        values = []
        for r in chunk:
            values.append(
                "("
                f"{fmt(r['Practice_Code'])}, {fmt(r['Practice_Name'])}, {fmt(r['Status'])}, "
                f"{fmt(r['Prescribing_Setting'])}, {fmt(r['Org_Sub_Type'])}, "
                f"{fmt(r['Address_Line1'])}, {fmt(r['Address_Line2'])}, {fmt(r['Address_Line3'])}, {fmt(r['Town'])}, {fmt(r['Postcode'])}, {fmt(r['Contact_Telephone'])}, "
                f"{fmt(r['PCN_Code'])}, {fmt(r['PCN_Name'])}, {fmt(r['Commissioner_Code'])}, {fmt(r['Commissioner_Name'])}, {fmt(r['ICB_Code'])}, {fmt(r['ICB_Name'])}, "
                f"{fmt(r['Open_Date'])}, {fmt(r['Close_Date'])}"
                ")"
            )
        lines.append(",\n".join(values) + ";")
    
    return "\n".join(lines)

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Fetch GP Practice data from NHS ODS CSV API')
    parser.add_argument('--report', default='epraccur', 
                        help='Report name (default: epraccur for current practices)')
    parser.add_argument('--changes-since', help='Only fetch changes since date (YYYY-MM-DD)')
    parser.add_argument('--output', choices=['sql', 'json', 'csv'], default='sql')
    parser.add_argument('--max-records', type=int, default=0, help='Limit records (0=all)')
    parser.add_argument('--batch-size', type=int, default=1000, help='Rows per INSERT batch (SQL output only)')
    
    args = parser.parse_args()
    
    print(f"\n{'='*70}")
    print("NHS GP Practice Fetcher (CSV API)")
    print(f"{'='*70}\n")
    
    # Fetch data
    raw_records = fetch_gp_practices_csv(args.report, args.changes_since)
    
    if not raw_records:
        print("No records fetched!")
        return 1
    
    # Parse records
    records = [parse_gp_record(row) for row in raw_records]
    
    # Limit if requested
    if args.max_records > 0:
        records = records[:args.max_records]
        print(f"Limited to first {args.max_records} records\n")
    
    # Output
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    
    if args.output == 'sql':
        filename = f"nhs_gp_practices_{args.report}_{timestamp}.sql"
        content = generate_sql(records, batch_size=args.batch_size)
    elif args.output == 'json':
        filename = f"nhs_gp_practices_{args.report}_{timestamp}.json"
        content = json.dumps(records, indent=2)
    else:  # csv
        filename = f"nhs_gp_practices_{args.report}_{timestamp}.csv"
        # Convert back to CSV
        if records:
            import csv
            output = io.StringIO()
            writer = csv.DictWriter(output, fieldnames=records[0].keys())
            writer.writeheader()
            writer.writerows(records)
            content = output.getvalue()
        else:
            content = ""
    
    with open(filename, 'w') as f:
        f.write(content)
    
    print(f"[OK] Saved to: {filename}")
    print(f"\n{'='*70}\n")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())

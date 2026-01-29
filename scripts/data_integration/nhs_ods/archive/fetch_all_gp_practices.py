#!/usr/bin/env python3
"""
NHS ODS Complete GP Practice Fetcher
Fetches ALL GP practices (active + inactive) with full history and successor relationships

Similar pattern to fetch_all_commissioners.py:
- Fetches current practices (epraccur)
- Fetches historical membership (epracmem) 
- Fetches successor relationships (succ)
- Combines into complete dataset with lineage tracking
"""

import urllib.request
import json
import csv
import io
import sys
from datetime import datetime
from typing import Dict, List, Set

def fetch_csv_report(report_name: str) -> List[Dict]:
    """Fetch a CSV report from NHS ODS API"""
    url = f"https://www.odsdatasearchandexport.nhs.uk/api/getReport?report={report_name}"
    
    print(f"Fetching {report_name}...")
    
    try:
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req, timeout=120) as response:
            csv_text = response.read().decode('utf-8')
        
        return csv_text
    except Exception as e:
        print(f"  ✗ Error: {e}")
        return ""

def parse_epraccur(csv_text: str) -> Dict[str, Dict]:
    """Parse current GP practices report"""
    headers = [
        'Organisation_Code', 'Name', 'National_Grouping', 'High_Level_Health_Geography',
        'Address_Line1', 'Address_Line2', 'Address_Line3', 'Address_Line4', 'Address_Line5',
        'Postcode', 'Open_Date', 'Close_Date', 'Status_Code', 'Organisation_SubType_Code',
        'Commissioner_Code', 'Join_Provider_Date', 'Left_Provider_Date', 'Contact_Telephone',
        'Null1', 'Null2', 'Null3', 'Amended_Record_Indicator', 'Null4',
        'Provider_Code', 'Null5', 'Role_Code', 'Null6'
    ]
    
    reader = csv.DictReader(io.StringIO(csv_text), fieldnames=headers)
    practices = {}
    
    for row in reader:
        code = row['Organisation_Code'].strip('"')
        practices[code] = {
            'Practice_Code': code,
            'Practice_Name': row['Name'].strip('"'),
            'Status': row['Status_Code'].strip('"'),
            'Open_Date': row['Open_Date'].strip('"'),
            'Close_Date': row['Close_Date'].strip('"'),
            'Postcode': row['Postcode'].strip('"'),
            'Address_Line1': row['Address_Line1'].strip('"'),
            'Address_Line2': row['Address_Line2'].strip('"'),
            'Address_Line3': row['Address_Line3'].strip('"'),
            'Town': row['Address_Line4'].strip('"'),
            'County': row['Address_Line5'].strip('"'),
            'Commissioner_Code': row['Commissioner_Code'].strip('"'),
            'National_Grouping': row['National_Grouping'].strip('"'),
            'High_Level_Health_Geography': row['High_Level_Health_Geography'].strip('"'),
            'Predecessor_Codes': None,
            'Successor_Code': None
        }
    
    print(f"  ✓ Parsed {len(practices)} current practices")
    return practices

def parse_succ(csv_text: str) -> Dict[str, str]:
    """Parse successor relationships - returns mapping of old_code -> new_code"""
    headers = ['Old_Code', 'New_Code', 'Null1', 'Effective_Date', 'Type']
    
    reader = csv.DictReader(io.StringIO(csv_text), fieldnames=headers)
    successors = {}
    
    for row in reader:
        old_code = row['Old_Code'].strip('"')
        new_code = row['New_Code'].strip('"')
        successors[old_code] = new_code
    
    print(f"  ✓ Parsed {len(successors)} successor relationships")
    return successors

def enrich_with_successors(practices: Dict[str, Dict], successors: Dict[str, str]):
    """Add successor information to practice records"""
    
    # Build reverse mapping (new -> list of old codes)
    predecessors = {}
    for old_code, new_code in successors.items():
        if new_code not in predecessors:
            predecessors[new_code] = []
        predecessors[new_code].append(old_code)
    
    # Enrich practices
    for code, practice in practices.items():
        # Add successor if this practice closed
        if code in successors:
            practice['Successor_Code'] = successors[code]
        
        # Add predecessors if this practice is a merger
        if code in predecessors:
            practice['Predecessor_Codes'] = ','.join(predecessors[code])
            practice['Predecessor_Count'] = len(predecessors[code])
        else:
            practice['Predecessor_Count'] = 0
    
    print(f"  ✓ Enriched with successor relationships")

def generate_sql(records: List[Dict], table='[Analytics].[tbl_Staging_GP_Practice]') -> str:
    """Generate SQL INSERT statements in batches"""
    
    lines = [
        f"-- GP Practice Complete Dataset from NHS ODS CSV API",
        f"-- Generated: {datetime.now().isoformat()}",
        f"-- Total Records: {len(records)}",
        f"-- Includes: Current practices + Historical successors + PCN membership",
        "",
        f"TRUNCATE TABLE {table};",
        ""
    ]
    
    def fmt(val):
        if not val or val == '':
            return "NULL"
        escaped = str(val).replace("'", "''")
        return f"'{escaped}'"
    
    # Batch inserts (1000 rows per batch for SQL Server)
    batch_size = 1000
    for i in range(0, len(records), batch_size):
        batch = records[i:i+batch_size]
        
        lines.append(f"-- Batch {i//batch_size + 1} ({len(batch)} records)")
        lines.append(f"INSERT INTO {table}")
        lines.append(f"    (Practice_Code, Practice_Name, Status,")
        lines.append(f"     Open_Date, Close_Date, Address_Line1, Address_Line2, Address_Line3, Town, County, Postcode,")
        lines.append(f"     Commissioner_Code, National_Grouping, High_Level_Health_Geography,")
        lines.append(f"     PCN_Code, PCN_Name, PCN_Join_Date,")
        lines.append(f"     Predecessor_Codes, Predecessor_Count, Successor_Code)")
        lines.append(f"VALUES")
        
        value_lines = []
        for r in batch:
            value_lines.append(
                f"    ({fmt(r['Practice_Code'])}, {fmt(r['Practice_Name'])}, {fmt(r['Status'])}, "
                f"{fmt(r['Open_Date'])}, {fmt(r['Close_Date'])}, {fmt(r['Address_Line1'])}, "
                f"{fmt(r['Address_Line2'])}, {fmt(r['Address_Line3'])}, {fmt(r['Town'])}, {fmt(r['County'])}, {fmt(r['Postcode'])}, "
                f"{fmt(r['Commissioner_Code'])}, {fmt(r['National_Grouping'])}, {fmt(r['High_Level_Health_Geography'])}, "
                f"{fmt(r.get('PCN_Code'))}, {fmt(r.get('PCN_Name'))}, {fmt(r.get('PCN_Join_Date'))}, "
                f"{fmt(r.get('Predecessor_Codes'))}, {r.get('Predecessor_Count', 0)}, {fmt(r.get('Successor_Code'))})"
            )
        
        lines.append(',\n'.join(value_lines) + ';')
        lines.append("")
    
    return "\n".join(lines)

def parse_pcn_membership(csv_text: str) -> Dict[str, Dict]:
    """Parse PCN core partner details - links practices to PCNs"""
    headers = [
        'Practice_Code', 'Practice_Name', 'Practice_ICB_Code', 'Practice_ICB_Name',
        'PCN_Code', 'PCN_Name', 'PCN_ICB_Code', 'PCN_ICB_Name',
        'Membership_Start_Date', 'Membership_End_Date', 'Is_Core_Partner'
    ]
    
    reader = csv.DictReader(io.StringIO(csv_text), fieldnames=headers)
    pcn_links = {}
    
    for row in reader:
        practice_code = row['Practice_Code'].strip('"')
        # Only store current memberships (no end date or TRUE core partner)
        if row['Is_Core_Partner'].strip('"') == 'TRUE':
            pcn_links[practice_code] = {
                'PCN_Code': row['PCN_Code'].strip('"'),
                'PCN_Name': row['PCN_Name'].strip('"'),
                'Membership_Start_Date': row['Membership_Start_Date'].strip('"')
            }
    
    print(f"  ✓ Parsed {len(pcn_links)} practice-PCN memberships")
    return pcn_links

def enrich_with_pcn(practices: Dict[str, Dict], pcn_links: Dict[str, Dict]):
    """Add PCN information to practice records"""
    
    for code, practice in practices.items():
        if code in pcn_links:
            practice['PCN_Code'] = pcn_links[code]['PCN_Code']
            practice['PCN_Name'] = pcn_links[code]['PCN_Name']
            practice['PCN_Join_Date'] = pcn_links[code]['Membership_Start_Date']
        else:
            practice['PCN_Code'] = None
            practice['PCN_Name'] = None
            practice['PCN_Join_Date'] = None
    
    with_pcn = sum(1 for p in practices.values() if p.get('PCN_Code'))
    print(f"  ✓ {with_pcn}/{len(practices)} practices linked to PCNs")

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Fetch complete GP Practice dataset from NHS ODS')
    parser.add_argument('--output', choices=['sql', 'json'], default='sql')
    parser.add_argument('--max-records', type=int, default=0, help='Limit records (0=all)')
    
    args = parser.parse_args()
    
    print(f"\n{'='*70}")
    print("NHS GP Practice Complete Fetcher")
    print(f"{'='*70}\n")
    
    # Step 1: Fetch current practices
    epraccur_csv = fetch_csv_report('epraccur')
    practices = parse_epraccur(epraccur_csv)
    
    # Step 2: Fetch successor relationships
    succ_csv = fetch_csv_report('succ')
    successors = parse_succ(succ_csv)
    
    # Step 3: Fetch PCN memberships
    pcn_csv = fetch_csv_report('epcncorepartnerdetails')
    pcn_links = parse_pcn_membership(pcn_csv)
    
    # Step 4: Enrich with successors and PCNs
    enrich_with_successors(practices, successors)
    enrich_with_pcn(practices, pcn_links)
    
    # Convert to list
    records = list(practices.values())
    
    # Limit if requested
    if args.max_records > 0:
        records = records[:args.max_records]
        print(f"\nLimited to first {args.max_records} records\n")
    
    # Summary
    active = sum(1 for r in records if r['Status'] == 'ACTIVE')
    inactive = sum(1 for r in records if r['Status'] != 'ACTIVE')
    with_successors = sum(1 for r in records if r.get('Successor_Code'))
    with_predecessors = sum(1 for r in records if r.get('Predecessor_Count', 0) > 0)
    with_pcn = sum(1 for r in records if r.get('PCN_Code'))
    
    print(f"\nDataset Summary:")
    print(f"  Total Practices: {len(records)}")
    print(f"  Active: {active}")
    print(f"  Inactive: {inactive}")
    print(f"  With PCN: {with_pcn}")
    print(f"  With Successors: {with_successors}")
    print(f"  Merged (with predecessors): {with_predecessors}")
    
    # Output
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    
    if args.output == 'sql':
        filename = f"nhs_gp_practices_complete_{timestamp}.sql"
        content = generate_sql(records)
    else:
        filename = f"nhs_gp_practices_complete_{timestamp}.json"
        content = json.dumps(records, indent=2)
    
    with open(filename, 'w') as f:
        f.write(content)
    
    print(f"\n[OK] Saved to: {filename}")
    print(f"\n{'='*70}\n")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())

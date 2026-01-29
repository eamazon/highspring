#!/usr/bin/env python3
"""
NHS ODS GP Practice Fetcher (Rewritten)
Fetches GP Practice data from NHS ODS API with full hierarchy
"""

import urllib.request
import urllib.error
import json
import time
import sys
import os
from datetime import datetime
from typing import Dict, List, Optional

ODS_API_BASE = "https://directory.spineservices.nhs.uk/ORD/2-0-0"

def search_gp_practices(status: str = 'Active', limit: int = 1000, commissioner: str = '36L') -> List[str]:
    """
    Search for GP practices commissioned by a specific ICB/Sub-ICB
    Default: 36L (NHS South West London ICB)
    """
    all_codes = []
    offset = 0
    
    # RE4 = "Is Commissioned By"
    print(f"Searching for GP Practices commissioned by {commissioner} (status {status})...")
    
    while True:
        # Build URL for Relationship Search
        url = f"https://directory.spineservices.nhs.uk/ORD/2-0-0/organisations?RelTypeId=RE4&TargetOrgId={commissioner}&Limit={limit}"
        
        if status != 'All':
            url += f"&Status={status}"
        if offset > 0:
            url += f"&Offset={offset}"
            
        print(f"DEBUG: URL={url}")
        
        try:
            req = urllib.request.Request(url)
            req.add_header('Accept', 'application/json')
            
            with urllib.request.urlopen(req, timeout=10) as response:
                data = json.loads(response.read().decode())
            
            orgs = data.get('Organisations', [])
            if not orgs:
                break
            
            for org in orgs:
                org_code = org.get('OrgId')
                # For Relationship search, results are already filtered by the query
                all_codes.append(org_code)
            
            print(f"  Fetched {len(orgs)} records, offset {offset}")
            offset += limit
            
            # Safety break
            if offset > 5000:
                print("  [WARN] Hit safety limit of 5k records")
                break
                
        except urllib.error.HTTPError as e:
            print(f"  [ERROR] HTTP {e.code}: {e.reason}")
            break
        except Exception as e:
            print(f"  [ERROR] {e}")
            break
    
    print(f"Found {len(all_codes)} practices linked to {commissioner}")
    return all_codes

# ... inside main() ...

    # Add argument
    parser.add_argument('--commissioner', default='36L', help='ODS Code of Commissioner (e.g. 36L)')

    # Update call
    codes = search_gp_practices(args.status, commissioner=args.commissioner)

def fetch_practice_details(code: str) -> Optional[Dict]:
    """Fetch detailed information for a single GP practice"""
    url = f"{ODS_API_BASE}/organisations/{code}"
    
    try:
        req = urllib.request.Request(url)
        req.add_header('Accept', 'application/json')
        
        with urllib.request.urlopen(req, timeout=15) as response:
            data = json.loads(response.read().decode())
            return parse_practice(data.get('Organisation', {}))
            
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return None
        print(f"    [ERROR] HTTP {e.code} for {code}")
        return None
    except Exception as e:
        print(f"    [ERROR] {e} for {code}")
        return None

def parse_practice(org: Dict) -> Dict:
    """Parse ODS organization data into flat structure"""
    
    # Valid Roles Check: Must have RO76 (GP Practice)
    # RO177 (Prescribing Cost Centre) is too broad (includes Walk-ins, OOH, Prisons, etc)
    roles = org.get('Roles', {}).get('Role', [])
    has_ro76 = False
    for r in roles:
        if r.get('id') == 'RO76' and r.get('Status') == 'Active':
            has_ro76 = True
            break
            
    if not has_ro76:
        return None

    # Extract relationships
    rels = org.get('Rels', {}).get('Rel', [])
    pcn_code = None
    commissioner_code = None
    
    for r in rels:
        if r.get('Status') == 'Active':
            rel_id = r.get('id')
            target = r.get('Target', {}).get('OrgId', {}).get('extension')
            
            if rel_id == 'RE9':  # Member of PCN
                pcn_code = target
            elif rel_id == 'RE4':  # Commissioned by Sub-ICB
                commissioner_code = target
    
    # Extract successor (for closed practices)
    successors = org.get('Succs', {}).get('Succ', [])
    successor_code = None
    if successors:
        successor_code = successors[0].get('Target', {}).get('OrgId', {}).get('extension')
    
    # Extract location
    loc = org.get('GeoLoc', {}).get('Location', {})
    
    # Extract dates
    dates = org.get('Date', [])
    open_date = None
    close_date = None
    for d in dates:
        if d.get('Type') == 'Operational':
            open_date = d.get('Start')
            close_date = d.get('End')
    
    return {
        'Practice_Code': org.get('OrgId', {}).get('extension'),
        'Practice_Name': org.get('Name'),
        'Status': org.get('Status'),
        'PCN_Code': pcn_code,
        'Commissioner_Code': commissioner_code,
        'Successor_Code': successor_code,
        'Open_Date': open_date,
        'Close_Date': close_date,
        'Address_Line1': loc.get('AddrLn1'),
        'Town': loc.get('Town'),
        'Postcode': loc.get('PostCode'),
        'Last_Change_Date': org.get('LastChangeDate'),
        'Fetch_Date': datetime.now().isoformat()
    }

def generate_sql(records: List[Dict], table: str = '[Analytics].[tbl_Staging_GP_Practice]') -> str:
    """Generate SQL INSERT statements"""
    
    lines = [
        f"-- GP Practice Data from NHS ODS API",
        f"-- Generated: {datetime.now().isoformat()}",
        f"-- Total Records: {len(records)}",
        "",
        f"TRUNCATE TABLE {table};",
        ""
    ]
    
    for r in records:
        def fmt(val):
            if val is None:
                return "NULL"
            escaped = str(val).replace("'", "''")
            return f"'{escaped}'"
        
        sql = (
            f"INSERT INTO {table} "
            f"(Practice_Code, Practice_Name, Status, PCN_Code, Commissioner_Code, Successor_Code, "
            f"Open_Date, Close_Date, Address_Line1, Town, Postcode, Last_Change_Date) "
            f"VALUES ("
            f"{fmt(r['Practice_Code'])}, {fmt(r['Practice_Name'])}, {fmt(r['Status'])}, "
            f"{fmt(r['PCN_Code'])}, {fmt(r['Commissioner_Code'])}, {fmt(r['Successor_Code'])}, "
            f"{fmt(r['Open_Date'])}, {fmt(r['Close_Date'])}, {fmt(r['Address_Line1'])}, "
            f"{fmt(r['Town'])}, {fmt(r['Postcode'])}, {fmt(r['Last_Change_Date'])});"
        )
        lines.append(sql)
    
    return "\n".join(lines)

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Fetch GP Practice data from NHS ODS')
    parser.add_argument('--status', choices=['Active', 'Inactive', 'All'], default='Active')
    parser.add_argument('--max-records', type=int, default=0, help='Limit number of records (0=all)')
    parser.add_argument('--output', choices=['sql', 'json'], default='sql')
    parser.add_argument('--output-dir', type=str, default='.', help='Directory to save output files')
    parser.add_argument('--search-only', action='store_true', help='Just list codes, no details')
    parser.add_argument('--commissioner', default='36L', help='ODS Code of Commissioner (e.g. 36L)')
    
    args = parser.parse_args()
    
    print(f"\n{'='*70}")
    print("NHS GP Practice Fetcher")
    print(f"{'='*70}\n")
    
    print("NHS GP Practice Fetcher")
    print(f"{'='*70}\n")

    # Step 1: Search for practices
    codes = search_gp_practices(args.status, commissioner=args.commissioner)
    
    if not codes:
        print("No practices found!")
        return 1
    
    if args.max_records > 0:
        codes = codes[:args.max_records]
        print(f"Limiting to first {args.max_records} records")
    
    if args.search_only:
        print("\nPractice codes:")
        for code in codes:
            print(f"  {code}")
        return 0
    
    # Step 2: Fetch details
    print(f"\nFetching details for {len(codes)} practices...")
    records = []
    
    for i, code in enumerate(codes, 1):
        if i % 50 == 0 or i == 1:
            print(f"  [{i}/{len(codes)}] {code}...")
        
        details = fetch_practice_details(code)
        if details:
            records.append(details)
        
        # Rate limiting
        if i % 10 == 0:
            time.sleep(0.5)
    
    print(f"\nSuccessfully fetched {len(records)}/{len(codes)} practices")
    
    # Step 3: Output
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    
    if args.output == 'sql':
        filename = f"nhs_gp_practices_{args.status.lower()}_{timestamp}.sql"
        content = generate_sql(records)
    else:
        filename = f"nhs_gp_practices_{args.status.lower()}_{timestamp}.json"
        content = json.dumps(records, indent=2)
    
    filepath = os.path.join(args.output_dir, filename)
    with open(filepath, 'w') as f:
        f.write(content)
    
    print(f"\n[OK] Saved to: {filepath}")
    print(f"\n{'='*70}\n")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())

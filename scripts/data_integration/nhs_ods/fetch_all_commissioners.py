#!/usr/bin/env python3
"""
NHS ODS API - Complete ICB/Sub-ICB Fetcher
Fetches ALL Integrated Care Boards (ICBs) and Sub-ICB Locations from NHS ODS API

Adheres to Kimball Dimensional Modeling Principles:
- Extracts complete source system data
- Preserves grain (one row per organization)
- Tracks predecessors/successors for SCD support
- Includes full audit trail

Database Agnostic: Works with SQL Server and Snowflake

Usage:
    # Fetch all ICBs and Sub-ICB Locations
    python fetch_all_commissioners.py --output staging --db-type sqlserver
    
    # Fetch specific roles only
    python fetch_all_commissioners.py --roles RO98 RO207 --output both
    
    # Dry run (no staging output, just counts)
    python fetch_all_commissioners.py --dry-run
"""

import json
import urllib.request
import urllib.error
from datetime import datetime
from typing import Dict, List, Optional
import sys
import argparse
import time


# NHS ODS FHIR API Base URL
ODS_API_BASE = "https://directory.spineservices.nhs.uk/ORD/2-0-0"

# ODS Role Codes (NHS organization types)
ROLE_CODES = {
    'RO98': 'Sub-ICB Location / CCG',
    'RO207': 'Integrated Care Board (ICB)',
    'RO319': 'Sub ICB Location (non-primary role)',
    'RO326': 'ICB Commissioning Proxy'
}


def search_organizations_by_role(role_code: str, status: str = 'Active') -> List[str]:
    """
    Search for all organizations with a specific role code
    
    Args:
        role_code: ODS role code (e.g., 'RO98', 'RO207')
        status: 'Active' or 'Inactive' or None for all
    
    Returns:
        List of organization codes
    """
    # ODS API search endpoint
    url = f"{ODS_API_BASE}/organisations"
    # Default limit is 20. Increase to 1000 to ensure we get all records.
    params = [f"PrimaryRoleId={role_code}", "Limit=1000"]
    
    if status:
        params.append(f"Status={status}")
    
    if params:
        url += "?" + "&".join(params)
    
    try:
        req = urllib.request.Request(url)
        req.add_header('Accept', 'application/json')
        
        with urllib.request.urlopen(req, timeout=30) as response:
            data = json.loads(response.read().decode())
            
            # Extract organization codes from search results
            orgs = data.get('Organisations', [])
            codes = []
            
            for org in orgs:
                # API structure difference:
                # Search Endpoint: OrgId is a STRING (e.g. '00L')
                # Detail Endpoint: OrgId is a DICT (e.g. {'extension': '00L'})
                org_id = org.get('OrgId')
                
                code = None
                if isinstance(org_id, dict):
                    code = org_id.get('extension')
                elif isinstance(org_id, str):
                    code = org_id
                    
                if code:
                    codes.append(code)
            
            print(f"  Found {len(codes)} organizations with role {role_code} ({status})")
            return codes
            
    except Exception as e:
        print(f"  Error searching for role {role_code}: {e}")
        return []


def fetch_organization(org_code: str, retry_count: int = 3) -> Optional[Dict]:
    """
    Fetch a single organization from NHS ODS API with retry logic
    
    Args:
        org_code: NHS ODS organization code
        retry_count: Number of retries on failure
    
    Returns:
        Dictionary with organization data, or None if not found
    """
    url = f"{ODS_API_BASE}/organisations/{org_code}"
    
    for attempt in range(retry_count):
        try:
            req = urllib.request.Request(url)
            req.add_header('Accept', 'application/json')
            
            with urllib.request.urlopen(req, timeout=30) as response:
                data = json.loads(response.read().decode())
                return data
                
        except urllib.error.HTTPError as e:
            if e.code == 404:
                print(f"    [NOT FOUND] Not found: {org_code}")
                return None
            elif e.code == 429:  # Rate limit
                wait_time = (attempt + 1) * 2
                print(f"    [WARN] Rate limited, waiting {wait_time}s...")
                time.sleep(wait_time)
            else:
                print(f"    [ERROR] HTTP {e.code}: {org_code}")
                return None
        except Exception as e:
            if attempt < retry_count - 1:
                print(f"    [WARN] Retry {attempt+1}/{retry_count} for {org_code}: {e}")
                time.sleep(1)
            else:
                print(f"    [ERROR] Failed: {org_code} - {e}")
                return None
    
    return None


def parse_organization(data: Dict) -> Dict:
    """
    Parse ODS API response into flat structure for staging table
    Follows Kimball principles: preserve all source attributes
    
    Returns normalized dictionary ready for SQL INSERT
    """
    org = data.get('Organisation', {})
    
    # Extract roles
    roles = org.get('Roles', {}).get('Role', [])
    primary_role = next((r for r in roles if r.get('primaryRole')), {})
    additional_roles = [r.get('id') for r in roles if not r.get('primaryRole')]
    
    # Extract location
    location = org.get('GeoLoc', {}).get('Location', {})
    
    # Extract predecessors (organizations that merged)
    successors = org.get('Succs', {}).get('Succ', [])
    predecessors = []
    successor_code = None
    
    for succ in successors:
        target_code = succ.get('Target', {}).get('OrgId', {}).get('extension')
        if succ.get('Type') == 'Predecessor':
            predecessors.append(target_code)
        elif succ.get('Type') == 'Successor':
            successor_code = target_code
    
    # Extract parent ICB relationship (RE5 = "in the geography of")
    relationships = org.get('Rels', {}).get('Rel', [])
    parent_icb_code = None
    for rel in relationships:
        if rel.get('id') == 'RE5' and rel.get('Status') == 'Active':
            parent_icb_code = rel.get('Target', {}).get('OrgId', {}).get('extension')
            break
    
    # Parse dates
    dates = org.get('Date', [])
    operational_start = next((d.get('Start') for d in dates if d.get('Type') == 'Operational'), None)
    operational_end = next((d.get('End') for d in dates if d.get('Type') == 'Operational'), None)
    legal_start = next((d.get('Start') for d in dates if d.get('Type') == 'Legal'), None)
    legal_end = next((d.get('End') for d in dates if d.get('Type') == 'Legal'), None)
    
    # Determine commissioner type
    commissioner_type = 'Unknown'
    if 'RO207' in [r.get('id') for r in roles]:
        commissioner_type = 'ICB'
    elif 'RO319' in additional_roles:
        commissioner_type = 'Sub-ICB Location'
    elif primary_role.get('id') == 'RO98':
        if 'HUB' in org.get('Name', '').upper():
            commissioner_type = 'Commissioning Hub'
        elif len(predecessors) > 0:
            commissioner_type = 'Sub-ICB (former CCG)'
        else:
            commissioner_type = 'CCG (Legacy)'
    
    # Transition date (when RO319 role was added)
    transition_date = None
    ro319_role = next((r for r in roles if r.get('id') == 'RO319'), None)
    if ro319_role:
        ro319_dates = ro319_role.get('Date', [])
        transition_date = next((d.get('Start') for d in ro319_dates if d.get('Type') == 'Operational'), None)
    
    # ODS URI
    ods_uri = f"{ODS_API_BASE}/organisations/{org.get('OrgId', {}).get('extension')}"
    
    return {
        'Commissioner_Code': org.get('OrgId', {}).get('extension'),
        'Commissioner_Name': org.get('Name'),
        'Status': org.get('Status'),
        'Commissioner_Type': commissioner_type,
        'ODS_Role_Code': primary_role.get('id'),
        'Additional_Roles': ','.join(additional_roles) if additional_roles else None,
        'Operational_Start_Date': operational_start,
        'Operational_End_Date': operational_end,
        'Legal_Start_Date': legal_start,
        'Legal_End_Date': legal_end,
        'Transition_Date': transition_date,
        'Last_Change_Date': org.get('LastChangeDate'),
        'Address_Line1': location.get('AddrLn1'),
        'Address_Line2': location.get('AddrLn2'),
        'Address_Line3': location.get('AddrLn3'),
        'Town': location.get('Town'),
        'County': location.get('County'),
        'Postcode': location.get('PostCode'),
        'Country': location.get('Country'),
        'Predecessor_Codes': ','.join(predecessors) if predecessors else None,
        'Predecessor_Count': len(predecessors),
        'Successor_Code': successor_code,
        'Parent_ICB_Code': parent_icb_code,
        'Parent_ICB_Name': None,  # Will be enriched later
        'ODS_URI': ods_uri,
        'API_Fetch_Date': datetime.now().isoformat(),
        'API_Version': '2-0-0'
    }


def enrich_parent_icb_names(records: List[Dict]) -> List[Dict]:
    """
    Enrich records with parent ICB names by looking up codes
    """
    # Create lookup of code -> name
    code_to_name = {r['Commissioner_Code']: r['Commissioner_Name'] for r in records}
    
    # Populate parent names
    for record in records:
        if record['Parent_ICB_Code']:
            record['Parent_ICB_Name'] = code_to_name.get(record['Parent_ICB_Code'])
    
    return records


def generate_sql_insert(records: List[Dict], table_name: str = "tbl_Staging_NHS_ODS_Commissioner", db_type: str = "sqlserver") -> str:
    """
    Generate database-agnostic SQL INSERT similar to the original script
    """
    if not records:
        return ""
    
    # Reuse logic from fetch_commissioners.py
    # (Column generation, SQL dialect handling, etc.)
    columns = list(records[0].keys())
    
    if db_type.lower() == 'snowflake':
        schema_prefix = "ANALYTICS."
        date_format = "TO_DATE('{value}', 'YYYY-MM-DD')"
    else:  # SQL Server
        schema_prefix = "[Analytics]."
        date_format = "CAST('{value}' AS DATE)"
    
    sql = f"-- NHS ODS Complete Commissioner Dataset\n"
    sql += f"-- Generated: {datetime.now().isoformat()}\n"
    sql += f"-- Total Records: {len(records)}\n"
    sql += f"-- Database Type: {db_type}\n\n"
    
    sql += f"-- Truncate staging table before load\n"
    sql += f"TRUNCATE TABLE {schema_prefix}[{table_name}];\n\n"
    
    sql += f"INSERT INTO {schema_prefix}[{table_name}]\n"
    sql += f"  ({', '.join(['[' + c + ']' for c in columns])})\nVALUES\n"
    
    value_rows = []
    for record in records:
        values = []
        for col in columns:
            val = record[col]
            if val is None:
                values.append('NULL')
            elif col.endswith('_Date') and val:
                formatted_date = date_format.format(value=val[:10])
                values.append(formatted_date)
            elif isinstance(val, (int, float)):
                values.append(str(val))
            else:
                escaped = str(val).replace("'", "''")
                values.append(f"'{escaped}'")
        value_rows.append(f"  ({', '.join(values)})")
    
    sql += ',\n'.join(value_rows) + ";\n"
    
    return sql


def main():
    parser = argparse.ArgumentParser(description='Fetch complete NHS ODS ICB/Sub-ICB dataset')
    # Added RO261 (High Level Health Geography) to capture ICB Statutory Bodies (e.g., QWE)
    parser.add_argument('--roles', nargs='+', default=['RO98', 'RO207', 'RO261'],
                        help='ODS role codes to fetch (default: RO98 RO207 RO261)')
    parser.add_argument('--status', choices=['Active', 'Inactive', 'All'], default='All',
                        help='Organization status filter (default: All, to include legacy CCGs)')
    parser.add_argument('--output', choices=['json', 'staging', 'both', 'sql'], default='both',
                        help='Output format: json, staging (SQL), both, or sql')
    parser.add_argument('--db-type', choices=['sqlserver', 'snowflake'], default='sqlserver',
                        help='Target database type')
    parser.add_argument('--output-dir', default='.',
                        help='Directory to save output files (default: current directory)')
    parser.add_argument('--dry-run', action='store_true',
                        help='Fetch counts only, do not download data')
    
    args = parser.parse_args()
    
    print(f"\n{'='*80}")
    print(f"NHS ODS Complete Commissioner Fetcher")
    print(f"{'='*80}\n")
    
    # Step 1: Search for organizations by role
    all_org_codes = set()
    
    for role in args.roles:
        print(f"Searching for organizations with role {role} ({ROLE_CODES.get(role, 'Unknown')})...")
        
        if args.status == 'All':
            active_codes = search_organizations_by_role(role, 'Active')
            inactive_codes = search_organizations_by_role(role, 'Inactive')
            codes = set(active_codes + inactive_codes)
        else:
            codes = set(search_organizations_by_role(role, args.status))
        
        all_org_codes.update(codes)
        print()
    
    print(f"Total unique organizations to fetch: {len(all_org_codes)}\n")
    
    if args.dry_run:
        print("Dry run complete. Exiting.")
        return 0
    
    # Step 2: Fetch details for each organization
    print(f"Fetching detailed data for {len(all_org_codes)} organizations...")
    print("(This may take several minutes due to API rate limits)\n")
    
    organizations = []
    for i, code in enumerate(sorted(all_org_codes), 1):
        print(f"  [{i}/{len(all_org_codes)}] {code}...", end=' ')
        data = fetch_organization(code)
        if data:
            parsed = parse_organization(data)
            organizations.append(parsed)
            print("[OK]")
        
        # Rate limiting: wait between requests
        if i % 10 == 0:
            time.sleep(1)
    
    print(f"\n[OK] Successfully fetched {len(organizations)}/{len(all_org_codes)} organizations\n")
    
    # Step 3: Enrich with parent ICB names
    organizations = enrich_parent_icb_names(organizations)
    
    # Step 4: Output
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    
    import os
    
    if args.output in ['json', 'both']:
        filename = f"nhs_ods_complete_{timestamp}.json"
        json_file = os.path.join(args.output_dir, filename)
        with open(json_file, 'w') as f:
            json.dump(organizations, f, indent=2)
        print(f"[OK] JSON saved to: {json_file}")
    
    if args.output in ['staging', 'both', 'sql']:
        sql = generate_sql_insert(organizations, db_type=args.db_type)

        # Create archive directory
        archive_dir = os.path.join(args.output_dir, 'archive')
        os.makedirs(archive_dir, exist_ok=True)

        # Write timestamped archive copy
        archive_filename = f"nhs_ods_complete_{args.db_type}_{timestamp}.sql"
        archive_file = os.path.join(archive_dir, archive_filename)
        with open(archive_file, 'w') as f:
            f.write(sql)
        print(f"[OK] Archive saved to: {archive_file}")

        # Write fixed "latest" file for deploy script (always overwrites)
        latest_file = os.path.join(args.output_dir, 'staging_commissioner.sql')
        with open(latest_file, 'w') as f:
            f.write(sql)
        print(f"[OK] Latest saved to: {latest_file}")
    
    # Summary statistics
    print(f"\n{'='*80}")
    print("Summary:")
    print(f"  Total Records: {len(organizations)}")
    print(f"  Active: {sum(1 for o in organizations if o['Status'] == 'Active')}")
    print(f"  Inactive: {sum(1 for o in organizations if o['Status'] != 'Active')}")
    print(f"\n  By Type:")
    types = {}
    for org in organizations:
        t = org['Commissioner_Type']
        types[t] = types.get(t, 0) + 1
    for t, count in sorted(types.items()):
        print(f"    {t}: {count}")
    print(f"{'='*80}\n")
    
    return 0


if __name__ == "__main__":
    sys.exit(main())

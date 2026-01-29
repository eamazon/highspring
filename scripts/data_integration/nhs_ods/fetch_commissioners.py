#!/usr/bin/env python3
"""
NHS ODS API - Commissioner Fetcher
Fetches Sub-ICB Locations and ICB data from NHS Organisation Data Service (ODS) API

Database Agnostic: Works with SQL Server and Snowflake

Usage:
    python fetch_commissioners.py --output staging --db-type sqlserver
    python fetch_commissioners.py --org-code 36L --db-type snowflake
"""

import json
import urllib.request
import urllib.error
from datetime import datetime
from typing import Dict, List, Optional
import sys
import argparse

# NHS ODS FHIR API Base URL
ODS_API_BASE = "https://directory.spineservices.nhs.uk/ORD/2-0-0"


def fetch_organization(org_code: str) -> Optional[Dict]:
    """
    Fetch a single organization from NHS ODS API
    
    Args:
        org_code: NHS ODS organization code (e.g., '36L')
    
    Returns:
        Dictionary with organization data, or None if not found
    """
    url = f"{ODS_API_BASE}/organisations/{org_code}"
    
    try:
        req = urllib.request.Request(url)
        req.add_header('Accept', 'application/json')
        
        with urllib.request.urlopen(req, timeout=30) as response:
            data = json.loads(response.read().decode())
            print(f"[OK] Fetched: {org_code}")
            return data
            
    except urllib.error.HTTPError as e:
        if e.code == 404:
            print(f"[NOT FOUND] Not found: {org_code}")
        else:
            print(f"[ERROR] HTTP Error {e.code}: {org_code}")
        return None
    except Exception as e:
        print(f"[ERROR] Error fetching {org_code}: {e}")
        return None


def parse_organization(data: Dict) -> Dict:
    """
    Parse ODS API response into flat structure for database loading
    
    Returns normalized dictionary ready for SQL INSERT
    """
    org = data.get('Organisation', {})
    
    # Extract primary role (should be RO98 for Sub-ICB Locations)
    roles = org.get('Roles', {}).get('Role', [])
    primary_role = next((r for r in roles if r.get('primaryRole')), {})
    
    # Extract additional roles  
    additional_roles = [r.get('id') for r in roles if not r.get('primaryRole')]
    
    # Extract location
    location = org.get('GeoLoc', {}).get('Location', {})
    
    # Extract predecessor CCGs (if merged)
    successors = org.get('Succs', {}).get('Succ', [])
    predecessors = [
        s.get('Target', {}).get('OrgId', {}).get('extension')
        for s in successors
        if s.get('Type') == 'Predecessor'
    ]
    
    # Parse dates
    dates = org.get('Date', [])
    operational_start = next((d.get('Start') for d in dates if d.get('Type') == 'Operational'), None)
    legal_start = next((d.get('Start') for d in dates if d.get('Type') == 'Legal'), None)
    
    # Determine commissioner type
    commissioner_type = 'Unknown'
    if 'RO319' in additional_roles:
        commissioner_type = 'Sub-ICB Location'
    elif 'RO207' in [r.get('id') for r in roles]:
        commissioner_type = 'ICB'
    elif primary_role.get('id') == 'RO98':
        if len(predecessors) > 0:
            commissioner_type = 'Sub-ICB (former CCG)'
        else:
            commissioner_type = 'CCG (Legacy)'
    
    # Transition date (when RO319 role was added)
    transition_date = None
    ro319_role = next((r for r in roles if r.get('id') == 'RO319'), None)
    if ro319_role:
        ro319_dates = ro319_role.get('Date', [])
        transition_date = next((d.get('Start') for d in ro319_dates if d.get('Type') == 'Operational'), None)
    
    return {
        'Commissioner_Code': org.get('OrgId', {}).get('extension'),
        'Commissioner_Name': org.get('Name'),
        'Status': org.get('Status'),
        'Commissioner_Type': commissioner_type,
        'ODS_Role_Code': primary_role.get('id'),
        'Additional_Roles': ','.join(additional_roles) if additional_roles else None,
        'Operational_Start_Date': operational_start,
        'Legal_Start_Date': legal_start,
        'Transition_Date': transition_date,
        'Last_Change_Date': org.get('LastChangeDate'),
        'Address_Line1': location.get('AddrLn1'),
        'Town': location.get('Town'),
        'County': location.get('County'),
        'Postcode': location.get('PostCode'),
        'Country': location.get('Country'),
        'Predecessor_Codes': ','.join(predecessors) if predecessors else None,
        'Predecessor_Count': len(predecessors),
        'API_Fetch_Date': datetime.now().isoformat()
    }


def generate_sql_insert(records: List[Dict], table_name: str = "tbl_Staging_NHS_ODS_Commissioner", db_type: str = "sqlserver") -> str:
    """
    Generate database-agnostic SQL INSERT statements
    
    Args:
        records: List of parsed organization records
        table_name: Target staging table name
        db_type: 'sqlserver' or 'snowflake'
    
    Returns:
        SQL INSERT statements as string
    """
    if not records:
        return ""
    
    # Column names
    columns = list(records[0].keys())
    
    # SQL dialect differences
    if db_type.lower() == 'snowflake':
        schema_prefix = "ANALYTICS."
        date_format = "TO_DATE('{value}', 'YYYY-MM-DD')"
    else:  # SQL Server
        schema_prefix = "[Analytics]."
        date_format = "CAST('{value}' AS DATE)"
    
    sql = f"-- Generated NHS ODS Commissioner data\n"
    sql += f"-- Generated: {datetime.now().isoformat()}\n"
    sql += f"-- Records: {len(records)}\n\n"
    
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
                # Date columns
                formatted_date = date_format.format(value=val[:10])
                values.append(formatted_date)
            elif isinstance(val, (int, float)):
                values.append(str(val))
            else:
                # String - escape single quotes
                escaped = str(val).replace("'", "''")
                values.append(f"'{escaped}'")
        value_rows.append(f"  ({', '.join(values)})")
    
    sql += ',\n'.join(value_rows) + ";\n"
    
    return sql


def main():
    parser = argparse.ArgumentParser(description='Fetch NHS ODS Commissioner data')
    parser.add_argument('--org-code', help='Specific organization code to fetch (e.g., 36L)')
    parser.add_argument('--output', choices=['json', 'staging', 'both'], default='json',
                        help='Output format: json file, SQL staging insert, or both')
    parser.add_argument('--db-type', choices=['sqlserver', 'snowflake'], default='sqlserver',
                        help='Target database type for SQL generation')
    parser.add_argument('--file', help='Output file path (default: auto-generated)')
    
    args = parser.parse_args()
    
    # Fetch data
    if args.org_code:
        # Single organization
        org_codes = [args.org_code]
    else:
        # Default: Fetch SWL ICB and known Sub-ICB Locations
        org_codes = ['36L', '07V', '08J', '08P', '08R', '08T', '08X']
    
    print(f"\n{'='*80}")
    print(f"NHS ODS Commissioner Fetcher")
    print(f"{'='*80}\n")
    print(f"Fetching {len(org_codes)} organizations...")
    print()
    
    organizations = []
    for code in org_codes:
        data = fetch_organization(code)
        if data:
            parsed = parse_organization(data)
            organizations.append(parsed)
    
    print(f"\n[OK] Successfully fetched {len(organizations)}/{len(org_codes)} organizations\n")
    
    # Output
    if args.output in ['json', 'both']:
        json_file = args.file or f"nhs_ods_commissioners_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(json_file, 'w') as f:
            json.dump(organizations, f, indent=2)
        print(f"[OK] JSON saved to: {json_file}")
    
    if args.output in ['staging', 'both']:
        sql = generate_sql_insert(organizations, db_type=args.db_type)
        sql_file = args.file or f"nhs_ods_staging_insert_{args.db_type}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.sql"
        if args.output == 'staging':
            sql_file = sql_file
        else:
            sql_file = sql_file.replace('.json', f'_{args.db_type}.sql')
        
        with open(sql_file, 'w') as f:
            f.write(sql)
        print(f"[OK] SQL ({args.db_type}) saved to: {sql_file}")
    
    print(f"\n{'='*80}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())

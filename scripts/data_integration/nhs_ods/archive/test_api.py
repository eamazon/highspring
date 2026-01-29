#!/usr/bin/env python3
"""Quick test of NHS ODS API for GP Practices"""

import urllib.request
import json

url = "https://directory.spineservices.nhs.uk/ORD/2-0-0/organisations?PrimaryRoleId=RO177&Limit=5"

print("Testing NHS ODS API for GP Practices...")
print(f"URL: {url}\n")

try:
    req = urllib.request.Request(url)
    req.add_header('Accept', 'application/json')
    
    print("Sending request...")
    with urllib.request.urlopen(req, timeout=10) as response:
        data = json.loads(response.read().decode())
        
    orgs = data.get('Organisations', [])
    print(f"✓ Success! Received {len(orgs)} organizations\n")
    
    for org in orgs[:3]:
        print(f"  - {org['OrgId']}: {org['Name']} ({org['Status']})")
        
except Exception as e:
    print(f"✗ Error: {e}")

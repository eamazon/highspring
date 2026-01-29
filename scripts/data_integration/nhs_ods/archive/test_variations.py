#!/usr/bin/env python3
"""Test different approaches to NHS ODS API"""

import urllib.request
import json

url = "https://directory.spineservices.nhs.uk/ORD/2-0-0/organisations?PrimaryRoleId=RO177&Limit=3"

print("Test 1: Exact curl replication")
try:
    req = urllib.request.Request(url)
    req.add_header('Accept', 'application/json')
    with urllib.request.urlopen(req, timeout=10) as response:
        data = json.loads(response.read().decode())
    print(f"  ✓ Success: {len(data.get('Organisations', []))} orgs")
except Exception as e:
    print(f"  ✗ Failed: {e}")

print("\nTest 2: With custom User-Agent")
try:
    req = urllib.request.Request(url)
    req.add_header('Accept', 'application/json')
    req.add_header('User-Agent', 'Python-urllib/3')
    with urllib.request.urlopen(req, timeout=10) as response:
        data = json.loads(response.read().decode())
    print(f"  ✓ Success: {len(data.get('Organisations', []))} orgs")
except Exception as e:
    print(f"  ✗ Failed: {e}")

print("\nTest 3: Using urlencode")
import urllib.parse
params = urllib.parse.urlencode({'PrimaryRoleId': 'RO177', 'Limit': '3'})
url_encoded = f"https://directory.spineservices.nhs.uk/ORD/2-0-0/organisations?{params}"
print(f"  URL: {url_encoded}")
try:
    req = urllib.request.Request(url_encoded)
    req.add_header('Accept', 'application/json')
    with urllib.request.urlopen(req, timeout=10) as response:
        data = json.loads(response.read().decode())
    print(f"  ✓ Success: {len(data.get('Organisations', []))} orgs")
except Exception as e:
    print(f"  ✗ Failed: {e}")

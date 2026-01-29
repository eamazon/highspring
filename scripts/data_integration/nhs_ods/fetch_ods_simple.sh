#!/bin/bash
################################################################################
# NHS ODS Data Fetcher - Simple Curl Version
# Fetches Commissioner, GP Practice, and PCN data using curl
################################################################################

set -e  # Exit on error

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_DIR="sql/analytics_platform/04_etl"

echo "========================================"
echo "NHS ODS Data Fetcher (Curl)"
echo "========================================"
echo ""

# 1. Fetch Commissioners
echo "Fetching Commissioners..."
curl -s "https://directory.spineservices.nhs.uk/ORD/2-0-0/organisations?PrimaryRoleId=RO98&Limit=1000" \
  -H "Accept: application/json" \
  > /tmp/commissioners_raw.json

echo "  ✓ Downloaded commissioner data"

# 2. Fetch GP Practices (epraccur report)
echo "Fetching GP Practices..."
curl -s "https://www.odsdatasearchandexport.nhs.uk/api/getReport?report=epraccur" \
  > "${OUTPUT_DIR}/gp_practices_raw_${TIMESTAMP}.csv"

PRACTICE_COUNT=$(wc -l < "${OUTPUT_DIR}/gp_practices_raw_${TIMESTAMP}.csv")
echo "  ✓ Downloaded ${PRACTICE_COUNT} GP practices"

# 3. Fetch PCNs
echo "Fetching PCNs..."
curl -s "https://www.odsdatasearchandexport.nhs.uk/api/getReport?report=epcn" \
  > "${OUTPUT_DIR}/pcn_raw_${TIMESTAMP}.csv"

PCN_COUNT=$(wc -l < "${OUTPUT_DIR}/pcn_raw_${TIMESTAMP}.csv")
echo "  ✓ Downloaded ${PCN_COUNT} PCNs"

echo ""
echo "========================================"
echo "Raw CSV files saved:"
echo "  - ${OUTPUT_DIR}/gp_practices_raw_${TIMESTAMP}.csv"
echo "  - ${OUTPUT_DIR}/pcn_raw_${TIMESTAMP}.csv"
echo ""
echo "Inspect these files to verify data quality before loading."
echo "========================================"

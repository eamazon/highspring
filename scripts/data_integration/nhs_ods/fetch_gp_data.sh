#!/bin/bash
# fetch_gp_data.sh - Download GP Practice PCN relationships from NHS Digital ODS
# Source: https://digital.nhs.uk/services/organisation-data-service/data-search-and-export/csv-downloads/gp-and-gp-practice-related-data

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/../../../sql/analytics_platform/05_api"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo ">>> Downloading GP Practice PCN Core Partner Details from NHS Digital ODS"

# Download CSV directly (API returns CSV, not zip)
TEMP_CSV="/tmp/gp_pcn_raw.csv"
curl -s "https://www.odsdatasearchandexport.nhs.uk/api/getReport?report=epcncorepartnerdetails" -o "$TEMP_CSV"

ROW_COUNT_RAW=$(wc -l < "$TEMP_CSV")
echo ">>> Downloaded: $ROW_COUNT_RAW rows"

# Add proper column headers (from NHS Digital documentation)
HEADER="Partner Organisation Code,Partner Name,Practice Parent Sub ICB Location Code,Practice Parent Sub ICB Location Name,PCN Code,PCN Name,PCN Parent Sub ICB Location Code,PCN Parent Sub ICB Location Name,Practice to PCN Relationship Start Date,Practice to PCN Relationship End Date,Practice Sub ICB and PCN Sub ICB Match?"

OUTPUT_CSV="$OUTPUT_DIR/gp_pcn_relationships_${TIMESTAMP}.csv"

# Create output with headers
echo "$HEADER" > "$OUTPUT_CSV"
cat "$TEMP_CSV" >> "$OUTPUT_CSV"

ROW_COUNT=$(wc -l < "$OUTPUT_CSV")
echo ">>> Saved to: $OUTPUT_CSV"
echo ">>> Row count: $((ROW_COUNT - 1)) records (excluding header)"

# Cleanup
rm -f "$TEMP_CSV"

echo ">>> Done"

#!/bin/bash
#===============================================================================
# REFRESH STAGING DATA
#===============================================================================
# Runs all Python fetchers to generate fresh staging SQL files.
# Run this BEFORE executing 00_Dev_Full_Rebuild.sql in SQLCMD mode.
#
# Usage:
#   ./scripts/refresh_staging_data.sh
#   ./scripts/refresh_staging_data.sh --skip-imd   # Skip IMD (needs manual URL)
#===============================================================================

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$REPO_ROOT/sql/05_api"

# Colours for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "==============================================================================="
echo "STAGING DATA REFRESH"
echo "==============================================================================="
echo "Repository: $REPO_ROOT"
echo "Output:     $OUTPUT_DIR"
echo ""

# Parse arguments
SKIP_IMD=false
for arg in "$@"; do
    case $arg in
        --skip-imd)
            SKIP_IMD=true
            shift
            ;;
    esac
done

# Activate virtual environment if it exists
if [ -d "$REPO_ROOT/.venv" ]; then
    echo "[INFO] Activating virtual environment..."
    source "$REPO_ROOT/.venv/bin/activate"
fi

cd "$REPO_ROOT"

#-------------------------------------------------------------------------------
# 1. Fetch Commissioner Data
#-------------------------------------------------------------------------------
echo ""
echo -e "${YELLOW}[1/3] Fetching Commissioner data from NHS ODS API...${NC}"
python scripts/data_integration/nhs_ods/fetch_all_commissioners.py \
    --output sql \
    --output-dir "$OUTPUT_DIR"

if [ -f "$OUTPUT_DIR/staging_commissioner.sql" ]; then
    echo -e "${GREEN}[OK] staging_commissioner.sql created${NC}"
else
    echo -e "${RED}[FAIL] staging_commissioner.sql not found${NC}"
    exit 1
fi

#-------------------------------------------------------------------------------
# 2. Fetch GP Practice Data
#-------------------------------------------------------------------------------
echo ""
echo -e "${YELLOW}[2/3] Fetching GP Practice data from NHS ODS CSV...${NC}"
python scripts/data_integration/nhs_ods/fetch_gp_practices_csv.py

if [ -f "$OUTPUT_DIR/staging_gp_practice.sql" ]; then
    echo -e "${GREEN}[OK] staging_gp_practice.sql created${NC}"
else
    echo -e "${RED}[FAIL] staging_gp_practice.sql not found${NC}"
    exit 1
fi

#-------------------------------------------------------------------------------
# 3. Fetch LSOA/IMD Data (optional - requires URL)
#-------------------------------------------------------------------------------
echo ""
if [ "$SKIP_IMD" = true ]; then
    echo -e "${YELLOW}[3/3] Skipping IMD data (--skip-imd flag set)${NC}"
    if [ -f "$OUTPUT_DIR/staging_lsoa_imd.sql" ]; then
        echo -e "${GREEN}[OK] Using existing staging_lsoa_imd.sql${NC}"
    else
        echo -e "${YELLOW}[WARN] staging_lsoa_imd.sql not found - dimension load may fail${NC}"
    fi
else
    echo -e "${YELLOW}[3/3] Fetching LSOA/IMD data...${NC}"

    # IMD 2019 data URL (English IoD from GOV.UK)
    IMD_URL="https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/845345/File_7_-_All_IoD2019_Scores__Ranks__Deciles_and_Population_Denominators_3.csv"

    # Check if we have the Excel file locally or need to fetch
    if [ -f "$REPO_ROOT/data/imd2019/File_7_ID2019_Scores_Ranks_Deciles.xlsx" ]; then
        echo "[INFO] Using local IMD Excel file..."
        IMD_URL="file://$REPO_ROOT/data/imd2019/File_7_ID2019_Scores_Ranks_Deciles.xlsx"
    fi

    # Try to fetch - if it fails, use existing file
    python scripts/data_integration/imd2019/fetch_imd2019_idaci_idaopi.py \
        --url "https://assets.publishing.service.gov.uk/media/5d8b364a40f0b609909e5fb3/File_7_-_All_IoD2019_Scores__Ranks__Deciles_and_Population_Denominators_3.xlsx" \
        --out-dir "$OUTPUT_DIR" || {
            echo -e "${YELLOW}[WARN] IMD fetch failed - checking for existing file...${NC}"
            if [ -f "$OUTPUT_DIR/staging_lsoa_imd.sql" ]; then
                echo -e "${GREEN}[OK] Using existing staging_lsoa_imd.sql${NC}"
            else
                echo -e "${RED}[FAIL] No staging_lsoa_imd.sql available${NC}"
                exit 1
            fi
        }

    if [ -f "$OUTPUT_DIR/staging_lsoa_imd.sql" ]; then
        echo -e "${GREEN}[OK] staging_lsoa_imd.sql available${NC}"
    fi
fi

#-------------------------------------------------------------------------------
# Summary
#-------------------------------------------------------------------------------
echo ""
echo "==============================================================================="
echo -e "${GREEN}STAGING DATA REFRESH COMPLETE${NC}"
echo "==============================================================================="
echo ""
echo "Files generated:"
ls -la "$OUTPUT_DIR"/staging_*.sql 2>/dev/null || echo "  (none found)"
echo ""
echo "Next step:"
echo "  Open H:\\sql\\00_Dev_Full_Rebuild.sql in SSMS/ADS"
echo "  Enable SQLCMD mode and execute (F5)"
echo ""
echo "==============================================================================="

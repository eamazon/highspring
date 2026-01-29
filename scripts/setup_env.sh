#!/bin/bash
# Setup Environment Configuration
# Creates .env file from .env.example with SWL SQL Server credentials

echo "========================================="
echo "SWL ICB HighSpring - .env Setup"
echo "========================================="
echo ""

# Check if .env already exists
if [ -f .env ]; then
    echo "⚠ .env file already exists!"
    read -p "Overwrite? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted. Keeping existing .env file."
        exit 0
    fi
fi

# Create .env from template
echo "Creating .env file..."
cat > .env << 'EOF'
# Environment Configuration for SWL ICB HighSpring
# ACTUAL CREDENTIALS - DO NOT COMMIT TO GIT!

# ==============================================================================
# SQL Server Configuration
# ==============================================================================

SQL_SERVER=PSFADHSSTP02.ad.elc.nhs.uk\SWL
SQL_DATABASE=Data_Lab_SWL_Live
SQL_SCHEMA=Analytics

# Connection settings
SQL_INTEGRATED_SECURITY=True
SQL_TRUST_CERTIFICATE=True
SQL_ENCRYPT=False
SQL_TIMEOUT=0
SQL_APP_NAME=SWL_Analytics_Platform

# ==============================================================================
# Snowflake Configuration (for future migration)
# ==============================================================================

SNOWFLAKE_ACCOUNT=
SNOWFLAKE_USER=
SNOWFLAKE_PASSWORD=
SNOWFLAKE_DATABASE=SWL_ANALYTICS
SNOWFLAKE_SCHEMA=ANALYTICS
SNOWFLAKE_WAREHOUSE=COMPUTE_WH
SNOWFLAKE_ROLE=ANALYTICS_ROLE

# ==============================================================================
# NHS ODS API Configuration
# ==============================================================================

ODS_API_BASE_URL=https://directory.spineservices.nhs.uk/ORD/2-0-0
ODS_CACHE_ENABLED=true
ODS_CACHE_TTL_HOURS=24

# ==============================================================================
# Environment Settings
# ==============================================================================

ENVIRONMENT=dev
LOG_LEVEL=INFO
EOF

# Set secure permissions
chmod 600 .env

echo "✓ .env file created successfully"
echo ""
echo "Configuration:"
echo "  SQL Server: PSFADHSSTP02.ad.elc.nhs.uk\SWL"
echo "  Database: Data_Lab_SWL_Live"
echo "  Authentication: Windows Integrated"
echo ""
echo "Next Steps:"
echo "  1. Test connection: python3 scripts/utilities/db_connection.py"
echo "  2. Run NHS ODS fetch: python3 scripts/data_integration/nhs_ods/fetch_all_commissioners.py"
echo ""
echo "Security:"
echo "  ✓ .env file is protected (chmod 600)"
echo "  ✓ .gitignore prevents Git commits"
echo ""

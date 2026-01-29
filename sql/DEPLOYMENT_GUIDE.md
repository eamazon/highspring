# SQL Deployment Guide

This guide explains how to deploy the HighSpring Analytics Platform to your SQL Server.

## Prerequisites

### Required
- SQL Server 2016+ or Azure SQL Database
- Database created and accessible
- Permissions: CREATE SCHEMA, CREATE TABLE, CREATE PROCEDURE
- Access to source data views (see CLAUDE.md for schema details)

### Tools
Choose ONE of these tools:

1. **SQL Server Management Studio (SSMS)** - Windows only
2. **Azure Data Studio (ADS)** - Cross-platform
3. **sqlcmd CLI** - Command line tool
4. **VS Code with mssql extension** - Cross-platform

## Configuration

### 1. Set up environment variables

Copy and configure `.env`:
```bash
cp .env.example .env
nano .env  # Edit with your values
```

### 2. Update deployment script paths

The deployment scripts use SQLCMD mode with `:r` (include) statements. You need to update paths based on your environment:

**Windows (SSMS/ADS):**
- Map your repo to a drive letter (e.g., H:\) OR
- Use absolute paths like `C:\Users\YourName\dev\icb\highspring\sql\`

**Linux/WSL (Azure Data Studio):**
- Use absolute paths like `/home/username/dev/icb/highspring/sql/`

## Deployment Methods

### Method 1: Full Deployment (Recommended for First Time)

Deploys everything: schema, dimensions, facts, ETL, validation.

**Using SSMS/ADS with SQLCMD Mode:**

1. Open `sql/00_Run_Everything_SQLCMD.sql`
2. **Update all paths** at the top of the file (see Path Configuration section below)
3. Enable SQLCMD Mode:
   - SSMS: Query > SQLCMD Mode
   - ADS: Not supported - use sqlcmd CLI instead
4. Execute (F5)

**Using sqlcmd CLI:**

```bash
# From repository root
cd ~/dev/icb/highspring

# Edit the script to update paths first!
# Then run:
sqlcmd -S "$SQL_SERVER\\$SQL_INSTANCE" -d $SQL_DATABASE -i sql/00_Run_Everything_SQLCMD.sql
```

### Method 2: Dimensions Only

For quick dimension deployment without facts:

```bash
# Open and edit paths first
sqlcmd -S "$SQL_SERVER\\$SQL_INSTANCE" -d $SQL_DATABASE -i sql/00_Deploy_Dimensions_Windows.sql
```

### Method 3: Dev Full Rebuild

For development environments - runs deploy + precompute + fact loads + enrichment:

**Prerequisites:**
- All dimension and fact objects already created
- Source data available

**Steps:**
1. Open `sql/00_Dev_Full_Rebuild.sql`
2. Update paths at line 51 (see below)
3. Configure parameters:
   ```sql
   :setvar FinYearStart 2025
   :setvar FromDate "2025-04-01"
   :setvar ToDate "2025-12-31"
   ```
4. Enable SQLCMD Mode
5. Execute

### Method 4: Manual Step-by-Step

For fine-grained control:

```bash
# 1. Setup
for file in sql/00_setup/*.sql; do
  sqlcmd -S "$SQL_SERVER\\$SQL_INSTANCE" -d $SQL_DATABASE -i "$file"
done

# 2. Dimensions
for file in sql/01_dimensions/*.sql; do
  sqlcmd -S "$SQL_SERVER\\$SQL_INSTANCE" -d $SQL_DATABASE -i "$file"
done

# 3. Facts
for file in sql/02_facts/*.sql; do
  sqlcmd -S "$SQL_SERVER\\$SQL_INSTANCE" -d $SQL_DATABASE -i "$file"
done

# 4. ETL
for file in sql/04_etl/*.sql; do
  sqlcmd -S "$SQL_SERVER\\$SQL_INSTANCE" -d $SQL_DATABASE -i "$file"
done

# 5. Validation
sqlcmd -S "$SQL_SERVER\\$SQL_INSTANCE" -d $SQL_DATABASE -i sql/06_validation/01_sp_Validate_Fact_Data.sql
```

## Path Configuration

The deployment scripts contain `:r` statements that need path updates.

### Find and Replace Paths

**In these files:**
- `sql/00_Run_Everything_SQLCMD.sql`
- `sql/00_Deploy_Dimensions_Windows.sql`
- `sql/00_Dev_Full_Rebuild.sql`

**Replace:**
```
H:\sql\analytics_platform\
```

**With your actual path:**

**Windows Example:**
```
C:\Users\speddi\dev\icb\highspring\sql\
```

**WSL/Linux Example:**
```
/home/speddi/dev/icb/highspring/sql/
```

### Quick Find/Replace Commands

**Windows PowerShell:**
```powershell
$files = @(
    "sql\00_Run_Everything_SQLCMD.sql",
    "sql\00_Deploy_Dimensions_Windows.sql",
    "sql\00_Dev_Full_Rebuild.sql"
)

$oldPath = "H:\sql\analytics_platform\"
$newPath = "C:\Users\speddi\dev\icb\highspring\sql\"

foreach ($file in $files) {
    (Get-Content $file) -replace [regex]::Escape($oldPath), $newPath | Set-Content $file
}
```

**Linux/WSL Bash:**
```bash
cd ~/dev/icb/highspring

files=(
    "sql/00_Run_Everything_SQLCMD.sql"
    "sql/00_Deploy_Dimensions_Windows.sql"
    "sql/00_Dev_Full_Rebuild.sql"
)

old_path='H:\\sql\\analytics_platform\\'
new_path='/home/speddi/dev/icb/highspring/sql/'

for file in "${files[@]}"; do
    sed -i "s|$old_path|$new_path|g" "$file"
done
```

## Deployment Order

If deploying manually, follow this order:

1. **00_setup/** - Schema, logging, staging tables
2. **01_dimensions/** - Dimension tables and views
3. **02_facts/** - Fact tables
4. **04_etl/** - ETL stored procedures
5. **06_validation/** - Validation framework

## Loading Data

After deployment, load facts:

```sql
-- Inpatient
EXEC [Analytics].[sp_Load_Fact_IP_Activity]
    @FromDate = '2025-04-01',
    @ToDate = '2025-12-31';

-- Outpatient
EXEC [Analytics].[sp_Load_Fact_OP_Activity]
    @FromDate = '2025-04-01',
    @ToDate = '2025-12-31';

-- A&E
EXEC [Analytics].[sp_Load_Fact_AE_Activity]
    @FromDate = '2025-04-01',
    @ToDate = '2025-12-31';
```

## Validation

Run validation after loading data:

```sql
EXEC [Analytics].[sp_Validate_Fact_Data]
    @FromDate = '2025-04-01',
    @ToDate = '2025-12-31',
    @MaterialityThreshold = 100;
```

See: `docs/testing/FACT_VALIDATION_USER_GUIDE.md`

## Troubleshooting

### Issue: "Could not find stored procedure"
- **Cause**: Dependencies not deployed in order
- **Fix**: Run setup scripts first, then dimensions, then facts

### Issue: ":r command not recognized"
- **Cause**: SQLCMD Mode not enabled
- **Fix**: Enable SQLCMD Mode in your SQL tool

### Issue: "Cannot open file 'H:\sql\...'"
- **Cause**: Paths not updated in deployment scripts
- **Fix**: Update all `:r` paths as described above

### Issue: "Invalid object name"
- **Cause**: Source views not available
- **Fix**: Verify source database objects exist (see CLAUDE.md)

### Issue: "CREATE PROCEDURE must be the first statement"
- **Cause**: Batch separator issue
- **Fix**: Ensure files have proper GO statements

## Cleanup

If you need to start over:

```sql
-- WARNING: This drops all Analytics objects!
DROP SCHEMA [Analytics];
```

Then run deployment again.

## CI/CD Integration

For automated deployment:

```bash
#!/bin/bash
# deploy.sh

set -e  # Exit on error

source .env

echo "Deploying to $SQL_SERVER\\$SQL_INSTANCE - $SQL_DATABASE"

# Update paths in scripts
sed -i "s|H:\\\\sql\\\\analytics_platform\\\\|$(pwd)/sql/|g" sql/00_Run_Everything_SQLCMD.sql

# Deploy
sqlcmd -S "$SQL_SERVER\\$SQL_INSTANCE" -d $SQL_DATABASE -i sql/00_Run_Everything_SQLCMD.sql

echo "Deployment complete"
```

## Next Steps

After deployment:

1. Load dimension data: `EXEC sp_Load_Dim_*` procedures
2. Load fact data: `EXEC sp_Load_Fact_*_Activity` procedures
3. Run validation: `EXEC sp_Validate_Fact_Data`
4. Connect Power BI: See `powerbi/PBIX_BUILD_GUIDE.md`

## Support

For issues:
- Check `docs/TECHNICAL_SPECIFICATION.md` for object details
- Review `docs/SCHEMA_OVERVIEW.md` for design patterns
- See `CLAUDE.md` for complete project context

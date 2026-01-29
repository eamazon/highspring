# Data Integration Scripts

Python scripts for fetching and loading NHS reference data.

## Overview

These scripts fetch data from external APIs and generate SQL insert statements for loading into staging tables.

**Total Scripts**: 20+ Python files organized by data source

## Quick Start

### 1. Set up environment

```bash
# Install dependencies
pip install -r ../requirements.txt

# Configure database connection (optional)
cp .env.template .env
nano .env
```

### 2. Run data fetchers

```bash
# NHS ODS data (see nhs_ods/README.md)
cd nhs_ods/
python fetch_all_commissioners.py
python fetch_gp_practices_csv.py
python fetch_pcn.py

# Bank holidays
cd ..
python fetch_bank_holidays.py
python generate_bank_holidays_sql.py

# IMD 2019 deprivation data
cd imd2019/
python fetch_imd2019_idaci_idaopi.py
```

## Data Sources

### NHS ODS (Organisation Data Service)

**Scripts**: `nhs_ods/` directory (17 Python files)

Fetches organisational reference data:
- Commissioners (ICBs, Sub-ICBs)
- GP Practices
- Primary Care Networks (PCN)
- Organisational relationships

**Documentation**: `nhs_ods/README.md`

**Key Scripts**:
- `fetch_all_commissioners.py` - All ICBs and Sub-ICBs
- `fetch_gp_practices_csv.py` - GP practices for SWL
- `fetch_pcn.py` - PCN hierarchies
- `run_ods_integration.py` - Complete workflow

**Output**: SQL files in `../../sql/04_etl/`

**Usage**:
```bash
cd nhs_ods/
python fetch_all_commissioners.py --output sql --db-type sqlserver
```

### Bank Holidays

**Scripts**:
- `fetch_bank_holidays.py` - Fetches UK bank holidays from gov.uk API
- `generate_bank_holidays_sql.py` - Generates SQL INSERT statements

**Data Source**: https://www.gov.uk/bank-holidays.json

**Target Table**: `[Analytics].[tbl_Bank_Holidays]` or `[Dictionary].[dbo].[DateBankHoliday]`

**Usage**:
```bash
# Fetch latest bank holidays
python fetch_bank_holidays.py

# Generate SQL statements
python generate_bank_holidays_sql.py > ../../sql/00_setup/bank_holidays_data.sql
```

**Output**: JSON file with bank holiday dates (2020-2030)

**What it fetches**:
- England and Wales bank holidays
- Scotland bank holidays
- Northern Ireland bank holidays
- Includes dates, titles, and notes

**Schema**:
```sql
CREATE TABLE [Analytics].[tbl_Bank_Holidays] (
    Date DATE PRIMARY KEY,
    Title NVARCHAR(100),
    Region NVARCHAR(50),
    Notes NVARCHAR(500)
);
```

### IMD 2019 (Index of Multiple Deprivation)

**Scripts**: `imd2019/` directory

Fetches deprivation indices for LSOAs:
- IDACI (Income Deprivation Affecting Children Index)
- IDAOPI (Income Deprivation Affecting Older People Index)

**Data Source**: UK Government MHCLG open data

**Target Tables**:
- `[Analytics].[tbl_Staging_LSOA_IMD2019]`
- Used to enrich `Dim_LSOA` dimension

**Usage**:
```bash
cd imd2019/
python fetch_imd2019_idaci_idaopi.py
```

**Output**: CSV files with LSOA codes and deprivation scores

## Script Features

### Common Capabilities

All scripts include:
- ✅ Error handling and retry logic
- ✅ Rate limiting for API calls
- ✅ Progress indicators
- ✅ Database-agnostic SQL generation
- ✅ Logging and audit trails
- ✅ Command-line arguments

### Output Formats

Scripts can generate:
- **SQL Server T-SQL** - INSERT statements
- **Snowflake SQL** - Compatible syntax
- **CSV files** - Raw data export
- **JSON files** - API responses

## Integration with Analytics Platform

### Data Flow

```
External APIs
    ↓
Python Fetcher Scripts
    ↓
Generated SQL Files (sql/04_etl/)
    ↓
Staging Tables ([Analytics].[tbl_Staging_*])
    ↓
ETL Procedures (sp_Load_Dim_*)
    ↓
Dimension Tables ([Analytics].[Dim_*])
```

### Staging Tables

Generated SQL populates these staging tables:
- `[Analytics].[tbl_Staging_NHS_ODS_Commissioner]`
- `[Analytics].[tbl_Staging_NHS_ODS_GPPractice]`
- `[Analytics].[tbl_Staging_NHS_ODS_PCN]`
- `[Analytics].[tbl_Staging_LSOA_IMD2019]`
- `[Analytics].[tbl_Bank_Holidays]` or `[Dictionary].[DateBankHoliday]`

### ETL Procedures

After loading staging data, run ETL:
```sql
EXEC [Analytics].[sp_Load_Dim_Commissioner];
EXEC [Analytics].[sp_Load_Dim_GPPractice];
EXEC [Analytics].[sp_Load_Dim_PCN];
```

## Scheduling

### Refresh Frequency

| Data Source | Recommended Refresh |
|-------------|---------------------|
| NHS ODS Commissioners | Monthly |
| NHS ODS GP Practices | Monthly |
| NHS ODS PCN | Monthly |
| Bank Holidays | Annually (December) |
| IMD 2019 | One-time load (historical) |

### Automation Script

Use `../../scripts/refresh_staging_data.sh` for automated refresh:

```bash
#!/bin/bash
# Refresh all staging data
./scripts/refresh_staging_data.sh
```

This runs:
1. NHS ODS fetchers
2. IMD data (if needed)
3. Bank holidays (if year changed)

## Configuration

### Environment Variables

Create `.env` file:
```bash
SQL_SERVER=your-server
SQL_INSTANCE=your-instance
SQL_DATABASE=your-database
```

### Command Line Options

Most scripts support:
```bash
--output sql|csv|json    # Output format
--db-type sqlserver|snowflake  # SQL dialect
--region swl|all        # Geographic scope
--help                  # Show all options
```

## Troubleshooting

### Common Issues

**Issue**: "API rate limit exceeded"
- **Fix**: Scripts include automatic retry with exponential backoff
- **Wait**: 60 seconds between retries

**Issue**: "SSL certificate verify failed"
- **Fix**: Check internet connectivity
- **Or**: Add `--no-verify-ssl` flag (not recommended)

**Issue**: "No module named 'requests'"
- **Fix**: `pip install -r ../requirements.txt`

**Issue**: "Permission denied writing to sql/ directory"
- **Fix**: Run from repository root with write permissions

### Validation

After running scripts, verify:
```bash
# Check generated SQL files exist
ls -lh ../../sql/04_etl/nhs_*.sql

# Check file sizes are reasonable
# Commissioners: ~50KB
# GP Practices: ~5MB
# PCN: ~500KB
```

## Development

### Adding New Data Sources

1. Create new directory: `data_integration/your_source/`
2. Add fetcher script: `fetch_your_data.py`
3. Generate SQL: Follow existing patterns
4. Document in README
5. Add to `refresh_staging_data.sh`

### Testing

```bash
# Test individual fetcher
python fetch_bank_holidays.py --test

# Dry run (no file writes)
python fetch_all_commissioners.py --dry-run
```

## References

- **NHS ODS API**: https://digital.nhs.uk/services/organisation-data-service
- **UK Bank Holidays**: https://www.gov.uk/bank-holidays
- **IMD 2019**: https://www.gov.uk/government/statistics/english-indices-of-deprivation-2019
- **Main Documentation**: `../../docs/NHS_ODS_INTEGRATION.md`
- **Operational Guide**: `../../docs/00_RUNBOOK.md`

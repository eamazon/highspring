# Configuration Guide

This repository requires database connection configuration before use.

## Environment Variables Setup

### 1. Create `.env` file

Copy the example file and fill in your actual values:

```bash
cp .env.example .env
```

### 2. Edit `.env` with your credentials

```bash
# Linux/Mac
nano .env

# Windows
notepad .env
```

### 3. Example `.env` configuration

```env
SQL_SERVER=your-server.domain.com
SQL_INSTANCE=YOUR_INSTANCE
SQL_DATABASE=YOUR_DATABASE
SQL_SCHEMA=Analytics

SOURCE_DATABASE=YOUR_SOURCE_DB
```

**IMPORTANT**: Never commit `.env` to git! It's already in `.gitignore`.

## SQL Deployment Scripts

When deploying SQL scripts, replace placeholders with your environment variables:

```bash
# Using environment variables (if your shell supports it)
sqlcmd -S "$SQL_SERVER\\$SQL_INSTANCE" -d $SQL_DATABASE -i sql/00_setup/01_Create_Analytics_Schema.sql

# Or use actual values
sqlcmd -S "your-server\instance" -d your_database -i sql/00_setup/01_Create_Analytics_Schema.sql
```

## Power BI TMDL Configuration

The Power BI TMDL files contain connection strings that need to be updated:

### Option 1: Update in Power BI Desktop

1. Open the TMDL model in Power BI Desktop
2. Go to **Transform Data** > **Data source settings**
3. Update the server and database names
4. Save the model

### Option 2: Find and Replace in TMDL files

Before opening in Power BI Desktop, replace connection strings:

```bash
# Find all occurrences
grep -r "PSFADHSSTP02" powerbi/tmdl/

# Replace with your server (example using sed)
find powerbi/tmdl/ -name "*.tmdl" -exec sed -i 's/PSFADHSSTP02\.ad\.elc\.nhs\.uk\\SWL/YOUR_SERVER\\INSTANCE/g' {} +
find powerbi/tmdl/ -name "*.tmdl" -exec sed -i 's/Data_Lab_SWL_Live/YOUR_DATABASE/g' {} +
```

## Configuration Files Location

| File | Purpose | Committed? |
|------|---------|------------|
| `.env.example` | Template with placeholder values | ✅ Yes |
| `.env` | Your actual credentials | ❌ No (gitignored) |
| `CONFIG.md` | This file - setup instructions | ✅ Yes |

## Security Best Practices

1. ✅ Never commit `.env` files
2. ✅ Never hardcode credentials in SQL scripts
3. ✅ Use Windows Authentication where possible
4. ✅ Rotate credentials if accidentally exposed
5. ✅ Keep repository private if it contains any sensitive config

## Verifying Setup

Test your configuration:

```bash
# Test SQL connection
sqlcmd -S "$SQL_SERVER\\$SQL_INSTANCE" -d $SQL_DATABASE -Q "SELECT @@VERSION"

# Should return SQL Server version info
```

## Troubleshooting

**Issue**: SQL scripts fail with "cannot connect"
- Verify server name and instance in `.env`
- Check network connectivity
- Verify SQL Server authentication method

**Issue**: Power BI can't connect
- Update data source settings in Power BI Desktop
- Ensure you have permissions to the database
- Check if DirectQuery or Import mode is configured

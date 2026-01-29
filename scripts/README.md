# Scripts Directory

Utility scripts for deployment, data refresh, and task management.

## Setup Scripts

### setup_env.sh
Sets up Python virtual environment and installs dependencies.

**Usage:**
```bash
./scripts/setup_env.sh
```

This will:
- Create a Python virtual environment
- Install packages from requirements.txt
- Configure environment for data integration scripts

### requirements.txt
Python package dependencies for data integration and utility scripts.

## Deployment Scripts

### refresh_staging_data.sh
Refreshes NHS reference data (ODS, GP Practices, PCN) in staging tables.

**Usage:**
```bash
# Run from repository root
./scripts/refresh_staging_data.sh

# Skip IMD data refresh (use existing)
./scripts/refresh_staging_data.sh --skip-imd
```

**Prerequisites:**
- Python environment set up (run setup_env.sh first)
- Database connection configured in .env
- Internet connection for NHS ODS API

**What it does:**
1. Fetches latest NHS Organisation Data Service (ODS) data
2. Fetches GP Practice data
3. Fetches Primary Care Network (PCN) data
4. Optionally refreshes IMD 2019 deprivation data
5. Loads data into staging tables

**Referenced by:**
- `sql/00_Dev_Full_Rebuild.sql` (Step 1 prerequisite)

## Task Management

### task_coordinator.py
Cross-session task coordination tool for managing Claude Code tasks.

**Usage:**
```bash
# List all tasks across all sessions
python scripts/task_coordinator.py list

# Check if a specific task is ready
python scripts/task_coordinator.py check <task-id>

# Watch for changes (implementation needed)
python scripts/task_coordinator.py watch
```

**Features:**
- Aggregates tasks from all Claude Code sessions
- Checks cross-session dependencies
- Displays task status and blockers
- Useful for multi-session workflows

See: `docs/CLAUDE_WORKFLOW.md` for task management best practices

## Environment Variables

These scripts read configuration from `.env`:

```bash
SQL_SERVER=your-server
SQL_INSTANCE=your-instance
SQL_DATABASE=your-database
```

Copy `.env.example` to `.env` and configure before running scripts.

## Dependencies

Python packages required (see requirements.txt):
- pyodbc or pymssql (SQL Server connectivity)
- requests (API calls)
- python-dotenv (environment variables)
- Additional packages as needed

Install with:
```bash
pip install -r scripts/requirements.txt
```

## Security Notes

- Never commit `.env` files with credentials
- Scripts read from environment variables, not hardcoded values
- Use Windows Authentication or SQL Auth based on your environment
- Ensure proper firewall rules for NHS ODS API access

## Troubleshooting

**Issue: "command not found"**
- Make scripts executable: `chmod +x scripts/*.sh`

**Issue: "pyodbc not found"**
- Run setup_env.sh to install dependencies
- Or: `pip install -r scripts/requirements.txt`

**Issue: "Cannot connect to database"**
- Verify .env configuration
- Test connection: `scripts/verify_dictionary_access.py`

**Issue: "NHS ODS API timeout"**
- Check internet connectivity
- NHS ODS API may be slow, increase timeout if needed

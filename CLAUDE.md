# SWL ICB Healthcare Analytics Platform

## Project Overview

This is a healthcare analytics data warehouse for South West London Integrated Care Board (SWL ICB). It implements a star schema for NHS activity data (Inpatient, Outpatient, A&E) with Power BI semantic model support.

## Database Connection

**IMPORTANT: Configure these values in your local environment - DO NOT commit actual credentials to the repository.**

```
Server: <YOUR_SQL_SERVER>\<INSTANCE>
Database: <YOUR_DATABASE>
Schema: [Analytics]
```

Source data schema (configure based on your environment):
- `[<SOURCE_DB>].[Unified].[tbl_IP_EncounterDenormalised_Active]` (Inpatient)
- `[<SOURCE_DB>].[Unified].[tbl_OP_EncounterDenormalised_Active]` (Outpatient)
- `[Dictionary]` database for NHS Data Dictionary reference tables

## Project Structure

```
swl-analytics-platform/
├── sql/                             # Core SQL deployment scripts
│   ├── 00_setup/                    # Schema creation, prerequisites
│   ├── 01_dimensions/               # 26 dimension table DDL
│   ├── 02_facts/                    # 3 fact tables (IP, OP, AE)
│   ├── 04_etl/                      # ETL stored procedures
│   └── 06_validation/               # Data validation SP
├── powerbi/
│   ├── tmdl/                        # Native TMDL folder (for PBI Desktop)
│   │   ├── model.tmdl
│   │   ├── relationships.tmdl
│   │   └── tables/*.tmdl
│   └── PBIX_BUILD_GUIDE.md          # How to build the PBIX
├── docs/
│   ├── FACT_VALIDATION_USER_GUIDE.md
│   └── SCHEMA_OVERVIEW.md
├── CLAUDE.md                        # Project context (this file)
└── README.md                        # Quick start guide
```

## Key SQL Objects

### Dimension Tables (26)
Naming: `[Analytics].[tbl_Dim_*]` with views `[Analytics].[vw_Dim_*]`

| Dimension | Business Key | Notes |
|-----------|--------------|-------|
| Dim_Date | DateKey (YYYYMMDD) | Calendar + Financial Year |
| Dim_Commissioner | Commissioner_Code | ICB/CCG codes |
| Dim_Provider | Provider_Code | NHS Trust codes |
| Dim_GPPractice | GPPractice_Code | GP Practice codes |
| Dim_PCN | PCN_Code | Primary Care Networks |
| Dim_Specialty | BK_SpecialtyCode | Treatment Function codes |
| Dim_Patient | Patient_ID | Pseudonymised patient |

### Fact Tables (3)
Naming: `[Analytics].[tbl_Fact_*_Activity]`

| Fact | Date Column | Key Relationships |
|------|-------------|-------------------|
| Fact_IP_Activity | Discharge_Date | 22 dimension FKs |
| Fact_OP_Activity | Appointment_Date | 23 dimension FKs |
| Fact_AE_Activity | Attendance_Date | Similar structure |

### Key Stored Procedures

```sql
-- ETL Loaders
EXEC [Analytics].[sp_Load_Fact_IP_Activity] @FromDate, @ToDate;
EXEC [Analytics].[sp_Load_Fact_OP_Activity] @FromDate, @ToDate;

-- Validation (run after ETL)
EXEC [Analytics].[sp_Validate_Fact_Data]
    @FromDate = '2025-04-01',
    @ToDate = '2025-12-31',
    @MaterialityThreshold = 100;
```

## Power BI TMDL Model

Located in `docs/powerbi/tmdl/` - this is the native TMDL folder structure for Power BI Desktop's TMDL View feature.

### Key Files
- `docs/powerbi/tmdl/model.tmdl` - Model definition
- `docs/powerbi/tmdl/relationships.tmdl` - All table relationships
- `docs/powerbi/tmdl/tables/*.tmdl` - Individual table definitions

### Measures
- `KeyMeasures` table contains all DAX measures for Excel users
- Organized in display folders: `Inpatient\Activity`, `Outpatient\Cost`, `A&E\Performance`, etc.

### Role-Playing Dimensions
- Dim_Date used for multiple date relationships (Discharge, Admission, Referral)
- Only ONE active relationship per fact table (Discharge for IP, Appointment for OP)
- Use `USERELATIONSHIP()` in DAX to activate inactive relationships

## Data Patterns

### Commissioner Code Truncation
Source codes ending in `00` are truncated to 3 characters:
```sql
CASE WHEN RIGHT(Organisation_Code_Code_of_Commissioner, 2) = '00'
     THEN LEFT(Organisation_Code_Code_of_Commissioner, 3)
     ELSE Organisation_Code_Code_of_Commissioner END
```

### Unknown Member Handling
- SK = -1 is the Unknown member in each dimension
- Facts get SK = -1 when source code doesn't match dimension

### Financial Year Ordering
Dates are ordered April-March using `sortByColumn` on Financial Month (1-12 starting April).

## Validation

The validation SP (`sp_Validate_Fact_Data`) performs 7 checks:
1. Row Count - Total records match
2. Monthly Distribution - Month-by-month comparison
3. Dimension Distribution - Health scores per dimension
4. Referential Integrity - No orphan records
5. Unknown Rates - % pointing to Unknown members
6. Missing Members - Codes not in dimensions
7. Dictionary Validation - Cross-reference NHS Dictionary

See: `docs/testing/FACT_VALIDATION_USER_GUIDE.md`

## Recent Work (Jan 2026)

1. **Power BI TMDL Model** - Complete semantic model with 26 dimensions, 3 facts, 75+ measures
2. **Enhanced Validation** - Replaced TOP 5 limit with materiality-based health scores
3. **Role-Playing Relationships** - IP (Discharge active), OP (Appointment active)
4. **Financial Year Ordering** - sortByColumn for FY display

## Quick Commands

```bash
# Deploy all dimensions
sqlcmd -S "PSFADHSSTP02.ad.elc.nhs.uk\SWL" -d Data_Lab_SWL_Live -i sql/analytics_platform/00_Deploy_Dimensions_Windows.sql

# Full rebuild (dev only)
sqlcmd -S "PSFADHSSTP02.ad.elc.nhs.uk\SWL" -d Data_Lab_SWL_Live -i sql/analytics_platform/00_Dev_Full_Rebuild.sql
```

## Claude Code Task Management & Session Persistence

**IMPORTANT: Tasks persist across sessions automatically!**

### How Task Persistence Works

1. **Session Storage** - Each Claude Code session has a unique ID (UUID)
2. **Automatic Persistence** - Tasks created with `TaskCreate`/`TaskUpdate` are automatically saved to:
   ```
   ~/.claude/todos/<session-id>-agent-<session-id>.json
   ```
3. **Multi-Agent Support** - Tasks can be:
   - Assigned to specific agents via `owner` field
   - Delegated to sub-agents launched with the Task tool
   - Tracked with dependencies (`blocks`, `blockedBy`)
   - Progressed through states: `pending` → `in_progress` → `completed`

### Resuming Sessions with Tasks

```bash
# Resume a specific session (preserves all tasks)
claude --resume <session-id>

# Interactive session picker
claude --resume

# Start new session with specific ID
claude --session-id <uuid>

# Fork a session (new ID, preserves history)
claude --resume <session-id> --fork-session
```

### Task Management Commands

```bash
# View all tasks in current session
/tasks

# Tasks are managed via Claude Code tools:
# - TaskCreate: Create new tasks
# - TaskUpdate: Update status, assign owner, set dependencies
# - TaskList: View all tasks
# - TaskGet: Get full task details
```

### Best Practices

- **Always use TaskCreate** for complex multi-step work (3+ steps)
- **Mark tasks in_progress** BEFORE starting work
- **Mark tasks completed** when fully done (not when blocked/errored)
- **Create dependency chains** when tasks must execute in order
- **Resume sessions** to continue work with full task context

### Session Persistence Settings

- **Enabled by default** - Sessions and tasks are automatically saved
- **Disable if needed**: `claude --no-session-persistence` (only works with `--print`)
- **Session history**: Stored in `~/.claude/history.jsonl`

## Deployment Notes

This is a clean analytics platform repository extracted from the original sustabular project. All essential components are included:

### Included Components
- ✅ `sql/00_setup/` - Schema setup scripts
- ✅ `sql/01_dimensions/` - All 26 dimension DDL files
- ✅ `sql/02_facts/` - All 3 fact table DDL files
- ✅ `sql/04_etl/` - ETL stored procedures
- ✅ `sql/06_validation/` - Data validation framework
- ✅ `powerbi/tmdl/` - Complete Power BI TMDL semantic model
- ✅ `docs/FACT_VALIDATION_USER_GUIDE.md` - Validation documentation
- ✅ `powerbi/PBIX_BUILD_GUIDE.md` - Power BI setup guide

### Not Included
- Bridge tables (03_bridges) - not currently in use
- API procedures (05_api) - not yet implemented
- NHS ODS data integration scripts - source data only

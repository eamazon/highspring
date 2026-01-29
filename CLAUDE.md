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
highspring/
├── sql/                             # Core SQL deployment scripts
│   ├── 00_setup/                    # Schema creation, prerequisites
│   ├── 01_dimensions/               # 28 dimension DDL (5 tables + 23 views)
│   ├── 02_facts/                    # 3 fact tables (IP, OP, AE)
│   ├── 03_bridges/                  # Bridge tables (ERF, OpPlan, CF Segment)
│   ├── 04_etl/                      # ETL stored procedures
│   ├── 05_api/                      # Staging data SQL (generated)
│   ├── 06_validation/               # Data validation SP
│   ├── cam/                         # CAM-specific objects
│   ├── 00_Dev_Full_Rebuild.sql      # Full rebuild script (SQLCMD)
│   └── 00_Run_Everything_SQLCMD.sql # Deploy only script
├── powerbi/
│   ├── tmdl/                        # Native TMDL folder (for PBI Desktop)
│   │   ├── model.tmdl
│   │   ├── relationships.tmdl
│   │   └── tables/*.tmdl
│   └── PBIX_BUILD_GUIDE.md          # How to build the PBIX
├── scripts/
│   └── refresh_staging_data.sh      # Staging data fetcher orchestrator
├── docs/
│   ├── PROJECT_OVERVIEW.md          # **Key reference doc** (start here)
│   ├── 00_RUNBOOK.md                # Operational execution handbook
│   ├── FACT_VALIDATION_USER_GUIDE.md
│   ├── SCHEMA_OVERVIEW.md
│   └── TECHNICAL_SPECIFICATION.md
├── CLAUDE.md                        # Project context (this file)
└── README.md                        # Quick start guide
```

📖 **Start with [docs/PROJECT_OVERVIEW.md](docs/PROJECT_OVERVIEW.md)** for comprehensive project documentation.

## Key SQL Objects

### Dimension Tables (28)
Naming: `[Analytics].[tbl_Dim_*]` (5 tables) with views `[Analytics].[vw_Dim_*]` (23 views)

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

Located in `powerbi/tmdl/` - this is the native TMDL folder structure for Power BI Desktop's TMDL View feature.

### Key Files
- `powerbi/tmdl/model.tmdl` - Model definition
- `powerbi/tmdl/relationships.tmdl` - All table relationships
- `powerbi/tmdl/tables/*.tmdl` - Individual table definitions

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

See: `docs/FACT_VALIDATION_USER_GUIDE.md`

## Quick Start

```bash
# Step 1: WSL terminal — refresh staging data
./scripts/refresh_staging_data.sh

# Step 2: Windows SSMS/ADS — run full rebuild
# Open sql/00_Dev_Full_Rebuild.sql in SQLCMD Mode → Execute (F5)
```

See [docs/00_RUNBOOK.md](docs/00_RUNBOOK.md) for detailed execution instructions.

## Component Summary

| Component | Location | Status |
|-----------|----------|--------|
| Setup scripts | `sql/00_setup/` | ✅ Complete |
| Dimensions | `sql/01_dimensions/` | ✅ 28 dimensions (5 tables + 23 views) |
| Facts | `sql/02_facts/` | ✅ 3 fact tables |
| Bridges | `sql/03_bridges/` | ✅ ERF, OpPlan MeasureSet, CF Segment |
| ETL procedures | `sql/04_etl/` | ✅ Complete |
| Staging data | `sql/05_api/` | ✅ Generated by Python fetchers |
| Validation | `sql/06_validation/` | ✅ Complete |
| CAM objects | `sql/cam/` | ✅ CAM-specific tables and procedures |
| Power BI model | `powerbi/tmdl/` | ✅ 31 tables, 40+ relationships |
| Data fetchers | `scripts/data_integration/` | ✅ NHS ODS, GP Practice, IMD |

**Status:** Phase 1 Complete — Ready for data load execution

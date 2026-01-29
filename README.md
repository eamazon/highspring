# SWL ICB Analytics Platform

Healthcare analytics data warehouse for South West London Integrated Care Board (SWL ICB).

## Overview

This platform implements a star schema for NHS activity data across:
- **Inpatient (IP)** encounters
- **Outpatient (OP)** appointments
- **A&E** attendances

The platform includes:
- 26 dimension tables with SCD Type 2 tracking
- 3 fact tables with comprehensive activity metrics
- ETL stored procedures for data loading
- Data validation framework
- Power BI semantic model (TMDL format)

## Configuration

**⚠️ IMPORTANT: This repository requires database configuration before use.**

1. Copy `.env.example` to `.env`
2. Fill in your actual database credentials
3. Never commit `.env` to git (already in `.gitignore`)

See **[CONFIG.md](CONFIG.md)** for detailed setup instructions.

```
Server: <YOUR_SQL_SERVER>\<INSTANCE>
Database: <YOUR_DATABASE>
Schema: [Analytics]
```

## Quick Start

### 1. Deploy Database Objects

```bash
# Set up schema and prerequisites
sqlcmd -S "<YOUR_SQL_SERVER>\<INSTANCE>" -d <YOUR_DATABASE> -i sql/00_setup/01_Create_Schema.sql

# Deploy all dimensions
for file in sql/01_dimensions/*.sql; do
  sqlcmd -S "<YOUR_SQL_SERVER>\<INSTANCE>" -d <YOUR_DATABASE> -i "$file"
done

# Deploy fact tables
for file in sql/02_facts/*.sql; do
  sqlcmd -S "<YOUR_SQL_SERVER>\<INSTANCE>" -d <YOUR_DATABASE> -i "$file"
done

# Deploy ETL procedures
for file in sql/04_etl/*.sql; do
  sqlcmd -S "<YOUR_SQL_SERVER>\<INSTANCE>" -d <YOUR_DATABASE> -i "$file"
done

# Deploy validation
sqlcmd -S "<YOUR_SQL_SERVER>\<INSTANCE>" -d <YOUR_DATABASE> -i sql/06_validation/sp_Validate_Fact_Data.sql
```

### 2. Load Data

```sql
-- Load Inpatient data for FY 2025/26
EXEC [Analytics].[sp_Load_Fact_IP_Activity]
    @FromDate = '2025-04-01',
    @ToDate = '2026-03-31';

-- Load Outpatient data
EXEC [Analytics].[sp_Load_Fact_OP_Activity]
    @FromDate = '2025-04-01',
    @ToDate = '2026-03-31';
```

### 3. Validate Data

```sql
-- Run validation checks
EXEC [Analytics].[sp_Validate_Fact_Data]
    @FromDate = '2025-04-01',
    @ToDate = '2026-03-31',
    @MaterialityThreshold = 100;
```

See: `docs/FACT_VALIDATION_USER_GUIDE.md`

### 4. Build Power BI Model

Open Power BI Desktop with TMDL view enabled and load the model:

```
File > Open > TMDL View > Select: powerbi/tmdl/
```

See: `powerbi/PBIX_BUILD_GUIDE.md`

## Project Structure

```
highspring/
├── sql/                            # Analytics Platform SQL
│   ├── 00_*.sql                    # 4 deployment orchestration scripts
│   ├── DEPLOYMENT_GUIDE.md         # Comprehensive deployment guide
│   ├── 00_setup/                   # 19 setup scripts
│   ├── 01_dimensions/              # 36 dimension DDL files
│   ├── 02_facts/                   # 6 fact table files
│   ├── 04_etl/                     # 33 ETL procedures
│   └── 06_validation/              # 1 validation procedure
│
├── reference_sql/                  # Source schema reference (150 files)
│   ├── README.md                   # Reference SQL documentation
│   ├── cam/                        # 6 files - Capacity & Access Management
│   ├── dictionary/                 # 109 files - NHS Data Dictionary
│   ├── erf/                        # 8 files - Elective Recovery Fund
│   ├── op_plan/                    # 6 files - Operating Plan targets
│   └── unified_sus/                # 21 files - Unified SUS source views
│
├── scripts/                        # Python utilities and pipelines
│   ├── README.md                   # Scripts documentation
│   ├── data_integration/           # NHS ODS API integration
│   │   ├── nhs_ods/               # 17 Python scripts + README
│   │   ├── imd2019/               # IMD deprivation data
│   │   ├── fetch_bank_holidays.py
│   │   └── .env.template
│   ├── pipeline/                   # Pipeline orchestration
│   ├── task_coordinator.py         # Cross-session task management
│   ├── refresh_staging_data.sh     # Refresh NHS reference data
│   ├── setup_env.sh                # Environment setup
│   └── requirements.txt            # Python dependencies
│
├── powerbi/
│   ├── tmdl/                       # Power BI TMDL semantic model
│   │   ├── model.tmdl
│   │   ├── relationships.tmdl
│   │   └── tables/                # 31 table definitions
│   └── PBIX_BUILD_GUIDE.md
│
├── docs/                           # Documentation (18 files)
│   ├── 00_RUNBOOK.md              # Operational runbook
│   ├── CLAUDE_WORKFLOW.md         # Session/task management
│   ├── NHS_ODS_INTEGRATION.md     # NHS ODS integration guide
│   ├── TECHNICAL_SPECIFICATION.md # Complete technical spec (72KB)
│   ├── DESIGN_DECISIONS.md        # Architectural decisions
│   ├── SCHEMA_OVERVIEW.md         # Schema design patterns
│   ├── ods_dimensions_operational_guide.md
│   ├── highspring_phase1_project_plan.md
│   ├── Connect_WSL_Map_Networkdrive.md
│   └── testing/                   # Testing documentation
│
├── .env.example                    # Configuration template
├── .gitignore                      # Git excludes (.env already ignored)
├── CONFIG.md                       # Configuration guide
├── CLAUDE.md                       # Project context for Claude Code
└── README.md                       # This file
```

**Total Files**: ~295 files (147 core + 150 reference SQL)

## Key Components

### Dimensions (26 tables)

| Dimension | Business Key | Description |
|-----------|--------------|-------------|
| Dim_Date | DateKey | Calendar + Financial Year |
| Dim_Commissioner | Commissioner_Code | ICB/CCG codes |
| Dim_Provider | Provider_Code | NHS Trust codes |
| Dim_GPPractice | GPPractice_Code | GP Practice codes |
| Dim_PCN | PCN_Code | Primary Care Networks |
| Dim_Specialty | BK_SpecialtyCode | Treatment Function codes |
| Dim_Patient | Patient_ID | Pseudonymised patient |
| ... | ... | 19 more dimensions |

All dimensions follow standard pattern:
- Surrogate Key (SK) as primary key
- Business Key (BK) for source system reference
- SCD Type 2 tracking (ValidFrom, ValidTo, IsCurrent)
- Unknown member at SK = -1

### Facts (3 tables)

| Fact | Grain | Key Date | Dimensions |
|------|-------|----------|------------|
| Fact_IP_Activity | Per inpatient spell | Discharge_Date | 22 FKs |
| Fact_OP_Activity | Per outpatient appointment | Appointment_Date | 23 FKs |
| Fact_AE_Activity | Per A&E attendance | Attendance_Date | Similar to IP |

### ETL Procedures

- `sp_Load_Fact_IP_Activity` - Load inpatient data
- `sp_Load_Fact_OP_Activity` - Load outpatient data
- `sp_Load_Fact_AE_Activity` - Load A&E data

### Validation Framework

`sp_Validate_Fact_Data` performs 7 validation checks:
1. Row count reconciliation
2. Monthly distribution comparison
3. Dimension health scores
4. Referential integrity
5. Unknown member rates
6. Missing dimension members
7. NHS Dictionary validation

## Power BI Model

Complete semantic model with:
- 26 dimension tables
- 3 fact tables
- 75+ DAX measures organized in display folders
- Role-playing date dimensions
- Financial year hierarchies (April-March)

Model format: **TMDL** (native Power BI Desktop format)

## Documentation

### Core Documentation
- **CLAUDE.md** - Complete project context for Claude Code
- **CONFIG.md** - Database configuration guide
- **README.md** - This file - quick start guide

### Operational Guides
- **docs/00_RUNBOOK.md** - Complete operational runbook (dev workflow, deployment)
- **docs/CLAUDE_WORKFLOW.md** - Session and task management workflow
- **sql/DEPLOYMENT_GUIDE.md** - SQL deployment procedures

### Technical Documentation
- **docs/TECHNICAL_SPECIFICATION.md** - Complete technical spec (72KB)
- **docs/DESIGN_DECISIONS.md** - Architectural decisions log
- **docs/SCHEMA_OVERVIEW.md** - Schema design patterns
- **docs/highspring_phase1_project_plan.md** - 5-week project roadmap

### Integration Guides
- **docs/NHS_ODS_INTEGRATION.md** - NHS ODS API integration architecture
- **docs/ods_dimensions_operational_guide.md** - Commissioner/GP/PCN dimensions
- **docs/Connect_WSL_Map_Networkdrive.md** - WSL H: drive mapping

### Validation & Testing
- **docs/FACT_VALIDATION_USER_GUIDE.md** - Validation framework guide
- **docs/testing/TESTING_WORKFLOW.md** - Testing procedures
- **docs/testing/VALIDATION_UPDATE_SUMMARY.md** - Validation updates

### Power BI
- **powerbi/PBIX_BUILD_GUIDE.md** - Power BI TMDL setup guide

## Data Sources

Source data from:
- `[Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active]` - Inpatient
- `[Data_Lab_SWL].[Unified].[tbl_OP_EncounterDenormalised_Active]` - Outpatient
- `[Dictionary]` database - NHS Data Dictionary reference tables

## Support

For issues or questions, contact the SWL ICB Data Team.

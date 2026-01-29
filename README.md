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
swl-analytics-platform/
├── sql/
│   ├── 00_setup/           # Schema creation, prerequisites
│   ├── 01_dimensions/      # 26 dimension table DDL
│   ├── 02_facts/           # 3 fact tables (IP, OP, AE)
│   ├── 04_etl/             # ETL stored procedures
│   └── 06_validation/      # Data validation SP
├── powerbi/
│   ├── tmdl/               # Power BI TMDL semantic model
│   └── PBIX_BUILD_GUIDE.md
├── docs/
│   ├── FACT_VALIDATION_USER_GUIDE.md
│   └── SCHEMA_OVERVIEW.md
├── CLAUDE.md               # Detailed project context
└── README.md               # This file
```

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

- **CLAUDE.md** - Complete project context for Claude Code
- **CONFIG.md** - Database configuration guide
- **docs/CLAUDE_WORKFLOW.md** - Session and task management workflow
- **docs/SCHEMA_OVERVIEW.md** - Schema design patterns
- **docs/FACT_VALIDATION_USER_GUIDE.md** - Validation guide
- **powerbi/PBIX_BUILD_GUIDE.md** - Power BI setup guide

## Data Sources

Source data from:
- `[Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active]` - Inpatient
- `[Data_Lab_SWL].[Unified].[tbl_OP_EncounterDenormalised_Active]` - Outpatient
- `[Dictionary]` database - NHS Data Dictionary reference tables

## Support

For issues or questions, contact the SWL ICB Data Team.

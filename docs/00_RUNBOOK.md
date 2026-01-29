# SWL HighSpring — Runbook

**Last updated:** 28-01-2026 UTC

This is the single operational runbook for deploying and running HighSpring in this repo.

---

## Quick Reference (Dev Workflow)

For repeated dev rebuilds, use this two-step workflow:

```bash
# Step 1: WSL terminal — refresh staging data
./scripts/refresh_staging_data.sh

# Step 2: Windows SSMS/ADS — run full rebuild
# Open H:\sql\analytics_platform\00_Dev_Full_Rebuild.sql
# Enable SQLCMD Mode → Execute (F5)
```

That's it. The dev rebuild script handles deploy + precompute + facts + enrichment in one execution.

---

## Scope

| Item | Value |
|------|-------|
| Target DB | `[Data_Lab_SWL_Live]` |
| Target schema | `[Analytics]` |
| Deployment style | Deploy now, load later (SQLCMD deploy creates objects and loads dimensions; facts/bridges/enrichment are executed manually or via dev rebuild script) |

---

## 1) Prerequisites

### 1.1 Upstream Dependencies

Fact/bridge/enrichment procedures read from existing objects in `[Data_Lab_SWL]`:

| Dependency | Description |
|------------|-------------|
| Unified SUS tables | `Unified.tbl_*_EncounterDenormalised_Active` (IP/OP/AE) |
| ERF repriced views | 25/26 financial year views |
| Operating Plan TVFs | `PLNG.Get_OpPlan_ActivityBridge_*_UfS` |
| CAM raw staging | `[Data_Lab_SWL].[CAM].[tbl_CAM_Raw]` (populated via `Analytics.sp_Compute_CAM_Raw`) |
| CAM reference tables | `[Data_Lab_SWL].[CAM_Ref]` (service flags, year/month bridge, commissioner mappings) |
| SUS delivery schedule | `[Data_Lab_SWL].[SWL].[tbl_SUS_Delivery_Schedule]` (published month cutoff) |
| LSOA reference | `[Data_Lab_SWL].[ref].[tbl_LSOA_ICB_CA_LocalAuthority]` |

The authoritative dependency list is maintained in: [sql/analytics_platform/README.md](../../sql/analytics_platform/README.md)

### 1.2 Tooling Requirements

| Tool | Purpose |
|------|---------|
| Python 3.x with venv | Run staging data fetchers |
| WSL (Windows Subsystem for Linux) | Execute bash scripts and Python |
| SSMS / Azure Data Studio / VS Code | Execute SQLCMD scripts (requires SQLCMD mode enabled) |
| H: drive mapping | WSL filesystem mapped to `H:\` for Windows SQL tooling |

---

## 2) Staging Data Pipeline (Python)

### 2.1 Overview

Three Python fetchers generate staging SQL files that the deploy script loads:

| Fetcher | Staging Table | Output File |
|---------|---------------|-------------|
| `fetch_all_commissioners.py` | `tbl_Staging_NHS_ODS_Commissioner` | `staging_commissioner.sql` |
| `fetch_gp_practices_csv.py` | `tbl_Staging_GP_Practice` | `staging_gp_practice.sql` |
| `fetch_imd2019_idaci_idaopi.py` | `tbl_Staging_LSOA_IMD2019` | `staging_lsoa_imd.sql` |

All fetchers write to:
- **Latest file:** `sql/analytics_platform/05_api/staging_*.sql` (deploy reads this)
- **Archive:** `sql/analytics_platform/05_api/archive/*_YYYYMMDD_HHMMSS.sql` (audit trail)

### 2.2 Automated Refresh (Recommended)

Run the orchestrator script to fetch all staging data in one command:

```bash
cd /home/speddi/dev/icb/sustabular
./scripts/refresh_staging_data.sh
```

Options:
- `--skip-imd` — Skip IMD fetch (use existing `staging_lsoa_imd.sql`)

### 2.3 Manual Refresh (Individual Fetchers)

If you need to run fetchers individually:

**Commissioner data (NHS ODS API):**
```bash
python scripts/data_integration/nhs_ods/fetch_all_commissioners.py \
  --output sql \
  --output-dir sql/analytics_platform/05_api
```

**GP Practice data (NHS ODS CSV export):**
```bash
python scripts/data_integration/nhs_ods/fetch_gp_practices_csv.py
```

**IMD/LSOA data (GOV.UK Excel):**
```bash
python scripts/data_integration/imd2019/fetch_imd2019_idaci_idaopi.py \
  --url "https://assets.publishing.service.gov.uk/media/5d8b364a40f0b609909e5fb3/File_7_-_All_IoD2019_Scores__Ranks__Deciles_and_Population_Denominators_3.xlsx" \
  --out-dir sql/analytics_platform/05_api
```

### 2.4 Dimension Load Order

The deploy script executes dimension loads in this order (dependency-aware):

1. `sp_Load_Dim_Commissioner` ← reads from `tbl_Staging_NHS_ODS_Commissioner`
2. `sp_Load_Dim_GPPractice` ← reads from `tbl_Staging_GP_Practice`
3. `sp_Load_Dim_PCN` ← **derives from `tbl_Dim_GPPractice`** (not staging)
4. `sp_Load_Dim_LSOA` ← reads from `tbl_Staging_LSOA_IMD2019` + `ref.tbl_LSOA_ICB_CA_LocalAuthority`

---

## 3) Deploy (SQLCMD)

### 3.1 Master Deploy Script

Creates all objects, loads staging data, and executes dimension loads:

```
sql/analytics_platform/00_Run_Everything_SQLCMD.sql
```

**What it does:**
1. Creates schemas, tables, views, stored procedures
2. Loads staging data from `05_api/staging_*.sql` files
3. Executes dimension load procedures
4. Does **not** execute fact/bridge/enrichment loads

**SQLCMD variables:**
- `:setvar ResetETLLogs 1` — Reset ETL logs on deploy (set to `0` to preserve history)

### 3.2 Dev Full Rebuild Script

For repeated dev rebuilds, use the all-in-one script:

```
sql/analytics_platform/00_Dev_Full_Rebuild.sql
```

**What it does:**
1. Runs master deploy (objects + dimensions)
2. Runs precompute (CAM Raw, CAM Active, ERF Active, OpPlan Active)
3. Runs fact loads (IP, OP, AE)
4. Runs enrichment (OpPlan, ERF, CAM)

**Configuration (edit at top of script):**
```sql
:setvar ResetETLLogs 1
:setvar FinYearStart 2025
:setvar FinancialYear "2025/2026"
:setvar FromDate "2025-04-01"
:setvar ToDate "2025-09-30"
```

### 3.3 Dimension DDL Safety

Dimension DDL scripts use `CREATE IF NOT EXISTS` pattern:
- **First run:** Creates table, inserts default members, creates indexes
- **Subsequent runs:** Skips creation, preserves surrogate keys

This ensures fact table FK references remain valid across rebuilds.

---

## 4) Execute (Manual Load Order)

If running loads individually (not using dev rebuild script), follow this order:

### 4.1 Precompute (Required Before Enrichment)

```sql
-- CAM Raw (populates [CAM].[tbl_CAM_Raw])
EXEC [Analytics].[sp_Compute_CAM_Raw]
  @FinYearStart = '2025',
  @FinancialYear = '2025/2026';

-- CAM Assignment Active
EXEC [Analytics].[sp_Load_CAM_Assignment_Active]
  @FinYearStart = '2025',
  @FinancialYear = '2025/2026';

-- ERF Repriced Active
EXEC [Analytics].[sp_Load_ERF_Repriced_Active]
  @FinYearStart = '2025';

-- OpPlan Active
EXEC [Analytics].[sp_Load_OpPlan_Active]
  @FinYearStart = '2025';
```

### 4.2 Fact Loads

**Option A: Combined (recommended)**
```sql
EXEC [Analytics].[sp_Run_Fact_Loads_With_Enrichment]
  @FromDate = '2025-04-01',
  @ToDate = '2025-09-30',
  @FinYearStart = '2025',
  @FinancialYear = '2025/2026',
  @ProviderCode = NULL;
```

**Option B: Individual**
```sql
EXEC [Analytics].[sp_Load_Fact_IP_Activity]
  @FromDate = '2025-04-01',
  @ToDate = '2025-09-30';

EXEC [Analytics].[sp_Load_Fact_OP_Activity]
  @FromDate = '2025-04-01',
  @ToDate = '2025-09-30';

EXEC [Analytics].[sp_Load_Fact_AE_Activity]
  @FromDate = '2025-04-01',
  @ToDate = '2025-09-30';
```

**Default window (no parameters):**
- Uses `Analytics.fn_SUS_Published_Cutoff_Date(NULL)` to find the last 6 published months
- Falls back to `GETDATE()` if schedule table is missing

### 4.3 Enrichment (Post-Facts)

```sql
-- Operating Plan enrichment
EXEC [Analytics].[sp_Enrich_Facts_Operating_Plan]
  @FinYearStart = '2025';

-- ERF enrichment
EXEC [Analytics].[sp_Enrich_Facts_ERF]
  @FinYearStart = '2025';

-- CAM enrichment
EXEC [Analytics].[sp_Enrich_Facts_CAM]
  @FinancialYear = '2025/2026',
  @ProviderCode = NULL,
  @FromDate = NULL,
  @ToDate = NULL;
```

### 4.4 Bridges (Optional)

```sql
EXEC [Analytics].[sp_Load_Bridge_ERF_Activity]
  @FinYearStart = '2025';
```

Note: Operating Plan deferred bridge is **deprecated**.

### 4.5 CF Segmentation (Optional)

Requires rules to be populated first:

```sql
-- Load CF code lookup (one-off)
EXEC [Analytics].[sp_Load_Ref_CF_Code_Lookup];

-- Run segmentation
EXEC [Analytics].[sp_Load_Bridge_CF_Segment_Patient_Snapshot]
  @SnapshotMonth = 202509;
```

---

## 5) Validation

Run validation queries after first controlled execution:

- [docs/VALIDATION_QUERIES.sql](../VALIDATION_QUERIES.sql)

---

## 6) File Reference

### Deploy Scripts
| Script | Purpose |
|--------|---------|
| `00_Run_Everything_SQLCMD.sql` | Master deploy (objects + dimensions) |
| `00_Dev_Full_Rebuild.sql` | Dev rebuild (deploy + precompute + facts + enrichment) |

### Python Fetchers
| Script | Data Source | Output |
|--------|-------------|--------|
| `scripts/refresh_staging_data.sh` | Orchestrator | Runs all fetchers |
| `scripts/data_integration/nhs_ods/fetch_all_commissioners.py` | NHS ODS API | Commissioner staging |
| `scripts/data_integration/nhs_ods/fetch_gp_practices_csv.py` | NHS ODS CSV | GP Practice staging |
| `scripts/data_integration/imd2019/fetch_imd2019_idaci_idaopi.py` | GOV.UK IMD 2019 | LSOA/IMD staging |

### Staging Files
| File | Staging Table |
|------|---------------|
| `05_api/staging_commissioner.sql` | `tbl_Staging_NHS_ODS_Commissioner` |
| `05_api/staging_gp_practice.sql` | `tbl_Staging_GP_Practice` |
| `05_api/staging_lsoa_imd.sql` | `tbl_Staging_LSOA_IMD2019` |

---

## 7) Design Documentation

- Design + model + decisions: [01_DESIGN.md](01_DESIGN.md)
- Backlog / what's left: [02_BACKLOG.md](02_BACKLOG.md)
- Phase 1 plan: [highspring_phase1_project_plan.md](highspring_phase1_project_plan.md)
- CF segmentation strategy: [archive/bridge_patient_segment_strategy.md](archive/bridge_patient_segment_strategy.md)

---

## 8) Operational Notes

### Recent Changes
- **Dimension DDL safety:** Dimensions now use `CREATE IF NOT EXISTS` pattern to preserve surrogate keys
- **Staging file naming:** Python fetchers write to fixed filenames (`staging_*.sql`) — no more timestamp juggling
- **Dev rebuild script:** Single script (`00_Dev_Full_Rebuild.sql`) runs everything for from-scratch rebuilds
- **Orchestrator script:** `refresh_staging_data.sh` runs all Python fetchers in one command

### Hard Rules
- This repo is **code-first**: run SQL scripts from `sql/analytics_platform/`
- Large loads (facts/bridges) are **manual by design** (or via dev rebuild script)
- Dimension load order matters: Commissioner → GPPractice → PCN (PCN derives from GPPractice)

### Legacy Lineage (Reference Only)
These folders are for historical context; do not run them for HighSpring:
- **SUS+ (pre-cube):** `legacy_sql/pgisus/`
- **V2 Cube (old cube model):** `legacy_sql/old_dm/` and `legacy_sql/docs/`
- **Unified SUS definitions (current upstream):** `sql/unified_sus/`

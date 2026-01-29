# SWL HighSpring — Execution Handbook

**Last updated:** 2026-01-29
**Status:** Phase 1 Complete — Ready for data load execution

This is the single operational runbook for deploying and running HighSpring.

---

## Quick Start (Dev Workflow)

For full dev rebuilds, use this two-step workflow:

```bash
# Step 1: WSL terminal — refresh staging data
./scripts/refresh_staging_data.sh

# Step 2: Windows SSMS/ADS — run full rebuild
# Open sql/00_Dev_Full_Rebuild.sql in SQLCMD Mode → Execute (F5)
```

That's it. The dev rebuild script handles deploy → precompute → facts → enrichment in one execution.

---

## Change Log

| Date | Change |
|------|--------|
| 2026-01-29 | Phase 1 complete; updated paths to reflect actual repo structure |
| 2026-01-28 | Added dev rebuild script workflow |
| 2026-01-15 | Reordered precompute before enrichment; OpPlan uses `tbl_OpPlan_Active` |

---

## 1) Prerequisites

### 1.1 Upstream Dependencies

| Dependency | Location | Description |
|------------|----------|-------------|
| Unified SUS tables | `[Data_Lab_SWL].[Unified]` | `tbl_*_EncounterDenormalised_Active` (IP/OP/AE) |
| ERF repriced views | `[Data_Lab_SWL].[Analytics]` | 25/26 financial year views |
| Operating Plan TVFs | `[Data_Lab_SWL].[PLNG]` | `Get_OpPlan_ActivityBridge_*_UfS` |
| CAM function | `[Data_Lab_SWL].[CAM]` | `fn_CommissionerAssignment` |
| SUS delivery schedule | `[Data_Lab_SWL].[SWL]` | `tbl_SUS_Delivery_Schedule` |
| LSOA reference | `[Data_Lab_SWL].[ref]` | `tbl_LSOA_ICB_CA_LocalAuthority` |

### 1.2 Tooling Requirements

| Tool | Purpose |
|------|---------|
| SSMS / Azure Data Studio | Execute SQLCMD scripts (SQLCMD mode required) |
| WSL + Python 3.x | Run staging data fetchers (optional) |

---

## 2) Deployment Scripts

### 2.1 Dev Full Rebuild (Recommended)

**Script:** `sql/00_Dev_Full_Rebuild.sql`

Single script that runs everything for a clean rebuild:

| Phase | What It Does |
|-------|--------------|
| Phase 1: Deploy | Runs `00_Run_Everything_SQLCMD.sql` (objects + dimensions) |
| Phase 2: Precompute | CAM Raw → CAM Active → ERF Active → OpPlan Active |
| Phase 3: Facts | IP → OP → AE fact loads |
| Phase 4: Enrichment | Operating Plan → ERF → CAM enrichment |

**Configuration (edit at top of script):**
```sql
:setvar ResetETLLogs 1
:setvar FinYearStart 2025
:setvar FinancialYear "2025/2026"
:setvar FromDate "2025-04-01"
:setvar ToDate "2025-12-31"
```

### 2.2 Master Deploy Only

**Script:** `sql/00_Run_Everything_SQLCMD.sql`

Creates all objects and loads dimensions only. Does **not** run fact/bridge/enrichment loads.

Use this when you only need to deploy schema changes without reloading data.

---

## 3) Manual ETL Run Order

If running loads individually (not using dev rebuild script), follow this order:

### 3.1 Precompute (Run First)

These must complete before any enrichment:

```sql
-- 1. CAM Raw
EXEC [Analytics].[sp_Compute_CAM_Raw]
    @FinYearStart = '2025',
    @FinancialYear = '2025/2026';

-- 2. CAM Assignment Active
EXEC [Analytics].[sp_Load_CAM_Assignment_Active]
    @FinYearStart = '2025',
    @FinancialYear = '2025/2026';

-- 3. ERF Repriced Active
EXEC [Analytics].[sp_Load_ERF_Repriced_Active]
    @FinYearStart = '2025';

-- 4. OpPlan Active
EXEC [Analytics].[sp_Load_OpPlan_Active]
    @FinYearStart = '2025';
```

### 3.2 Facts + Enrichments (Combined)

Recommended approach — runs facts and enrichment together:

```sql
EXEC [Analytics].[sp_Run_Fact_Loads_With_Enrichment]
    @FromDate = '2025-04-01',
    @ToDate = '2025-12-31',
    @FinYearStart = '2025',
    @FinancialYear = '2025/2026',
    @ProviderCode = NULL;
```

### 3.3 Facts Only (Manual)

If you need to run fact loads separately:

```sql
EXEC [Analytics].[sp_Load_Fact_IP_Activity]
    @FromDate = '2025-04-01',
    @ToDate = '2025-12-31';

EXEC [Analytics].[sp_Load_Fact_OP_Activity]
    @FromDate = '2025-04-01',
    @ToDate = '2025-12-31';

EXEC [Analytics].[sp_Load_Fact_AE_Activity]
    @FromDate = '2025-04-01',
    @ToDate = '2025-12-31';
```

### 3.4 Enrichments Only (After Manual Facts)

If you ran facts manually, run enrichments separately:

```sql
EXEC [Analytics].[sp_Enrich_Facts_Operating_Plan]
    @FinYearStart = '2025';

EXEC [Analytics].[sp_Enrich_Facts_ERF]
    @FinYearStart = '2025';

EXEC [Analytics].[sp_Enrich_Facts_CAM]
    @FinancialYear = '2025/2026',
    @ProviderCode = NULL,
    @FromDate = '2025-04-01',
    @ToDate = '2025-12-31';
```

### 3.5 Bridges (Optional)

```sql
EXEC [Analytics].[sp_Load_Bridge_ERF_Activity]
    @FinYearStart = '2025';
```

### 3.6 CF Segmentation (Optional)

Requires rules to be populated first:

```sql
EXEC [Analytics].[sp_Load_Bridge_CF_Segment_Patient_Snapshot]
    @SnapshotMonth = 202512;
```

---

## 4) Validation

Run validation after data loads complete:

```sql
EXEC [Analytics].[sp_Validate_Fact_Data]
    @FromDate = '2025-04-01',
    @ToDate = '2025-12-31',
    @MaterialityThreshold = 100;
```

See [FACT_VALIDATION_USER_GUIDE.md](FACT_VALIDATION_USER_GUIDE.md) for detailed validation guidance.

---

## 5) Quick Reference (Run Order)

```
Deploy
  └── sql/00_Dev_Full_Rebuild.sql (or 00_Run_Everything_SQLCMD.sql)

Precompute (if manual)
  ├── sp_Compute_CAM_Raw
  ├── sp_Load_CAM_Assignment_Active
  ├── sp_Load_ERF_Repriced_Active
  └── sp_Load_OpPlan_Active

Facts + Enrichment
  └── sp_Run_Fact_Loads_With_Enrichment

Bridges (optional)
  ├── sp_Load_Bridge_ERF_Activity
  └── sp_Load_Bridge_CF_Segment_Patient_Snapshot

Validate
  └── sp_Validate_Fact_Data
```

---

## 6) File Reference

### SQL Scripts

| Script | Purpose |
|--------|---------|
| `sql/00_Dev_Full_Rebuild.sql` | Full rebuild (deploy + precompute + facts + enrichment) |
| `sql/00_Run_Everything_SQLCMD.sql` | Deploy only (objects + dimensions) |
| `sql/04_etl/00_Run_All_Dimension_Loads.sql` | Dimension loads orchestration |

### Key Directories

| Directory | Contents |
|-----------|----------|
| `sql/00_setup/` | Schema, partitioning, staging tables (19 files) |
| `sql/01_dimensions/` | Dimension DDL and views (36 files) |
| `sql/02_facts/` | Fact tables and denormalized views (6 files) |
| `sql/04_etl/` | ETL stored procedures (30 files) |
| `sql/06_validation/` | Validation framework |
| `powerbi/tmdl/` | Power BI semantic model (31 tables) |

### Staging Data (Optional)

| Script | Purpose |
|--------|---------|
| `scripts/refresh_staging_data.sh` | Refresh NHS ODS staging data |
| `scripts/setup_env.sh` | Setup Python environment |

---

## 7) Operational Notes

### Default Date Window

- When `@FromDate` / `@ToDate` are NULL, procedures use `Analytics.fn_SUS_Published_Cutoff_Date`
- Falls back to last 6 months from current date if schedule table unavailable

### Idempotent Loads

- Fact loads are idempotent (delete/reload for the specified window)
- Dimension loads preserve surrogate keys across rebuilds

### Partition Management

- Facts are partitioned monthly by activity date
- Extend partition boundaries: `EXEC Analytics.sp_Extend_Fact_Partitions;`

### Deprecated Objects

- `sp_Load_Bridge_Operating_Plan_Deferred` — **do not execute** (replaced by MeasureSet model)

---

## 8) Related Documentation

| Document | Purpose |
|----------|---------|
| [../CLAUDE.md](../CLAUDE.md) | Project instructions for Claude Code |
| [highspring_phase1_project_plan.md](highspring_phase1_project_plan.md) | Phase 1 project plan |
| [FACT_VALIDATION_USER_GUIDE.md](FACT_VALIDATION_USER_GUIDE.md) | Data validation guide |
| [../powerbi/PBIX_BUILD_GUIDE.md](../powerbi/PBIX_BUILD_GUIDE.md) | Power BI model build guide |

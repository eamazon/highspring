# Reference SQL

This directory contains reference SQL scripts for supporting schemas and data sources. These are **not part of the core Analytics platform** but provide context for understanding source systems and enrichment pipelines.

## Overview

The Analytics platform (`sql/` directory) consumes data from several source schemas. This `reference_sql/` directory contains the DDL and logic for those upstream systems.

**Total**: 150 SQL files across 5 schemas

## Directories

### cam/ (6 files)
**Capacity & Access Management**

Contains schema definitions and procedures for CAM (Capacity & Access Management) data:
- `[CAM].[tbl_CAM_Raw]` - Raw CAM activity data
- CAM assignment logic
- CAM service categories and assignment reasons

**Used by Analytics**:
- `sql/04_etl/24_sp_Compute_CAM_Raw.sql`
- `sql/04_etl/21_sp_Load_CAM_Assignment_Active.sql`
- `sql/04_etl/16_sp_Enrich_Facts_CAM.sql`

**Purpose**: CAM provides capacity utilization data enriched onto IP/OP/AE facts.

---

### dictionary/ (109 files)
**NHS Data Dictionary Reference Tables**

Contains views and mappings to NHS Data Dictionary tables:
- National codes for admission methods, discharge destinations, etc.
- Ethnicity, gender, specialty, HRG codes
- Provider, commissioner, GP practice lookups

**Examples**:
- Admission Method codes (01-98)
- Discharge Destination codes
- Treatment Function codes
- Healthcare Resource Groups (HRG)

**Used by Analytics**:
- Dimension tables reference Dictionary views
- `sql/01_dimensions/` creates views on top of Dictionary tables

**Purpose**: Provides standardized NHS code sets for referential integrity.

---

### erf/ (8 files)
**Elective Recovery Fund**

Contains schema for ERF (Elective Recovery Fund) tracking:
- `[ERF].[tbl_ERF_Repriced_Active]` - Repriced activity for ERF
- ERF activity attribution logic
- Bridge tables linking facts to ERF targets

**Used by Analytics**:
- `sql/04_etl/22_sp_Load_ERF_Repriced_Active.sql`
- `sql/04_etl/20_sp_Enrich_Facts_ERF.sql`
- `sql/04_etl/13_sp_Load_Bridge_ERF_Activity.sql`

**Purpose**: Tracks elective recovery activity against national targets.

---

### op_plan/ (6 files)
**Operating Plan Targets**

Contains schema for operational planning and target setting:
- `[OpPlan].[tbl_OpPlan_Active]` - Activity targets by specialty/POD
- Measure definitions and target values
- Bridge tables linking facts to plan targets

**Used by Analytics**:
- `sql/04_etl/23_sp_Load_OpPlan_Active.sql`
- `sql/04_etl/19_sp_Enrich_Facts_Operating_Plan.sql`
- `sql/04_etl/14_sp_Load_Bridge_Operating_Plan_Deferred.sql`

**Purpose**: Compares actual activity against planned targets.

---

### unified_sus/ (21 files)
**Unified SUS (Secondary Uses Service)**

Contains denormalized views combining multiple SUS datasets:
- `[Unified].[vw_IP_EncounterDenormalised_Active]` - Inpatient encounters
- `[Unified].[vw_OP_EncounterDenormalised_Active]` - Outpatient appointments
- `[Unified].[vw_ED_EncounterDenormalised_Active]` - A&E attendances

**Used by Analytics**:
- **PRIMARY DATA SOURCE** for all Analytics fact tables
- `sql/04_etl/10_sp_Load_Fact_IP_Activity.sql` reads from Unified views
- `sql/04_etl/11_sp_Load_Fact_OP_Activity.sql` reads from Unified views
- `sql/04_etl/12_sp_Load_Fact_AE_Activity.sql` reads from Unified views

**Purpose**: Provides clean, denormalized source data for Analytics facts.

---

## Relationship to Analytics Platform

```
[Dictionary]  ──────┐
[Unified SUS] ──────┼─→ [Analytics]  ──→  Power BI
[CAM]         ──────┤    (sql/)
[ERF]         ──────┤
[OpPlan]      ──────┘
```

### Data Flow

1. **Source Systems** → SUS feeds (IP, OP, AE)
2. **Unified SUS** → Denormalizes and cleanses source data
3. **Analytics** → Transforms into star schema (dimensions + facts)
4. **Enrichment** → Adds CAM, ERF, OpPlan context to facts
5. **Power BI** → Consumes Analytics star schema

### Deployment Order

If deploying from scratch:

1. **Dictionary** - Reference tables (may already exist)
2. **Unified SUS** - Source views
3. **CAM, ERF, OpPlan** - Enrichment schemas
4. **Analytics** - Star schema (`sql/` directory)

**Note**: Most environments already have Dictionary, Unified, CAM, ERF, and OpPlan deployed. You typically only deploy Analytics.

---

## Usage Notes

### These scripts are for REFERENCE ONLY

- The Analytics platform (`sql/`) assumes these schemas exist
- You typically do **NOT** need to deploy these scripts
- They're included for:
  - Understanding source data structures
  - Documenting dependencies
  - Troubleshooting source data issues
  - Recreating environments from scratch (rare)

### When to Deploy These

**Deploy if**:
- Setting up a completely new environment
- Dictionary tables are missing
- Unified views need recreation
- CAM/ERF/OpPlan schemas don't exist

**Don't deploy if**:
- Your environment already has these schemas
- You're just updating Analytics platform
- You're unsure - check with DBA first

### Schema Ownership

These schemas are typically owned by upstream teams:
- **Dictionary**: National NHS reference data
- **Unified SUS**: SUS data team
- **CAM/ERF/OpPlan**: Planning and performance teams

Changes to these schemas should be coordinated with their respective owners.

---

## Key Dependencies

### Analytics Depends On

| Analytics Object | Depends On |
|------------------|------------|
| `sp_Load_Fact_IP_Activity` | `[Unified].[vw_IP_EncounterDenormalised_Active]` |
| `sp_Load_Fact_OP_Activity` | `[Unified].[vw_OP_EncounterDenormalised_Active]` |
| `sp_Load_Fact_AE_Activity` | `[Unified].[vw_ED_EncounterDenormalised_Active]` |
| `vw_Dim_Admission_Method` | `[Dictionary].[Admission_Method]` |
| `vw_Dim_Ethnicity` | `[Dictionary].[Ethnic_Category]` |
| `sp_Enrich_Facts_CAM` | `[CAM].[tbl_CAM_Assignment_Active]` |
| `sp_Enrich_Facts_ERF` | `[ERF].[tbl_ERF_Repriced_Active]` |

### Checking Dependencies

```sql
-- Check if source schemas exist
SELECT name FROM sys.schemas
WHERE name IN ('Dictionary', 'Unified', 'CAM', 'ERF', 'OpPlan');

-- Check if Unified views exist
SELECT name FROM sys.views
WHERE schema_name(schema_id) = 'Unified'
  AND name LIKE '%EncounterDenormalised%';
```

---

## File Inventory

### cam/ (6 files)
- CAM raw table definitions
- CAM assignment procedures
- CAM service category and reason dimensions

### dictionary/ (109 files)
- NHS Data Dictionary reference tables
- Code lookups (admission, discharge, specialty, etc.)
- Provider and commissioner reference data

### erf/ (8 files)
- ERF repricing logic
- ERF activity bridge tables
- ERF target tracking

### op_plan/ (6 files)
- Operating plan targets
- Measure definitions
- Plan vs actual comparison logic

### unified_sus/ (21 files)
- Denormalized IP/OP/AE encounter views
- POD (Point of Delivery) mapping functions
- Activity aggregation views

---

## Support

For questions about:
- **Analytics platform**: See `sql/DEPLOYMENT_GUIDE.md` and `CLAUDE.md`
- **Source schemas**: Contact respective schema owners
- **Data issues**: Check with source data teams

## Version Control

These scripts represent a snapshot of the source schemas at the time of extraction. They may differ from production schemas. Always validate against your actual environment before deploying.

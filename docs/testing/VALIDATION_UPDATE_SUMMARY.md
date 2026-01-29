# Validation Scripts Update Summary

**Date:** 2026-01-15
**Updated By:** Claude
**Reason:** Align validation with current architecture where ERF bridge is optional

---

## Changes Made

### 1. Architecture Change Confirmed

**Old Pattern (Deprecated):**
- ERF data in separate bridge table (required)
- Bridge joins required for reporting

**New Pattern (Current):**
- ERF data enriched directly as columns on fact tables (PRIMARY)
- ERF bridge is OPTIONAL (for reporting/lineage only)
- Same pattern applies to CAM and OpPlan (enriched on facts)

### 2. Files Updated

#### `docs/TESTING_VALIDATION_SCRIPTS.sql`

**Section 2.1 - Controlled Load Execution:**
- ✅ Updated Step 3 to mark ERF bridge as OPTIONAL
- ✅ Changed expected volumes to reflect enrichment columns on facts
- ✅ Added note that ERF/CAM/OpPlan enriched on fact columns

**Section 2.2.3 - Post-Load Validation:**
- ✅ Changed from "Bridge table row counts" to "ERF enrichment on facts (PRIMARY)"
- ✅ Now validates Is_ERF_Eligible flag and ERF cost columns on IP/OP facts
- ✅ Added optional check for ERF bridge (only if loaded)

**Section 3.2 - Renamed and Refocused:**
- ✅ Changed from "BRIDGE RELATIONSHIPS" to "ENRICHMENT VALIDATION"
- ✅ Primary validation: ERF enrichment columns on facts
- ✅ Primary validation: OpPlan MeasureSet enrichment on facts
- ✅ Secondary validation: Optional ERF bridge (if loaded)
- ✅ Removed emphasis on bridge joins as required

#### `docs/operations/TESTING_WORKFLOW.md`

**Phase 1 - Controlled Load:**
- ✅ Step 1.3 marked as OPTIONAL with explanation
- ✅ Expected rows updated to mention enrichment columns
- ✅ Added note explaining ERF/CAM/OpPlan now enriched on facts

**Phase 3 - Business Logic Validation:**
- ✅ Test 3.2 renamed to "Enrichment Validation"
- ✅ Pass criteria updated to focus on fact columns, not bridge joins
- ✅ ERF bridge marked as optional validation

**Validation Checklist:**
- ✅ Updated to reflect enrichment columns on facts (not bridge rows)
- ✅ Marked ERF bridge as optional

**Full Load Section:**
- ✅ ERF bridge load command commented out as optional
- ✅ Expected rows clarified (enrichment columns vs bridge rows)

---

## Current Load Order (Confirmed)

```sql
-- Step 1: Precompute (MUST run first)
EXEC [Analytics].[sp_Compute_CAM_Raw] @FinYearStart='2025', @FinancialYear='2025/2026';
EXEC [Analytics].[sp_Load_CAM_Assignment_Active] @FinYearStart='2025', @FinancialYear='2025/2026';
EXEC [Analytics].[sp_Load_ERF_Repriced_Active] @FinYearStart='2025';
EXEC [Analytics].[sp_Load_OpPlan_Active] @FinYearStart='2025';

-- Step 2: Facts + Enrichment (Recommended wrapper)
EXEC [Analytics].[sp_Run_Fact_Loads_With_Enrichment]
    @FromDate='2025-04-01', @ToDate='2025-04-30',
    @FinYearStart='2025', @FinancialYear='2025/2026';

-- Step 3: Bridges (OPTIONAL - only if needed)
-- EXEC [Analytics].[sp_Load_Bridge_ERF_Activity] @FinYearStart='2025';
```

---

## Validation Focus Areas (Updated)

### Primary Validations (Required):
1. **CAM Enrichment** → Validates columns on IP/OP facts
   - `CAM_Commissioner_Code`
   - `CAM_Service_Category`
   - `CAM_Assignment_Reason`
   - Target: >95% attribution coverage

2. **ERF Enrichment** → Validates columns on IP/OP facts
   - `Is_ERF_Eligible`
   - `ERF_Total_Cost_Incl_MFF`
   - `ERF_National_Price`
   - `ERF_Tariff_Used`

3. **OpPlan Enrichment** → Validates columns on IP/OP/AE facts
   - `Is_Operating_Plan`
   - `SK_OpPlan_MeasureSet`
   - MeasureSet dimension populated

### Secondary Validations (Optional):
4. **ERF Bridge** → Only validates if loaded
   - Row counts by POD
   - Total ERF cost
   - Join coverage to facts

---

## Deprecated Components

The following are confirmed **DEPRECATED** and should NOT be used:

❌ `sp_Load_Bridge_Operating_Plan_Deferred` - Operating Plan now uses MeasureSet design
❌ ERF bridge as required component - Now optional for reporting/lineage only

---

## Testing Impact

**Before (Incorrect):**
- Required ERF bridge to be loaded
- Validated bridge joins as primary test
- Would FAIL if bridge not loaded

**After (Correct):**
- Validates enrichment columns on facts (PRIMARY)
- ERF bridge is optional validation
- PASS if enrichment columns populated, regardless of bridge

---

## Files NOT Changed

The following files already had correct information:
- ✅ `docs/operations/EXECUTION_HANDBOOK.md` - Already shows ERF bridge as optional (section 3.5)
- ✅ `docs/operations/00_RUNBOOK.md` - (Assumed correct, not reviewed)
- ✅ `sql/analytics_platform/README.md` - (Assumed correct, not reviewed)

---

## References

- **Execution Handbook:** `docs/operations/EXECUTION_HANDBOOK.md` (section 3.5)
- **Project Plan:** `docs/operations/highspring_phase1_project_plan.md` (lines 644-677, 714-730)
- **Pipeline Doc:** `docs/pipelines/IP_PIPELINE.md` (lines 12-14, 28-30)

---

## Validation Quick Reference

### What to Check After Loads

**✅ REQUIRED (must check):**
```sql
-- ERF enrichment on facts
SELECT COUNT(*), SUM(CASE WHEN Is_ERF_Eligible=1 THEN 1 END)
FROM Analytics.tbl_Fact_IP_Activity;

-- CAM enrichment on facts
SELECT COUNT(*), SUM(CASE WHEN CAM_Commissioner_Code IS NOT NULL THEN 1 END)
FROM Analytics.tbl_Fact_IP_Activity;

-- OpPlan enrichment on facts
SELECT COUNT(*), SUM(CASE WHEN Is_Operating_Plan=1 THEN 1 END)
FROM Analytics.tbl_Fact_IP_Activity;
```

**⚠️ OPTIONAL (check only if loaded):**
```sql
-- ERF bridge (if loaded)
SELECT COUNT(*) FROM Analytics.tbl_Bridge_ERF_Activity;
```

---

**Last Updated:** 2026-01-15
**Next Review:** After first production load test

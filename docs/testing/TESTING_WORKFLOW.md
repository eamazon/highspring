# Testing & Validation Workflow

**Created:** 2026-01-15
**Purpose:** Step-by-step guide for testing the Analytics platform before Power BI deployment
**Database:** `[Data_Lab_SWL_Live].[Analytics]`

---

## Quick Start

```sql
-- Run the comprehensive validation suite
:r ../../TESTING_VALIDATION_SCRIPTS.sql
```

---

## Testing Phases

### Phase 0: Pre-Flight (5 mins)

**Purpose:** Verify deployment completed successfully

```sql
-- Check dependencies exist
USE [Data_Lab_SWL_Live];
-- Run Section 0 from TESTING_VALIDATION_SCRIPTS.sql
```

**Pass Criteria:**
- All upstream views exist (Unified, SWL, ref)
- Analytics schema has 50+ objects
- Dimensions have rows

---

### Phase 1: Controlled Load (30-60 mins)

**Purpose:** Test with 1 month of data to catch issues early

#### Step 1.1: Precompute CAM/ERF/OpPlan Active Tables

```sql
-- Run BEFORE fact loads
EXEC [Analytics].[sp_Compute_CAM_Raw]
    @FinYearStart = '2025',
    @FinancialYear = '2025/2026',
    @ProviderCode = NULL,
    @FromDate = NULL,
    @ToDate = NULL;

EXEC [Analytics].[sp_Load_CAM_Assignment_Active]
    @FinYearStart = '2025',
    @FinancialYear = '2025/2026';

EXEC [Analytics].[sp_Load_ERF_Repriced_Active]
    @FinYearStart = '2025';

EXEC [Analytics].[sp_Load_OpPlan_Active]
    @FinYearStart = '2025';
```

**Expected Duration:** 10-20 minutes total
**Expected Rows:**
- CAM Active: ~13M rows (IP + OP for FY)
- ERF Active: ~1-2M rows (IP + OP eligible)
- OpPlan Active: ~5-8M rows (IP + OP + AE)

#### Step 1.2: Load Facts + Enrichment (Recommended)

```sql
-- This wrapper calls all fact loads + CAM/ERF/OpPlan enrichments
EXEC [Analytics].[sp_Run_Fact_Loads_With_Enrichment]
    @FromDate = '2025-04-01',
    @ToDate = '2025-04-30',
    @FinYearStart = '2025',
    @FinancialYear = '2025/2026',
    @ProviderCode = NULL;
```

**Expected Duration:** 15-30 minutes
**Expected Rows (1 month):**
- IP: ~125,000 rows (with ERF/CAM/OpPlan enrichment columns)
- OP: ~2,000,000 rows (with ERF/CAM/OpPlan enrichment columns)
- AE: ~130,000 rows

**Alternative (Individual Loads):**

```sql
-- Facts only
EXEC [Analytics].[sp_Load_Fact_IP_Activity]
    @FromDate = '2025-04-01', @ToDate = '2025-04-30';
EXEC [Analytics].[sp_Load_Fact_OP_Activity]
    @FromDate = '2025-04-01', @ToDate = '2025-04-30';
EXEC [Analytics].[sp_Load_Fact_AE_Activity]
    @FromDate = '2025-04-01', @ToDate = '2025-04-30';

-- Then enrichments
EXEC [Analytics].[sp_Enrich_Facts_CAM]
    @FinancialYear = '2025/2026',
    @FromDate = '2025-04-01',
    @ToDate = '2025-04-30';

EXEC [Analytics].[sp_Enrich_Facts_ERF]
    @FinYearStart = '2025',
    @FromDate = '2025-04-01',
    @ToDate = '2025-04-30';

EXEC [Analytics].[sp_Enrich_Facts_Operating_Plan]
    @FinYearStart = '2025',
    @FromDate = '2025-04-01',
    @ToDate = '2025-04-30';
```

#### Step 1.3: Load Bridges (OPTIONAL)

```sql
-- ERF bridge is OPTIONAL (data enriched directly on facts)
-- Only run if needed for reporting/lineage purposes
-- EXEC [Analytics].[sp_Load_Bridge_ERF_Activity] @FinYearStart = '2025';
```

**Note:** ERF, CAM, and OpPlan data are now enriched directly as columns on fact tables.
The ERF bridge is optional and only needed if you require separate ERF reporting/lineage views.

---

### Phase 2: Validation (15 mins)

**Purpose:** Verify data quality meets acceptance criteria

#### Test 2.1: Post-Load Checks

```sql
-- Run Section 2.2 from TESTING_VALIDATION_SCRIPTS.sql
-- Check row counts and date ranges
```

**Pass Criteria:**
- All fact tables have rows
- Date ranges match load window (2025-04-01 to 2025-04-30)

#### Test 2.3: Cost Reconciliation

```sql
-- Run Section 2.3 from TESTING_VALIDATION_SCRIPTS.sql
```

**Pass Criteria:**
- Cost variance < 2% = PASS
- Cost variance < 5% = WARN (acceptable if pricing differences known)
- Cost variance >= 5% = FAIL (investigate)

#### Test 2.4: Attribution Completeness

```sql
-- Run Section 2.4 from TESTING_VALIDATION_SCRIPTS.sql
```

**Pass Criteria:**
- CAM attribution >= 95% = PASS
- CAM attribution >= 90% = WARN
- CAM attribution < 90% = FAIL

---

### Phase 3: Business Logic Validation (15 mins)

**Purpose:** Verify measures and calculations are correct

#### Test 3.1: Fact Calculations

```sql
-- Run Section 3.1 from TESTING_VALIDATION_SCRIPTS.sql
-- Checks: LOS, wait times, DNAs, 4-hour breaches
```

**Pass Criteria:**
- No negative LOS
- No invalid dates (discharge < admission)
- No negative costs
- Distributions look reasonable

#### Test 3.2: Enrichment Validation (ERF & OpPlan on Facts)

```sql
-- Run Section 3.2 from TESTING_VALIDATION_SCRIPTS.sql
-- Checks: ERF enrichment columns, OpPlan MeasureSet enrichment
```

**Pass Criteria:**
- ERF enrichment: Is_ERF_Eligible flag set, ERF cost columns populated
- OpPlan enrichment: Is_Operating_Plan flag set, SK_OpPlan_MeasureSet populated
- OpPlan MeasureSet dimension populated
- ERF bridge is optional (only validates if loaded)

---

### Phase 4: Idempotency Test (30 mins)

**Purpose:** Verify re-running loaders doesn't create duplicates

```sql
-- Run Section 1.3 from TESTING_VALIDATION_SCRIPTS.sql
-- Captures baseline snapshot

-- Then RE-RUN the same load command
EXEC [Analytics].[sp_Run_Fact_Loads_With_Enrichment]
    @FromDate = '2025-04-01',
    @ToDate = '2025-04-30',
    @FinYearStart = '2025',
    @FinancialYear = '2025/2026',
    @ProviderCode = NULL;

-- Check for duplicates
SELECT SK_EncounterID, COUNT(*)
FROM [Analytics].[tbl_Fact_IP_Activity]
GROUP BY SK_EncounterID
HAVING COUNT(*) > 1;
-- Should return 0 rows
```

**Pass Criteria:**
- Row counts identical before/after re-run
- Zero duplicates on SK_EncounterID
- Cost totals match

---

### Phase 5: Performance Review (5 mins)

**Purpose:** Verify ETL runs within acceptable timeframes

```sql
-- Run Section 4 from TESTING_VALIDATION_SCRIPTS.sql
-- Reviews ETL log tables
```

**Pass Criteria:**
- 1-month load completes in < 30 minutes
- No errors in ETL_Error_Details
- All batches show 'SUCCESS' status

**Expected Performance (1 month):**
- IP load: 5-8 minutes
- OP load: 10-15 minutes
- AE load: 3-5 minutes
- ERF bridge: 3-5 minutes
- Enrichments: 5-10 minutes

---

## Full Load (After Successful Testing)

Once 1-month test passes all validation, extend to 6-month window:

```sql
-- Precompute (if not already done for full FY)
EXEC [Analytics].[sp_Load_CAM_Assignment_Active]
    @FinYearStart = '2025',
    @FinancialYear = '2025/2026';
EXEC [Analytics].[sp_Load_ERF_Repriced_Active]
    @FinYearStart = '2025';
EXEC [Analytics].[sp_Load_OpPlan_Active]
    @FinYearStart = '2025';

-- Facts + Enrichment (6 months)
EXEC [Analytics].[sp_Run_Fact_Loads_With_Enrichment]
    @FromDate = '2024-10-01',
    @ToDate = '2025-03-31',
    @FinYearStart = '2025',
    @FinancialYear = '2025/2026',
    @ProviderCode = NULL;

-- Bridges (OPTIONAL - only if needed)
-- EXEC [Analytics].[sp_Load_Bridge_ERF_Activity] @FinYearStart = '2025';
```

**Expected Duration:** 90-120 minutes
**Expected Rows (6 months):**
- IP: ~750,000 rows (with enrichment columns)
- OP: ~12,000,000 rows (with enrichment columns)
- AE: ~800,000 rows
- ERF Bridge: ~3,000,000 rows (OPTIONAL - only if loaded)

---

## Validation Checklist

Use this checklist to track testing progress:

### Pre-Flight
- [ ] All upstream dependencies exist
- [ ] Analytics schema deployed (50+ objects)
- [ ] Dimensions loaded and populated

### Controlled Load (1 Month)
- [ ] Precompute tables loaded (CAM/ERF/OpPlan Active)
- [ ] IP facts loaded (~125k rows)
- [ ] OP facts loaded (~2M rows)
- [ ] AE facts loaded (~130k rows)
- [ ] CAM enrichment complete (>95% attribution)
- [ ] ERF enrichment complete (Is_ERF_Eligible flag + cost columns on facts)
- [ ] OpPlan enrichment complete (Is_Operating_Plan flag + MeasureSet on facts)
- [ ] ERF bridge loaded (OPTIONAL - skip unless needed for reporting)

### Validation Tests
- [ ] **2.3 Cost Reconciliation:** <2% variance (PASS)
- [ ] **2.4 Attribution:** >95% CAM coverage (PASS)
- [ ] **3.1 Fact Calculations:** No negative values, valid dates
- [ ] **3.2 Enrichment Validation:** ERF columns populated, OpPlan flags set
- [ ] **1.3 Idempotency:** Re-run produces identical counts, zero duplicates
- [ ] **4 Performance:** 1-month load completes in <30 mins

### Full Load (6 Months)
- [ ] Full 6-month load completed
- [ ] All validation tests re-run on full dataset
- [ ] No errors in ETL logs
- [ ] Performance acceptable (<2 hours)

### Ready for Power BI
- [ ] All validation checklist items passed
- [ ] Finance sign-off on cost reconciliation
- [ ] Business users confirm test queries work
- [ ] Documentation updated with any findings

---

## Troubleshooting

### Issue: Cost variance > 5%

**Investigation:**
```sql
-- Compare specific cost fields
SELECT TOP 100
    f.SK_EncounterID,
    f.Total_Activity_Cost AS Analytics_Cost,
    u.dv_Total_Cost_Inc_MFF AS Unified_Cost,
    f.Total_Activity_Cost - u.dv_Total_Cost_Inc_MFF AS Difference
FROM [Analytics].[tbl_Fact_IP_Activity] f
INNER JOIN [Unified].[vw_IP_EncounterDenormalised_DateRange] u
    ON f.SK_EncounterID = u.SK_EncounterID
WHERE ABS(f.Total_Activity_Cost - u.dv_Total_Cost_Inc_MFF) > 100
ORDER BY ABS(f.Total_Activity_Cost - u.dv_Total_Cost_Inc_MFF) DESC;
```

**Common Causes:**
- Different pricing logic (Unified vs PGISUS)
- MFF applied differently
- NULL costs in source
- Data type truncation

---

### Issue: CAM attribution < 90%

**Investigation:**
```sql
-- Check which records have no CAM attribution
SELECT TOP 100
    SK_EncounterID,
    Admission_Date,
    Provider_Code,
    POD_Code,
    CAM_Commissioner_Code,
    CAM_Assignment_Reason
FROM [Analytics].[tbl_Fact_IP_Activity]
WHERE CAM_Commissioner_Code IS NULL;
```

**Common Causes:**
- CAM enrichment not run yet
- Source data missing GP practice
- Specialist commissioning not in CAM lookup
- CAM precompute table empty

---

### Issue: Duplicates after re-run (idempotency fail)

**Investigation:**
```sql
-- Find duplicate encounters
SELECT SK_EncounterID, COUNT(*) AS [Duplicates]
FROM [Analytics].[tbl_Fact_IP_Activity]
GROUP BY SK_EncounterID
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;

-- Check ETL logs
SELECT * FROM [Analytics].[tbl_ETL_Batch_Log]
ORDER BY Batch_Start_DateTime DESC;
```

**Common Causes:**
- Delete logic not working (window mismatch)
- Fact loader not using TRUNCATE or DELETE pattern
- Concurrent loads running

---

### Issue: Performance slower than expected

**Investigation:**
```sql
-- Check table sizes
SELECT
    t.name AS TableName,
    SUM(p.rows) AS [Rows],
    SUM(a.total_pages) * 8 / 1024 AS [Size_MB]
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE SCHEMA_NAME(t.schema_id) = 'Analytics'
    AND t.name LIKE 'tbl_Fact%'
GROUP BY t.name;

-- Check for missing indexes
EXEC sp_helpindex '[Analytics].[tbl_Fact_IP_Activity]';
```

**Common Causes:**
- Columnstore index not created
- Statistics not updated
- Tempdb contention
- Network latency to upstream views

---

## Sign-Off Requirements

Before proceeding to Power BI deployment:

### Technical Sign-Off
- [ ] All validation tests PASS
- [ ] Idempotency confirmed
- [ ] Performance acceptable
- [ ] No critical errors in logs

### Business Sign-Off
- [ ] Finance approves cost reconciliation (<2% variance)
- [ ] Clinical team confirms data quality acceptable
- [ ] Data governance approves for production use

### Documentation Sign-Off
- [ ] Known limitations documented
- [ ] User guide drafted
- [ ] Support process defined

---

## Next Steps

After successful validation:

1. **Load Full 6-Month Window** (if not already done)
2. **Build Power BI Semantic Model**
   - Import dimensions
   - DirectQuery to facts
   - Configure incremental refresh
   - Set up aggregations
3. **Deploy Standard Reports**
   - Core20PLUS5 dashboard
   - Activity overview
   - Health equity reports
4. **User Acceptance Testing**
   - Train power users
   - Gather feedback
   - Iterate on reports

---

## References

- **Validation Script:** `docs/TESTING_VALIDATION_SCRIPTS.sql`
- **Runbook:** `docs/operations/00_RUNBOOK.md`
- **Execution Handbook:** `docs/operations/EXECUTION_HANDBOOK.md`
- **Technical Spec:** `docs/TECHNICAL_SPECIFICATION.md`
- **Start Here:** `docs/operations/START_HERE.md`

---

**Last Updated:** 2026-01-15
**Maintained By:** SWL ICB Analytics Team

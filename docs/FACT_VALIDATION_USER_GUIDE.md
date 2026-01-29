# Fact Data Validation User Guide

## Overview

The `[Analytics].[sp_Validate_Fact_Data]` stored procedure performs comprehensive automated validation comparing Analytics fact tables against Unified source data. It uses the **exact same column mappings** as the fact loader procedures to ensure consistency.

---

## Quick Start

### Basic Usage

```sql
EXEC [Analytics].[sp_Validate_Fact_Data]
    @FromDate = '2025-04-01',
    @ToDate = '2025-12-31';
```

### Full Parameters

```sql
EXEC [Analytics].[sp_Validate_Fact_Data]
    @FromDate = '2025-04-01',           -- Start date for validation
    @ToDate = '2025-12-31',             -- End date for validation
    @VarianceThresholdPct = 1.0,        -- Acceptable row count variance (default 1%)
    @UnknownThresholdPct = 5.0,         -- Acceptable unknown member rate (default 5%)
    @MaterialityThreshold = 100,        -- Min records for code to be flagged (default 100)
    @FailOnError = 0;                   -- Raise error if failures (0=No, 1=Yes)
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `@FromDate` | DATE | 2025-04-01 | Start of validation period |
| `@ToDate` | DATE | 2025-12-31 | End of validation period |
| `@VarianceThresholdPct` | DECIMAL(5,2) | 1.0 | Maximum allowed variance % for row counts |
| `@UnknownThresholdPct` | DECIMAL(5,2) | 5.0 | Maximum allowed % of records pointing to Unknown members |
| `@MaterialityThreshold` | INT | 100 | Minimum record count for a dimension code to be flagged as material issue |
| `@FailOnError` | BIT | 0 | If 1, raises SQL error when any test fails (useful for automated pipelines) |

---

## Source Tables

The procedure validates against these Unified source tables (same as fact loaders):

| Domain | Source Table | Target Table |
|--------|--------------|--------------|
| **IP (Inpatient)** | `[Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active]` | `[Analytics].[tbl_Fact_IP_Activity]` |
| **OP (Outpatient)** | `[Data_Lab_SWL].[Unified].[tbl_OP_EncounterDenormalised_Active]` | `[Analytics].[tbl_Fact_OP_Activity]` |

---

## Validation Sections

### Section 1: Row Count Validation

**Purpose:** Ensures total record counts match between source and target.

**What it checks:**
- IP: Records where `End_Date_Hospital_Provider_Spell` (source) = `Discharge_Date` (target)
- OP: Records where `Appointment_Date` matches in both

**PASS condition:** Variance ≤ `@VarianceThresholdPct`

**Interpretation:**

| Result | Meaning | Action |
|--------|---------|--------|
| PASS | Row counts match within threshold | No action needed |
| FAIL (Target < Source) | Records missing from Analytics | Check loader procedure ran successfully; investigate filters |
| FAIL (Target > Source) | Extra records in Analytics | Possible duplicate loads; check for orphan records |

**Further Investigation:**

```sql
-- Compare exact counts by month
SELECT
    FORMAT(End_Date_Hospital_Provider_Spell, 'yyyy-MM') AS Month,
    COUNT(*) AS Source_Count
FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active]
WHERE End_Date_Hospital_Provider_Spell BETWEEN '2025-04-01' AND '2025-12-31'
GROUP BY FORMAT(End_Date_Hospital_Provider_Spell, 'yyyy-MM')
ORDER BY Month;

SELECT
    FORMAT(Discharge_Date, 'yyyy-MM') AS Month,
    COUNT(*) AS Target_Count
FROM [Analytics].[tbl_Fact_IP_Activity]
WHERE Discharge_Date BETWEEN '2025-04-01' AND '2025-12-31'
GROUP BY FORMAT(Discharge_Date, 'yyyy-MM')
ORDER BY Month;
```

---

### Section 2: Monthly Distribution

**Purpose:** Validates row counts match by month to detect partial loads or data gaps.

**What it checks:**
- Compares record counts for each month in the date range
- Highlights months with variance > threshold

**Interpretation:**

| Result | Meaning | Action |
|--------|---------|--------|
| PASS | All months within threshold | No action needed |
| FAIL (specific month) | That month has data discrepancy | Re-run loader for that month; check source data |
| Missing month in target | Loader didn't process that month | Run incremental load for missing period |

**Further Investigation:**

```sql
-- Find specific dates with mismatches (IP example)
WITH SourceDates AS (
    SELECT CAST(End_Date_Hospital_Provider_Spell AS DATE) AS ActivityDate, COUNT(*) AS Cnt
    FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active]
    WHERE End_Date_Hospital_Provider_Spell BETWEEN '2025-04-01' AND '2025-04-30'
    GROUP BY CAST(End_Date_Hospital_Provider_Spell AS DATE)
),
TargetDates AS (
    SELECT CAST(Discharge_Date AS DATE) AS ActivityDate, COUNT(*) AS Cnt
    FROM [Analytics].[tbl_Fact_IP_Activity]
    WHERE Discharge_Date BETWEEN '2025-04-01' AND '2025-04-30'
    GROUP BY CAST(Discharge_Date AS DATE)
)
SELECT
    COALESCE(s.ActivityDate, t.ActivityDate) AS ActivityDate,
    ISNULL(s.Cnt, 0) AS Source_Count,
    ISNULL(t.Cnt, 0) AS Target_Count,
    ISNULL(t.Cnt, 0) - ISNULL(s.Cnt, 0) AS Difference
FROM SourceDates s
FULL OUTER JOIN TargetDates t ON s.ActivityDate = t.ActivityDate
WHERE ISNULL(s.Cnt, 0) <> ISNULL(t.Cnt, 0)
ORDER BY ActivityDate;
```

---

### Section 3: Dimension Distribution (Enhanced v2.0)

**Purpose:** Validates that dimension code distributions match between source and target using a comprehensive health-score approach.

**Dimensions Checked:**
- Commissioner (with `00` suffix truncation logic)
- Provider (with `00` suffix truncation logic)
- Specialty (Treatment_Function_Code)
- Gender
- Admission Method (IP only)
- Discharge Method (IP only)
- GP Practice
- Attendance Status (OP only)

**What it checks:**
- Compares ALL codes between source and target (no arbitrary TOP 5 limit)
- Calculates a **Health Score** for each dimension
- Flags **material issues** (codes with ≥100 records that exceed variance threshold)
- Reports total record discrepancy per dimension

**New Parameter:**
```sql
@MaterialityThreshold INT = 100  -- Minimum records for a code to be flagged as material
```

**Output Levels:**

| Level | What it shows |
|-------|---------------|
| **Health Summary** | Overall health per dimension with match rate % and status |
| **Material Issues** | All codes exceeding threshold with ≥@MaterialityThreshold records |
| **Full Detail** | Available in temp table for drill-down if needed |

**Health Status Interpretation:**

| Status | Match Rate | Meaning |
|--------|------------|---------|
| EXCELLENT | ≥99% | Nearly all codes match perfectly |
| GOOD | 95-99% | Most codes match, minor issues |
| ACCEPTABLE | 90-95% | Some variance, review recommended |
| NEEDS ATTENTION | <90% | Significant issues, action required |

**Material Issue Criteria:**

A code is flagged as a material issue when BOTH conditions are met:
1. Record count ≥ `@MaterialityThreshold` (default 100)
2. Variance exceeds `@VarianceThresholdPct` (default 1%)

This prevents noise from low-volume codes while ensuring impactful issues are caught.

**Example Health Summary Output:**

| Domain | Dimension | Total Codes | Matched | Mismatched | Match Rate | Status |
|--------|-----------|-------------|---------|------------|------------|--------|
| IP | Commissioner | 45 | 44 | 1 | 97.78% | GOOD |
| IP | Provider | 120 | 115 | 5 | 95.83% | GOOD |
| IP | GP Practice | 890 | 812 | 78 | 91.24% | ACCEPTABLE |

**Further Investigation:**

```sql
-- Investigate Commissioner distribution mismatch
SELECT
    CASE WHEN RIGHT(Organisation_Code_Code_of_Commissioner, 2) = '00'
         THEN LEFT(Organisation_Code_Code_of_Commissioner, 3)
         ELSE Organisation_Code_Code_of_Commissioner END AS Commissioner_Code,
    COUNT(*) AS Source_Count
FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active]
WHERE End_Date_Hospital_Provider_Spell BETWEEN '2025-04-01' AND '2025-12-31'
GROUP BY CASE WHEN RIGHT(Organisation_Code_Code_of_Commissioner, 2) = '00'
              THEN LEFT(Organisation_Code_Code_of_Commissioner, 3)
              ELSE Organisation_Code_Code_of_Commissioner END
ORDER BY Source_Count DESC;

-- Check if code exists in dimension
SELECT * FROM [Analytics].[tbl_Dim_Commissioner]
WHERE Commissioner_Code = 'QWE';  -- Replace with failing code
```

---

### Section 4: Referential Integrity (Orphan Detection)

**Purpose:** Detects fact records with foreign keys that don't exist in dimension tables.

**What it checks:**
- Commissioner orphans
- GP Practice orphans
- Provider orphans
- Specialty orphans

**PASS condition:** Zero orphan records

**Interpretation:**

| Result | Meaning | Action |
|--------|---------|--------|
| PASS | All FKs have valid dimension members | No action needed |
| FAIL | Orphan records exist | Serious issue - dimension key doesn't exist |

**Why this matters:**
Orphan records will cause inner joins to fail and data will be missing from reports. This typically indicates:
1. Dimension was deleted after facts were loaded
2. Loader bug using wrong surrogate key
3. Database corruption

**Further Investigation:**

```sql
-- Find orphan Commissioner records
SELECT f.SK_CommissionerID, COUNT(*) AS Orphan_Count
FROM [Analytics].[tbl_Fact_IP_Activity] f
LEFT JOIN [Analytics].[tbl_Dim_Commissioner] d ON f.SK_CommissionerID = d.SK_CommissionerID
WHERE d.SK_CommissionerID IS NULL
GROUP BY f.SK_CommissionerID;

-- Trace back to source data
SELECT TOP 100
    f.*,
    'Orphan - SK_CommissionerID=' + CAST(f.SK_CommissionerID AS VARCHAR) AS Issue
FROM [Analytics].[tbl_Fact_IP_Activity] f
LEFT JOIN [Analytics].[tbl_Dim_Commissioner] d ON f.SK_CommissionerID = d.SK_CommissionerID
WHERE d.SK_CommissionerID IS NULL;
```

---

### Section 5: Unknown/Default Member Rates

**Purpose:** Monitors the percentage of records assigned to Unknown (SK = -1) dimension members.

**What it checks:**
- Commissioner Unknown rate
- GP Practice Unknown rate
- Provider Unknown rate
- Specialty Unknown rate

**PASS condition:** Unknown % ≤ `@UnknownThresholdPct`

**Interpretation:**

| Result | Meaning | Action |
|--------|---------|--------|
| PASS | Unknown rate acceptable | Normal data quality |
| FAIL (slightly over) | More unknowns than expected | Review dimension loader; may need new members |
| FAIL (significantly over) | Major data quality issue | Source data may have NULL/invalid codes |

**What "Unknown" means:**
- SK = -1 is the Unknown member in each dimension
- Facts get assigned to Unknown when the source code doesn't match any dimension member
- This is intentional (prevents orphans) but high rates indicate issues

**Further Investigation:**

```sql
-- Find what source codes are mapping to Unknown Commissioner
SELECT
    CASE WHEN RIGHT(s.Organisation_Code_Code_of_Commissioner, 2) = '00'
         THEN LEFT(s.Organisation_Code_Code_of_Commissioner, 3)
         ELSE s.Organisation_Code_Code_of_Commissioner END AS Source_Code,
    COUNT(*) AS Record_Count
FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active] s
WHERE s.End_Date_Hospital_Provider_Spell BETWEEN '2025-04-01' AND '2025-12-31'
  AND NOT EXISTS (
      SELECT 1 FROM [Analytics].[tbl_Dim_Commissioner] d
      WHERE d.Commissioner_Code = CASE WHEN RIGHT(s.Organisation_Code_Code_of_Commissioner, 2) = '00'
                                       THEN LEFT(s.Organisation_Code_Code_of_Commissioner, 3)
                                       ELSE s.Organisation_Code_Code_of_Commissioner END
  )
GROUP BY CASE WHEN RIGHT(s.Organisation_Code_Code_of_Commissioner, 2) = '00'
              THEN LEFT(s.Organisation_Code_Code_of_Commissioner, 3)
              ELSE s.Organisation_Code_Code_of_Commissioner END
ORDER BY Record_Count DESC;
```

---

### Section 6: Missing Dimension Members

**Purpose:** Identifies source codes that exist in activity data but not in dimension tables.

**What it checks:**
- All major dimensions for both IP and OP
- Returns the code and how many source records have that code

**This section complements Section 5:**
- Section 5 tells you the *rate* of unknowns
- Section 6 tells you *which specific codes* are missing

**Interpretation:**

| Finding | Meaning | Action |
|---------|---------|--------|
| No missing members | All source codes have dimension entries | Good data quality |
| Missing with high count | Important code needs adding | Add to dimension table |
| Missing with low count | Rare code, possibly invalid | Verify in NHS Data Dictionary |

**Resolution Steps:**

1. Check if code is valid in NHS Data Dictionary (Section 7)
2. If valid: Add to dimension table
3. If invalid: Report to data quality team / source system owners

**Example: Adding missing Commissioner:**

```sql
-- Check if code is in NHS Dictionary
SELECT * FROM [Dictionary].[dbo].[Commissioner]
WHERE CommissionerCode = 'QWE';

-- If valid, add to dimension
INSERT INTO [Analytics].[tbl_Dim_Commissioner] (Commissioner_Code, Commissioner_Name, ...)
SELECT CommissionerCode, CommissionerName, ...
FROM [Dictionary].[dbo].[Commissioner]
WHERE CommissionerCode = 'QWE';
```

---

### Section 7: Dictionary Validation

**Purpose:** Cross-references source codes against NHS Data Dictionary to determine if they are valid NHS codes.

**What it checks:**
- Discharge Method codes against `[Dictionary].[IP].[DischargeMethod]`
- Admission Method codes against `[Dictionary].[IP].[AdmissionMethods]`
- Commissioner codes against `[Dictionary].[dbo].[Commissioner]`
- Specialty codes against `[Dictionary].[dbo].[Specialties]`
- Provider codes against `[Dictionary].[dbo].[Organisation]`
- GP Practice codes against `[Dictionary].[dbo].[Organisation]`

**Action Required values:**

| Action | Meaning | Resolution |
|--------|---------|------------|
| `Add to Dimension (valid NHS code)` | Code is in NHS Dictionary but not in Analytics dimension | Add the code to the dimension table |
| `Invalid code (not in NHS Dictionary)` | Code is not recognised by NHS | Report to source system; may be data entry error |
| `OK` | Code is properly configured | No action needed |

**Interpretation Flowchart:**

```
Source Code Found
       │
       ▼
In NHS Dictionary?
       │
   ┌───┴───┐
   │       │
  Yes      No
   │       │
   ▼       ▼
In Analytics    "Invalid code"
Dimension?      (Report to source)
   │
┌──┴──┐
│     │
Yes   No
│     │
▼     ▼
OK   "Add to Dimension"
```

**Further Investigation:**

```sql
-- Check specific code in dictionary
SELECT * FROM [Dictionary].[IP].[DischargeMethod]
WHERE BK_DischargeMethodCode = '29';

-- List all valid Admission Methods from dictionary
SELECT BK_AdmissionMethodCode, Admission_Method_Description
FROM [Dictionary].[IP].[AdmissionMethods]
ORDER BY BK_AdmissionMethodCode;
```

---

## Output Result Sets

The procedure returns multiple result sets:

### Result Set 1: Detailed Test Results

| Column | Description |
|--------|-------------|
| Test_ID | Sequential test number |
| Domain | IP or OP |
| Test_Category | Row Count, Monthly, Distribution, etc. |
| Test_Name | Specific test description |
| Source_Value | Count from Unified source |
| Target_Value | Count from Analytics target |
| Variance_Pct | Calculated variance percentage |
| Threshold_Pct | Configured threshold |
| Status | PASS or FAIL |
| Details | Human-readable summary |

### Result Set 2: Summary

| Column | Description |
|--------|-------------|
| Total_Tests | Number of tests run |
| Passed | Count of passed tests |
| Failed | Count of failed tests |
| Overall_Status | PASS (all passed) or FAIL |

### Result Set 3: Distribution Health Summary (NEW)

Shows overall health of each dimension's distribution comparison.

| Column | Description |
|--------|-------------|
| Domain | IP or OP |
| Dimension_Name | Which dimension |
| Total_Codes | Number of distinct codes compared |
| Codes_Matched | Codes within variance threshold |
| Codes_Mismatched | Codes exceeding threshold |
| Total_Source_Records | Sum of all source records |
| Total_Target_Records | Sum of all target records |
| Total_Record_Discrepancy | Absolute sum of all differences |
| Match_Rate_Pct | Percentage of codes that match |
| Health_Status | EXCELLENT / GOOD / ACCEPTABLE / NEEDS ATTENTION |

### Result Set 4: Distribution Issues (NEW)

All material codes exceeding the variance threshold (no TOP 5 limit).

| Column | Description |
|--------|-------------|
| Domain | IP or OP |
| Dimension_Name | Which dimension |
| Code | The dimension code |
| Source_Count | Records in source |
| Target_Count | Records in target |
| Difference | Target - Source (negative = missing) |
| Variance_Pct | Percentage variance |

### Result Set 5: Missing Dimension Members

Only returned if missing members found.

| Column | Description |
|--------|-------------|
| Domain | IP or OP |
| Dimension_Name | Which dimension |
| Missing_Code | The code not in dimension |
| Source_Record_Count | How many records have this code |

### Result Set 6: Dictionary Validation

Only returned if issues found.

| Column | Description |
|--------|-------------|
| Domain | IP, OP, or IP/OP |
| Dimension_Name | Which dimension |
| Code | The code being validated |
| Source_Record_Count | How many records |
| In_NHS_Dictionary | Yes/No |
| In_Analytics_Dimension | Yes/No |
| Action_Required | What to do |

---

## Common Scenarios and Resolution

### Scenario 1: Row Count Mismatch After ETL

**Symptom:** FAIL on Row Count, Target < Source

**Investigation:**
```sql
-- Check if loader ran for the period
SELECT * FROM [Analytics].[ETL_Log]
WHERE Process_Name LIKE '%IP%'
  AND Run_Date >= DATEADD(day, -7, GETDATE())
ORDER BY Run_Date DESC;

-- Check for loader errors
SELECT * FROM [Analytics].[ETL_Error_Log]
WHERE Error_Date >= DATEADD(day, -7, GETDATE());
```

**Resolution:**
1. Re-run the fact loader for affected date range
2. Verify no filter conditions are excluding records

---

### Scenario 2: High Unknown Rate for GP Practice

**Symptom:** FAIL on Unknown GP Practice Rate (e.g., 12%)

**Investigation:**
```sql
-- What codes are mapping to Unknown?
SELECT
    s.GP_Practice_Code_Original_Data,
    COUNT(*) AS Record_Count
FROM [Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active] s
LEFT JOIN [Analytics].[tbl_Dim_GPPractice] d ON d.GPPractice_Code = s.GP_Practice_Code_Original_Data
WHERE s.End_Date_Hospital_Provider_Spell BETWEEN '2025-04-01' AND '2025-12-31'
  AND d.GPPractice_Code IS NULL
GROUP BY s.GP_Practice_Code_Original_Data
ORDER BY Record_Count DESC;
```

**Resolution:**
1. Refresh GP Practice dimension from NHS Digital ODS
2. Add missing practices to dimension
3. Re-run fact loader

---

### Scenario 3: New Specialty Code Appearing

**Symptom:** Missing Dimension Member for Specialty code '999'

**Investigation:**
```sql
-- Check if valid NHS code
SELECT * FROM [Dictionary].[dbo].[Specialties]
WHERE BK_SpecialtyCode = '999';
```

**Resolution:**
- If valid: Add to `[Analytics].[tbl_Dim_Specialty]`
- If invalid: Escalate to data quality team

---

## Automation

### Using in ETL Pipeline

```sql
-- Run validation after fact load, fail pipeline if issues
EXEC [Analytics].[sp_Validate_Fact_Data]
    @FromDate = '2025-04-01',
    @ToDate = '2025-12-31',
    @FailOnError = 1;  -- Will RAISERROR if any failures
```

### Scheduled Daily Validation

```sql
-- Run daily for previous month
DECLARE @StartDate DATE = DATEADD(month, -1, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1));
DECLARE @EndDate DATE = EOMONTH(@StartDate);

EXEC [Analytics].[sp_Validate_Fact_Data]
    @FromDate = @StartDate,
    @ToDate = @EndDate;
```

---

## Best Practices

1. **Run after every ETL load** - Catch issues early
2. **Monitor trends** - Track unknown rates over time
3. **Address failures promptly** - Don't let issues accumulate
4. **Review thresholds periodically** - Adjust based on data maturity
5. **Document exceptions** - Some variances may be expected (e.g., late-arriving data)

---

## Related Documentation

- [TESTING_WORKFLOW.md](TESTING_WORKFLOW.md) - Overall testing strategy
- [VALIDATION_UPDATE_SUMMARY.md](VALIDATION_UPDATE_SUMMARY.md) - Recent validation architecture changes

---

## Contact

For questions about this validation procedure, contact the Data Engineering team.

*Last Updated: January 2026*

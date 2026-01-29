# NHS ODS Dimensions - Operational Guide

**Created:** 2026-01-02 17:52 UTC  
**Updated:** 2026-01-05 17:36 UTC  
**Purpose:** Step-by-step guide to create and load Commissioner, GP Practice, and PCN dimensions from NHS Digital ODS CSV files

---

## 📋 Overview

**What we're building:**
- ✅ `Dim_Commissioner` - ICBs and Sub-ICBs (147 records)
- ✅ `Dim_GPPractice` - GP Practices (15,352 records nationally, 374 in SWL ICB)  
- ✅ `Dim_PCN` - Primary Care Networks (1,389 records)
- ✅ `Ref_Prescribing_Setting` - Prescribing role codes (23 codes)

**Data source:** NHS Organisation Data Service (ODS) CSV files (epraccur, epcn, prescribing_roles)

---

## 🎯 Step-by-Step Implementation

### **STEP 1: Download NHS Digital CSV Files**

Download the latest ODS data files to `sql/analytics_platform/05_api/raw_inspection/`:

**Required Files:**
1. **epraccur.csv** - GP Practice master data (15,352 practices)
   - Source: https://www.odsdatasearchandexport.nhs.uk/api/getReport?report=epraccur
   - Contains: Practice details, ICB codes, addresses, prescribing settings

2. **epcn.csv** - PCN (Primary Care Network) master data (1,389 PCNs)
   - Source: https://www.odsdatasearchandexport.nhs.uk/api/getReport?report=epcn
   - Contains: PCN details, Sub-ICB relationships, addresses

3. **prescribing_roles.csv** - Prescribing role reference data (23 roles)
   - Manually maintained reference file
   - Maps role codes (RO76, RO72, etc.) to descriptions

**Download Commands:**
```bash
cd /home/speddi/dev/icb/sustabular/sql/analytics_platform/05_api/raw_inspection

# Download GP Practices
curl -o epraccur.csv "https://www.odsdatasearchandexport.nhs.uk/api/getReport?report=epraccur"

# Download PCNs
curl -o epcn.csv "https://www.odsdatasearchandexport.nhs.uk/api/getReport?report=epcn"
```

---

### **STEP 2: Generate SQL Load Scripts**

Run Python parsers to convert CSV files to SQL INSERT statements:

```bash
cd /home/speddi/dev/icb/sustabular

# Parse GP Practices (generates SQL in 05_api/)
python3 scripts/data_integration/nhs_ods/parse_epraccur.py

# Parse PCNs (generates SQL in 05_api/)
python3 scripts/data_integration/nhs_ods/parse_epcn.py

# Parse Prescribing Roles (generates SQL in 03_static_data/)
python3 scripts/data_integration/nhs_ods/parse_prescribing_roles.py
```

**Generated Files:**
- `05_api/gp_practices_epraccur_YYYYMMDD_HHMMSS.sql`
- `05_api/pcn_master_YYYYMMDD_HHMMSS.sql`
- `03_static_data/01_Load_Ref_Prescribing_Setting.sql`

---

### **STEP 3: Setup Environment (DDL)**

Execute these SQL scripts **in folder order**:

#### **3.1 Core Setup**
```bash
cd sql/analytics_platform
```

1. `00_setup/01_Create_Analytics_Schema.sql` - Creates [Analytics] schema
2. `00_setup/03_Create_ETL_Logging.sql` - Creates ETL logging tables & SPs
3. `00_setup/04_Create_Staging_NHS_ODS.sql` - Creates staging tables:
   - `tbl_Staging_NHS_ODS_Commissioner`
   - `tbl_Staging_GP_Practice`
   - `tbl_Staging_PCN`

#### **3.2 Create Dimensions**
4. `01_dimensions/01_Create_Dim_Commissioner.sql`
5. `01_dimensions/02_Create_Dim_POD.sql`
6. `01_dimensions/03_Create_Dim_GPPractice.sql`
7. `01_dimensions/04_Create_Dim_PCN.sql`
8. `01_dimensions/05_Create_Dim_Measures_Catalogue.sql`

#### **3.3 Create ETL Procedures**
9. `04_etl/01_Load_Dim_Commissioner.sql`
10. `04_etl/02_Load_Dim_GPPractice.sql`
11. `04_etl/03_Load_Dim_PCN.sql`

---

### **STEP 4: Load Data**

#### **4.1 Load Static/Reference Data:**
```sql
-- POD dimension (static)
:r ./01_dimensions/05_Populate_Dim_POD.sql

-- Prescribing role reference
:r ./03_static_data/01_Load_Ref_Prescribing_Setting.sql
```

#### **4.2 Load Staging Data:**
Execute the auto-generated SQL files:

```sql
-- Load GP Practices (use latest timestamp file)
:r ./05_api/gp_practices_epraccur_20260105_171244.sql

-- Load PCNs (use latest timestamp file)
:r ./05_api/pcn_master_20260105_173529.sql
```

> **Note**: Update filenames with your actual timestamps

---

### **STEP 5: Run ETL**

Execute ETL procedures to populate dimension tables from staging:

```sql
-- Run all ETLs in order
EXEC [Analytics].[sp_Load_Dim_Commissioner];
EXEC [Analytics].[sp_Load_Dim_PCN];
EXEC [Analytics].[sp_Load_Dim_GPPractice];
```

**Or use the master runner:**
```sql
:r ./04_etl/00_Run_All_Dimension_Loads.sql
```

---

## 🚀 Quick Start (Docker Local Development)

For local Docker SQL Server setup, use the consolidated deployment script:

```bash
cd /home/speddi/dev/icb/sustabular

# Start Docker SQL Server
./scripts/dev/start_db.sh

# Deploy entire schema + data
./scripts/dev/deploy_to_docker.sh
```

**What this does:**
- Creates all schemas, staging tables, and dimensions
- Creates all ETL stored procedures
- Loads static data (POD, Prescribing Roles)
- Loads staging data (GP Practices, PCNs)
- Runs ETL to populate dimensions

**Connection:**
- Server: `localhost:1433`
- User: `sa`
- Password: `Password123!`
- Database: `Data_Lab_SWL_Live`

---

## 📊 Data Verification

After ETL completion, verify row counts:

```sql
-- Staging tables
SELECT COUNT(*) FROM [Analytics].[tbl_Staging_GP_Practice];  -- Expected: 15,352
SELECT COUNT(*) FROM [Analytics].[tbl_Staging_PCN];          -- Expected: 1,389

-- Dimension tables
SELECT COUNT(*) FROM [Analytics].[Dim_GPPractice] WHERE Is_Current = 1;  -- Expected: ~15,356 (includes defaults)
SELECT COUNT(*) FROM [Analytics].[Dim_PCN] WHERE Is_Current = 1;         -- Expected: ~1,390 (includes defaults)

-- ICB distribution (should show 43 distinct ICBs, not all hardcoded to one)
SELECT ICB_Code, ICB_Grouping, COUNT(*) AS Practice_Count
FROM [Analytics].[Dim_GPPractice]
WHERE Is_Current = 1
GROUP BY ICB_Code, ICB_Grouping
ORDER BY COUNT(*) DESC;
```

**Expected ICB Distribution:**
- **QWE** = 374 practices (NHS South West London ICB) 
- **QOP** = 879 practices (largest ICB)
- **QHM**, **QYG**, **QWO**, etc. = Various other ICBs
- **Total**: 43 distinct ICBs

---

## 📁 Key Files Reference

### **Parser Scripts** (`scripts/data_integration/nhs_ods/`)
- `parse_epraccur.py` - Converts epraccur.csv → SQL INSERTs for GP Practices
- `parse_epcn.py` - Converts epcn.csv → SQL INSERTs for PCNs
- `parse_prescribing_roles.py` - Converts prescribing_roles.csv → SQL INSERTs

### **Staging Tables**
- `tbl_Staging_GP_Practice` - 19 columns from epraccur.csv
- `tbl_Staging_PCN` - 11 columns from epcn.csv

### **Dimension Tables**
- `Dim_GPPractice` - SCD Type 2, includes ICB hierarchy
- `Dim_PCN` - SCD Type 2
- `Dim_Commissioner` - ICBs and Sub-ICBs
- `Ref_Prescribing_Setting` - Role code lookup

---

## 🔄 Refresh Process

To refresh with latest ODS data:

1. Download new CSV files (STEP 1)
2. Run parsers to generate new SQL (STEP 2)
3. Load new staging data (STEP 4.2)
4. Re-run ETL (STEP 5)

The ETL procedures handle SCD Type 2 logic automatically:
- New practices: Inserted with `Is_Current = 1`
- Changed practices: Old row gets `Is_Current = 0`, new row inserted
- Unchanged practices: No action

---

## ⚠️ Common Issues

### Issue: All practices show ICB_Code = '36L'
**Cause**: ETL hardcoding instead of using staging data  
**Fix**: Ensure ETL uses `Stg.ICB_Code` column (Column 4 from epraccur)

### Issue: Truncation errors during load
**Cause**: Column lengths too small  
**Fix**: Widen `Prescribing_Setting` to VARCHAR(255)

### Issue: Parser not finding CSV files
**Cause**: Files not in raw_inspection folder  
**Fix**: Download CSVs to `sql/analytics_platform/05_api/raw_inspection/`

---

**Last Updated:** 2026-01-05 17:36 UTC

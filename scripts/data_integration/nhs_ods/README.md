# NHS ODS Data Integration

This directory contains scripts and documentation for integrating NHS Organisation Data Service (ODS) data into the SWL ICB HighSpring.

## **Purpose**

Replace dependency on `Dictionary.dbo.Commissioner` with authoritative NHS ODS data fetched directly from the national API.

## **Architecture - Kimball Dimensional Modeling**

```
NHS ODS API
    ↓
[Python Fetch Script]
    ↓
tbl_Staging_NHS_ODS_Commissioner (landing zone)
    ↓
[ETL Procedure with Validation]
    ↓
Dim_Commissioner (dimension table)
```

### **Kimball Principles Applied:**

1. **Source System Extract** - Complete extraction of ICBs and Sub-ICB Locations
2. **Staging Layer** - Raw data preservation with full audit trail
3. **Data Quality** - Validation before loading to dimension
4. **Slowly Changing Dimensions** - SCD Type 1 (with Type 2 upgrade path)
5. **Surrogate Keys** - Independent of natural keys for flexibility

---

## **Files in This Directory**

| File | Purpose | Database Agnostic |
|------|---------|-------------------|
| `fetch_commissioners.py` | Fetch specific organization(s) | ✅ Yes |
| `fetch_all_commissioners.py` | **Fetch complete ICB/Sub-ICB dataset** | ✅ Yes |
| `run_ods_integration.py` | Orchestrate full ETL workflow | ✅ Yes |
| `fetch_gp_practices_csv.py` | **Fetch GP practices (EPRACCUR) via CSV API** | ✅ Yes |
| `fetch_pcn.py` | **Fetch PCNs (EPCN) via CSV API** | ✅ Yes |
| `nhs_ods_*.json` | Raw API responses (archive) | N/A |
| `nhs_ods_*.sql` | Generated staging INSERT statements | ✅ Yes |

**Note:** Legacy GP/PCN scripts have been moved to `scripts/data_integration/nhs_ods/archive/`.

---

## **Quick Start**

### **1. Fetch Complete Dataset**

```bash
# Fetch all ICBs and Sub-ICB Locations (both active and inactive)
cd /home/speddi/dev/icb/sustabular
python3 scripts/data_integration/nhs_ods/fetch_all_commissioners.py \
    --output both \
    --db-type sqlserver \
    --status All

# Output:
#   nhs_ods_complete_YYYYMMDD_HHMMSS.json   (raw data)
#   nhs_ods_complete_sqlserver_YYYYMMDD_HHMMSS.sql  (staging INSERT)
```

###  **2. Load to Staging Table**

```sql
-- Execute generated SQL file in SSMS or Azure Data Studio
-- File: scripts/data_integration/nhs_ods/nhs_ods_complete_sqlserver_*.sql

-- Verify load
SELECT COUNT(*), Commissioner_Type, Status
FROM [Analytics].[tbl_Staging_NHS_ODS_Commissioner]
GROUP BY Commissioner_Type, Status;
```

### **3. Run ETL Procedure**

```sql
-- Load from staging to Dim_Commissioner
EXEC [Analytics].[sp_Load_Dim_Commissioner_From_ODS];

-- Validate
SELECT * 
FROM [Analytics].[Dim_Commissioner]
WHERE Commissioner_Code IN ('36L', '07V', '08J', '08P', '08R', '08T', '08X');
```

---

## **Scheduled Refresh**

### **Frequency:** Weekly (Sunday 2 AM)

### **Windows Task Scheduler:**

```cmd
@echo off
cd /d C:\path\to\sustabular
python scripts\data_integration\nhs_ods\run_ods_integration.py --env prod --db-type sqlserver
```

### **Linux Cron:**

```cron
0 2 * * 0 cd /home/speddi/dev/icb/sustabular && python3 scripts/data_integration/nhs_ods/run_ods_integration.py --env prod
```

---

## **Data Summary (as of Jan 2026)**

Based on NHS ODS API:

- **Total ICBs:** 42 (covering all of England)
- **Total Sub-ICB Locations:** ~200+ (former CCGs)  
- **SWL Specific:**
  - 1 ICB: `36L` (NHS South West London ICB)
  - 6 Predecessor CCGs: `07V, 08J, 08P, 08R, 08T, 08X`

### **SWL Commissioner Codes:**

| Code | Name | Type | Status |
|------|------|------|--------|
| 36L | NHS South West London ICB - 36L | Sub-ICB (former CCG) | Active |
| 07V | NHS Croydon CCG | CCG (Legacy) | Inactive |
| 08J | NHS Kingston CCG | CCG (Legacy) | Inactive |
| 08P | NHS Richmond CCG | CCG (Legacy) | Inactive |
| 08R | NHS Merton CCG | CCG (Legacy) | Inactive |
| 08T | NHS Sutton CCG | CCG (Legacy) | Inactive |
| 08X | NHS Wandsworth CCG | CCG (Legacy) | Inactive |

**Note:** Code 36L represents the merged entity (created April 1, 2020) and received Sub-ICB role (RO319) on July 1, 2022.

---

## **Snowflake Migration Support**

All scripts support Snowflake:

```bash
# Generate Snowflake-compatible SQL
python3 scripts/data_integration/nhs_ods/fetch_all_commissioners.py \
    --output staging \
    --db-type snowflake

# Output uses Snowflake syntax:
#   TO_DATE('2022-07-01', 'YYYY-MM-DD')
#   ANALYTICS.tbl_Staging_NHS_ODS_Commissioner
```

---

## **Troubleshooting**

### **API Rate Limiting**

The NHS ODS API has rate limits. The script includes:
- Retry logic (3 attempts)
- Backoff delays (1-2 seconds between requests)
- Batch delays (every 10 requests)

### **Missing Parent ICB Names**

If `Parent_ICB_Name` is NULL:
1. Check if parent ICB code exists in dataset
2. Run enrichment: script auto-populates from fetched records
3. Manual fix: Update staging table directly

### **Data Validation Failures**

Check `[Analytics].[tbl_Staging_NHS_ODS_Commissioner]` columns:
- `Validation_Status` - 'Valid', 'Invalid', 'Duplicate'
- `Validation_Notes` - Specific issues found

---

## **References**

- **NHS ODS Homepage:** https://digital.nhs.uk/services/organisation-data-service
- **ODS API Docs:** https://digital.nhs.uk/developer/api-catalogue/organisation-data-service-ordr4
- **Data Search & Export:** https://www.odsdatasearchandexport.nhs.uk/
- **Role Codes Reference:** https://www.odsdatasearchandexport.nhs.uk/referenceDataCatalogue/index.html

---

**Created:** 2026-01-02  
**Last Updated:** 2026-01-02

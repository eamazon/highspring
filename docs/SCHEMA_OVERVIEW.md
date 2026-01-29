# Analytics Platform Schema Overview

## Architecture Pattern

This analytics platform implements a **star schema** design pattern optimized for healthcare activity reporting.

## Star Schema Components

### Fact Tables (3)

Fact tables store measurable activity events at the lowest grain:

| Fact Table | Grain | Key Date | Measures |
|------------|-------|----------|----------|
| `Fact_IP_Activity` | Per inpatient spell | Discharge_Date | Bed days, spell duration, costs |
| `Fact_OP_Activity` | Per outpatient appointment | Appointment_Date | Attendance status, DNA flags, costs |
| `Fact_AE_Activity` | Per A&E attendance | Attendance_Date | Wait times, discharge status |

### Dimension Tables (26)

Dimensions provide descriptive context for fact records:

#### Core Healthcare Dimensions

| Dimension | Business Key | Description |
|-----------|--------------|-------------|
| `Dim_Date` | DateKey (YYYYMMDD) | Calendar dates with FY, Quarter, Month hierarchies |
| `Dim_Patient` | Patient_ID | Pseudonymised patient demographics (Age, Gender, Ethnicity) |
| `Dim_Provider` | Provider_Code | NHS Trust/Provider organizations |
| `Dim_Specialty` | BK_SpecialtyCode | Treatment Function/Specialty codes |
| `Dim_Consultant` | BK_ConsultantCode | Consultant identifiers |

#### Commissioning & Geography

| Dimension | Business Key | Description |
|-----------|--------------|-------------|
| `Dim_Commissioner` | Commissioner_Code | ICB/CCG commissioning organizations |
| `Dim_GPPractice` | GPPractice_Code | GP practice registrations |
| `Dim_PCN` | PCN_Code | Primary Care Network groupings |
| `Dim_LSOA` | LSOA_Code | Lower Super Output Area geography |
| `Dim_Ward` | Ward_Code | Electoral ward geography |
| `Dim_Locality` | Locality_Code | ICB locality groupings |

#### Clinical Classification

| Dimension | Business Key | Description |
|-----------|--------------|-------------|
| `Dim_Diagnosis` | BK_DiagnosisCode | ICD-10 diagnosis codes |
| `Dim_Procedure` | BK_ProcedureCode | OPCS-4 procedure codes |
| `Dim_HRG` | HRG_Code | Healthcare Resource Group classifications |

#### Activity Classification

| Dimension | Business Key | Description |
|-----------|--------------|-------------|
| `Dim_AdmissionMethod` | BK_AdmissionMethodCode | How patient was admitted |
| `Dim_DischargeDestination` | BK_DischargeDestCode | Where patient went after discharge |
| `Dim_TreatmentFunction` | BK_TreatmentFuncCode | Treatment specialty function |
| `Dim_AppointmentType` | BK_AppointmentTypeCode | Type of outpatient appointment |
| `Dim_AttendanceType` | BK_AttendanceTypeCode | First/Follow-up attendance |

#### Other Dimensions

- `Dim_ReferralSource` - Referral source
- `Dim_WaitingTimeType` - Waiting time categories
- `Dim_PriorityType` - Urgency of referral/appointment
- `Dim_MainSpecialty` - Main specialty of treatment
- `Dim_PodGroup` - Point of delivery grouping
- `Dim_ActivityType` - Type of activity
- `Dim_ServiceType` - Type of service provided

## Design Patterns

### Surrogate Keys

All tables use integer surrogate keys (SK) as primary keys:
- **Dimension SK**: Auto-incrementing integer starting from 1
- **Unknown Member**: SK = -1 in all dimensions
- **Fact FK**: Foreign keys reference dimension SK values

### Slowly Changing Dimensions (Type 2)

All dimensions implement SCD Type 2 tracking:
```sql
SK              INT             -- Surrogate key
BK_*            NVARCHAR        -- Business key from source
ValidFrom       DATE            -- Effective start date
ValidTo         DATE            -- Effective end date (9999-12-31 if current)
IsCurrent       BIT             -- 1 if current version, 0 if historical
```

### Unknown Members

Every dimension has an Unknown member at SK = -1:
- Used when source code doesn't match any dimension member
- Allows referential integrity without losing fact records
- Enables tracking of data quality issues

### Naming Conventions

#### Tables
- Dimensions: `[Analytics].[tbl_Dim_{Name}]`
- Facts: `[Analytics].[tbl_Fact_{Name}_Activity]`
- Views: `[Analytics].[vw_Dim_{Name}]`

#### Columns
- Surrogate keys: `{TableName}_SK`
- Business keys: `BK_{SourceField}` or `{Entity}_Code`
- Foreign keys: `FK_{DimensionName}_SK`
- Dates: `{Event}_Date` (e.g., Discharge_Date)

#### ETL Procedures
- Fact loaders: `sp_Load_Fact_{Name}_Activity`
- Validation: `sp_Validate_Fact_Data`

## Relationships

### Fact_IP_Activity Relationships

The Inpatient fact table has 22 dimension foreign keys:

| Foreign Key | Dimension | Relationship |
|-------------|-----------|--------------|
| FK_Discharge_Date_SK | Dim_Date | Many-to-One (Active) |
| FK_Admission_Date_SK | Dim_Date | Many-to-One (Inactive) |
| FK_Patient_SK | Dim_Patient | Many-to-One |
| FK_Provider_SK | Dim_Provider | Many-to-One |
| FK_Commissioner_SK | Dim_Commissioner | Many-to-One |
| FK_GPPractice_SK | Dim_GPPractice | Many-to-One |
| FK_Specialty_SK | Dim_Specialty | Many-to-One |
| ... | ... | ... |

### Fact_OP_Activity Relationships

The Outpatient fact table has 23 dimension foreign keys:

| Foreign Key | Dimension | Relationship |
|-------------|-----------|--------------|
| FK_Appointment_Date_SK | Dim_Date | Many-to-One (Active) |
| FK_Referral_Date_SK | Dim_Date | Many-to-One (Inactive) |
| FK_Patient_SK | Dim_Patient | Many-to-One |
| FK_Provider_SK | Dim_Provider | Many-to-One |
| FK_Commissioner_SK | Dim_Commissioner | Many-to-One |
| ... | ... | ... |

### Role-Playing Dimensions

**Dim_Date** is used multiple times per fact with different roles:
- Inpatient: Discharge Date (active), Admission Date (inactive)
- Outpatient: Appointment Date (active), Referral Date (inactive)

Only ONE relationship is active per fact table in Power BI. Use `USERELATIONSHIP()` in DAX to activate inactive relationships.

## Data Flow

```
Source Systems → ETL Procedures → Star Schema → Power BI Model
```

1. **Source Systems**
   - `[Data_Lab_SWL].[Unified].[tbl_IP_EncounterDenormalised_Active]`
   - `[Data_Lab_SWL].[Unified].[tbl_OP_EncounterDenormalised_Active]`
   - `[Dictionary]` database (NHS Data Dictionary)

2. **ETL Procedures**
   - `sp_Load_Fact_IP_Activity` - Loads inpatient spells
   - `sp_Load_Fact_OP_Activity` - Loads outpatient appointments
   - Handles dimension lookups, Unknown member assignment, SCD Type 2 logic

3. **Star Schema** (`[Analytics]` schema)
   - 26 dimension tables with views
   - 3 fact tables
   - Referential integrity enforced

4. **Power BI Model** (TMDL format)
   - Direct Query or Import mode
   - Pre-built measures and hierarchies
   - Role-playing dimension support

## Data Quality

### Validation Checks

The `sp_Validate_Fact_Data` procedure performs 7 validation checks:

1. **Row Count** - Fact vs Source record counts
2. **Monthly Distribution** - Month-by-month comparison
3. **Dimension Distribution** - Health scores per dimension
4. **Referential Integrity** - No orphan records
5. **Unknown Rates** - % of facts pointing to Unknown members
6. **Missing Members** - Source codes not in dimensions
7. **Dictionary Validation** - Cross-reference NHS Dictionary

### Unknown Member Handling

When a source code doesn't match a dimension member:
- Fact record uses FK = -1 (Unknown member)
- Validation report flags high unknown rates
- Missing members report shows what codes need to be added

## Financial Year Calendar

All date hierarchies follow NHS Financial Year (April-March):
- FY 2025/26 = Apr 2025 to Mar 2026
- Q1 = Apr-Jun, Q2 = Jul-Sep, Q3 = Oct-Dec, Q4 = Jan-Mar
- Month numbering: 1 (Apr) to 12 (Mar)

The `Dim_Date` table includes:
- `FinancialYear` (e.g., "2025/26")
- `FinancialQuarter` (Q1-Q4)
- `FinancialMonth` (1-12, sorted Apr-Mar)

## Best Practices

### Query Patterns

**Good - Filter via dimensions:**
```sql
SELECT COUNT(*) AS IP_Spells
FROM [Analytics].[tbl_Fact_IP_Activity] f
JOIN [Analytics].[vw_Dim_Commissioner] c ON f.FK_Commissioner_SK = c.Commissioner_SK
WHERE c.Commissioner_Code = 'QWE'  -- Filter on dimension
```

**Bad - Filter on fact table:**
```sql
SELECT COUNT(*) AS IP_Spells
FROM [Analytics].[tbl_Fact_IP_Activity] f
WHERE f.Commissioner_Code = 'QWE'  -- Don't filter on denormalized fact columns
```

### Adding New Dimensions

1. Create dimension table with SK, BK, ValidFrom, ValidTo, IsCurrent
2. Add Unknown member (SK = -1)
3. Create view: `vw_Dim_{Name}`
4. Update fact table ETL to add FK column
5. Update validation procedures
6. Add to Power BI model

### ETL Parameters

Always specify date ranges when loading facts:
```sql
EXEC [Analytics].[sp_Load_Fact_IP_Activity]
    @FromDate = '2025-04-01',  -- FY start
    @ToDate = '2026-03-31';     -- FY end
```

## Performance Considerations

- **Indexing**: All dimension BK columns are indexed
- **Partitioning**: Consider partitioning fact tables by Financial Year
- **Aggregations**: Build aggregate tables for year-on-year comparisons
- **Views**: Use dimension views for current members only (`IsCurrent = 1`)

## Further Reading

- **FACT_VALIDATION_USER_GUIDE.md** - How to run and interpret validation checks
- **PBIX_BUILD_GUIDE.md** - Building the Power BI model
- **CLAUDE.md** - Complete project context

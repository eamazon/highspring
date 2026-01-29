# Power BI Desktop - Step-by-Step Build Guide

This guide provides optimized SQL queries and step-by-step instructions for building the Healthcare Analytics semantic model in Power BI Desktop.

## Why Custom SQL vs Views?

| Approach | Pros | Cons |
|----------|------|------|
| **Import Views Directly** | Simple, one-click | Imports ALL columns, larger model size, no filtering |
| **Custom SQL Queries** | Only needed columns, incremental refresh support, smaller model | Requires SQL knowledge, more setup |

**Recommendation:** Use custom SQL for fact tables (large, need incremental refresh) and dimension tables where you want to exclude audit/ETL columns.

---

## Prerequisites

- [ ] Power BI Desktop (latest version)
- [ ] Access to `PSFADHSSTP02.ad.elc.nhs.uk\SWL`
- [ ] Read permissions on `Data_Lab_SWL_Live.Analytics` schema
- [ ] Power BI Premium capacity (for incremental refresh)

---

## Part 1: Create New Power BI File

1. Open Power BI Desktop
2. **File > Save As** → `Healthcare_Analytics_HighSpring_Dev.pbix`
3. **File > Options and Settings > Options**
   - Current File > Data Load: Uncheck "Auto date/time"
   - Current File > Regional Settings: English (United Kingdom)

---

## Part 2: Configure Data Source Connection

1. **Home > Get Data > SQL Server**
2. Enter connection details:
   ```
   Server: PSFADHSSTP02.ad.elc.nhs.uk\SWL
   Database: Data_Lab_SWL_Live
   Data Connectivity Mode: Import
   ```
3. Click **Advanced Options** and check "Include relationship columns"
4. Click **OK** and authenticate (Windows credentials)

---

## Part 3: Import Dimension Tables

For each dimension, use **Get Data > SQL Server** and paste the custom SQL query.

### 3.1 Dim_Date (Calendar)

```sql
-- Dim_Date: Calendar dimension with NHS Financial Year
SELECT
    [SK_Date]                           AS [DateKey],
    [FullDate]                          AS [Date],
    [Day]                               AS [Day of Month],
    [DayOfWeek]                         AS [Day Name],
    [DayOfWeekNumber]                   AS [Day of Week],
    [WeekOfYearNumber]                  AS [Week Number],
    [CalendarMonthNumber]               AS [Month Number],
    [CalendarMonthName]                 AS [Month Name],
    [CalendarMonthNameShort]            AS [Month],
    [CalendarQuarterNumber]             AS [Calendar Quarter],
    [CalendarYearNumber]                AS [Calendar Year],
    [FiscalCalendarMonthNumber]         AS [Financial Month],
    [FiscalCalendarQuarterNumber]       AS [Financial Quarter],
    [FiscalCalendarYearNumber]          AS [Financial Year Number],
    [FiscalCalendarYearName]            AS [Financial Year],
    [FiscalCalendarYearNameShort]       AS [FY Short],
    [IsWeekend]                         AS [Is Weekend],
    [IsBankHoliday]                     AS [Is Bank Holiday],
    [BankHoliday_Name]                  AS [Bank Holiday],
    [IsSchoolHoliday]                   AS [Is School Holiday],
    [IsNHSStrikeDay]                    AS [Is NHS Strike Day],
    [IsChristmasPeriod]                 AS [Is Christmas Period],
    [IsEasterPeriod]                    AS [Is Easter Period]
FROM [Analytics].[vw_Dim_Date]
WHERE [FullDate] >= '2019-04-01'
  AND [FullDate] <= DATEADD(YEAR, 1, GETDATE())
```

**Post-Import Steps:**
- Mark as Date Table: Select table > Table Tools > Mark as date table > `Date`
- Hide `DateKey` from report view (used only for relationships)

---

### 3.2 Dim_Patient

```sql
-- Dim_Patient: Core patient dimension (SCD Type 1)
SELECT
    [SK_PatientID]              AS [PatientKey],
    [Pseudo_ID]                 AS [Patient ID],
    [Date_Of_Birth]             AS [Date of Birth],
    [Date_Of_Death]             AS [Date of Death],
    [Gender_Code]               AS [Gender Code],
    [Gender_Description]        AS [Gender],
    [Ethnicity_Code]            AS [Ethnicity Code],
    [Ethnicity_Description]     AS [Ethnicity],
    [LSOA_Code]                 AS [LSOA Code],
    [Postcode_Sector]           AS [Postcode Sector],
    [GP_Practice_Code]          AS [GP Practice Code],
    [GP_Practice_Name]          AS [GP Practice],
    [PCN_Code]                  AS [PCN Code],
    [ICB_Code]                  AS [ICB Code],
    [Is_Sensitive]              AS [Is Sensitive],
    [Is_Current]                AS [Is Current]
FROM [Analytics].[tbl_Dim_Patient]
WHERE [Is_Current] = 1
```

---

### 3.3 Dim_Commissioner

```sql
-- Dim_Commissioner: CCG/Sub-ICB/ICB hierarchy
SELECT
    [SK_CommissionerID]         AS [CommissionerKey],
    [Commissioner_Code]         AS [Commissioner Code],
    [Commissioner_Name]         AS [Commissioner],
    [ICB_Code]                  AS [ICB Code],
    [ICB_Name]                  AS [ICB],
    [Is_SWL_ICB]                AS [Is SWL],
    [CAM_Attribution_Method]    AS [CAM Method],
    [PODTeam_Code]              AS [POD Team Code],
    [PODTeam_Name]              AS [POD Team],
    [SubICB_Code]               AS [Sub-ICB Code],
    [SubICB_Name]               AS [Sub-ICB],
    [SubICB_Location_Name]      AS [Sub-ICB Location],
    [Commissioner_Type]         AS [Commissioner Type],
    [ODS_Role_Code]             AS [ODS Role],
    [Legacy_Commissioner_Name]  AS [Legacy Name],
    [Is_Current]                AS [Is Current]
FROM [Analytics].[tbl_Dim_Commissioner]
WHERE [Is_Current] = 1
   OR [SK_CommissionerID] IN (-1, -2)  -- Keep Unknown/Unassigned members
```

---

### 3.4 Dim_GPPractice

```sql
-- Dim_GPPractice: GP Practice with PCN/Sub-ICB hierarchy
SELECT
    [SK_GPPracticeID]       AS [GPPracticeKey],
    [GPPractice_Code]       AS [GP Practice Code],
    [GPPractice_Name]       AS [GP Practice],
    [Practice_Category]     AS [Practice Category],
    [Prescribing_Setting]   AS [Prescribing Setting],
    [Town]                  AS [Town],
    [Postcode]              AS [Postcode],
    [PCN_Code]              AS [PCN Code],
    [PCN_Name]              AS [PCN],
    [SubICB_Code]           AS [Sub-ICB Code],
    [SubICB_Name]           AS [Sub-ICB],
    [ICB_Code]              AS [ICB Code],
    [ICB_Name]              AS [ICB],
    [ICB_Grouping]          AS [ICB Group],
    [ICB_Grouping_Sort]     AS [ICB Group Sort],
    [Registration_Status]   AS [Registration Status],
    [Is_Active]             AS [Is Active],
    [Is_Current]            AS [Is Current]
FROM [Analytics].[tbl_Dim_GPPractice]
WHERE [Is_Current] = 1
   OR [SK_GPPracticeID] IN (-1, -2, -3, -4)  -- Keep special members
```

---

### 3.5 Dim_PCN

```sql
-- Dim_PCN: Primary Care Networks
SELECT
    [SK_PCNID]      AS [PCNKey],
    [PCN_Code]      AS [PCN Code],
    [PCN_Name]      AS [PCN],
    [ICB_Code]      AS [ICB Code],
    [ICB_Name]      AS [ICB],
    [Town]          AS [Town],
    [Postcode]      AS [Postcode],
    [Is_Active]     AS [Is Active],
    [Is_Current]    AS [Is Current]
FROM [Analytics].[tbl_Dim_PCN]
WHERE [Is_Current] = 1
   OR [SK_PCNID] = -1
```

---

### 3.6 Dim_POD (Point of Delivery)

```sql
-- Dim_POD: NHS Point of Delivery taxonomy
SELECT
    [SK_PodID]          AS [PODKey],
    [POD_Code]          AS [POD Code],
    [POD_Domain]        AS [POD Domain],
    [POD_Subcategory]   AS [POD Subcategory],
    [POD_Measure]       AS [POD Measure],
    [POD_Description]   AS [POD Description],
    [POD_Display]       AS [Point of Delivery],
    [POD_Dataset]       AS [Dataset],
    [POD_MainGroup]     AS [Main Group],
    [POD_SubGroup]      AS [Sub Group],
    [POD_Category]      AS [Category],
    [Is_Elective]       AS [Is Elective],
    [Is_Emergency]      AS [Is Emergency],
    [Is_Admitted]       AS [Is Admitted],
    [Is_Outpatient]     AS [Is Outpatient],
    [Is_AE]             AS [Is A&E]
FROM [Analytics].[tbl_Dim_POD]
```

---

### 3.7 Dim_LSOA

```sql
-- Dim_LSOA: Lower Super Output Areas with IMD
SELECT
    [SK_LSOA_ID]            AS [LSOAKey],
    [LSOA_Code]             AS [LSOA Code],
    [LSOA_Name]             AS [LSOA Name],
    [LSOA_Display]          AS [LSOA],
    [SubICB_Code]           AS [Sub-ICB Code],
    [SubICB_Name]           AS [Sub-ICB],
    [ICB_Code]              AS [ICB Code],
    [ICB_Name]              AS [ICB],
    [LocalAuthority_Code]   AS [Local Authority Code],
    [LocalAuthority_Name]   AS [Local Authority],
    [IMD_Year]              AS [IMD Year],
    [IMD_Rank]              AS [IMD Rank],
    [IMD_Decile]            AS [IMD Decile],
    [IDACI_Decile]          AS [Child Deprivation Decile],
    [IDAOPI_Decile]         AS [Older Person Deprivation Decile]
FROM [Analytics].[vw_Dim_LSOA]
```

---

### 3.8 Dim_Provider

```sql
-- Dim_Provider: Healthcare trusts/providers
SELECT
    [SK_ProviderID]         AS [ProviderKey],
    [Provider_Code]         AS [Provider Code],
    [Provider_Name]         AS [Provider],
    [Provider_Type_Code]    AS [Provider Type Code],
    [Provider_Type]         AS [Provider Type],
    [Town]                  AS [Town],
    [Provider_Status]       AS [Status],
    [Is_Active]             AS [Is Active]
FROM [Analytics].[vw_Dim_Provider]
```

---

### 3.9 Dim_Specialty

```sql
-- Dim_Specialty: Treatment Function Codes
SELECT
    [SK_SpecialtyID]                AS [SpecialtyKey],
    [BK_SpecialtyCode]              AS [Specialty Code],
    [SpecialtyName]                 AS [Specialty Name],
    [SpecialtyCategory]             AS [Specialty Category],
    [IsTreatmentFunction]           AS [Is Treatment Function],
    [IsMainSpecialty]               AS [Is Main Specialty],
    [MainSpecialtyDescription]      AS [Main Specialty],
    [TreatmentFunctionDescription]  AS [Treatment Function],
    [Specialty_Short]               AS [Specialty]
FROM [Analytics].[vw_Dim_Specialty]
```

---

### 3.10 Dim_HRG

```sql
-- Dim_HRG: Healthcare Resource Groups
SELECT
    [SK_HRGID]          AS [HRGKey],
    [HRGCode]           AS [HRG Code],
    [HRGDescription]    AS [HRG Description],
    [HRGChapterKey]     AS [HRG Chapter Code],
    [HRGChapter]        AS [HRG Chapter],
    [HRGSubchapterKey]  AS [HRG Subchapter Code],
    [HRGSubchapter]     AS [HRG Subchapter],
    [HRG_Version]       AS [HRG Version],
    [HRG_Short]         AS [HRG]
FROM [Analytics].[vw_Dim_HRG]
```

---

### 3.11 Dim_Gender

```sql
-- Dim_Gender: NHS gender codes
SELECT
    [SK_GenderID]   AS [GenderKey],
    [Gender]        AS [Gender],
    [GenderCode]    AS [Gender Code],
    [GenderCode1]   AS [Gender Code 1],
    [GenderCode2]   AS [Gender Code 2]
FROM [Analytics].[vw_Dim_Gender]
```

---

### 3.12 Dim_Ethnicity

```sql
-- Dim_Ethnicity: NHS HES 16+1 categories
SELECT
    [SK_EthnicityID]    AS [EthnicityKey],
    [EthnicityCode]     AS [Ethnicity Code],
    [EthnicityDesc]     AS [Ethnicity Description],
    [EthnicityDesc2]    AS [Ethnicity Group],
    [Ethnicity_Short]   AS [Ethnicity]
FROM [Analytics].[vw_Dim_Ethnicity]
```

---

### 3.13 Dim_Age_Band

```sql
-- Dim_Age_Band: Multiple banding schemes
SELECT
    [Age]               AS [Age],
    [Age_Band_5yr]      AS [Age Band (5yr)],
    [Age_Band_GP]       AS [Age Band (GP)],
    [Age_Band_10yr]     AS [Age Band (10yr)],
    [Age_Band_Clinical] AS [Age Band (Clinical)],
    [Age_Band_Summary]  AS [Age Band]
FROM [Analytics].[vw_Dim_Age_Band]
```

**Note:** This dimension uses `Age` as the key column (joins to fact tables via `SK_Age_BandID` which maps to `Age`).

---

### 3.14 CAM & Operating Plan Dimensions

```sql
-- Dim_CAM_Service_Category
SELECT
    [SK_CAM_Service_CategoryID] AS [CAMServiceCategoryKey],
    [CAM_Service_Category]      AS [CAM Service Category]
FROM [Analytics].[tbl_Dim_CAM_Service_Category]
```

```sql
-- Dim_CAM_Assignment_Reason
SELECT
    [SK_CAM_Assignment_ReasonID]    AS [CAMAssignmentReasonKey],
    [CAM_Assignment_Code]           AS [CAM Assignment Code],
    [CAM_Assignment_Reason]         AS [CAM Assignment Reason]
FROM [Analytics].[tbl_Dim_CAM_Assignment_Reason]
```

```sql
-- Dim_OpPlan_MeasureSet
SELECT
    [SK_OpPlan_MeasureSet]  AS [OpPlanMeasureSetKey],
    [MeasureIds]            AS [Measure IDs],
    [MeasureCount]          AS [Measure Count],
    [Is_Active]             AS [Is Active]
FROM [Analytics].[tbl_Dim_OpPlan_MeasureSet]
```

---

### 3.15 IP-Specific Dimensions

```sql
-- Dim_Admission_Method
SELECT
    [SK_AdmissionMethodID]      AS [AdmissionMethodKey],
    [Admission_Method_Code]     AS [Admission Method Code],
    [Admission_Method_Name]     AS [Admission Method Name],
    [Admission_Method_Group]    AS [Admission Method Group],
    [Admission_Method_Short]    AS [Admission Method]
FROM [Analytics].[vw_Dim_Admission_Method]
```

```sql
-- Dim_Admission_Source
SELECT
    [SK_AdmissionSourceID]      AS [AdmissionSourceKey],
    [Admission_Source_Code]     AS [Admission Source Code],
    [Admission_Source_Name]     AS [Admission Source Name],
    [Admission_Source_Short]    AS [Admission Source]
FROM [Analytics].[vw_Dim_Admission_Source]
```

```sql
-- Dim_Discharge_Method
SELECT
    [SK_DischargeMethodID]      AS [DischargeMethodKey],
    [Discharge_Method_Code]     AS [Discharge Method Code],
    [Discharge_Method_Name]     AS [Discharge Method Name],
    [Discharge_Method_Short]    AS [Discharge Method]
FROM [Analytics].[vw_Dim_Discharge_Method]
```

```sql
-- Dim_Discharge_Destination
SELECT
    [SK_DischargeDestinationID]     AS [DischargeDestinationKey],
    [Discharge_Destination_Code]    AS [Discharge Destination Code],
    [Discharge_Destination_Name]    AS [Discharge Destination Name],
    [Discharge_Destination_Short]   AS [Discharge Destination]
FROM [Analytics].[vw_Dim_Discharge_Destination]
```

```sql
-- Dim_IP_Patient_Classification
SELECT
    [SK_PatientClassificationID]    AS [PatientClassificationKey],
    [Patient_Classification_Code]   AS [Patient Classification Code],
    [Patient_Classification_Name]   AS [Patient Classification Name],
    [Patient_Classification_Short]  AS [Patient Classification]
FROM [Analytics].[vw_Dim_IP_Patient_Classification]
```

---

### 3.16 OP-Specific Dimensions

```sql
-- Dim_Attendance_Status
SELECT
    [SK_AttendanceStatusID]             AS [AttendanceStatusKey],
    [Attendance_Status_Code]            AS [Attendance Status Code],
    [Attendance_Status_Description]     AS [Attendance Status Description],
    [Attendance_Status_Short]           AS [Attendance Status]
FROM [Analytics].[vw_Dim_Attendance_Status]
```

```sql
-- Dim_Attendance_Outcome (import all - small table)
SELECT * FROM [Analytics].[vw_Dim_Attendance_Outcome]
```

```sql
-- Dim_Attendance_Type (import all - small table)
SELECT * FROM [Analytics].[vw_Dim_Attendance_Type]
```

```sql
-- Dim_DNA_Indicator (import all - small table)
SELECT * FROM [Analytics].[vw_Dim_DNA_Indicator]
```

```sql
-- Dim_Priority_Type (import all - small table)
SELECT * FROM [Analytics].[vw_Dim_Priority_Type]
```

```sql
-- Dim_Referral_Source (import all - small table)
SELECT * FROM [Analytics].[vw_Dim_Referral_Source]
```

---

### 3.17 AE-Specific Dimension

```sql
-- Dim_Attendance_Disposal
SELECT
    [SK_AttendanceDisposalID]           AS [AttendanceDisposalKey],
    [Attendance_Disposal_Code]          AS [Attendance Disposal Code],
    [Attendance_Disposal_Description]   AS [Attendance Disposal Description],
    [Attendance_Disposal_Short]         AS [Attendance Disposal]
FROM [Analytics].[vw_Dim_Attendance_Disposal]
```

---

## Part 4: Import Fact Tables (with Incremental Refresh)

Fact tables require special handling for incremental refresh. Power BI uses parameters `RangeStart` and `RangeEnd` to filter data.

### 4.1 Create Parameters First

Before importing facts, create these parameters:

1. **Home > Transform Data** (opens Power Query Editor)
2. **Home > Manage Parameters > New Parameter**

| Parameter | Type | Current Value | Suggested Values |
|-----------|------|---------------|------------------|
| `RangeStart` | Date/Time | `2019-04-01` | Any value |
| `RangeEnd` | Date/Time | `2026-12-31` | Any value |

---

### 4.2 Fact_IP_Activity (Inpatient)

**Get Data > SQL Server > Advanced Options > SQL Statement:**

```sql
-- Fact_IP_Activity: Inpatient spells
-- Incremental refresh on Discharge_Date
SELECT
    -- Keys (hidden in report view, used for relationships)
    [SK_EncounterID]                    AS [EncounterKey],
    [SK_PatientID]                      AS [PatientKey],
    [SK_DateAdmissionID]                AS [AdmissionDateKey],
    [SK_DateDischargeID]                AS [DischargeDateKey],
    [SK_Age_BandID]                     AS [AgeKey],
    [SK_GenderID]                       AS [GenderKey],
    [SK_EthnicityID]                    AS [EthnicityKey],
    [SK_ProviderID]                     AS [ProviderKey],
    [SK_LSOA_ID]                        AS [LSOAKey],
    [SK_SpecialtyID]                    AS [SpecialtyKey],
    [SK_HRG_ID]                         AS [HRGKey],
    [SK_CommissionerID]                 AS [CommissionerKey],
    [SK_GPPracticeID]                   AS [GPPracticeKey],
    [SK_PCN_ID]                         AS [PCNKey],
    [SK_POD_ID]                         AS [PODKey],
    [SK_OpPlan_MeasureSet]              AS [OpPlanMeasureSetKey],

    -- IP-Specific FKs
    [SK_Admission_MethodID]             AS [AdmissionMethodKey],
    [SK_Admission_SourceID]             AS [AdmissionSourceKey],
    [SK_Discharge_MethodID]             AS [DischargeMethodKey],
    [SK_Discharge_DestinationID]        AS [DischargeDestinationKey],
    [SK_IP_Patient_ClassificationID]    AS [PatientClassificationKey],

    -- CAM FKs
    [SK_CAM_CommissionerID]             AS [CAMCommissionerKey],
    [SK_CAM_Service_CategoryID]         AS [CAMServiceCategoryKey],
    [SK_CAM_Assignment_ReasonID]        AS [CAMAssignmentReasonKey],

    -- Date columns (for filtering and display)
    [Admission_Date]                    AS [Admission Date],
    [Discharge_Date]                    AS [Discharge Date],

    -- Measures
    [Admissions]                        AS [Admissions],
    [Length_Of_Stay]                    AS [Length of Stay],
    [Total_Cost]                        AS [Total Cost],
    [Delayed_Discharge_Days]            AS [Delayed Discharge Days],
    [Excess_Bed_Days]                   AS [Excess Bed Days],
    [Excess_Bed_Days_Cost]              AS [Excess Bed Days Cost],
    [Palliative_Care_Days]              AS [Palliative Care Days],
    [Rehab_Days]                        AS [Rehab Days],
    [Base_Tariff]                       AS [Base Tariff],
    [MFF_Multiplier]                    AS [MFF Multiplier],
    [ERF_National_Price]                AS [ERF National Price],
    [ERF_Total_Cost_Incl_MFF]           AS [ERF Cost],

    -- Flags
    [Commissioner_Variance]             AS [Commissioner Variance],
    [Service_Category_Variance]         AS [Service Category Variance],
    [Is_Operating_Plan]                 AS [Is Operating Plan],
    [Is_ERF_Eligible]                   AS [Is ERF Eligible]

FROM [Analytics].[tbl_Fact_IP_Activity]
WHERE [Discharge_Date] >= @RangeStart
  AND [Discharge_Date] < @RangeEnd
```

**After Import - Apply Incremental Refresh Filter in Power Query:**

1. In Power Query, select `Fact_IP_Activity`
2. Select `Discharge Date` column
3. Filter column: "is after or equal to" `RangeStart` AND "is before" `RangeEnd`
4. **Close & Apply**

---

### 4.3 Fact_OP_Activity (Outpatient)

```sql
-- Fact_OP_Activity: Outpatient appointments
-- Incremental refresh on Appointment_Date
SELECT
    -- Keys (hidden in report view, used for relationships)
    [SK_EncounterID]                AS [EncounterKey],
    [SK_PatientID]                  AS [PatientKey],
    [SK_DateAppointmentID]          AS [AppointmentDateKey],
    [SK_DateReferralID]             AS [ReferralDateKey],
    [SK_Age_BandID]                 AS [AgeKey],
    [SK_GenderID]                   AS [GenderKey],
    [SK_EthnicityID]                AS [EthnicityKey],
    [SK_ProviderID]                 AS [ProviderKey],
    [SK_LSOA_ID]                    AS [LSOAKey],
    [SK_SpecialtyID]                AS [SpecialtyKey],
    [SK_HRG_ID]                     AS [HRGKey],
    [SK_CommissionerID]             AS [CommissionerKey],
    [SK_GPPracticeID]               AS [GPPracticeKey],
    [SK_PCN_ID]                     AS [PCNKey],
    [SK_POD_ID]                     AS [PODKey],
    [SK_OpPlan_MeasureSet]          AS [OpPlanMeasureSetKey],

    -- OP-Specific FKs
    [SK_Attendance_StatusID]        AS [AttendanceStatusKey],
    [SK_Attendance_OutcomeID]       AS [AttendanceOutcomeKey],
    [SK_Attendance_TypeID]          AS [AttendanceTypeKey],
    [SK_DNA_IndicatorID]            AS [DNAIndicatorKey],
    [SK_Priority_TypeID]            AS [PriorityTypeKey],
    [SK_Referral_SourceID]          AS [ReferralSourceKey],

    -- CAM FKs
    [SK_CAM_CommissionerID]         AS [CAMCommissionerKey],
    [SK_CAM_Service_CategoryID]     AS [CAMServiceCategoryKey],
    [SK_CAM_Assignment_ReasonID]    AS [CAMAssignmentReasonKey],

    -- Date columns (for filtering and display)
    [Appointment_Date]              AS [Appointment Date],
    [Referral_Date]                 AS [Referral Date],

    -- Measures
    [Appointments]                  AS [Appointments],
    [Total_Cost]                    AS [Total Cost],
    [DNA_Count]                     AS [DNA Count],
    [Is_FirstAttendance]            AS [Is First Attendance],
    [Referral_To_Appt_Days]         AS [Days to Appointment],
    [RTT_Wait_Weeks]                AS [RTT Wait Weeks],

    -- Flags
    [Commissioner_Variance]         AS [Commissioner Variance],
    [Service_Category_Variance]     AS [Service Category Variance],
    [Is_Operating_Plan]             AS [Is Operating Plan],
    [Is_ERF_Eligible]               AS [Is ERF Eligible]

FROM [Analytics].[tbl_Fact_OP_Activity]
WHERE [Appointment_Date] >= @RangeStart
  AND [Appointment_Date] < @RangeEnd
```

---

### 4.4 Fact_AE_Activity (A&E)

```sql
-- Fact_AE_Activity: A&E attendances
-- Incremental refresh on Arrival_Date
SELECT
    -- Keys (hidden in report view, used for relationships)
    [SK_EncounterID]                    AS [EncounterKey],
    [SK_PatientID]                      AS [PatientKey],
    [SK_DateArrivalID]                  AS [ArrivalDateKey],
    [SK_DateDepartureID]                AS [DepartureDateKey],
    [SK_Age_BandID]                     AS [AgeKey],
    [SK_GenderID]                       AS [GenderKey],
    [SK_EthnicityID]                    AS [EthnicityKey],
    [SK_ProviderID]                     AS [ProviderKey],
    [SK_LSOA_ID]                        AS [LSOAKey],
    [SK_SpecialtyID]                    AS [SpecialtyKey],
    [SK_HRG_ID]                         AS [HRGKey],
    [SK_CommissionerID]                 AS [CommissionerKey],
    [SK_GPPracticeID]                   AS [GPPracticeKey],
    [SK_PCN_ID]                         AS [PCNKey],
    [SK_POD_ID]                         AS [PODKey],
    [SK_OpPlan_MeasureSet]              AS [OpPlanMeasureSetKey],

    -- AE-Specific FK
    [SK_Attendance_DisposalID]          AS [AttendanceDisposalKey],

    -- Date columns (for filtering and display)
    [Arrival_Date]                      AS [Arrival Date],
    [Departure_Date]                    AS [Departure Date],

    -- Measures
    [Attendances]                       AS [Attendances],
    [Time_In_Department_Mins]           AS [Time in Department (mins)],
    [Time_To_Initial_Assessment_Mins]   AS [Time to Assessment (mins)],
    [Total_Cost]                        AS [Total Cost],

    -- Flags
    [Is_4Hour_Breach]                   AS [Is 4-Hour Breach],
    [Is_12Hour_Breach]                  AS [Is 12-Hour Breach],
    [Is_Admitted]                       AS [Is Admitted],
    [Is_Operating_Plan]                 AS [Is Operating Plan]

FROM [Analytics].[tbl_Fact_AE_Activity]
WHERE [Arrival_Date] >= @RangeStart
  AND [Arrival_Date] < @RangeEnd
```

---

## Part 5: Configure Incremental Refresh

After importing fact tables, configure incremental refresh for each:

1. In Model view, right-click `Fact_IP_Activity`
2. Select **Incremental refresh**
3. Configure:

| Setting | Value |
|---------|-------|
| Incrementally refresh this table | ON |
| Archive data starting | 5 Years before refresh date |
| Incrementally refresh data starting | 6 Months before refresh date |
| Detect data changes | ON (column: `Discharge_Date`) |

4. Repeat for `Fact_OP_Activity` (partition on `Appointment_Date`)
5. Repeat for `Fact_AE_Activity` (partition on `Arrival_Date`)

---

## Part 6: Build Relationships

After all tables are imported, create relationships in Model view.

### 6.1 Date Relationships (Role-Playing)

| From | To | Cardinality | Active |
|------|-----|-------------|--------|
| `Dim_Date[DateKey]` | `Fact_IP_Activity[DischargeDateKey]` | 1:Many | **Yes** |
| `Dim_Date[DateKey]` | `Fact_IP_Activity[AdmissionDateKey]` | 1:Many | No |
| `Dim_Date[DateKey]` | `Fact_OP_Activity[AppointmentDateKey]` | 1:Many | **Yes** |
| `Dim_Date[DateKey]` | `Fact_OP_Activity[ReferralDateKey]` | 1:Many | No |
| `Dim_Date[DateKey]` | `Fact_AE_Activity[ArrivalDateKey]` | 1:Many | **Yes** |
| `Dim_Date[DateKey]` | `Fact_AE_Activity[DepartureDateKey]` | 1:Many | No |

### 6.2 Core Dimension Relationships

Create these for **all three fact tables** (IP, OP, AE):

| Dimension | Fact Column |
|-----------|-------------|
| `Dim_Patient[PatientKey]` | `PatientKey` |
| `Dim_Provider[ProviderKey]` | `ProviderKey` |
| `Dim_Commissioner[CommissionerKey]` | `CommissionerKey` |
| `Dim_GPPractice[GPPracticeKey]` | `GPPracticeKey` |
| `Dim_PCN[PCNKey]` | `PCNKey` |
| `Dim_LSOA[LSOAKey]` | `LSOAKey` |
| `Dim_Specialty[SpecialtyKey]` | `SpecialtyKey` |
| `Dim_HRG[HRGKey]` | `HRGKey` |
| `Dim_Gender[GenderKey]` | `GenderKey` |
| `Dim_Ethnicity[EthnicityKey]` | `EthnicityKey` |
| `Dim_Age_Band[Age]` | `AgeKey` |
| `Dim_POD[PODKey]` | `PODKey` |
| `Dim_OpPlan_MeasureSet[OpPlanMeasureSetKey]` | `OpPlanMeasureSetKey` |

### 6.3 CAM Relationships

| Dimension | Fact Column | Active |
|-----------|-------------|--------|
| `Dim_Commissioner[CommissionerKey]` | `CAMCommissionerKey` | No (role-playing) |
| `Dim_CAM_Service_Category[CAMServiceCategoryKey]` | `CAMServiceCategoryKey` | Yes |
| `Dim_CAM_Assignment_Reason[CAMAssignmentReasonKey]` | `CAMAssignmentReasonKey` | Yes |

### 6.4 Dataset-Specific Relationships

**IP Only:**
| Dimension | Fact Column |
|-----------|-------------|
| `Dim_Admission_Method[AdmissionMethodKey]` | `AdmissionMethodKey` |
| `Dim_Admission_Source[AdmissionSourceKey]` | `AdmissionSourceKey` |
| `Dim_Discharge_Method[DischargeMethodKey]` | `DischargeMethodKey` |
| `Dim_Discharge_Destination[DischargeDestinationKey]` | `DischargeDestinationKey` |
| `Dim_IP_Patient_Classification[PatientClassificationKey]` | `PatientClassificationKey` |

**OP Only:**
| Dimension | Fact Column |
|-----------|-------------|
| `Dim_Attendance_Status[AttendanceStatusKey]` | `AttendanceStatusKey` |
| `Dim_Attendance_Outcome` | `AttendanceOutcomeKey` |
| `Dim_Attendance_Type` | `AttendanceTypeKey` |
| `Dim_DNA_Indicator` | `DNAIndicatorKey` |
| `Dim_Priority_Type` | `PriorityTypeKey` |
| `Dim_Referral_Source` | `ReferralSourceKey` |

**AE Only:**
| Dimension | Fact Column |
|-----------|-------------|
| `Dim_Attendance_Disposal[AttendanceDisposalKey]` | `AttendanceDisposalKey` |

### 6.5 Snowflake Relationship

| From | To |
|------|-----|
| `Dim_GPPractice[PCN Code]` | `Dim_PCN[PCN Code]` |

---

## Part 7: Create Measures

Create a new table for measures: **Home > Enter Data** → Name: `_Measures`

### 7.1 Activity Measures

```dax
// Core Activity Counts
Admissions = COUNTROWS(Fact_IP_Activity)

Appointments = COUNTROWS(Fact_OP_Activity)

Attendances = COUNTROWS(Fact_AE_Activity)

Total Activities = [Admissions] + [Appointments] + [Attendances]

// OP Breakdown
First Attendances =
CALCULATE([Appointments], Fact_OP_Activity[Is First Attendance] = TRUE)

Follow-up Attendances = [Appointments] - [First Attendances]

New to Follow-up Ratio =
DIVIDE([First Attendances], [Follow-up Attendances], BLANK())
```

### 7.2 Cost Measures

```dax
Total Cost =
SUM(Fact_IP_Activity[Total Cost]) +
SUM(Fact_OP_Activity[Total Cost]) +
SUM(Fact_AE_Activity[Total Cost])

Total Cost IP = SUM(Fact_IP_Activity[Total Cost])
Total Cost OP = SUM(Fact_OP_Activity[Total Cost])
Total Cost AE = SUM(Fact_AE_Activity[Total Cost])

Base Tariff = SUM(Fact_IP_Activity[Base Tariff])

ERF Cost = SUM(Fact_IP_Activity[ERF Cost])

Excess Bed Days Cost = SUM(Fact_IP_Activity[Excess Bed Days Cost])

Cost per Admission = DIVIDE([Total Cost IP], [Admissions], BLANK())
Cost per Appointment = DIVIDE([Total Cost OP], [Appointments], BLANK())
Cost per Attendance = DIVIDE([Total Cost AE], [Attendances], BLANK())
```

### 7.3 Clinical Performance Measures

```dax
// Inpatient
Avg Length of Stay = AVERAGE(Fact_IP_Activity[Length of Stay])

Total Bed Days = SUM(Fact_IP_Activity[Length of Stay])

Excess Bed Days = SUM(Fact_IP_Activity[Excess Bed Days])

Delayed Discharge Days = SUM(Fact_IP_Activity[Delayed Discharge Days])

// Outpatient
DNA Count = SUM(Fact_OP_Activity[DNA Count])

DNA Rate = DIVIDE([DNA Count], [Appointments], 0)

Avg Wait Days = AVERAGE(Fact_OP_Activity[Days to Appointment])

RTT Weeks Avg = AVERAGE(Fact_OP_Activity[RTT Wait Weeks])

// A&E
4-Hour Breaches =
CALCULATE([Attendances], Fact_AE_Activity[Is 4-Hour Breach] = TRUE)

4-Hour Breach Rate = DIVIDE([4-Hour Breaches], [Attendances], 0)

12-Hour Breaches =
CALCULATE([Attendances], Fact_AE_Activity[Is 12-Hour Breach] = TRUE)

12-Hour Breach Rate = DIVIDE([12-Hour Breaches], [Attendances], 0)

Avg Time in Dept (mins) = AVERAGE(Fact_AE_Activity[Time in Department (mins)])

Avg Time to Assessment (mins) = AVERAGE(Fact_AE_Activity[Time to Assessment (mins)])

AE Admissions =
CALCULATE([Attendances], Fact_AE_Activity[Is Admitted] = TRUE)

AE Conversion Rate = DIVIDE([AE Admissions], [Attendances], 0)
```

### 7.4 CAM Measures

```dax
Commissioner Variance Count =
CALCULATE([Admissions], Fact_IP_Activity[Commissioner Variance] = TRUE)

Commissioner Variance % =
DIVIDE([Commissioner Variance Count], [Admissions], 0)

Service Category Variance Count =
CALCULATE([Admissions], Fact_IP_Activity[Service Category Variance] = TRUE)
```

### 7.5 Operating Plan Measures

```dax
OpPlan Activities IP =
CALCULATE([Admissions], Fact_IP_Activity[Is Operating Plan] = TRUE)

OpPlan Activities OP =
CALCULATE([Appointments], Fact_OP_Activity[Is Operating Plan] = TRUE)

OpPlan Activities Total = [OpPlan Activities IP] + [OpPlan Activities OP]

Operating Plan % =
DIVIDE([OpPlan Activities Total], [Admissions] + [Appointments], 0)
```

### 7.6 Role-Playing Date Measures (USERELATIONSHIP)

```dax
// IP by Admission Date
Admissions by Admission Date =
CALCULATE(
    [Admissions],
    USERELATIONSHIP(Dim_Date[DateKey], Fact_IP_Activity[AdmissionDateKey])
)

// OP by Referral Date
Appointments by Referral Date =
CALCULATE(
    [Appointments],
    USERELATIONSHIP(Dim_Date[DateKey], Fact_OP_Activity[ReferralDateKey])
)

// AE by Departure Date
Attendances by Departure Date =
CALCULATE(
    [Attendances],
    USERELATIONSHIP(Dim_Date[DateKey], Fact_AE_Activity[DepartureDateKey])
)

// CAM Commissioner (role-playing)
Admissions by CAM Commissioner =
CALCULATE(
    [Admissions],
    USERELATIONSHIP(Dim_Commissioner[CommissionerKey], Fact_IP_Activity[CAMCommissionerKey])
)
```

---

## Part 8: Post-Import Optimization

### 8.1 Hide Technical Columns

In Model view, hide these columns from Report view:
- All `*Key` columns in fact tables (e.g., `PatientKey`, `ProviderKey`)
- All `*Key` columns in dimension tables (e.g., `DateKey`, `CommissionerKey`)
- `Is Current` columns
- Sort columns (e.g., `ICB Group Sort`)

### 8.2 Create Hierarchies

**Date Hierarchy:**
```
Dim_Date
└── Financial Year
    └── Financial Quarter
        └── Month Name
            └── Date
```

**GP Practice Hierarchy:**
```
Dim_GPPractice
└── ICB Group
    └── Sub-ICB
        └── PCN
            └── GP Practice
```

**POD Hierarchy:**
```
Dim_POD
└── POD Domain
    └── POD Subcategory
        └── POD Description
```

### 8.3 Set Data Categories

| Column | Data Category |
|--------|---------------|
| `Dim_LSOA[LSOA Code]` | Place |
| `Dim_GPPractice[Postcode]` | Postal Code |
| `Dim_Date[Date]` | Date |

### 8.4 Format Measures

| Measure | Format |
|---------|--------|
| Cost measures | Currency (£) |
| Rate/% measures | Percentage |
| Count measures | Whole number with thousands separator |
| Average measures | Decimal (1 place) |

---

## Part 9: Validation Checklist

Before publishing, validate:

- [ ] **Row counts match SQL** (within 0.1%)
  ```sql
  SELECT COUNT(*) FROM [Analytics].[tbl_Fact_IP_Activity]
  SELECT COUNT(*) FROM [Analytics].[tbl_Fact_OP_Activity]
  SELECT COUNT(*) FROM [Analytics].[tbl_Fact_AE_Activity]
  ```

- [ ] **Cost totals match SQL** (within £1,000)
  ```sql
  SELECT SUM(Total_Cost) FROM [Analytics].[tbl_Fact_IP_Activity]
  SELECT SUM(Total_Cost) FROM [Analytics].[tbl_Fact_OP_Activity]
  SELECT SUM(Total_Cost) FROM [Analytics].[tbl_Fact_AE_Activity]
  ```

- [ ] **Date ranges complete** (2019-04-01 to present)
- [ ] **All relationships created** and correct cardinality
- [ ] **All measures calculate** without errors
- [ ] **Model size acceptable** (target < 5 GB)

---

## Part 10: Publish to Service

1. **Home > Publish**
2. Select workspace: `HIGHSPR_PBI_MODEL`
3. After publish:
   - Configure gateway connection
   - Set refresh schedule (Monday 8:00 PM)
   - Verify incremental refresh partitions created

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Cannot connect to server" | Check VPN/network, verify server name |
| "Query timeout" | Add TOP 1000 to test queries first |
| "Relationship already exists" | Delete duplicate relationships |
| "Circular dependency" | Check for bidirectional relationships |
| "Model too large" | Remove unused columns, increase aggregation |

---

## Summary of Columns Excluded

These columns were intentionally excluded from import to reduce model size:

**From Fact Tables:**
- `ETL_LoadDateTime`, `ETL_UpdateDateTime` (audit only)
- `LSOA_Code` (degenerate, already in LSOA dimension)
- `CAM_Commissioner_Code`, `CAM_Service_Category`, `CAM_Assignment_Reason` (text duplicates of FKs)
- `Outcome_Code`, `Priority_Code`, `Clinic_Code`, `Admin_Category_Code` (OP degenerate dims)
- `Arrival_Mode_Code`, `Attendance_Category_Code`, `Referral_Source_Code`, `Department_Type_Code` (AE degenerate dims)
- `ERF_MFF_Applied`, `ERF_Tariff_Used` (intermediate ERF calc columns)

**From Dimension Tables:**
- `Source_System`, `Created_By`, `Created_Date`, `Updated_By`, `Updated_Date` (audit only)
- Address fields beyond what's needed for display
- `SetHash` from OpPlan_MeasureSet (internal use only)

## Naming Convention Used

| SQL Column | Power BI Name | Notes |
|------------|---------------|-------|
| `SK_*` columns | `*Key` | Technical keys, hidden in report |
| `*_Code` columns | `* Code` | Reference codes with spaces |
| `*_Name` columns | `*` or `* Name` | Friendly display names |
| `Is_*` flags | `Is *` | Boolean flags with spaces |
| `*_Date` columns | `* Date` | Date fields with spaces |

---

**Document Version:** 2.0
**Last Updated:** 2026-01-29
**SQL Queries Validated Against:** Analytics schema definitions

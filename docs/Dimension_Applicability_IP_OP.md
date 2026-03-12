# Dimension Applicability Matrix (IP/OP)

This matrix defines whether each exposed dimension is applicable to `Fact_IP_Activity` and `Fact_OP_Activity`.

Rule:
- `Applicable` means the fact should carry a business-resolved FK for that dimension.
- `N/A (-1)` means the fact must store `-1` for that FK and resolve to the `N/A` member in the dimension.

| Dimension | IP | OP |
|---|---|---|
| `Dim_Date` (role dates) | Applicable | Applicable |
| `Dim_Age_Band` | Applicable | Applicable |
| `Dim_Gender` | Applicable | Applicable |
| `Dim_Ethnicity` | Applicable | Applicable |
| `Dim_Provider` | Applicable | Applicable |
| `Dim_LSOA` | Applicable | Applicable |
| `Dim_Specialty` | Applicable | Applicable |
| `Dim_HRG` | Applicable | Applicable |
| `Dim_Commissioner` | Applicable | Applicable |
| `Dim_GPPractice` | Applicable | Applicable |
| `Dim_PCN` | Applicable | Applicable |
| `Dim_POD` | Applicable | Applicable |
| `Dim_OpPlan_MeasureSet` | Applicable | Applicable |
| `Dim_CAM_Service_Category` | Applicable | Applicable |
| `Dim_CAM_Assignment_Reason` | Applicable | Applicable |
| `Dim_Admission_Method` | Applicable | N/A (-1) |
| `Dim_Admission_Source` | Applicable | N/A (-1) |
| `Dim_Discharge_Method` | Applicable | N/A (-1) |
| `Dim_Discharge_Destination` | Applicable | N/A (-1) |
| `Dim_IP_Patient_Classification` | Applicable | N/A (-1) |
| `Dim_Attendance_Status` | N/A (-1) | Applicable |
| `Dim_Attendance_Outcome` | N/A (-1) | Applicable |
| `Dim_Attendance_Type` | N/A (-1) | Applicable |
| `Dim_DNA_Indicator` | N/A (-1) | Applicable |
| `Dim_Priority_Type` | N/A (-1) | Applicable |
| `Dim_Referral_Source` | N/A (-1) | Applicable |
| `Dim_Attendance_Disposal` | N/A (-1) | N/A (-1) |

Notes:
- Scope is intentionally IP/OP only. AE applicability is handled in a separate phase.
- `N/A` members are provided by dictionary-backed dimension views via explicit `UNION ALL` rows with surrogate key `-1`.

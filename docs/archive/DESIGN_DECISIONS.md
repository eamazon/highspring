# Design Decisions

**Created:** 2026-01-05 11:06 UTC  
**Last Updated:** 2026-01-19 10:52 UTC

**Purpose:** Log major architectural and technical choices with rationale.

**Format:** Append new decisions chronologically. Include date, decision, rationale, and alternatives considered.

---

## 2026-01-05: Commissioner End Dates & Schema Fixes

**Decision:** Capture `Operational_End_Date` and `Legal_End_Date` from ODS API; Map `Operational_End_Date` to `Dim_Commissioner.Valid_To`.
**Rationale:**
- **Data Quality:** Legacy CCGs (e.g., 07V) appeared active (Valid_To = 9999-12-31) because we ignored end dates.
- **Schema Alignment:** Staging table must match extraction script outputs exactly.
- **Logic:** Inactive status + End Date allows correct `Valid_To` population in Dimension.

**Alternatives Considered:**
- Infer End Date from Status change - Rejected: Unreliable without history.
- Use Legal End Date - Rejected: Assessment shows Operational dates map better to financial responsibility.

---

## 2026-01-05: Automated Workflow System

**Decision:** Implement .agent/workflows with dual-state model (CURRENT_STATE.md + task.md)  
**Rationale:** 
- Native Antigravity patterns (.agent/ not .claude/)
- Persistent state survives conversations
- Real-time task tracking during work
- Intelligent quality monitoring via review.md

**Alternatives Considered:**
- Claude Code conventions (.claude/CLAUDE.md) - Rejected: Not native to Antigravity
- Single state file approach - Rejected: Loses granular task tracking
- Manual handovers only - Rejected: Inconsistent, time-consuming

---

## 2026-01-05: Minimal Documentation Policy

**Decision:** Consolidate 27 docs files → 7 core files max  
**Rationale:**
- 22 files were never read by agents
- Redundant planning docs (4 implementation plans)
- Context scattered across multiple locations
- Agent init took 5-10 minutes searching

**Core Files:**
1. README.md (human onboarding)
2. .agent/context/CURRENT_STATE.md (agent context)
3. docs/build/deployment_guide.md (SOP)
4. docs/DESIGN_DECISIONS.md (this file)
5. docs/schema/*.md (data models)

**Alternatives Considered:**
- Keep all docs - Rejected: Overwhelming, redundant
- Delete old docs - Rejected: Lose historical context
- Wiki-based - Rejected: Adds external dependency

**Implementation:** Archive 20 files to docs/archive/

---

## 2026-01-02: PCN Dimension Strategy

**Decision:** Denormalize PCN into Dim_GPPractice (no separate Dim_PCN)  
**Rationale:**
- Simpler queries (one FK in fact tables vs two)
- Better Power BI performance (fewer joins)
- PCN always accessed via GP Practice, never standalone
- Follows Kimball best practice for "always-joined" dimensions

**Alternatives Considered:**
- Separate Dim_PCN - Rejected: Adds complexity without value
- Bridge table GP<>PCN - Rejected: Overkill for 1:1 relationship

---

## 2026-01-02: POD Code Data Type

**Decision:** Use VARCHAR(20) instead of INT for POD_Code  
**Rationale:**
- IP.GetPodType() and OP.GetPodType() return VARCHAR
- Avoids type conversion overhead in ETL
- NHS POD codes are alphanumeric (e.g., "OPFASPCL", "NEL")

**Alternatives Considered:**
- INT with lookup table - Rejected: POD codes aren't sequential integers
- Keep as INT, convert in ETL - Rejected: Unnecessary complexity

---

## 2026-01-02: HTTP 406 Fix for GP Fetcher

**Decision:** Remove `&Status=Active` parameter from RO177 API call  
**Rationale:**
- NHS ODS API returns 406 error when Status parameter used with RO177 role
- API quirk specific to GP Practice (Prescribing Cost Centre) endpoint
- Filter client-side in Python instead

**Alternatives Considered:**
- Different API endpoint - Rejected: RO177 is correct role for GPs
- Accept all records - Rejected: Need active filter for data quality

---

## 2026-01-19: PCN Dimension Derived from GP Practice

**Decision:** Populate `Dim_PCN` from `Analytics.tbl_Dim_GPPractice` (distinct PCN_Code/PCN_Name), rather than external PCN staging loads.  
**Rationale:**
- **Completeness:** GP practice data already contains PCN mappings at scale; prior PCN staging loads were empty/partial.
- **Consistency:** Keeps PCN values aligned with practice records used in facts and avoids mismatched lookups.
- **Operational simplicity:** Removes dependency on a separate PCN staging feed for Phase 1.

**Alternatives Considered:**
- Continue PCN staging loads - Rejected: Staging feeds were incomplete and caused `SK_PCN_ID = -1` in facts.
- Remove `Dim_PCN` entirely - Rejected: Existing fact joins and reporting expect a PCN dimension.

---

## 2026-01-19: Parallel ED v2 Materialisation

**Decision:** Materialise ED v2 activity in parallel using `Unified.vw_ED_EncounterDenormalised_DateRange_v2`, writing to `Unified.tbl_ED_EncounterDenormalised_Active_v2` and FY-specific tables until validation is complete.  
**Rationale:**
- **Accuracy:** v2 view includes the newer ECDS fields and discharge status coding.
- **Safety:** Parallel tables allow side-by-side validation without disrupting existing consumers of v1.
- **Promotion path:** v2 can be promoted to the legacy table/proc names once testing is signed off.

**Alternatives Considered:**
- Replace v1 in place - Rejected: high risk to downstream reporting without validation.
- Keep v2 view only (no materialised tables) - Rejected: materialisation is required for performance and downstream loads.

---

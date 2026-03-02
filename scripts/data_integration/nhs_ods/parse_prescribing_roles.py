#!/usr/bin/env python3
"""Generate SQL loader for [Analytics].[Ref_Prescribing_Setting] from prescribing_roles.csv."""

from __future__ import annotations

import argparse
import csv
from pathlib import Path


def sql_escape(value: str | None) -> str:
    if value is None or value == "":
        return "NULL"
    return "'" + str(value).replace("'", "''") + "'"


def sql_int_or_null(value: str | None) -> str:
    if value is None:
        return "NULL"
    cleaned = str(value).strip()
    if cleaned == "":
        return "NULL"
    return cleaned if cleaned.isdigit() else "NULL"


def resolve_default_input() -> Path:
    repo_root = Path(__file__).resolve().parents[3]
    local_candidate = repo_root / "sql" / "05_api" / "raw_inspection" / "prescribing_roles.csv"
    if local_candidate.exists():
        return local_candidate
    # Back-compat fallback for existing shared data workspace.
    fallback = Path("/home/speddi/dev/icb/sustabular/sql/analytics_platform/05_api/raw_inspection/prescribing_roles.csv")
    return fallback


def resolve_default_output() -> Path:
    repo_root = Path(__file__).resolve().parents[3]
    return repo_root / "sql" / "05_api" / "01_Load_Ref_Prescribing_Setting.sql"


def main() -> int:
    parser = argparse.ArgumentParser(description="Build SQL for Ref_Prescribing_Setting lookup table.")
    parser.add_argument("--input", default=str(resolve_default_input()), help="Path to prescribing_roles.csv")
    parser.add_argument("--output", default=str(resolve_default_output()), help="Output SQL file path")
    args = parser.parse_args()

    input_csv = Path(args.input)
    output_sql = Path(args.output)

    if not input_csv.exists():
        raise FileNotFoundError(f"Input CSV not found: {input_csv}")

    output_sql.parent.mkdir(parents=True, exist_ok=True)

    print(f">>> Parsing {input_csv}")

    with input_csv.open("r", encoding="utf-8-sig", newline="") as infile, output_sql.open("w", encoding="utf-8") as outfile:
        reader = csv.DictReader(infile)

        outfile.write(
            """-------------------------------------------------------------------------------
-- Reference Table: Prescribing Setting / Role Mapping
-- Maps NHS ODS role IDs to prescribing setting descriptions
-- Auto-generated from prescribing_roles.csv
-------------------------------------------------------------------------------

USE [Data_Lab_SWL_Live];
GO

IF OBJECT_ID('[Analytics].[Ref_Prescribing_Setting]', 'U') IS NOT NULL
BEGIN
    PRINT 'Table [Analytics].[Ref_Prescribing_Setting] already exists. Dropping...';
    DROP TABLE [Analytics].[Ref_Prescribing_Setting];
END
GO

CREATE TABLE [Analytics].[Ref_Prescribing_Setting]
(
    Role_ID VARCHAR(20) NOT NULL,         -- e.g. RO76, RO87 and RO80
    Setting_Code INT NULL,                -- Numeric prescribing setting code from CSV
    Setting_Description VARCHAR(255) NOT NULL,
    CONSTRAINT PK_Ref_Prescribing_Setting PRIMARY KEY (Role_ID)
);
GO

PRINT '[OK] Created table: [Analytics].[Ref_Prescribing_Setting]';
GO

-- Insert reference data
"""
        )

        row_count = 0
        for row in reader:
            role_id = sql_escape((row.get("role_id") or "").strip())
            setting_code = sql_int_or_null(row.get("prescribing_setting"))
            setting_desc = sql_escape((row.get("setting_desc") or "").strip())

            outfile.write(
                "INSERT INTO [Analytics].[Ref_Prescribing_Setting] "
                f"(Role_ID, Setting_Code, Setting_Description) VALUES ({role_id}, {setting_code}, {setting_desc});\n"
            )
            row_count += 1

        outfile.write(
            """GO

PRINT '[OK] Inserted ' + CAST(@@ROWCOUNT AS VARCHAR) + ' prescribing role reference records';
GO

CREATE NONCLUSTERED INDEX IX_Ref_Prescribing_Setting_Code
    ON [Analytics].[Ref_Prescribing_Setting](Setting_Code)
    INCLUDE (Setting_Description);
GO

PRINT '[OK] Created index: IX_Ref_Prescribing_Setting_Code';
GO
"""
        )

    print(f">>> Generated {output_sql}")
    print(f">>> Rows: {row_count}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

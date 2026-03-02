#!/usr/bin/env python3
"""
Fetch NHS HRG code-to-group workbooks and generate SQL for Analytics.tbl_Staging_HRG.

Supports both workbook layouts:
1) Modern: sheet "HRG & Subchapters"
2) Older: separate sheets "HRG", "Subchapter", "Chapter"
"""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import io
import json
import re
import urllib.request
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Tuple


NS = {
    "a": "http://schemas.openxmlformats.org/spreadsheetml/2006/main",
    "r": "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
}


SOURCES = [
    {
        "label": "HRG4 2025/26",
        "release_date": "2025-04-01",
        "url": "https://digital.nhs.uk/binaries/content/assets/website-assets/services/national-casemix-office/hrg4-2025-2026-local-payment-grouper/hrg4-202526-local-payment-grouper-code-to-group-v1.0.xlsx",
    },
    {
        "label": "HRG4 2024/25",
        "release_date": "2024-04-01",
        "url": "https://digital.nhs.uk/binaries/content/assets/website-assets/services/national-casemix-office/hrg4-2024-25-local-payment-grouper/hrg4-202425-local-payment-grouper-code-to-group-v1.0.xlsx",
    },
    {
        "label": "HRG4 2023/24",
        "release_date": "2023-04-01",
        "url": "https://digital.nhs.uk/binaries/content/assets/website-assets/services/national-casemix-office/hrg4-2023-24-consultation-grouper/hrg4-202324-consultation-grouper-code-to-group-v1.0.xlsx",
    },
    {
        "label": "HRG4 2022/23",
        "release_date": "2022-04-01",
        "url": "https://digital.nhs.uk/binaries/content/assets/website-assets/services/national-casemix-office/hrg4-202223-consultation-grouper/hrg4-202223-consultation-grouper-code-to-group-v1.0.xlsx",
    },
    {
        "label": "HRG4 2021/22",
        "release_date": "2021-04-01",
        "url": "https://digital.nhs.uk/binaries/content/assets/website-assets/services/national-casemix-office/hrg4-2021-22-consultation-grouper/hrg4-202122-consultation-grouper-code-to-group-v1.0.xlsx",
    },
    {
        "label": "HRG4 2020/21",
        "release_date": "2020-04-01",
        "url": "https://digital.nhs.uk/binaries/content/assets/website-assets/services/national-casemix-office/hrg4-2020-21-consultation-grouper/hrg4-202021-consultation-grouper-code-to-group-v1.0.xlsx",
    },
]


def normalize_text(value: Optional[str]) -> str:
    if value is None:
        return ""
    value = value.replace("\n", " ")
    value = re.sub(r"\s+", " ", value.strip())
    return value


def sanitize_code(value: Optional[str]) -> str:
    return normalize_text(value).upper()


def fetch_bytes(url: str, timeout: int = 120) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": "highspring-hrg-loader/1.0"})
    with urllib.request.urlopen(req, timeout=timeout) as response:
        return response.read()


def load_shared_strings(zf: zipfile.ZipFile) -> List[str]:
    if "xl/sharedStrings.xml" not in zf.namelist():
        return []
    root = ET.fromstring(zf.read("xl/sharedStrings.xml"))
    values: List[str] = []
    for si in root.findall("a:si", NS):
        values.append("".join((t.text or "") for t in si.findall(".//a:t", NS)))
    return values


def workbook_sheet_map(zf: zipfile.ZipFile) -> Dict[str, str]:
    wb = ET.fromstring(zf.read("xl/workbook.xml"))
    rels = ET.fromstring(zf.read("xl/_rels/workbook.xml.rels"))
    rel_map = {r.attrib["Id"]: r.attrib["Target"] for r in rels}
    out: Dict[str, str] = {}
    for sh in wb.findall("a:sheets/a:sheet", NS):
        name = sh.attrib["name"]
        rid = sh.attrib["{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id"]
        target = rel_map[rid]
        out[name] = "xl/" + target if not target.startswith("/") else target[1:]
    return out


def parse_sheet_rows(
    zf: zipfile.ZipFile, sheet_path: str, shared_strings: List[str]
) -> List[List[str]]:
    root = ET.fromstring(zf.read(sheet_path))
    rows: List[List[str]] = []
    for row in root.findall("a:sheetData/a:row", NS):
        out_row: List[str] = []
        for c in row.findall("a:c", NS):
            ctype = c.attrib.get("t")
            v = c.find("a:v", NS)
            if v is None or v.text is None:
                out_row.append("")
                continue
            raw = v.text
            if ctype == "s" and raw.isdigit():
                idx = int(raw)
                out_row.append(shared_strings[idx] if idx < len(shared_strings) else raw)
            else:
                out_row.append(raw)
        if any(normalize_text(x) for x in out_row):
            rows.append(out_row)
    return rows


def parse_modern_hrg_subchapters(rows: List[List[str]]) -> List[Dict[str, str]]:
    if not rows:
        return []
    data_rows = rows[1:]
    out: List[Dict[str, str]] = []
    for r in data_rows:
        if len(r) < 7:
            continue
        hrg_code = sanitize_code(r[0])
        if not hrg_code:
            continue
        out.append(
            {
                "HRGCode": hrg_code,
                "HRGDescription": normalize_text(r[1]),
                "Core_Or_Unbundled": normalize_text(r[2]),
                "HRGSubchapterKey": sanitize_code(r[3]),
                "HRGSubchapter": normalize_text(r[4]),
                "HRGChapterKey": sanitize_code(r[5]),
                "HRGChapter": normalize_text(r[6]),
            }
        )
    return out


def parse_older_layout(
    hrg_rows: List[List[str]], sub_rows: List[List[str]], chapter_rows: List[List[str]]
) -> List[Dict[str, str]]:
    chapter_map: Dict[str, str] = {}
    for r in chapter_rows[1:]:
        if len(r) < 2:
            continue
        chapter_map[sanitize_code(r[0])] = normalize_text(r[1])

    sub_map: Dict[str, Tuple[str, str]] = {}
    for r in sub_rows[1:]:
        if len(r) < 3:
            continue
        chapter_key = sanitize_code(r[0])
        sub_key = sanitize_code(r[1])
        sub_desc = normalize_text(r[2])
        if sub_key:
            sub_map[sub_key] = (chapter_key, sub_desc)

    out: List[Dict[str, str]] = []
    for r in hrg_rows[1:]:
        if len(r) < 3:
            continue
        hrg_code = sanitize_code(r[0])
        if not hrg_code:
            continue
        sub_key = sanitize_code(hrg_code[:2])
        chapter_key, sub_desc = sub_map.get(sub_key, ("", ""))
        out.append(
            {
                "HRGCode": hrg_code,
                "HRGDescription": normalize_text(r[1]),
                "Core_Or_Unbundled": normalize_text(r[2]),
                "HRGSubchapterKey": sub_key,
                "HRGSubchapter": sub_desc,
                "HRGChapterKey": chapter_key,
                "HRGChapter": chapter_map.get(chapter_key, ""),
            }
        )
    return out


def parse_hrg_file(blob: bytes) -> List[Dict[str, str]]:
    with zipfile.ZipFile(io.BytesIO(blob)) as zf:
        shared_strings = load_shared_strings(zf)
        sheet_map = workbook_sheet_map(zf)

        if "HRG & Subchapters" in sheet_map:
            rows = parse_sheet_rows(zf, sheet_map["HRG & Subchapters"], shared_strings)
            return parse_modern_hrg_subchapters(rows)

        required = ("HRG", "Subchapter", "Chapter")
        if all(name in sheet_map for name in required):
            hrg_rows = parse_sheet_rows(zf, sheet_map["HRG"], shared_strings)
            sub_rows = parse_sheet_rows(zf, sheet_map["Subchapter"], shared_strings)
            chapter_rows = parse_sheet_rows(zf, sheet_map["Chapter"], shared_strings)
            return parse_older_layout(hrg_rows, sub_rows, chapter_rows)

    return []


def dedupe_rows(rows: Iterable[Dict[str, str]]) -> List[Dict[str, str]]:
    seen = set()
    out: List[Dict[str, str]] = []
    for row in rows:
        key = (
            row["HRGCode"],
            row["HRGDescription"],
            row["Core_Or_Unbundled"],
            row["HRGSubchapterKey"],
            row["HRGSubchapter"],
            row["HRGChapterKey"],
            row["HRGChapter"],
            row["Release_Date"],
        )
        if key in seen:
            continue
        seen.add(key)
        out.append(row)
    return out


def collapse_rows_by_code(rows: List[Dict[str, str]]) -> List[Dict[str, str]]:
    releases = sorted({r["Release_Date"] for r in rows})
    next_release = {releases[i]: (releases[i + 1] if i + 1 < len(releases) else None) for i in range(len(releases))}

    by_code: Dict[str, List[Dict[str, str]]] = {}
    for r in rows:
        by_code.setdefault(r["HRGCode"], []).append(r)

    out: List[Dict[str, str]] = []
    latest_release = releases[-1] if releases else None

    for code, code_rows in by_code.items():
        code_rows.sort(key=lambda x: x["Release_Date"])
        first_release = code_rows[0]["Release_Date"]
        last_release = code_rows[-1]["Release_Date"]
        latest_row = code_rows[-1]

        nr = next_release.get(last_release)
        valid_to = None if (latest_release and last_release == latest_release) else (None if nr is None else (dt.date.fromisoformat(nr) - dt.timedelta(days=1)).isoformat())

        out.append(
            {
                "HRGCode": code,
                "HRGDescription": latest_row["HRGDescription"],
                "Core_Or_Unbundled": latest_row["Core_Or_Unbundled"],
                "HRGSubchapterKey": latest_row["HRGSubchapterKey"],
                "HRGSubchapter": latest_row["HRGSubchapter"],
                "HRGChapterKey": latest_row["HRGChapterKey"],
                "HRGChapter": latest_row["HRGChapter"],
                "Valid_From": first_release,
                "Last_Seen_Release_Date": last_release,
                "Valid_To": valid_to,
                "Is_Current": 1 if (latest_release and last_release == latest_release) else 0,
                "Source_URL": latest_row["Source_URL"],
            }
        )

    out.sort(key=lambda x: x["HRGCode"])
    return out


def sql_literal(value: Optional[str]) -> str:
    if value is None:
        return "NULL"
    value = str(value).strip()
    if value == "":
        return "NULL"
    return "'" + value.replace("'", "''") + "'"


def generate_sql(rows: List[Dict[str, str]], batch_size: int = 1000) -> str:
    lines = [
        "-- HRG staging load generated from NHS digital HRG code-to-group files",
        f"-- Generated: {dt.datetime.now().isoformat()}",
        f"-- Total rows: {len(rows)}",
        "",
        "TRUNCATE TABLE [Analytics].[tbl_Staging_HRG];",
        "",
    ]
    columns = (
        "HRGCode, HRGDescription, Core_Or_Unbundled, "
        "HRGSubchapterKey, HRGSubchapter, HRGChapterKey, HRGChapter, Release_Date, Source_URL"
    )

    for i in range(0, len(rows), batch_size):
        chunk = rows[i : i + batch_size]
        lines.append(f"INSERT INTO [Analytics].[tbl_Staging_HRG] ({columns}) VALUES")
        values = []
        for r in chunk:
            values.append(
                "("
                f"{sql_literal(r['HRGCode'])}, "
                f"{sql_literal(r['HRGDescription'])}, "
                f"{sql_literal(r['Core_Or_Unbundled'])}, "
                f"{sql_literal(r['HRGSubchapterKey'])}, "
                f"{sql_literal(r['HRGSubchapter'])}, "
                f"{sql_literal(r['HRGChapterKey'])}, "
                f"{sql_literal(r['HRGChapter'])}, "
                f"{sql_literal(r['Release_Date'])}, "
                f"{sql_literal(r['Source_URL'])}"
                ")"
            )
        lines.append(",\n".join(values) + ";")
        lines.append("")
    return "\n".join(lines)


def generate_csv(rows: List[Dict[str, str]]) -> str:
    out = io.StringIO()
    writer = csv.writer(out, lineterminator="\n")
    writer.writerow(
        [
            "HRGCode",
            "HRGDescription",
            "Core_Or_Unbundled",
            "HRGSubchapterKey",
            "HRGSubchapter",
            "HRGChapterKey",
            "HRGChapter",
            "Release_Date",
            "Source_URL",
        ]
    )
    for r in rows:
        writer.writerow(
            [
                r["HRGCode"],
                r["HRGDescription"],
                r["Core_Or_Unbundled"],
                r["HRGSubchapterKey"],
                r["HRGSubchapter"],
                r["HRGChapterKey"],
                r["HRGChapter"],
                r["Release_Date"],
                r["Source_URL"],
            ]
        )
    return out.getvalue()


def generate_bulk_sql(csv_path_for_sql_server: str) -> str:
    escaped_path = csv_path_for_sql_server.replace("'", "''")
    return f"""-- HRG staging bulk load (CSV -> tbl_Staging_HRG)
-- Update the path below if SQL Server cannot access this location.
TRUNCATE TABLE [Analytics].[tbl_Staging_HRG];

BULK INSERT [Analytics].[tbl_Staging_HRG]
FROM '{escaped_path}'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '\"',
    CODEPAGE = '65001',
    TABLOCK
);
"""


def generate_collapsed_sql(rows: List[Dict[str, str]], batch_size: int = 1000) -> str:
    lines = [
        "-- HRG collapsed load generated from NHS digital HRG code-to-group files",
        f"-- Generated: {dt.datetime.now().isoformat()}",
        f"-- Total rows: {len(rows)}",
        "",
        "TRUNCATE TABLE [Analytics].[tbl_HRG];",
        "SET IDENTITY_INSERT [Analytics].[tbl_HRG] ON;",
        "INSERT INTO [Analytics].[tbl_HRG] (SK_HRGID, HRGCode, HRGDescription, Core_Or_Unbundled, HRGSubchapterKey, HRGSubchapter, HRGChapterKey, HRGChapter, Last_Seen_Release_Date, Source_URL, Valid_From, Valid_To, Is_Current, Created_By)",
        "VALUES (-1, 'UNKNOWN', 'Unknown HRG', NULL, NULL, 'Unknown', NULL, 'Unknown', '1900-01-01', NULL, '1900-01-01', NULL, 1, SUSER_SNAME());",
        "SET IDENTITY_INSERT [Analytics].[tbl_HRG] OFF;",
        "",
    ]
    cols = (
        "HRGCode, HRGDescription, Core_Or_Unbundled, "
        "HRGSubchapterKey, HRGSubchapter, HRGChapterKey, HRGChapter, "
        "Last_Seen_Release_Date, Source_URL, Valid_From, Valid_To, Is_Current, Created_By"
    )
    for i in range(0, len(rows), batch_size):
        chunk = rows[i : i + batch_size]
        lines.append(f"INSERT INTO [Analytics].[tbl_HRG] ({cols}) VALUES")
        values = []
        for r in chunk:
            values.append(
                "("
                f"{sql_literal(r['HRGCode'])}, "
                f"{sql_literal(r['HRGDescription'])}, "
                f"{sql_literal(r['Core_Or_Unbundled'])}, "
                f"{sql_literal(r['HRGSubchapterKey'])}, "
                f"{sql_literal(r['HRGSubchapter'])}, "
                f"{sql_literal(r['HRGChapterKey'])}, "
                f"{sql_literal(r['HRGChapter'])}, "
                f"{sql_literal(r['Last_Seen_Release_Date'])}, "
                f"{sql_literal(r['Source_URL'])}, "
                f"{sql_literal(r['Valid_From'])}, "
                f"{sql_literal(r['Valid_To'])}, "
                f"{r['Is_Current']}, "
                "SUSER_SNAME()"
                ")"
            )
        lines.append(",\n".join(values) + ";")
        lines.append("")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Fetch NHS HRG workbooks and generate staging SQL")
    parser.add_argument(
        "--output",
        choices=["sql", "json", "bulk", "collapsed_sql"],
        default="sql",
        help="Output format",
    )
    parser.add_argument(
        "--out-dir",
        default="sql/04_etl",
        help="Output directory",
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=1000,
        help="Rows per INSERT batch for SQL output",
    )
    parser.add_argument(
        "--bulk-file-path",
        default=None,
        help="Server-accessible CSV path to embed in BULK INSERT SQL (used with --output bulk)",
    )
    args = parser.parse_args()

    all_rows: List[Dict[str, str]] = []
    for source in SOURCES:
        print(f"Fetching {source['label']} ...")
        blob = fetch_bytes(source["url"])
        parsed = parse_hrg_file(blob)
        if not parsed:
            raise RuntimeError(f"No HRG rows parsed for {source['label']}")
        for row in parsed:
            row["Release_Date"] = source["release_date"]
            row["Source_URL"] = source["url"]
        all_rows.extend(parsed)
        print(f"  rows: {len(parsed)}")

    all_rows = dedupe_rows(all_rows)
    print(f"Total rows (deduped): {len(all_rows)}")

    timestamp = dt.datetime.now().strftime("%Y%m%d_%H%M%S")
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    if args.output == "sql":
        path = out_dir / f"nhs_hrg_code_to_group_{timestamp}.sql"
        path.write_text(generate_sql(all_rows, batch_size=args.batch_size), encoding="utf-8")
    elif args.output == "collapsed_sql":
        collapsed = collapse_rows_by_code(all_rows)
        path = out_dir / f"nhs_hrg_code_to_group_collapsed_{timestamp}.sql"
        path.write_text(generate_collapsed_sql(collapsed, batch_size=args.batch_size), encoding="utf-8")
        print(f"[OK] Collapsed rows: {len(collapsed)}")
    elif args.output == "bulk":
        csv_path = out_dir / f"nhs_hrg_code_to_group_{timestamp}.csv"
        csv_path.write_text(generate_csv(all_rows), encoding="utf-8")
        sql_path = out_dir / f"nhs_hrg_code_to_group_bulk_{timestamp}.sql"
        sql_bulk_path = args.bulk_file_path if args.bulk_file_path else str(csv_path)
        sql_path.write_text(generate_bulk_sql(sql_bulk_path), encoding="utf-8")
        path = sql_path
        print(f"[OK] Wrote {csv_path}")
    else:
        path = out_dir / f"nhs_hrg_code_to_group_{timestamp}.json"
        path.write_text(json.dumps(all_rows, indent=2), encoding="utf-8")

    print(f"[OK] Wrote {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

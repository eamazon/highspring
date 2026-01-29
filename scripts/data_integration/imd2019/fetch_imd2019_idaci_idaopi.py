#!/usr/bin/env python3
import argparse, io, os, sys, time
import requests
import pandas as pd

def norm(s):
    return ''.join(ch for ch in str(s).lower() if ch.isalnum())

def pick_sheet(xls):
    required = [
        ('lsoa', 'code'),
        ('lsoa', 'name'),
        ('local', 'authority', 'district', 'code'),
        ('local', 'authority', 'district', 'name'),
        ('imd', 'rank'),
        ('imd', 'decile')
    ]
    for name in xls.sheet_names:
        for header_row in range(0, 6):
            try:
                df = xls.parse(name, nrows=1, header=header_row)
            except Exception:
                continue
            cols = {norm(c): c for c in df.columns}
            if all(any(all(k in col for k in keys) for col in cols) for keys in required):
                return name, header_row
    raise SystemExit('No sheet found with required IMD 2019 columns')

def find_col(cols, *keys):
    for k, orig in cols.items():
        if all(key in k for key in keys):
            return orig
    return None

def main():
    ap = argparse.ArgumentParser(description='Fetch IMD 2019 IDACI/IDAOPI and generate SQL for staging')
    ap.add_argument('--url', required=True, help='IMD 2019 XLSX URL')
    ap.add_argument('--output', choices=['sql', 'csv'], default='sql')
    ap.add_argument('--batch-size', type=int, default=1000)
    ap.add_argument('--out-dir', default='.')
    ap.add_argument('--sheet', help='Optional sheet name override')
    ap.add_argument('--header-row', type=int, help='Optional header row override (0-based)')
    args = ap.parse_args()

    t0 = time.time()
    r = requests.get(args.url, timeout=60)
    r.raise_for_status()
    xls = pd.ExcelFile(io.BytesIO(r.content))
    if args.sheet:
        sheet = args.sheet
        header_row = 0 if args.header_row is None else args.header_row
    else:
        sheet, header_row = pick_sheet(xls)
    df = xls.parse(sheet, header=header_row)

    cols = {norm(c): c for c in df.columns}
    lsoa = find_col(cols, 'lsoa', 'code')
    lsoa_name = find_col(cols, 'lsoa', 'name')
    lad_code = find_col(cols, 'local', 'authority', 'district', 'code')
    lad_name = find_col(cols, 'local', 'authority', 'district', 'name')
    imd_rank = find_col(cols, 'imd', 'rank')
    imd_decile = find_col(cols, 'imd', 'decile')
    idaci_score = find_col(cols, 'idaci', 'score')
    idaci_rank = find_col(cols, 'idaci', 'rank')
    idaci_decile = find_col(cols, 'idaci', 'decile')
    idaopi_score = find_col(cols, 'idaopi', 'score')
    idaopi_rank = find_col(cols, 'idaopi', 'rank')
    idaopi_decile = find_col(cols, 'idaopi', 'decile')

    missing = [n for n, v in {
        'LSOA_Code': lsoa,
        'LSOA_Name': lsoa_name,
        'LocalAuthority_District_Code': lad_code,
        'LocalAuthority_District_Name': lad_name,
        'IMD_Rank': imd_rank,
        'IMD_Decile': imd_decile
    }.items() if v is None]
    if missing:
        raise SystemExit(f'Missing columns in sheet \"{sheet}\" (header row {header_row}): {", ".join(missing)}')

    cols_in = [lsoa, lsoa_name, lad_code, lad_name, imd_rank, imd_decile]
    out = df[cols_in].copy()
    out.columns = ['LSOA_Code', 'LSOA_Name', 'LocalAuthority_District_Code', 'LocalAuthority_District_Name', 'IMD_Rank', 'IMD_Decile']
    out['IDACI_Score'] = df[idaci_score] if idaci_score else None
    out['IDACI_Rank'] = df[idaci_rank] if idaci_rank else None
    out['IDACI_Decile'] = df[idaci_decile] if idaci_decile else None
    out['IDAOPI_Score'] = df[idaopi_score] if idaopi_score else None
    out['IDAOPI_Rank'] = df[idaopi_rank] if idaopi_rank else None
    out['IDAOPI_Decile'] = df[idaopi_decile] if idaopi_decile else None
    out = out[['LSOA_Code', 'LSOA_Name', 'LocalAuthority_District_Code', 'LocalAuthority_District_Name', 'IMD_Rank', 'IMD_Decile', 'IDACI_Score', 'IDACI_Rank', 'IDACI_Decile', 'IDAOPI_Score', 'IDAOPI_Rank', 'IDAOPI_Decile']]
    out = out[out['LSOA_Code'].notna()]

    ts = time.strftime('%Y%m%d_%H%M%S')
    label = f'imd2019_idaci_idaopi_{ts}'
    os.makedirs(args.out_dir, exist_ok=True)

    if args.output == 'csv':
        path = os.path.join(args.out_dir, f'{label}.csv')
        out.to_csv(path, index=False)
        print(f'rows={len(out)} output={path} sheet={sheet} duration_secs={round(time.time()-t0,2)}')
        return 0

    # Create archive directory
    archive_dir = os.path.join(args.out_dir, 'archive')
    os.makedirs(archive_dir, exist_ok=True)

    archive_path = os.path.join(archive_dir, f'{label}.sql')
    latest_path = os.path.join(args.out_dir, 'staging_lsoa_imd.sql')

    def fmt(v):
        if pd.isna(v) or v == '':
            return 'NULL'
        if isinstance(v, str):
            return "'" + v.replace("'", "''") + "'"
        return str(int(v)) if isinstance(v, (int,)) else str(v)

    lines = [
        '-- IMD 2019 IDACI/IDAOPI staging load',
        f'-- Source: {args.url}',
        f'-- Sheet: {sheet}',
        f'-- Rows: {len(out)}',
        '',
        'TRUNCATE TABLE [Analytics].[tbl_Staging_LSOA_IMD2019];',
        ''
    ]

    cols_sql = 'LSOA_Code, LSOA_Name, LocalAuthority_District_Code, LocalAuthority_District_Name, IMD_Rank, IMD_Decile, IDACI_Score, IDACI_Rank, IDACI_Decile, IDAOPI_Score, IDAOPI_Rank, IDAOPI_Decile, Source_File'
    for i in range(0, len(out), args.batch_size):
        chunk = out.iloc[i:i + args.batch_size]
        lines.append(f'INSERT INTO [Analytics].[tbl_Staging_LSOA_IMD2019] ({cols_sql}) VALUES')
        values = []
        for _, row in chunk.iterrows():
            values.append('(' + ', '.join([
                fmt(row['LSOA_Code']),
                fmt(row['LSOA_Name']),
                fmt(row['LocalAuthority_District_Code']),
                fmt(row['LocalAuthority_District_Name']),
                fmt(row['IMD_Rank']),
                fmt(row['IMD_Decile']),
                fmt(row['IDACI_Score']),
                fmt(row['IDACI_Rank']),
                fmt(row['IDACI_Decile']),
                fmt(row['IDAOPI_Score']),
                fmt(row['IDAOPI_Rank']),
                fmt(row['IDAOPI_Decile']),
                fmt(args.url)
            ]) + ')')
        lines.append(',\n'.join(values) + ';')

    sql_content = '\n'.join(lines)

    # Write timestamped archive copy
    with open(archive_path, 'w', encoding='utf-8') as f:
        f.write(sql_content)
    print(f'Saved archive to: {archive_path}')

    # Write fixed "latest" file for deploy script (always overwrites)
    with open(latest_path, 'w', encoding='utf-8') as f:
        f.write(sql_content)
    print(f'Saved latest to: {latest_path}')

    print(f'rows={len(out)} sheet={sheet} duration_secs={round(time.time()-t0,2)}')
    return 0

if __name__ == '__main__':
    sys.exit(main())

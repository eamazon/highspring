#!/usr/bin/env python3
import argparse, csv, os, sys, time

def fmt(val):
    if val is None:
        return 'NULL'
    v = str(val).strip()
    if v == '':
        return 'NULL'
    return "'" + v.replace("'", "''") + "'"

def parse_date(v):
    v = (v or '').strip()
    if not v:
        return None
    if len(v) == 8 and v.isdigit():
        return f"{v[0:4]}-{v[4:6]}-{v[6:8]}"
    return v

def main():
    ap = argparse.ArgumentParser(description='Generate SQL for PCN core partner relationships')
    ap.add_argument('--input', required=True, help='Path to epcncorepartnerdetails CSV')
    ap.add_argument('--out-dir', default='sql/analytics_platform/05_api')
    ap.add_argument('--batch-size', type=int, default=1000)
    args = ap.parse_args()

    if not os.path.exists(args.input):
        print('Input file not found', file=sys.stderr)
        return 1

    ts = time.strftime('%Y%m%d_%H%M%S')
    os.makedirs(args.out_dir, exist_ok=True)
    out_path = os.path.join(args.out_dir, f'gp_pcn_relationships_{ts}.sql')

    with open(args.input, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    lines = [
        '-- PCN core partner relationships (epcncorepartnerdetails)',
        f'-- Source: {os.path.basename(args.input)}',
        f'-- Rows: {len(rows)}',
        '',
        'TRUNCATE TABLE [Analytics].[tbl_Staging_PCN_Relationships];',
        ''
    ]

    cols = ('Partner_Organisation_Code, Partner_Name, Practice_Parent_SubICB_Code, '
            'Practice_Parent_SubICB_Name, PCN_Code, PCN_Name, PCN_Parent_SubICB_Code, '
            'PCN_Parent_SubICB_Name, Relationship_Start_Date, Relationship_End_Date, '
            'SubICB_Match_Flag, Source_File')

    batch = []
    for r in rows:
        row = (
            fmt(r.get('Partner Organisation Code')),
            fmt(r.get('Partner Name')),
            fmt(r.get('Practice Parent Sub ICB Location Code')),
            fmt(r.get('Practice Parent Sub ICB Location Name')),
            fmt(r.get('PCN Code')),
            fmt(r.get('PCN Name')),
            fmt(r.get('PCN Parent Sub ICB Location Code')),
            fmt(r.get('PCN Parent Sub ICB Location Name')),
            fmt(parse_date(r.get('Practice to PCN Relationship Start Date'))),
            fmt(parse_date(r.get('Practice to PCN Relationship End Date'))),
            fmt(r.get('Practice Sub ICB and PCN Sub ICB Match?')),
            fmt(os.path.basename(args.input))
        )
        batch.append('(' + ', '.join(row) + ')')
        if len(batch) >= args.batch_size:
            lines.append(f'INSERT INTO [Analytics].[tbl_Staging_PCN_Relationships] ({cols}) VALUES')
            lines.append(',\n'.join(batch) + ';\n')
            batch = []

    if batch:
        lines.append(f'INSERT INTO [Analytics].[tbl_Staging_PCN_Relationships] ({cols}) VALUES')
        lines.append(',\n'.join(batch) + ';')

    with open(out_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))

    print(f'rows={len(rows)} output={out_path}')
    return 0

if __name__ == '__main__':
    sys.exit(main())

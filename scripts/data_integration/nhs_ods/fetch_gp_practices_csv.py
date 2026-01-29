
import pandas as pd
import requests
import zipfile
import io
import os
from datetime import datetime

# ---------------------------------------------------------
# Configuration
# ---------------------------------------------------------
OUTPUT_DIR = "./sql/analytics_platform/05_api"
TIMESTAMP = datetime.now().strftime('%Y%m%d_%H%M%S')

# ODS Data Search and Export - API Endpoints for CSV/ZIP Reports
# URL_GP_PRACTICES (epraccur) = GP Practices / Prescribing Cost Centres
URL_EPRACCUR = "https://www.odsdatasearchandexport.nhs.uk/api/getReport?report=epraccur"

# URL_PCN (epcn) = Primary Care Networks
URL_EPCN = "https://www.odsdatasearchandexport.nhs.uk/api/getReport?report=epcn"

# URL_MEMBERSHIPS (epcncorepartnerdetails) = PCN Core Partner Details (Links GPs to PCNs)
URL_EPCN_MEMBERS = "https://www.odsdatasearchandexport.nhs.uk/api/getReport?report=epcncorepartnerdetails"

# ---------------------------------------------------------
# Helpers
# ---------------------------------------------------------
def download_and_extract_csv(url: str, name: str) -> pd.DataFrame:
    print(f"Downloading {name} from {url}...")
    try:
        r = requests.get(url)
        r.raise_for_status()
        
        # Save Raw File for Inspection
        raw_dir = os.path.join(OUTPUT_DIR, "raw")
        if not os.path.exists(raw_dir):
            os.makedirs(raw_dir)
            
        # ODS reports usually come as ZIP files containing a single CSV
        try:
            z = zipfile.ZipFile(io.BytesIO(r.content))
            filename = z.namelist()[0]
            print(f"  Extracting {filename}...")
            
            # Save raw extracted CSV
            raw_path = os.path.join(raw_dir, f"raw_{name}.csv")
            with z.open(filename) as f_in, open(raw_path, 'wb') as f_out:
                f_out.write(f_in.read())
            print(f"  Saved raw file: {raw_path}")
            
            with z.open(filename) as f:
                df = pd.read_csv(f, header=None, dtype=str)
                
            print(f"  Loaded {len(df)} records.")
            return df
        except zipfile.BadZipFile:
            print("  Not a zip file, trying as raw CSV...")
            
            # Save raw CSV
            raw_path = os.path.join(raw_dir, f"raw_{name}.csv")
            with open(raw_path, 'wb') as f_out:
                f_out.write(r.content)
            print(f"  Saved raw file: {raw_path}")
            
            df = pd.read_csv(io.BytesIO(r.content), header=None, dtype=str)
            print(f"  Loaded {len(df)} records.")
            return df
            
    except Exception as e:
        print(f"  [ERROR] Failed to download {name}: {e}")
        return pd.DataFrame()

def save_output(df: pd.DataFrame, prefix: str):
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)
        
    filename = f"{prefix}_{TIMESTAMP}.csv"
    filepath = os.path.join(OUTPUT_DIR, filename)
    df.to_csv(filepath, index=False)
    print(f"Saved {prefix} to {filepath}")

# ---------------------------------------------------------
# Main Logic
# ---------------------------------------------------------
def main():
    print("Starting ODS CSV Fetch Pipeline (Pandas)...")
    
    # -------------------------------------------------------------------------
    # 1. Fetch PCN Memberships (epcncorepartnerdetails) - For PCN/ICB Info
    # -------------------------------------------------------------------------
    MEMBERSHIP_COLS = [
        "Partner Organisation Code", 
        "Partner Name", 
        "Practice Parent Sub ICB Location Code", 
        "Practice Parent Sub ICB Location Name", 
        "PCN Code", 
        "PCN Name", 
        "PCN Parent Sub ICB Location Code", 
        "PCN Parent Sub ICB Location Name", 
        "Practice to PCN Relationship Start Date", 
        "Practice to PCN Relationship End Date", 
        "Practice Sub ICB and PCN Sub ICB Match?"
    ]
    
    print("Fetching PCN Memberships...")
    df_members = download_and_extract_csv(URL_EPCN_MEMBERS, "epcncorepartnerdetails")
    df_members = pd.read_csv(io.StringIO(df_members.to_csv(index=False, header=False)), header=None, dtype=str, names=MEMBERSHIP_COLS)

    # DEDUPLICATION LOGIC (Keep 1 row per Partner Code)
    # We want the LATEST membership record for each practice.
    # 1. Active Relationships (End Date = NULL) are preferred.
    # 2. If no active relationship, take the one with the latest End Date.
    print("Deduplicating Memberships (Active > Latest Historic)...")
    df_members.sort_values(
        by=['Practice to PCN Relationship End Date', 'Practice to PCN Relationship Start Date'], 
        ascending=[False, False], 
        na_position='first', 
        inplace=True
    )
    df_members_dedup = df_members.drop_duplicates(subset=['Partner Organisation Code'], keep='first')
    print(f"Loaded {len(df_members_dedup)} unique PCN memberships.")

    # -----------------------------------------------------
    # 2. Fetch GP Practices (epraccur) - MASTER LIST
    # -----------------------------------------------------
    EPRACCUR_COLS = [
        "Organisation Code", 
        "Name", 
        "National Grouping", 
        "High Level Health Geography", 
        "Address Line 1", 
        "Address Line 2", 
        "Address Line 3", 
        "Address Line 4", 
        "Address Line 5", 
        "Postcode", 
        "Open Date", 
        "Close Date", 
        "Status Code", 
        "Organisation Sub-Type Code", 
        "Commissioner", 
        "Join Provider/Purchaser Date", 
        "Left Provider/Purchaser Date", 
        "Contact Telephone Number",
        "Null_19", "Null_20", "Null_21", "Amended Record Indicator", "Null_23", 
        "Provider/Purchaser", "Null_25", "Prescribing Setting", "Null_27"
    ]
    
    print("Fetching GP Practice Details (epraccur)...")
    df_gp = download_and_extract_csv(URL_EPRACCUR, "epraccur")
    df_gp_raw = pd.read_csv(io.StringIO(df_gp.to_csv(index=False, header=False)), header=None, dtype=str)
    
    # Header alignment
    current_cols_count = len(df_gp_raw.columns)
    assigned_cols = EPRACCUR_COLS[:current_cols_count] 
    if current_cols_count > len(EPRACCUR_COLS):
         assigned_cols += [f"Extra_{i}" for i in range(len(EPRACCUR_COLS), current_cols_count)]
    df_gp_raw.columns = assigned_cols
    
    # -----------------------------------------------------
    # 3. Join: EPRACCUR (Left) -> MEMBERSHIPS (Right)
    # -----------------------------------------------------
    print("Joining Master GP List with PCN Memberships...")
    df_merged = df_gp_raw.merge(
        df_members_dedup,
        left_on='Organisation Code',
        right_on='Partner Organisation Code',
        how='left'
    )
    # Remove filter for SWL - User requested ALL practices
    print(f"Total Practices (National): {len(df_merged)}")
    
    # 4. Generate SQL (Batched INSERT)
    # -----------------------------------------------------
    lines = [
        f"-- GP Practice Data from NHS ODS CSV (Pandas)",
        f"-- Generated: {TIMESTAMP}",
        f"-- Source: epraccur (All) LEFT JOIN epcncorepartnerdetails (Deduplicated)",
        f"-- Scope: National (All Practices, Active + Inactive)",
        f"-- Total Records: {len(df_merged)}",
        "",
        "TRUNCATE TABLE [Analytics].[tbl_Staging_GP_Practice];",
        ""
    ]
    
    BATCH_SIZE = 1000
    rows = []
    
    for _, row in df_merged.iterrows():
        def fmt(val):
            if pd.isna(val) or val == 'nan': return "NULL"
            return f"'{str(val).replace("'", "''")}'"
            
        # Commissioner Logic: Use PCN Membership info if available (contains Name), else epraccur code
        comm_code = row.get('Practice Parent Sub ICB Location Code')
        if pd.isna(comm_code):
             comm_code = row.get('Commissioner') # Fallback to epraccur

        comm_name = row.get('Practice Parent Sub ICB Location Name') # Only in Memberships
        
        # Helper for extracting codes
        # Col 25 = Prescribing Setting, Col 13 = Organisation Sub-Type
        presc_setting = row.get('Prescribing Setting')
        org_sub_type = row.get('Organisation Sub-Type Code')

        status_code = (row.get('Status Code') or '').strip().upper()
        if status_code in ('A', 'ACTIVE'):
            status = 'Active'
        elif status_code in ('C', 'CLOSED', 'I', 'INACTIVE'):
            status = 'Inactive'
        else:
            status = 'Inactive'

        row_vals = (
            f"({fmt(row['Organisation Code'])}, {fmt(row['Name'])}, "
            f"{fmt(status)}, "
            f"{fmt(presc_setting)}, {fmt(org_sub_type)}, "
            f"{fmt(row.get('Address Line 1'))}, {fmt(row.get('Address Line 2'))}, {fmt(row.get('Address Line 3'))}, "
            f"{fmt(row.get('Address Line 4'))}, {fmt(row.get('Postcode'))}, {fmt(row.get('Contact Telephone Number'))}, "
            f"{fmt(row.get('PCN Code'))}, {fmt(row.get('PCN Name'))}, {fmt(comm_code)}, {fmt(comm_name)}, "
            f"NULL, NULL, "
            f"{fmt(row.get('Open Date'))}, {fmt(row.get('Close Date'))})"
        )
        rows.append(row_vals)
        
        # Batch Flush
        if len(rows) >= BATCH_SIZE:
            lines.append("INSERT INTO [Analytics].[tbl_Staging_GP_Practice] "
                         "(Practice_Code, Practice_Name, Status, Prescribing_Setting, Org_Sub_Type, "
                         "Address_Line1, Address_Line2, Address_Line3, Town, Postcode, Contact_Telephone, "
                         "PCN_Code, PCN_Name, Commissioner_Code, Commissioner_Name, ICB_Code, ICB_Name, "
                         "Open_Date, Close_Date) VALUES")
            lines.append(",\n".join(rows) + ";\n")
            rows = []
            
    # Final Flush
    if rows:
        lines.append("INSERT INTO [Analytics].[tbl_Staging_GP_Practice] "
                     "(Practice_Code, Practice_Name, Status, Prescribing_Setting, Org_Sub_Type, "
                     "Address_Line1, Address_Line2, Address_Line3, Town, Postcode, Contact_Telephone, "
                     "PCN_Code, PCN_Name, Commissioner_Code, Commissioner_Name, ICB_Code, ICB_Name, "
                     "Open_Date, Close_Date) VALUES")
        lines.append(",\n".join(rows) + ";")
        
    sql_content = "\n".join(lines)
    
    # Save SQL
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)

    # Create archive directory
    archive_dir = os.path.join(OUTPUT_DIR, "archive")
    if not os.path.exists(archive_dir):
        os.makedirs(archive_dir)

    # Write timestamped archive copy
    archive_file = os.path.join(archive_dir, f"nhs_gp_practices_epraccur_{TIMESTAMP}.sql")
    with open(archive_file, 'w') as f:
        f.write(sql_content)
    print(f"Saved archive to: {archive_file}")

    # Write fixed "latest" file for deploy script (always overwrites)
    latest_file = os.path.join(OUTPUT_DIR, "staging_gp_practice.sql")
    with open(latest_file, 'w') as f:
        f.write(sql_content)
    print(f"Saved latest to: {latest_file}")

    
if __name__ == "__main__":
    main()

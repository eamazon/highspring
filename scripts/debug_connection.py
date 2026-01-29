
import os
import sys
import socket
import logging
from dotenv import load_dotenv

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def check_wsl_host_ip():
    """Attempts to find the Windows Host IP from WSL2."""
    try:
        with open("/etc/resolv.conf", "r") as f:
            for line in f:
                if "nameserver" in line:
                    ip = line.split()[1]
                    return ip
    except Exception:
        return None
    return None

def main():
    print("--- SQL Server Connection Debugger ---")
    
    # 1. Load Environment Variables
    # Try looking in parent dirs too if not in current
    if os.path.exists('.env'):
        load_dotenv('.env')
        print("Loaded .env file from current directory.")
    elif os.path.exists('../.env'):
        load_dotenv('../.env')
        print("Loaded .env file from parent directory.")
    else:
        print("WARNING: Could not find .env file nearby.")

    server = os.getenv('SQL_SERVER')
    database = os.getenv('SQL_DATABASE')
    user = os.getenv('SQL_USER')
    password = os.getenv('SQL_PWD')

    print(f"SQL_SERVER:   {server}")
    print(f"SQL_DATABASE: {database}")
    print(f"SQL_USER:     {user}")
    print(f"SQL_PWD:      {'******' if password else 'NOT FOUND'}")

    if not all([server, database, user, password]):
        print("\nERROR: Missing one or more required environment variables.")
        return

    # 2. Check Drivers & Connect
    # Try pyodbc first
    try:
        import pyodbc
        print(f"\npyodbc version: {pyodbc.version}")
        drivers = pyodbc.drivers()
        print("Available ODBC Drivers:")
        for d in drivers:
            print(f"  - {d}")
        
        # Pick a driver
        driver = None
        for d in drivers:
            if "ODBC Driver 17" in d or "ODBC Driver 18" in d:
                driver = d
                break
        
        if driver:
            print(f"\nAttempting connection via pyodbc using {driver}...")
            conn_str = f'DRIVER={{{driver}}};SERVER={server};DATABASE={database};UID={user};PWD={password}'
            if "ODBC Driver 18" in driver:
                conn_str += ";TrustServerCertificate=yes"
            
            try:
                conn = pyodbc.connect(conn_str, timeout=5)
                print("\nSUCCESS! Connected to SQL Server via pyodbc.")
                cursor = conn.cursor()
                cursor.execute("SELECT @@VERSION")
                print(f"Server Version: {cursor.fetchone()[0]}")
                conn.close()
                return
            except Exception as e:
                print(f"pyodbc connection failed: {e}")
        else:
            print("No suitable ODBC Driver found for pyodbc.")

    except ImportError:
        print("pyodbc not installed.")

    # Try pymssql as fallback
    print("\nAttempting connection via pymssql...")
    try:
        import pymssql
        print(f"pymssql version: {pymssql.__version__}")
        
        try:
            # pymssql usually takes host:port or just host. named instances with \ might need escaping or port usage.
            # If server is like 'DESKTOP-XXX\SQLEXPRESS', pymssql might need 'DESKTOP-XXX\\SQLEXPRESS'
            conn = pymssql.connect(server=server, user=user, password=password, database=database, timeout=5)
            print("\nSUCCESS! Connected to SQL Server via pymssql.")
            cursor = conn.cursor()
            cursor.execute("SELECT @@VERSION")
            print(f"Server Version: {cursor.fetchone()[0]}")
            conn.close()
            return
        except Exception as e:
            print(f"pymssql connection failed: {e}")
            
            # Diagnostics
            print("\n--- Troubleshooting ---")
            if '20009' in str(e) or '20002' in str(e) or "Adaptive Server is unavailable" in str(e): # Network errors
                print("1. Network unreachable. Check if SQL Server TCP/IP is enabled.")
                wsl_gateway = check_wsl_host_ip()
                if wsl_gateway and (server == 'localhost' or server == '.' or server == '127.0.0.1'):
                    print(f"2. WSL Issue: You are using '{server}'. Try using the host IP: {wsl_gateway}")
            elif '18456' in str(e):
                print("1. Login failed. Check User/Password.")
    except ImportError:
        print("pymssql not installed.")

if __name__ == "__main__":
    main()

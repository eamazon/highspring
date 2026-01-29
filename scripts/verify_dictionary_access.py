
import os
import pyodbc
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

server = os.getenv('DB_SERVER')
database = os.getenv('DB_DATABASE')
username = os.getenv('DB_USER')
password = os.getenv('DB_PASSWORD')
driver = '{ODBC Driver 17 for SQL Server}'

print(f"Connecting to {server}...")

try:
    conn_str = f'DRIVER={driver};SERVER={server};DATABASE={database};UID={username};PWD={password}'
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    print("Successfully connected to the main database.")

    # Check for Dictionary database
    print("Checking for 'Dictionary' database...")
    cursor.execute("SELECT name FROM sys.databases WHERE name = 'Dictionary'")
    row = cursor.fetchone()
    
    if row:
        print("✅ 'Dictionary' database found!")
        
        # Test access to a specific table
        print("Testing access to [Dictionary].[dbo].[Dim_Gender]...")
        try:
            cursor.execute("SELECT TOP 1 * FROM [Dictionary].[dbo].[Dim_Gender]")
            print("✅ Successfully queried [Dictionary].[dbo].[Dim_Gender]")
            
            # Test access to IP schema
            print("Testing access to [Dictionary].[IP].[AdmissionMethods]...")
            cursor.execute("SELECT TOP 1 * FROM [Dictionary].[IP].[AdmissionMethods]")
            print("✅ Successfully queried [Dictionary].[IP].[AdmissionMethods]")
            
        except pyodbc.Error as e:
            print(f"❌ Error querying Dictionary tables: {e}")
    else:
        print("❌ 'Dictionary' database NOT found in sys.databases.")

    conn.close()

except pyodbc.Error as e:
    print(f"❌ Connection failed: {e}")
except Exception as e:
    print(f"❌ An error occurred: {e}")

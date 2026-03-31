"""
Load CSV Data into PostgreSQL
Imports data from data/raw/*.csv into sales_analysis database
"""

import pandas as pd
from sqlalchemy import create_engine, text
import os
import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
from db_config import DB_CONFIG

def create_sqlalchemy_engine():
    """Create SQLAlchemy engine for PostgreSQL"""
    connection_string = (
        f"postgresql://{DB_CONFIG['user']}:{DB_CONFIG['password']}"
        f"@{DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['database']}"
    )
    try:
        engine = create_engine(connection_string, echo=False)
        print("✅ SQLAlchemy engine created successfully")
        return engine
    except Exception as e:
        print(f"❌ Failed to create engine: {e}")
        raise

def truncate_tables(engine, tables):
    """
    Truncate tables in reverse dependency order to respect foreign keys
    
    Args:
        engine: SQLAlchemy engine
        tables: List of table names to truncate
    """
    # Reverse order: order_items → orders → products → customers
    truncate_order = ['order_items', 'orders', 'products', 'customers']
    
    print("🗑️  Truncating existing tables...\n")
    with engine.connect() as conn:
        for table in truncate_order:
            if table in tables:
                try:
                    conn.execute(text(f"TRUNCATE TABLE {table};"))
                    conn.commit()
                    print(f"   ✓ Truncated {table}")
                except Exception as e:
                    print(f"   ⚠️  Could not truncate {table}: {e}")

def load_csv_to_postgres(engine, csv_file, table_name):
    """
    Load CSV file into PostgreSQL table (append mode)
    
    Args:
        engine: SQLAlchemy engine
        csv_file: Path to CSV file
        table_name: Target table name
    """
    print(f"\n📥 Loading {csv_file} → {table_name}...")
    
    try:
        df = pd.read_csv(csv_file)
        print(f"   Rows to insert: {len(df):,}")
        
        df.to_sql(table_name, engine, if_exists='append', index=False)
        print(f"   ✅ Successfully loaded {len(df):,} rows")
        return True
    except Exception as e:
        print(f"   ❌ Failed to load: {e}")
        return False

def verify_data_load(engine):
    """Verify all data was loaded correctly"""
    print("\n" + "=" * 70)
    print("DATA VERIFICATION")
    print("=" * 70)
    
    tables = ['customers', 'products', 'orders', 'order_items']
    
    with engine.connect() as conn:
        for table in tables:
            query = text(f"SELECT COUNT(*) FROM {table};")
            result = conn.execute(query).fetchone()
            count = result[0]
            print(f"✓ {table}: {count:,} rows")
    
    print("\n✅ All data loaded successfully!\n")

def main():
    print("=" * 70)
    print("LOAD CSV DATA TO POSTGRESQL")
    print("=" * 70)
    
    # Create engine
    engine = create_sqlalchemy_engine()
    
    # Define CSV files and target tables (with correct path from script location)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    
    # Load order matters: customers → products → orders → order_items
    # (respects foreign key relationships)
    csv_files_ordered = [
        (os.path.join(project_root, 'data/raw/customers.csv'), 'customers'),
        (os.path.join(project_root, 'data/raw/products.csv'), 'products'),
        (os.path.join(project_root, 'data/raw/orders.csv'), 'orders'),
        (os.path.join(project_root, 'data/raw/order_items.csv'), 'order_items')
    ]
    
    # Check if all CSV files exist
    missing_files = [f for f, _ in csv_files_ordered if not os.path.exists(f)]
    if missing_files:
        print(f"❌ Missing files: {missing_files}")
        print("Run python/generate_data.py first")
        return
    
    # Truncate tables in reverse dependency order
    table_names = [t for _, t in csv_files_ordered]
    truncate_tables(engine, table_names)
    
    # Load each CSV in dependency order
    print("\nStarting data load...")
    results = {}
    for csv_file, table_name in csv_files_ordered:
        results[csv_file] = load_csv_to_postgres(engine, csv_file, table_name)
    
    # Verify load
    if all(results.values()):
        verify_data_load(engine)
        print("=" * 70)
        print("Next steps:")
        print("1. python python/01_data_loading.py  (verify from PostgreSQL)")
        print("2. python python/02_data_cleaning.py")
        print("=" * 70)
    else:
        print("❌ Some files failed to load. Check errors above.")

if __name__ == '__main__':
    main()

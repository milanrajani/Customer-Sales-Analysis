"""
Phase 2 - Step 8: Data Loading Script
Loads and inspects data from PostgreSQL database
"""

import pandas as pd
import numpy as np
from python.db_config import get_connection

def load_and_inspect_data():
    """Load data from PostgreSQL and display basic information"""
    
    print("\n" + "=" * 70)
    print("PHASE 2: DATA LOADING & INSPECTION (FROM POSTGRESQL)")
    print("=" * 70)
    
    try:
        conn = get_connection()
        print("\n✅ Successfully connected to PostgreSQL database\n")
    except Exception as e:
        print(f"\n❌ Failed to connect: {e}")
        print("Check your credentials in python/db_config.py")
        return None
    
    # Load data from PostgreSQL
    print("📂 Loading data from PostgreSQL...")
    
    customers = pd.read_sql_query("SELECT * FROM customers;", conn)
    products = pd.read_sql_query("SELECT * FROM products;", conn)
    orders = pd.read_sql_query("SELECT * FROM orders;", conn)
    order_items = pd.read_sql_query("SELECT * FROM order_items;", conn)
    
    print("✓ All tables loaded successfully\n")
    
    # Display dataset overview
    print("=" * 70)
    print("DATASET OVERVIEW")
    print("=" * 70)
    
    print(f"\n📊 CUSTOMERS")
    print(f"  Records: {len(customers):,}")
    print(f"  Columns: {len(customers.columns)}")
    print(f"  Memory: {customers.memory_usage(deep=True).sum() / 1024**2:.2f} MB")
    
    print(f"\n📊 PRODUCTS")
    print(f"  Records: {len(products):,}")
    print(f"  Columns: {len(products.columns)}")
    print(f"  Memory: {products.memory_usage(deep=True).sum() / 1024**2:.2f} MB")
    
    print(f"\n📊 ORDERS")
    print(f"  Records: {len(orders):,}")
    print(f"  Columns: {len(orders.columns)}")
    print(f"  Memory: {orders.memory_usage(deep=True).sum() / 1024**2:.2f} MB")
    
    print(f"\n📊 ORDER_ITEMS")
    print(f"  Records: {len(order_items):,}")
    print(f"  Columns: {len(order_items.columns)}")
    print(f"  Memory: {order_items.memory_usage(deep=True).sum() / 1024**2:.2f} MB")
    
    # Data types
    print("\n" + "=" * 70)
    print("DATA TYPES & STRUCTURE")
    print("=" * 70)
    
    print("\n🔹 CUSTOMERS:")
    print(customers.dtypes)
    print(f"\nFirst 3 rows:")
    print(customers.head(3).to_string())
    
    print("\n\n🔹 PRODUCTS:")
    print(products.dtypes)
    print(f"\nFirst 3 rows:")
    print(products.head(3).to_string())
    
    print("\n\n🔹 ORDERS:")
    print(orders.dtypes)
    print(f"\nFirst 3 rows:")
    print(orders.head(3).to_string())
    
    print("\n\n🔹 ORDER_ITEMS:")
    print(order_items.dtypes)
    print(f"\nFirst 3 rows:")
    print(order_items.head(3).to_string())
    
    # Missing values analysis
    print("\n" + "=" * 70)
    print("MISSING VALUES")
    print("=" * 70)
    
    def check_nulls(df, name):
        nulls = df.isnull().sum()
        if nulls.sum() == 0:
            print(f"\n✓ {name}: No missing values")
        else:
            print(f"\n⚠️  {name}:")
            print(nulls[nulls > 0])
    
    check_nulls(customers, "CUSTOMERS")
    check_nulls(products, "PRODUCTS")
    check_nulls(orders, "ORDERS")
    check_nulls(order_items, "ORDER_ITEMS")
    
    # Summary statistics
    print("\n" + "=" * 70)
    print("SUMMARY STATISTICS")
    print("=" * 70)
    
    print("\n📈 ORDERS - Numeric Columns:")
    print(orders[['order_amount']].describe().to_string())
    
    print("\n📈 ORDER_ITEMS - Numeric Columns:")
    print(order_items[['quantity', 'unit_price', 'line_total']].describe().to_string())
    
    # Date ranges
    print("\n" + "=" * 70)
    print("DATE RANGES")
    print("=" * 70)
    
    customers['signup_date'] = pd.to_datetime(customers['signup_date'])
    orders['order_date'] = pd.to_datetime(orders['order_date'])
    products['launch_date'] = pd.to_datetime(products['launch_date'])
    
    print(f"\n📅 Customer Signups: {customers['signup_date'].min().date()} to {customers['signup_date'].max().date()}")
    print(f"📅 Orders: {orders['order_date'].min().date()} to {orders['order_date'].max().date()}")
    print(f"📅 Product Launches: {products['launch_date'].min().date()} to {products['launch_date'].max().date()}")
    
    # Category analysis
    print("\n" + "=" * 70)
    print("CATEGORICAL INSIGHTS")
    print("=" * 70)
    
    print("\n📋 Product Categories:")
    print(products['category'].value_counts().to_string())
    
    print("\n📋 Order Status:")
    print(orders['order_status'].value_counts().to_string())
    
    print("\n📋 Countries (Top 10):")
    print(customers['country'].value_counts().head(10).to_string())
    
    # Revenue analysis
    print("\n" + "=" * 70)
    print("REVENUE ANALYSIS")
    print("=" * 70)
    
    total_revenue = orders[orders['order_status'] == 'Completed']['order_amount'].sum()
    avg_order_value = orders[orders['order_status'] == 'Completed']['order_amount'].mean()
    
    print(f"\n💰 Total Revenue (Completed Orders): ${total_revenue:,.2f}")
    print(f"💰 Average Order Value: ${avg_order_value:,.2f}")
    print(f"💰 Total Orders: {len(orders):,}")
    print(f"💰 Completed Orders: {len(orders[orders['order_status'] == 'Completed']):,}")
    print(f"💰 Cancelled Orders: {len(orders[orders['order_status'] == 'Cancelled']):,}")
    print(f"💰 Cancellation Rate: {len(orders[orders['order_status'] == 'Cancelled']) / len(orders) * 100:.2f}%")
    
    # Customer analysis
    print("\n" + "=" * 70)
    print("CUSTOMER ANALYSIS")
    print("=" * 70)
    
    orders_per_customer = orders.groupby('customer_id').size()
    customers_with_orders = orders['customer_id'].nunique()
    
    print(f"\n👥 Total Customers: {len(customers):,}")
    print(f"👥 Customers with Orders: {customers_with_orders:,}")
    print(f"👥 Customers without Orders: {len(customers) - customers_with_orders:,}")
    print(f"👥 Average Orders per Customer: {orders_per_customer.mean():.2f}")
    print(f"👥 Max Orders by One Customer: {orders_per_customer.max()}")
    
    # Product analysis
    print("\n" + "=" * 70)
    print("PRODUCT ANALYSIS")
    print("=" * 70)
    
    print(f"\n🛍️  Total Products: {len(products):,}")
    print(f"🛍️  Total Product Categories: {products['category'].nunique()}")
    
    # Top products by revenue
    product_revenue = order_items.groupby('product_id').agg({
        'line_total': 'sum',
        'quantity': 'sum'
    }).reset_index().merge(products[['product_id', 'product_name']], on='product_id')
    
    print("\n🛍️  Top 5 Products by Revenue:")
    top_products = product_revenue.nlargest(5, 'line_total')
    for idx, row in top_products.iterrows():
        print(f"   {row['product_name']}: ${row['line_total']:,.2f}")
    
    print("\n" + "=" * 70)
    print("✅ DATA LOADING COMPLETE!")
    print("=" * 70)
    print("\nNext steps:")
    print("  1. python python/02_data_cleaning.py  (Phase 4)")
    print("  2. python python/03_exploratory_analysis.py  (Phase 3)")
    print("\nSQL queries available in:")
    print("  - sql/01_data_exploration.sql")
    print("=" * 70 + "\n")
    
    conn.close()

if __name__ == '__main__':
    load_and_inspect_data()
    
    # Display dataset overview
    print("=" * 70)
    print("DATASET OVERVIEW")
    print("=" * 70)
    
    print(f"\n📊 CUSTOMERS")
    print(f"  Records: {len(customers):,}")
    print(f"  Columns: {len(customers.columns)}")
    print(f"  Memory: {customers.memory_usage(deep=True).sum() / 1024**2:.2f} MB")
    
    print(f"\n📊 PRODUCTS")
    print(f"  Records: {len(products):,}")
    print(f"  Columns: {len(products.columns)}")
    print(f"  Memory: {products.memory_usage(deep=True).sum() / 1024**2:.2f} MB")
    
    print(f"\n📊 ORDERS")
    print(f"  Records: {len(orders):,}")
    print(f"  Columns: {len(orders.columns)}")
    print(f"  Memory: {orders.memory_usage(deep=True).sum() / 1024**2:.2f} MB")
    
    print(f"\n📊 ORDER_ITEMS")
    print(f"  Records: {len(order_items):,}")
    print(f"  Columns: {len(order_items.columns)}")
    print(f"  Memory: {order_items.memory_usage(deep=True).sum() / 1024**2:.2f} MB")
    
    # Data types
    print("\n" + "=" * 70)
    print("DATA TYPES & STRUCTURE")
    print("=" * 70)
    
    print("\n🔹 CUSTOMERS:")
    print(customers.dtypes)
    print(f"\nFirst 3 rows:")
    print(customers.head(3).to_string())
    
    print("\n\n🔹 PRODUCTS:")
    print(products.dtypes)
    print(f"\nFirst 3 rows:")
    print(products.head(3).to_string())
    
    print("\n\n🔹 ORDERS:")
    print(orders.dtypes)
    print(f"\nFirst 3 rows:")
    print(orders.head(3).to_string())
    
    print("\n\n🔹 ORDER_ITEMS:")
    print(order_items.dtypes)
    print(f"\nFirst 3 rows:")
    print(order_items.head(3).to_string())
    
    # Missing values analysis
    print("\n" + "=" * 70)
    print("MISSING VALUES")
    print("=" * 70)
    
    def check_nulls(df, name):
        nulls = df.isnull().sum()
        if nulls.sum() == 0:
            print(f"\n✓ {name}: No missing values")
        else:
            print(f"\n⚠️  {name}:")
            print(nulls[nulls > 0])
    
    check_nulls(customers, "CUSTOMERS")
    check_nulls(products, "PRODUCTS")
    check_nulls(orders, "ORDERS")
    check_nulls(order_items, "ORDER_ITEMS")
    
    # Summary statistics
    print("\n" + "=" * 70)
    print("SUMMARY STATISTICS")
    print("=" * 70)
    
    print("\n📈 ORDERS - Numeric Columns:")
    print(orders[['order_amount']].describe().to_string())
    
    print("\n📈 ORDER_ITEMS - Numeric Columns:")
    print(order_items[['quantity', 'unit_price', 'line_total']].describe().to_string())
    
    # Date ranges
    print("\n" + "=" * 70)
    print("DATE RANGES")
    print("=" * 70)
    
    customers['signup_date'] = pd.to_datetime(customers['signup_date'])
    orders['order_date'] = pd.to_datetime(orders['order_date'])
    products['launch_date'] = pd.to_datetime(products['launch_date'])
    
    print(f"\n📅 Customer Signups: {customers['signup_date'].min().date()} to {customers['signup_date'].max().date()}")
    print(f"📅 Orders: {orders['order_date'].min().date()} to {orders['order_date'].max().date()}")
    print(f"📅 Product Launches: {products['launch_date'].min().date()} to {products['launch_date'].max().date()}")
    
    # Category analysis
    print("\n" + "=" * 70)
    print("CATEGORICAL INSIGHTS")
    print("=" * 70)
    
    print("\n📋 Product Categories:")
    print(products['category'].value_counts().to_string())
    
    print("\n📋 Order Status:")
    print(orders['order_status'].value_counts().to_string())
    
    print("\n📋 Countries (Top 10):")
    print(customers['country'].value_counts().head(10).to_string())
    
    # Revenue analysis
    print("\n" + "=" * 70)
    print("REVENUE ANALYSIS")
    print("=" * 70)
    
    total_revenue = orders[orders['order_status'] == 'Completed']['order_amount'].sum()
    avg_order_value = orders[orders['order_status'] == 'Completed']['order_amount'].mean()
    
    print(f"\n💰 Total Revenue (Completed Orders): ${total_revenue:,.2f}")
    print(f"💰 Average Order Value: ${avg_order_value:,.2f}")
    print(f"💰 Total Orders: {len(orders):,}")
    print(f"💰 Completed Orders: {len(orders[orders['order_status'] == 'Completed']):,}")
    print(f"💰 Cancelled Orders: {len(orders[orders['order_status'] == 'Cancelled']):,}")
    print(f"💰 Cancellation Rate: {len(orders[orders['order_status'] == 'Cancelled']) / len(orders) * 100:.2f}%")
    
    # Customer analysis
    print("\n" + "=" * 70)
    print("CUSTOMER ANALYSIS")
    print("=" * 70)
    
    orders_per_customer = orders.groupby('customer_id').size()
    customers_with_orders = orders['customer_id'].nunique()
    
    print(f"\n👥 Total Customers: {len(customers):,}")
    print(f"👥 Customers with Orders: {customers_with_orders:,}")
    print(f"👥 Customers without Orders: {len(customers) - customers_with_orders:,}")
    print(f"👥 Average Orders per Customer: {orders_per_customer.mean():.2f}")
    print(f"👥 Max Orders by One Customer: {orders_per_customer.max()}")
    
    # Product analysis
    print("\n" + "=" * 70)
    print("PRODUCT ANALYSIS")
    print("=" * 70)
    
    print(f"\n🛍️  Total Products: {len(products):,}")
    print(f"🛍️  Total Product Categories: {products['category'].nunique()}")
    
    # Top products by revenue
    product_revenue = order_items.groupby('product_id').agg({
        'line_total': 'sum',
        'quantity': 'sum'
    }).reset_index().merge(products[['product_id', 'product_name']], on='product_id')
    
    print("\n🛍️  Top 5 Products by Revenue:")
    top_products = product_revenue.nlargest(5, 'line_total')
    for idx, row in top_products.iterrows():
        print(f"   {row['product_name']}: ${row['line_total']:,.2f}")
    
    print("\n" + "=" * 70)
    print("✅ DATA LOADING COMPLETE!")
    print("=" * 70)
    print("\nNext steps:")
    print("  1. python python/02_data_cleaning.py  (Phase 4)")
    print("  2. python python/03_exploratory_analysis.py  (Phase 3)")
    print("\nOr continue with:")
    print("  - Review SQL queries in: sql/01_data_exploration.sql")
    print("=" * 70 + "\n")

if __name__ == '__main__':
    load_and_inspect_data()

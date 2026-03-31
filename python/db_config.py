"""
PostgreSQL Database Configuration
Handles connection to sales_analysis database
"""

import psycopg2
from psycopg2 import sql
import os

# Database Configuration
DB_CONFIG = {
    'host': 'localhost',
    'database': 'sales_analysis',
    'user': 'postgres',
    'password': '123456',
    'port': 5433
}

def get_connection():
    """
    Create and return a PostgreSQL connection
    
    Returns:
        psycopg2 connection object
        
    Raises:
        psycopg2.OperationalError if connection fails
    """
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        return conn
    except psycopg2.OperationalError as e:
        print(f"❌ Connection failed: {e}")
        print("Check your credentials in python/db_config.py")
        raise

def test_connection():
    """Test database connection"""
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT version();")
        db_version = cursor.fetchone()
        print("✅ PostgreSQL Connection Successful!")
        print(f"PostgreSQL Version: {db_version[0]}")
        
        cursor.close()
        conn.close()
        return True
    except Exception as e:
        print(f"❌ Connection test failed: {e}")
        return False

def execute_query(query, params=None, fetch=False):
    """
    Execute a SQL query
    
    Args:
        query: SQL query string
        params: Query parameters (optional)
        fetch: If True, return results; if False, just execute
        
    Returns:
        Query results if fetch=True, else None
    """
    conn = get_connection()
    cursor = conn.cursor()
    
    try:
        if params:
            cursor.execute(query, params)
        else:
            cursor.execute(query)
        
        if fetch:
            results = cursor.fetchall()
        else:
            conn.commit()
            results = None
            
        cursor.close()
        conn.close()
        return results
    except Exception as e:
        conn.rollback()
        cursor.close()
        conn.close()
        print(f"❌ Query execution failed: {e}")
        raise

def get_table_row_count(table_name):
    """Get row count for a table"""
    query = f"SELECT COUNT(*) FROM {table_name};"
    result = execute_query(query, fetch=True)
    return result[0][0] if result else 0

if __name__ == '__main__':
    print("Testing PostgreSQL Connection...")
    test_connection()

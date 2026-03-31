# PostgreSQL Migration Setup Guide

Complete step-by-step instructions for migrating from CSV files to PostgreSQL database.

---

## ✅ Quick Checklist (Do This First)

- [ ] PostgreSQL 16 installed and running
- [ ] Know your PostgreSQL password
- [ ] Update `python/db_config.py` with your password
- [ ] Run `pip install -r requirements.txt`

---

## 🔷 COMPLETE STEP-BY-STEP GUIDE

### **Step 1: Install Python Dependencies**

```bash
cd "C:\Users\USER\OneDrive\Desktop\Customer & Sales Analysis"
pip install -r requirements.txt -q
```

**What it installs:**
- psycopg2-binary — PostgreSQL driver for Python
- sqlalchemy — Database ORM
- pandas, numpy, matplotlib, seaborn — Data analysis
- faker, openpyxl — Utilities

---

### **Step 2: Update Database Credentials**

**Before proceeding, edit this file:**

📄 `python/db_config.py` (Line 6-13)

**Change:**
```python
'password': '',  # ← EMPTY
```

**To:**
```python
'password': 'your_actual_password_here',  # ← Your PostgreSQL password
```

**Other settings (adjust if needed):**
```python
'host': 'localhost',      # Usually localhost
'user': 'postgres',       # Usually postgres
'port': 5432,            # Default PostgreSQL port
```

---

### **Step 3: Test PostgreSQL Connection**

Run this to verify your credentials work:

```bash
python python/db_config.py
```

**Expected output:**
```
✅ PostgreSQL Connection Successful!
PostgreSQL Version: PostgreSQL 16.x on ...
```

**If it fails:**
- Check your password in `db_config.py`
- Verify PostgreSQL is running
- Ensure PostgreSQL is listening on port 5432

---

### **Step 4: Create Database**

Open PowerShell and run:

```bash
psql -U postgres -h localhost
```

Then in psql console, type:

```sql
CREATE DATABASE sales_analysis;
\q
```

---

### **Step 5: Create Tables from SQL Schema**

```bash
psql -U postgres -h localhost -d sales_analysis -f "data/raw/sales.sql"
```

**Verify tables were created:**

```bash
psql -U postgres -d sales_analysis -c "\dt"
```

**Expected output - should show 4 tables:**
```
customers
products
orders
order_items
```

---

### **Step 6: Load Data from CSV to PostgreSQL**

This script reads CSVs and inserts into PostgreSQL:

```bash
python python/load_to_postgres.py
```

**Expected output:**
```
========================================================================
LOAD CSV DATA TO POSTGRESQL
========================================================================

✅ SQLAlchemy engine created successfully

📥 Loading data/raw/customers.csv → customers...
   Rows to insert: 10,000
   ✅ Successfully loaded 10,000 rows

📥 Loading data/raw/products.csv → products...
   Rows to insert: 120
   ✅ Successfully loaded 120 rows

📥 Loading data/raw/orders.csv → orders...
   Rows to insert: 50,000
   ✅ Successfully loaded 50,000 rows

📥 Loading data/raw/order_items.csv → order_items...
   Rows to insert: 150,049
   ✅ Successfully loaded 150,049 rows

========================================================================
DATA VERIFICATION
========================================================================

✓ customers: 10,000 rows
✓ products: 120 rows
✓ orders: 50,000 rows
✓ order_items: 150,049 rows

✅ All data loaded successfully!
```

---

### **Step 7: Verify Data in PostgreSQL**

Now query PostgreSQL directly to confirm data loaded:

```bash
python python/01_data_loading.py
```

This should now read FROM PostgreSQL instead of CSVs and show similar output as before.

---

### **Step 8: Run SQL Analysis Queries** (Optional)

You can now run any of the SQL query files to explore your data:

**From PowerShell:**

```bash
# View data exploration queries
psql -U postgres -d sales_analysis -f "sql/01_data_exploration.sql"

# View cleaning queries
psql -U postgres -d sales_analysis -f "sql/02_data_cleaning.sql"

# View advanced analysis (RFM, LTV, Cohorts)
psql -U postgres -d sales_analysis -f "sql/03_advanced_analysis.sql"

# View dashboard export queries
psql -U postgres -d sales_analysis -f "sql/04_dashboard_data.sql"
```

---

## 📊 Architecture Overview

Your new PostgreSQL setup:

```
┌─────────────┐
│   CSV Files │
│  (Original) │
└──────┬──────┘
       │
       │ (One-time load)
       ▼
┌─────────────────────────────────────┐
│     PostgreSQL 16 Database          │
│     sales_analysis                  │
├─────────────────────────────────────┤
│ ├─ customers (10,000 rows)          │
│ ├─ products (120 rows)               │
│ ├─ orders (50,000 rows)             │
│ └─ order_items (150,049 rows)       │
└──────┬──────────────────────────────┘
       │
       │ (Python reads from DB)
       ▼
┌──────────────────────────────┐
│   Python Scripts             │
│ ├─ 01_data_loading.py        │
│ ├─ 02_data_cleaning.py       │ (Coming next)
│ ├─ 03_exploratory_analysis.py│ (Coming next)
│ └─ 04_visualization.py       │ (Coming next)
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────┐
│ Analysis Output  │
│ ├─ Charts (PNG)  │
│ ├─ Excel Report  │
│ └─ CSV Exports   │
└──────────────────┘
       │
       ▼
┌──────────────────┐
│ Tableau          │
│ Dashboards       │
└──────────────────┘
```

---

## 🔍 Troubleshooting

### Error: "role 'postgres' does not exist"
- PostgreSQL may not be installed correctly
- Try: `psql -U "Postgres Server"` or check Services (Windows)

### Error: "FATAL: password authentication failed"
- Wrong password in `db_config.py`
- Reset PostgreSQL password: [Google: "Reset PostgreSQL password Windows"]

### Error: "database 'sales_analysis' does not exist"
- Haven't created the database yet
- Run: `psql -U postgres -h localhost` and execute `CREATE DATABASE sales_analysis;`

### Error: "relation 'customers' does not exist"
- Tables haven't been created from `sales.sql`
- Run: `psql -U postgres -h localhost -d sales_analysis -f "data/raw/sales.sql"`

### Error: "psql: command not found"
- PostgreSQL bin not in PATH
- Add to PATH: `C:\Program Files\PostgreSQL\16\bin`

---

## 📝 Next Steps

Once PostgreSQL is set up and data is loaded:

1. **Phase 3 & 4**: Create Python cleaning & analysis scripts
2. **Phase 5 & 6**: Generate visualizations and Excel reports
3. **Phase 7 & 8**: Connect to Tableau for interactive dashboards
4. **Phase 9**: Final QA and documentation

---

## 🔗 Useful PostgreSQL Commands

```bash
# Connect to specific database
psql -U postgres -d sales_analysis

# List all databases
psql -U postgres -c "\l"

# List all tables
psql -U postgres -d sales_analysis -c "\dt"

# View table structure
psql -U postgres -d sales_analysis -c "\d customers"

# Run a query
psql -U postgres -d sales_analysis -c "SELECT COUNT(*) FROM customers;"

# Backup database
pg_dump -U postgres sales_analysis > backup.sql

# Restore database
psql -U postgres -d sales_analysis < backup.sql
```

---

## ✅ Validation Checklist

After completing all steps:

- [ ] Python dependencies installed (`pip list | grep psycopg2`)
- [ ] `db_config.py` has password entered
- [ ] `python db_config.py` shows successful connection
- [ ] Database `sales_analysis` created in PostgreSQL
- [ ] Tables created: customers, products, orders, order_items
- [ ] Data loaded: customers (10k), products (120), orders (50k), order_items (150k)
- [ ] `python 01_data_loading.py` runs without errors and shows PostgreSQL source

---

**All set?** Move to Phase 3 & 4 for data cleaning and exploratory analysis!

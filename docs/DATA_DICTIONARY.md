# Data Dictionary - Sales & Customer Analysis Project

## Overview
This document defines all fields and tables used in the Sales & Customer Data Analysis project. Data is sourced from CSV files and processed through Python and SQL scripts.

---

## Table: CUSTOMERS

**File**: `data/raw/customers.csv`  
**Purpose**: Master customer dimension table  
**Records**: ~10,000 customer records

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| customer_id | Integer (PK) | Unique customer identifier | 1001 |
| first_name | String | Customer first name | John |
| last_name | String | Customer last name | Smith |
| email | String | Customer email address | john.smith@email.com |
| phone | String | Customer phone number (optional) | 555-1234 |
| country | String | Customer country | United States |
| state_province | String | State or province | CA |
| city | String | City name | San Francisco |
| postal_code | String | Postal/ZIP code | 94105 |
| signup_date | Date (YYYY-MM-DD) | Account creation date | 2023-01-15 |
| lifetime_value_raw | Decimal | Total orders before cleaning (deprecated after phase 4) | 5432.50 |

**Notes**:
- `customer_id` is the primary key
- `signup_date` ranges from 2022 onwards
- Location fields (country, state_province, city) used for geographic analysis
- Raw `lifetime_value_raw` is calculated from orders; cleaned version placed in processed data

---

## Table: ORDERS

**File**: `data/raw/orders.csv`  
**Purpose**: Fact table for customer purchases  
**Records**: ~50,000 order records

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| order_id | Integer (PK) | Unique order identifier | 50001 |
| customer_id | Integer (FK) | References CUSTOMERS.customer_id | 1001 |
| order_date | Date (YYYY-MM-DD) | Date of purchase | 2024-06-20 |
| order_amount | Decimal | Total order value (USD) | 249.99 |
| currency | String | Currency code | USD |
| order_status | String | Status: Completed, Cancelled, Returned | Completed |

**Notes**:
- `order_id` is the primary key
- `customer_id` links to CUSTOMERS table
- `order_date` ranges from 2022 to 2025
- `order_amount` > $0 for valid orders
- Status used to filter for valid transactions during analysis

---

## Table: ORDER_ITEMS

**File**: `data/raw/orders.csv` (combined with products)  
**Purpose**: Line-item detail for each order  
**Records**: ~75,000 line items

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| order_item_id | Integer (PK) | Unique line item identifier | 1 |
| order_id | Integer (FK) | References ORDERS.order_id | 50001 |
| product_id | Integer (FK) | References PRODUCTS.product_id | 100 |
| quantity | Integer | Units ordered | 2 |
| unit_price | Decimal | Price per unit at time of sale | 124.99 |
| line_total | Decimal | quantity × unit_price | 249.99 |

**Notes**:
- Allows tracking of multiple products per order
- `line_total` = quantity × unit_price
- Historical prices preserved (may differ from current PRODUCTS.price)

---

## Table: PRODUCTS

**File**: `data/raw/products.csv`  
**Purpose**: Master product dimension table  
**Records**: ~100+ product records

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| product_id | Integer (PK) | Unique product identifier | 100 |
| product_name | String | Product display name | Wireless Headphones Pro |
| category | String | Product category | Electronics |
| subcategory | String | Subcategory | Audio |
| price | Decimal | Current list price (USD) | 199.99 |
| cost | Decimal | Product cost | 80.00 |
| supplier | String | Supplier name | TechSupply Inc |
| launch_date | Date | Product launch date | 2023-06-01 |
| status | String | Active / Discontinued | Active |

**Notes**:
- `product_id` is the primary key
- `category` examples: Electronics, Apparel, Home & Garden, Sports
- `price` is current price; historical prices in ORDER_ITEMS.unit_price
- `margin` = (price - cost) / price
- Status used to filter active products for revenue analysis

---

## Derived Fields (Created During Cleaning - Phase 4)

**Location**: `data/processed/cleaned_data.csv` and analysis tables

| Field | Calculation | Purpose | Example |
|-------|-----------|---------|---------|
| customer_lifetime_value | SUM(order_amount) per customer | Total spend per customer | 5432.50 |
| purchase_frequency | COUNT(DISTINCT order_id) per customer | Number of orders placed | 12 |
| days_since_last_purchase | TODAY() - MAX(order_date) | Recency metric | 45 |
| customer_age_years | (TODAY() - signup_date) / 365.25 | Years as customer | 2.5 |
| order_month | EXTRACT(MONTH FROM order_date) | Month for aggregation | 6 |
| order_quarter | EXTRACT(QUARTER FROM order_date) | Quarter for trend analysis | Q2 |
| order_year | EXTRACT(YEAR FROM order_date) | Year for trend analysis | 2024 |
| profit_margin | (price - cost) / price | Product profitability | 0.60 |

---

## RFM Segmentation (Created During Analysis - Phase 5)

**Location**: `data/processed/analysis_results.csv` and RFM dimension table

| Field | Type | Description | Range |
|-------|------|-------------|-------|
| rfm_recency_score | Integer | Days since last purchase (1-5, lower is better) | 1-5 |
| rfm_frequency_score | Integer | Number of purchases (1-5, higher is better) | 1-5 |
| rfm_monetary_score | Integer | Total spend (1-5, higher is better) | 1-5 |
| rfm_segment | String | Combined segment classification | See below |

**RFM Segments** (based on score combinations):
- **Champions** — (5,5,5) — Best customers, high value, frequent, recent
- **Loyal Customers** — High frequency & monetary, any recency
- **At-Risk** — High LTV but low recency (haven't purchased recently)
- **New Customers** — Recent signup, low frequency
- **Lost** — No recent activity; hadn't purchased in 180+ days

---

## Data Quality Rules (Enforced in Phase 4)

| Rule | Description | Action |
|------|-------------|--------|
| No NULL customer_id | All orders must link to valid customer | Remove rows |
| No NULL order_date | All orders must have valid date | Remove rows |
| order_amount > 0 | Order total must be positive | Remove/flag |
| order_date valid range | Dates between 2022-01-01 and TODAY() | Remove/flag |
| No duplicate order_id | Each order unique | Remove duplicates |
| order_date ≤ TODAY() | No future-dated orders | Remove |
| quantity ≥ 1 | All ordered items have qty ≥ 1 | Remove line items |
| Referential integrity | customer_id exists in CUSTOMERS | Remove/flag |
| Referential integrity | product_id exists in PRODUCTS | Remove/flag |

---

## Data Freshness & Update Frequency

| Table | Last Updated | Refresh Frequency |
|-------|--------------|-------------------|
| CUSTOMERS | 2025-12-31* | Monthly |
| ORDERS | 2025-12-31* | Daily |
| ORDER_ITEMS | 2025-12-31* | Daily |
| PRODUCTS | 2025-12-31* | As needed |

*Synthetic data frozen at end of 2025 for stability

---

## Column Data Types & Constraints

### Numeric
- **Integer** — Whole numbers (IDs, quantities)
- **Decimal(10,2)** — Currency values (always USD unless noted)

### Date
- **Date (YYYY-MM-DD)** — Calendar dates

### String
- **VARCHAR(50-255)** — Text fields (names, addresses)

### Boolean
- Used implicitly for status fields (Active/Discontinued)

---

## SQL Schema Reference

Create table statements available in `data/raw/sales.sql`.  
Python pandas read all CSVs using `read_csv()` with automatic type inference.

---

## Common Analysis Queries

```sql
-- Total revenue by month
SELECT DATE_TRUNC(order_date, 'MONTH') as month, 
       SUM(order_amount) as revenue
FROM orders
WHERE order_status = 'Completed'
GROUP BY month
ORDER BY month;

-- RFM Summary
SELECT rfm_segment, COUNT(*) as count, 
       AVG(customer_lifetime_value) as avg_ltv
FROM analysis_results
GROUP BY rfm_segment
ORDER BY avg_ltv DESC;

-- Top 10 Products by Revenue
SELECT product_name, category, 
       SUM(line_total) as revenue,
       COUNT(DISTINCT order_id) as orders
FROM products
JOIN order_items ON products.product_id = order_items.product_id
GROUP BY product_name, category
ORDER BY revenue DESC
LIMIT 10;
```

---

## Glossary

- **RFM** — Recency, Frequency, Monetary (customer segmentation model)
- **LTV** — Customer Lifetime Value (total historical spend)
- **SKU** — Stock Keeping Unit (product identifier)
- **Cohort** — Group of customers defined by signup period
- **Churn** — Customer no longer making purchases
- **Active** — Customer with purchase in last 30-90 days
- **At-Risk** — High-value customer with no recent activity

---

**Version**: 1.0  
**Last Updated**: March 29, 2026

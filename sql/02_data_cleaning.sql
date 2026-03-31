-- SQL Data Cleaning Queries
-- Phase 4: Data quality and preparation queries

-- =========================================================
-- DATA QUALITY ASSESSMENT
-- =========================================================

-- 1. Identify duplicate orders
SELECT 
    order_id,
    customer_id,
    order_date,
    order_amount,
    COUNT(*) as duplicate_count
FROM orders
GROUP BY order_id, customer_id, order_date, order_amount
HAVING COUNT(*) > 1;

-- 2. Identify duplicate customers (same email)
SELECT 
    email,
    COUNT(*) as count
FROM customers
WHERE email IS NOT NULL
GROUP BY email
HAVING COUNT(*) > 1;

-- 3. Check for invalid order amounts (negative or zero)
SELECT 
    order_id,
    customer_id,
    order_amount
FROM orders
WHERE order_amount <= 0;

-- 4. Check for future-dated orders
SELECT 
    order_id,
    order_date,
    CURRENT_DATE as today
FROM orders
WHERE order_date > CURRENT_DATE;

-- 5. Check for anomalous large orders
SELECT 
    order_id,
    customer_id,
    order_amount,
    order_date
FROM orders
WHERE order_amount > (
    SELECT AVG(order_amount) + 4 * STDDEV(order_amount)
    FROM orders
    WHERE order_status = 'Completed'
)
ORDER BY order_amount DESC;

-- =========================================================
-- DERIVED COLUMNS CREATION (VIEW BASED APPROACH)
-- =========================================================

-- 6. Create view with derived customer metrics
CREATE OR REPLACE VIEW v_customer_metrics AS
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    c.country,
    c.signup_date,
    EXTRACT(DAY FROM CURRENT_DATE - c.signup_date::date) as days_customer,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, c.signup_date::date)) as years_customer,
    COUNT(DISTINCT o.order_id) as purchase_frequency,
    COALESCE(MAX(o.order_date), c.signup_date) as last_purchase_date,
    EXTRACT(DAY FROM CURRENT_DATE - COALESCE(MAX(o.order_date), c.signup_date)::date) as days_since_last_purchase,
    COALESCE(SUM(o.order_amount), 0) as customer_lifetime_value,
    COALESCE(AVG(o.order_amount), 0) as avg_order_value
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id 
    AND o.order_status = 'Completed'
GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.country, c.signup_date;

-- 7. Create view with product performance metrics
CREATE OR REPLACE VIEW v_product_performance AS
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    p.subcategory,
    p.price,
    p.cost,
    ROUND((p.price - p.cost) / NULLIF(p.price, 0) * 100, 2) as profit_margin_pct,
    COUNT(DISTINCT oi.order_id) as order_count,
    SUM(oi.quantity) as units_sold,
    COALESCE(AVG(oi.unit_price), 0) as avg_price,
    COALESCE(SUM(oi.line_total), 0) as total_revenue
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.category, p.subcategory, p.price, p.cost;

-- 8. Create view with monthly sales aggregation
CREATE OR REPLACE VIEW v_monthly_sales AS
SELECT 
    DATE_TRUNC('month', o.order_date)::date as month,
    COUNT(DISTINCT o.order_id) as orders,
    SUM(o.order_amount) as revenue,
    AVG(o.order_amount) as avg_order_value,
    COUNT(DISTINCT o.customer_id) as unique_customers
FROM orders o
WHERE o.order_status = 'Completed'
GROUP BY DATE_TRUNC('month', o.order_date);

-- =========================================================
-- CLEANING: REMOVE INVALID DATA (WRITE TO NEW TABLES)
-- =========================================================

-- 9. Create cleaned orders table (remove invalid records)
-- This would delete orders that don't meet quality criteria
DELETE FROM orders
WHERE order_amount <= 0
   OR order_amount IS NULL
   OR order_date > CURRENT_DATE
   OR order_date < '2022-01-01'
   OR customer_id NOT IN (SELECT customer_id FROM customers);

-- 10. Remove orphaned order items
DELETE FROM order_items
WHERE order_id NOT IN (SELECT order_id FROM orders)
   OR product_id NOT IN (SELECT product_id FROM products);

-- 11. Standardize email format (lowercase)
UPDATE customers
SET email = LOWER(TRIM(email))
WHERE email IS NOT NULL;

-- 12. Standardize phone format (remove special characters)
UPDATE customers
SET phone = REGEXP_REPLACE(phone, '[^0-9]', '', 'g')
WHERE phone IS NOT NULL;

-- =========================================================
-- OUTLIER DETECTION
-- =========================================================

-- 13. Flag outlier orders (top 1%)
SELECT 
    order_id,
    order_amount,
    ROUND(order_amount / AVG(order_amount) OVER (), 2) as ratio_to_avg,
    CASE 
        WHEN order_amount > PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY order_amount) OVER () 
        THEN 'Outlier (>99th percentile)'
        ELSE 'Normal'
    END as outlier_flag
FROM orders
WHERE order_status = 'Completed'
ORDER BY order_amount DESC
LIMIT 20;

-- 14. Flag customers with unusual behavior
SELECT 
    c.customer_id,
    COUNT(o.order_id) as order_count,
    SUM(o.order_amount) as lifetime_value,
    CASE 
        WHEN COUNT(o.order_id) > PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY COUNT(o.order_id)) OVER ()
        THEN 'High Frequency'
        WHEN SUM(o.order_amount) > PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY SUM(o.order_amount)) OVER ()
        THEN 'High Value'
        ELSE 'Normal'
    END as customer_type
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id
HAVING COUNT(o.order_id) > PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY COUNT(o.order_id)) OVER ()
   OR SUM(o.order_amount) > PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY SUM(o.order_amount)) OVER ();

-- =========================================================
-- SUMMARY STATISTICS
-- =========================================================

-- 15. Order value distribution statistics
SELECT 
    ROUND(MIN(order_amount), 2) as min_order,
    ROUND(MAX(order_amount), 2) as max_order,
    ROUND(AVG(order_amount), 2) as avg_order,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY order_amount), 2) as median_order,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY order_amount), 2) as q1_order,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY order_amount), 2) as q3_order,
    ROUND(STDDEV(order_amount), 2) as stddev_order
FROM orders
WHERE order_status = 'Completed';

-- 16. Data quality report
SELECT 
    'Total records' as metric,
    COUNT(*) as value
FROM orders
UNION ALL
SELECT 'Valid orders', COUNT(*) FROM orders WHERE order_status = 'Completed' AND order_amount > 0
UNION ALL
SELECT 'Invalid orders', COUNT(*) FROM orders WHERE order_amount <= 0 OR order_date > CURRENT_DATE
UNION ALL
SELECT 'Records with NULL amounts', SUM(CASE WHEN order_amount IS NULL THEN 1 ELSE 0 END) FROM orders
UNION ALL
SELECT 'Duplicate orders (approx)', COUNT(*) FROM (
    SELECT order_id FROM orders GROUP BY order_id HAVING COUNT(*) > 1
) subq;

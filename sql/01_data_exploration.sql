-- SQL Data Exploration Queries
-- Sales & Customer Data Analysis Project
-- Phase 3: Exploratory analysis using SQL

-- =========================================================
-- BASIC EXPLORATION
-- =========================================================

-- 1. Record counts and data quality overview
SELECT 
    'Customers' as table_name,
    COUNT(*) as row_count,
    COUNT(DISTINCT customer_id) as unique_ids
FROM customers
UNION ALL
SELECT 'Products', COUNT(*), COUNT(DISTINCT product_id) FROM products
UNION ALL
SELECT 'Orders', COUNT(*), COUNT(DISTINCT order_id) FROM orders
UNION ALL
SELECT 'Order Items', COUNT(*), COUNT(DISTINCT order_item_id) FROM order_items;

-- 2. Date ranges
SELECT 
    'Customers' as dataset,
    MIN(signup_date) as earliest_date,
    MAX(signup_date) as latest_date,
    COUNT(*) as records
FROM customers
UNION ALL
SELECT 'Orders', MIN(order_date), MAX(order_date), COUNT(*) FROM orders
UNION ALL
SELECT 'Products', MIN(launch_date), MAX(launch_date), COUNT(*) FROM products;

-- =========================================================
-- CUSTOMER ANALYSIS
-- =========================================================

-- 3. Customer demographics by country
SELECT 
    country,
    COUNT(*) as customer_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM customers), 2) as percentage
FROM customers
GROUP BY country
ORDER BY customer_count DESC;

-- 4. Customers by signup period (monthly)
SELECT 
    DATE_TRUNC('month', signup_date) as signup_month,
    COUNT(*) as customers
FROM customers
GROUP BY DATE_TRUNC('month', signup_date)
ORDER BY signup_month;

-- 5. Customers without any orders
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.signup_date,
    c.country
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL
LIMIT 10;

-- =========================================================
-- ORDER ANALYSIS
-- =========================================================

-- 6. Order status distribution
SELECT 
    order_status,
    COUNT(*) as order_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM orders), 2) as percentage,
    ROUND(AVG(order_amount), 2) as avg_order_value,
    ROUND(SUM(order_amount), 2) as total_revenue
FROM orders
GROUP BY order_status;

-- 7. Daily order volume
SELECT 
    order_date,
    COUNT(*) as orders,
    ROUND(AVG(order_amount), 2) as avg_amount,
    ROUND(SUM(order_amount), 2) as daily_revenue
FROM orders
WHERE order_status = 'Completed'
GROUP BY order_date
ORDER BY order_date DESC
LIMIT 10;

-- 8. Monthly revenue trend
SELECT 
    DATE_TRUNC('month', order_date) as month,
    COUNT(*) as order_count,
    ROUND(SUM(order_amount), 2) as revenue
FROM orders
WHERE order_status = 'Completed'
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;

-- =========================================================
-- PRODUCT ANALYSIS
-- =========================================================

-- 9. Products by category
SELECT 
    category,
    COUNT(*) as product_count,
    ROUND(AVG(price), 2) as avg_price,
    ROUND(MIN(price), 2) as min_price,
    ROUND(MAX(price), 2) as max_price
FROM products
GROUP BY category
ORDER BY product_count DESC;

-- 10. Top 20 products by revenue
SELECT TOP 20
    p.product_id,
    p.product_name,
    p.category,
    COUNT(DISTINCT oi.order_id) as orders,
    SUM(oi.quantity) as units_sold,
    ROUND(AVG(oi.unit_price), 2) as avg_price,
    ROUND(SUM(oi.line_total), 2) as total_revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_revenue DESC;

-- 11. Low-selling products
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    COUNT(oi.order_id) as orders,
    ROUND(SUM(oi.line_total), 2) as revenue
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
WHERE oi.order_item_id IS NULL OR COUNT(oi.order_id) < 5
GROUP BY p.product_id, p.product_name, p.category
HAVING COUNT(oi.order_id) <= 5
ORDER BY orders;

-- =========================================================
-- CUSTOMER PURCHASING BEHAVIOR
-- =========================================================

-- 12. Customers by order frequency
SELECT 
    order_count,
    COUNT(*) as customer_count
FROM (
    SELECT 
        customer_id,
        COUNT(order_id) as order_count
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY customer_id
) customer_orders
GROUP BY order_count
ORDER BY order_count;

-- 13. Top 20 customers by lifetime value
SELECT TOP 20
    c.customer_id,
    c.first_name || ' ' || c.last_name as customer_name,
    COUNT(o.order_id) as order_count,
    ROUND(SUM(o.order_amount), 2) as lifetime_value,
    ROUND(AVG(o.order_amount), 2) as avg_order_value,
    MAX(o.order_date) as last_purchase_date
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status = 'Completed'
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY lifetime_value DESC;

-- 14. Average order value by country
SELECT 
    c.country,
    COUNT(o.order_id) as order_count,
    ROUND(AVG(o.order_amount), 2) as avg_order_value,
    ROUND(SUM(o.order_amount), 2) as total_revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status = 'Completed'
GROUP BY c.country
ORDER BY avg_order_value DESC;

-- =========================================================
-- DATA QUALITY CHECKS
-- =========================================================

-- 15. NULL values check
SELECT 
    'customers' as table_name,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) as null_customer_id,
    SUM(CASE WHEN email IS NULL THEN 1 ELSE 0 END) as null_email,
    SUM(CASE WHEN signup_date IS NULL THEN 1 ELSE 0 END) as null_signup_date
FROM customers
UNION ALL
SELECT 'orders',
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN order_amount IS NULL THEN 1 ELSE 0 END)
FROM orders;

-- 16. Orphaned records (referential integrity check)
SELECT 
    COUNT(*) as orphaned_order_items
FROM order_items oi
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- 17. Orders with invalid amounts
SELECT 
    order_id,
    order_amount,
    order_status
FROM orders
WHERE order_amount <= 0
   OR order_amount IS NULL
   OR order_date > CURRENT_DATE;

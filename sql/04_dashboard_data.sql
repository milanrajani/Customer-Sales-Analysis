-- SQL Dashboard Data Export Queries
-- Phase 7: Pre-aggregated data for Tableau/visualization export

-- =========================================================
-- SALES DASHBOARD DATA
-- =========================================================

-- 1. Monthly sales trend for line chart
CREATE OR REPLACE VIEW v_monthly_trends AS
SELECT 
    DATE_TRUNC('month', o.order_date)::date as month,
    COUNT(DISTINCT o.order_id) as order_count,
    ROUND(SUM(o.order_amount), 2) as revenue,
    ROUND(AVG(o.order_amount), 2) as avg_order_value
FROM orders o
WHERE o.order_status = 'Completed'
GROUP BY DATE_TRUNC('month', o.order_date);

-- 2. Top 15 products by revenue
CREATE OR REPLACE VIEW v_top_products AS
SELECT TOP 15
    p.product_id,
    p.product_name,
    p.category,
    COUNT(DISTINCT oi.order_id) as orders,
    SUM(oi.quantity) as units_sold,
    ROUND(SUM(oi.line_total), 2) as revenue
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY revenue DESC;

-- 3. Sales by category
CREATE OR REPLACE VIEW v_category_sales AS
SELECT 
    p.category,
    COUNT(DISTINCT oi.order_id) as orders,
    SUM(oi.quantity) as units_sold,
    ROUND(SUM(oi.line_total), 2) as revenue,
    ROUND(AVG(oi.unit_price), 2) as avg_price
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.category;

-- 4. Sales by country for geographic analysis
CREATE OR REPLACE VIEW v_sales_by_country AS
SELECT 
    c.country,
    COUNT(DISTINCT c.customer_id) as customers,
    COUNT(DISTINCT o.order_id) as orders,
    ROUND(SUM(o.order_amount), 2) as revenue,
    ROUND(AVG(o.order_amount), 2) as avg_order_value
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status = 'Completed' OR o.order_id IS NULL
GROUP BY c.country;

-- =========================================================
-- CUSTOMER DASHBOARD DATA
-- =========================================================

-- 5. RFM segment summary for pie/donut chart
CREATE OR REPLACE VIEW v_rfm_summary AS
SELECT 
    s.rfm_segment,
    COUNT(DISTINCT s.customer_id) as customer_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) as percentage,
    ROUND(AVG(m.customer_lifetime_value), 2) as avg_ltv,
    ROUND(MAX(m.customer_lifetime_value), 2) as max_ltv,
    ROUND(MIN(m.customer_lifetime_value), 2) as min_ltv
FROM v_rfm_segments s
JOIN v_customer_metrics m ON s.customer_id = m.customer_id
GROUP BY s.rfm_segment;

-- 6. Customer LTV distribution (buckets)
CREATE OR REPLACE VIEW v_ltv_distribution AS
SELECT 
    CASE 
        WHEN m.customer_lifetime_value < 500 THEN '$0-$500'
        WHEN m.customer_lifetime_value < 1000 THEN '$500-$1000'
        WHEN m.customer_lifetime_value < 2000 THEN '$1000-$2000'
        WHEN m.customer_lifetime_value < 5000 THEN '$2000-$5000'
        ELSE '>$5000'
    END as ltv_bucket,
    COUNT(*) as customer_count,
    ROUND(AVG(m.customer_lifetime_value), 2) as avg_ltv
FROM v_customer_metrics m
GROUP BY ltv_bucket;

-- 7. Repeat customer metrics
CREATE OR REPLACE VIEW v_repeat_customers AS
SELECT 
    'Repeat Purchase Customers' as segment,
    COUNT(*) as count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(DISTINCT customer_id) FROM customers), 2) as percentage_of_total
FROM v_customer_metrics
WHERE purchase_frequency > 1
UNION ALL
SELECT 'Single Purchase Customers',
    COUNT(*),
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(DISTINCT customer_id) FROM customers), 2)
FROM v_customer_metrics
WHERE purchase_frequency = 1
UNION ALL
SELECT 'No Purchase Customers',
    COUNT(*),
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(DISTINCT customer_id) FROM customers), 2)
FROM v_customer_metrics
WHERE purchase_frequency IS NULL;

-- 8. New vs returning customers (by signup month)
CREATE OR REPLACE VIEW v_customer_acquisition AS
SELECT 
    DATE_TRUNC('month', c.signup_date)::date as signup_month,
    COUNT(DISTINCT c.customer_id) as new_customers,
    COUNT(DISTINCT CASE WHEN o.order_id IS NOT NULL THEN c.customer_id END) as customers_with_orders,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN o.order_id IS NOT NULL THEN c.customer_id END) / 
        COUNT(DISTINCT c.customer_id), 2) as conversion_rate
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY DATE_TRUNC('month', c.signup_date);

-- 9. Cohort retention by month
CREATE OR REPLACE VIEW v_cohort_retention_export AS
SELECT 
    DATE_TRUNC('month', c.signup_date)::date as cohort_month,
    EXTRACT(MONTH FROM AGE(o.order_date::date, DATE_TRUNC('month', c.signup_date)::date)) as months_after_signup,
    COUNT(DISTINCT c.customer_id) as retained_customers
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY DATE_TRUNC('month', c.signup_date), 
    EXTRACT(MONTH FROM AGE(o.order_date::date, DATE_TRUNC('month', c.signup_date)::date));

-- =========================================================
-- EXECUTIVE KPI DASHBOARD DATA
-- =========================================================

-- 10. Overall business metrics (summary)
CREATE OR REPLACE VIEW v_executive_summary AS
SELECT 
    (SELECT COUNT(*) FROM customers) as total_customers,
    (SELECT COUNT(DISTINCT customer_id) FROM orders WHERE order_status = 'Completed') as customers_with_purchases,
    (SELECT ROUND(SUM(order_amount), 2) FROM orders WHERE order_status = 'Completed')::NUMERIC as total_revenue,
    (SELECT ROUND(AVG(order_amount), 2) FROM orders WHERE order_status = 'Completed')::NUMERIC as avg_order_value,
    (SELECT COUNT(*) FROM orders WHERE order_status = 'Completed') as total_completed_orders,
    (SELECT COUNT(*) FROM orders WHERE order_status = 'Cancelled') as total_cancelled_orders,
    (SELECT ROUND(100.0 * COUNT(*) FILTER (WHERE order_status = 'Cancelled') / COUNT(*), 2) 
        FROM orders)::NUMERIC as cancellation_rate;

-- 11. KPI changes month-over-month
CREATE OR REPLACE VIEW v_kpi_trends AS
SELECT 
    DATE_TRUNC('month', order_date)::date as month,
    COUNT(DISTINCT customer_id) as active_customers,
    COUNT(DISTINCT order_id) as orders,
    ROUND(SUM(order_amount), 2) as revenue,
    ROUND(AVG(order_amount), 2) as avg_order_value,
    ROUND(SUM(order_amount) / COUNT(DISTINCT customer_id), 2) as revenue_per_customer
FROM orders
WHERE order_status = 'Completed'
GROUP BY DATE_TRUNC('month', order_date);

-- 12. Product category trend (monthly)
CREATE OR REPLACE VIEW v_category_trend AS
SELECT 
    DATE_TRUNC('month', o.order_date)::date as month,
    p.category,
    COUNT(DISTINCT oi.order_id) as orders,
    SUM(oi.quantity) as units,
    ROUND(SUM(oi.line_total), 2) as revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'Completed'
GROUP BY DATE_TRUNC('month', o.order_date), p.category;

-- =========================================================
-- EXPORT QUERIES (for CSV export to data/processed/)
-- =========================================================

-- 13. Export cleaned customer data with metrics
SELECT 
    m.customer_id,
    m.first_name,
    m.last_name,
    m.email,
    m.country,
    m.signup_date,
    m.days_customer,
    m.purchase_frequency,
    m.customer_lifetime_value,
    m.avg_order_value,
    m.days_since_last_purchase,
    s.rfm_segment,
    s.rfm_score_combined
INTO cleaned_customers_export
FROM v_customer_metrics m
LEFT JOIN v_rfm_segments s ON m.customer_id = s.customer_id;

-- 14. Export monthly sales summary
SELECT * INTO monthly_sales_export FROM v_monthly_trends;

-- 15. Export product performance
SELECT * INTO product_performance_export FROM v_product_performance;

-- 16. Export RFM analysis
SELECT * INTO rfm_analysis_export FROM v_rfm_summary;

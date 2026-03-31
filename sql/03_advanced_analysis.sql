-- SQL Advanced Analysis Queries
-- Phase 5: RFM Analysis, Cohorts, and Advanced Metrics

-- =========================================================
-- RFM SEGMENTATION (Recency, Frequency, Monetary)
-- =========================================================

-- 1. Calculate RFM scores for all customers
CREATE OR REPLACE VIEW v_rfm_analysis AS
SELECT 
    customer_id,
    -- Recency: Days since last purchase (lower is better)
    EXTRACT(DAY FROM CURRENT_DATE - last_purchase_date::date) as recency_days,
    NTILE(5) OVER (ORDER BY EXTRACT(DAY FROM CURRENT_DATE - last_purchase_date::date)) as recency_score,
    
    -- Frequency: Number of purchases (higher is better)
    purchase_frequency,
    NTILE(5) OVER (ORDER BY purchase_frequency DESC) as frequency_score,
    
    -- Monetary: Total spend (higher is better)
    customer_lifetime_value,
    NTILE(5) OVER (ORDER BY customer_lifetime_value DESC) as monetary_score
FROM v_customer_metrics
WHERE last_purchase_date IS NOT NULL;

-- 2. RFM segment classification
CREATE OR REPLACE VIEW v_rfm_segments AS
SELECT 
    customer_id,
    recency_score,
    frequency_score,
    monetary_score,
    CASE 
        WHEN recency_score = 5 AND frequency_score = 5 AND monetary_score = 5 THEN 'Champions'
        WHEN recency_score = 5 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Loyal Customers'
        WHEN frequency_score >= 4 AND monetary_score >= 4 THEN 'Can''t Lose Them'
        WHEN recency_score >= 4 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'At Risk'
        WHEN recency_score <= 2 AND frequency_score >= 3 THEN 'Need Attention'
        WHEN recency_score <= 2 THEN 'Lost'
        WHEN frequency_score <= 1 AND monetary_score <= 1 THEN 'New Customers'
        ELSE 'Other'
    END as rfm_segment,
    recency_score || frequency_score || monetary_score as rfm_score_combined
FROM v_rfm_analysis;

-- 3. RFM segment distribution and metrics
SELECT 
    rfm_segment,
    COUNT(*) as customer_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) as percentage,
    ROUND(AVG(customer_lifetime_value), 2) as avg_ltv,
    ROUND(MAX(customer_lifetime_value), 2) as max_ltv,
    ROUND(MIN(customer_lifetime_value), 2) as min_ltv
FROM v_rfm_segments s
JOIN v_customer_metrics m ON s.customer_id = m.customer_id
GROUP BY rfm_segment
ORDER BY avg_ltv DESC;

-- =========================================================
-- COHORT ANALYSIS
-- =========================================================

-- 4. Customer cohorts by signup month
CREATE OR REPLACE VIEW v_cohorts AS
SELECT 
    DATE_TRUNC('month', c.signup_date)::date as cohort_month,
    c.customer_id,
    DATE_TRUNC('month', o.order_date)::date as order_month,
    EXTRACT(YEAR FROM AGE(o.order_date::date, DATE_TRUNC('month', c.signup_date)::date)) * 12 +
    EXTRACT(MONTH FROM AGE(o.order_date::date, DATE_TRUNC('month', c.signup_date)::date)) as months_since_signup
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
    AND o.order_status = 'Completed'
WHERE o.order_date IS NOT NULL;

-- 5. Cohort retention table (% of cohort making purchases each month)
SELECT 
    cohort_month,
    months_since_signup,
    COUNT(DISTINCT customer_id) as customers,
    COUNT(DISTINCT customer_id)::FLOAT / FIRST_VALUE(COUNT(DISTINCT customer_id)) 
        OVER (PARTITION BY cohort_month ORDER BY months_since_signup) * 100 as retention_rate
FROM v_cohorts
GROUP BY cohort_month, months_since_signup
ORDER BY cohort_month DESC, months_since_signup;

-- 6. Cohort revenue table
SELECT 
    cohort_month,
    COUNT(DISTINCT c.customer_id) as customers_in_cohort,
    ROUND(SUM(o.order_amount), 2) as total_revenue,
    ROUND(AVG(o.order_amount), 2) as avg_order_value,
    ROUND(SUM(o.order_amount) / COUNT(DISTINCT c.customer_id), 2) as revenue_per_customer
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
    AND o.order_status = 'Completed'
GROUP BY DATE_TRUNC('month', c.signup_date)
ORDER BY cohort_month DESC;

-- =========================================================
-- CUSTOMER LIFETIME VALUE (LTV) ANALYSIS
-- =========================================================

-- 7. Detailed customer LTV calculation
SELECT TOP 100
    c.customer_id,
    c.first_name || ' ' || c.last_name as name,
    c.signup_date,
    c.country,
    COUNT(o.order_id) as total_orders,
    SUM(CASE WHEN o.order_status = 'Completed' THEN 1 ELSE 0 END) as completed_orders,
    SUM(CASE WHEN o.order_status = 'Cancelled' THEN 1 ELSE 0 END) as cancelled_orders,
    ROUND(SUM(CASE WHEN o.order_status = 'Completed' THEN o.order_amount ELSE 0 END), 2) as ltv,
    ROUND(AVG(CASE WHEN o.order_status = 'Completed' THEN o.order_amount ELSE NULL END), 2) as avg_order_value,
    MAX(o.order_date) as last_purchase,
    EXTRACT(DAY FROM CURRENT_DATE - MAX(o.order_date)::date) as days_since_purchase
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.signup_date, c.country
ORDER BY ltv DESC;

-- 8. LTV distribution
SELECT 
    CASE 
        WHEN ltv < 500 THEN 'Low ($0-$500)'
        WHEN ltv < 1000 THEN 'Medium ($500-$1000)'
        WHEN ltv < 2000 THEN 'High ($1000-$2000)'
        WHEN ltv < 5000 THEN 'Very High ($2000-$5000)'
        ELSE 'Premium (>$5000)'
    END as ltv_segment,
    COUNT(*) as customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) as percentage,
    ROUND(AVG(ltv), 2) as avg_ltv,
    ROUND(SUM(ltv), 2) as total_revenue
FROM v_customer_metrics
GROUP BY ltv_segment
ORDER BY ltv DESC;

-- =========================================================
-- CUSTOMER CHURN ANALYSIS
-- =========================================================

-- 9. Identify at-risk customers (no purchase in 90+ days)
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name as name,
    c.email,
    MAX(o.order_date) as last_purchase,
    EXTRACT(DAY FROM CURRENT_DATE - MAX(o.order_date)::date) as days_inactive,
    SUM(o.order_amount) as lifetime_value,
    COUNT(o.order_id) as total_orders
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.email
HAVING EXTRACT(DAY FROM CURRENT_DATE - MAX(o.order_date)::date) >= 90
ORDER BY days_inactive DESC;

-- 10. Churn rate by cohort (customers who stopped purchasing)
SELECT 
    cohort_month,
    ROUND(100.0 * (
        FIRST_VALUE(COUNT(DISTINCT customer_id)) 
            OVER (PARTITION BY cohort_month ORDER BY months_since_signup) -
        COUNT(DISTINCT customer_id)
    ) / 
    FIRST_VALUE(COUNT(DISTINCT customer_id)) 
        OVER (PARTITION BY cohort_month ORDER BY months_since_signup) / 
    12, 2) as monthly_churn_rate
FROM v_cohorts
WHERE months_since_signup <= 12
GROUP BY cohort_month, months_since_signup
ORDER BY cohort_month DESC;

-- =========================================================
-- PRODUCT & CATEGORY ANALYSIS
-- =========================================================

-- 11. Top products by profit
SELECT TOP 20
    product_id,
    product_name,
    category,
    units_sold,
    ROUND(avg_price, 2) as avg_price,
    ROUND(total_revenue, 2) as revenue,
    ROUND((avg_price - (SELECT AVG(cost) FROM products WHERE product_id = v_product_performance.product_id)) * units_sold, 2) as estimated_profit
FROM v_product_performance
ORDER BY revenue DESC;

-- 12. Category performance summary
SELECT 
    category,
    COUNT(DISTINCT product_id) as products,
    SUM(units_sold) as units_sold,
    ROUND(SUM(total_revenue), 2) as category_revenue,
    ROUND(AVG(avg_price), 2) as avg_product_price,
    ROUND(SUM(total_revenue) / SUM(units_sold), 2) as revenue_per_unit
FROM v_product_performance
GROUP BY category
ORDER BY category_revenue DESC;

-- =========================================================
-- SEASONAL & TREND ANALYSIS
-- =========================================================

-- 13. Monthly sales trends with year-over-year comparison
SELECT 
    EXTRACT(YEAR FROM order_date) as year,
    EXTRACT(MONTH FROM order_date) as month,
    COUNT(DISTINCT order_id) as orders,
    ROUND(SUM(order_amount), 2) as revenue,
    ROUND(AVG(order_amount), 2) as avg_order_value
FROM orders
WHERE order_status = 'Completed'
GROUP BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date)
ORDER BY year DESC, month;

-- 14. Quarterly revenue trends
SELECT 
    EXTRACT(YEAR FROM order_date) as year,
    EXTRACT(QUARTER FROM order_date) as quarter,
    COUNT(DISTINCT order_id) as orders,
    ROUND(SUM(order_amount), 2) as revenue,
    COUNT(DISTINCT customer_id) as unique_customers,
    ROUND(SUM(order_amount) / COUNT(DISTINCT customer_id), 2) as revenue_per_customer
FROM orders
WHERE order_status = 'Completed'
GROUP BY EXTRACT(YEAR FROM order_date), EXTRACT(QUARTER FROM order_date)
ORDER BY year DESC, quarter DESC;

-- =========================================================
-- DASHBOARD DATA EXPORT
-- =========================================================

-- 15. Summary metrics for dashboard
SELECT 
    'Total Customers' as metric,
    COUNT(DISTINCT customer_id)::TEXT as value
FROM customers
UNION ALL
SELECT 'Active Customers', COUNT(DISTINCT customer_id)::TEXT FROM v_customer_metrics WHERE days_since_last_purchase <= 90
UNION ALL
SELECT 'Total Revenue', ROUND(SUM(customer_lifetime_value), 2)::TEXT FROM v_customer_metrics
UNION ALL
SELECT 'Average LTV', ROUND(AVG(customer_lifetime_value), 2)::TEXT FROM v_customer_metrics
UNION ALL
SELECT 'Total Orders', COUNT(*)::TEXT FROM orders WHERE order_status = 'Completed'
UNION ALL
SELECT 'Average Order Value', ROUND(AVG(order_amount), 2)::TEXT FROM orders WHERE order_status = 'Completed';

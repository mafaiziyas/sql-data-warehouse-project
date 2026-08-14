/*
===============================================================================
Script Name   : 10_analytics_reporting.sql
Engine        : MySQL Workbench
Description   : Final business intelligence and analytical reporting suite.
                Uses Gold Star Schema views to deliver key executive KPIs,
                customer lifetime value, product performance, and trend analyses.
===============================================================================
*/

USE gold;

-- ============================================================================
-- 1. EXECUTIVE KPI OVERVIEW
-- Single high-level summary dashboard query
-- ============================================================================
SELECT 
    COUNT(DISTINCT order_number)                     AS total_orders,
    COUNT(DISTINCT customer_key)                     AS total_purchasing_customers,
    SUM(quantity)                                    AS total_units_sold,
    ROUND(SUM(sales_amount), 2)                      AS total_revenue,
    ROUND(AVG(sales_amount), 2)                      AS avg_order_value,
    ROUND(SUM(sales_amount) / SUM(quantity), 2)      AS avg_unit_selling_price
FROM fact_sales;


-- ============================================================================
-- 2. PRODUCT CATEGORY & SUBCATEGORY PERFORMANCE
-- Identifies revenue drivers, volume leaders, and average prices
-- ============================================================================
SELECT 
    p.category,
    p.subcategory,
    COUNT(DISTINCT f.order_number)                   AS total_orders,
    SUM(f.quantity)                                  AS units_sold,
    ROUND(SUM(f.sales_amount), 2)                    AS revenue,
    ROUND(
        (SUM(f.sales_amount) / SUM(SUM(f.sales_amount)) OVER()) * 100, 2
    )                                                AS revenue_contribution_pct
FROM fact_sales f
JOIN dim_products p ON f.product_key = p.product_key
GROUP BY p.category, p.subcategory
ORDER BY revenue DESC;


-- ============================================================================
-- 3. CUSTOMER GEOGRAPHIC & DEMOGRAPHIC ANALYSIS
-- Breaks down revenue across countries and gender
-- ============================================================================
SELECT 
    c.country,
    c.gender,
    COUNT(DISTINCT c.customer_key)                   AS customer_count,
    COUNT(DISTINCT f.order_number)                   AS total_orders,
    ROUND(SUM(f.sales_amount), 2)                    AS total_revenue,
    ROUND(SUM(f.sales_amount) / COUNT(DISTINCT c.customer_key), 2) AS revenue_per_customer
FROM fact_sales f
JOIN dim_customers c ON f.customer_key = c.customer_key
GROUP BY c.country, c.gender
ORDER BY total_revenue DESC;


-- ============================================================================
-- 4. MONTHLY REVENUE & RUNNING TOTAL TRENDS
-- Tracks month-over-month (MoM) revenue growth and cumulative business revenue
-- ============================================================================
WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m')             AS sales_month,
        COUNT(DISTINCT order_number)                 AS total_orders,
        SUM(sales_amount)                            AS monthly_revenue
    FROM fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)
SELECT 
    sales_month,
    total_orders,
    ROUND(monthly_revenue, 2)                         AS monthly_revenue,
    ROUND(
        SUM(monthly_revenue) OVER (ORDER BY sales_month), 2
    )                                                AS cumulative_running_revenue
FROM monthly_sales
ORDER BY sales_month ASC;


-- ============================================================================
-- 5. TOP 10 PRODUCTS BY REVENUE (RANKED)
-- Uses DENSE_RANK() to identify flagship products
-- ============================================================================
WITH product_rankings AS (
    SELECT 
        p.product_name,
        p.category,
        SUM(f.quantity)                              AS total_quantity,
        SUM(f.sales_amount)                          AS total_revenue,
        DENSE_RANK() OVER (ORDER BY SUM(f.sales_amount) DESC) AS revenue_rank
    FROM fact_sales f
    JOIN dim_products p ON f.product_key = p.product_key
    GROUP BY p.product_name, p.category
)
SELECT 
    revenue_rank,
    product_name,
    category,
    total_quantity,
    ROUND(total_revenue, 2) AS total_revenue
FROM product_rankings
WHERE revenue_rank <= 10;


-- ============================================================================
-- 6. RFM CUSTOMER SEGMENTATION (RECENCY, FREQUENCY, MONETARY)
-- Categorizes customers into VIP, Regular, or Inactive based on behavior
-- ============================================================================
WITH customer_rfm AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name)       AS customer_name,
        MAX(f.order_date)                            AS last_order_date,
        COUNT(DISTINCT f.order_number)               AS frequency,
        SUM(f.sales_amount)                          AS monetary_value
    FROM fact_sales f
    JOIN dim_customers c ON f.customer_key = c.customer_key
    GROUP BY c.customer_id, customer_name
)
SELECT 
    customer_id,
    customer_name,
    last_order_date,
    frequency,
    ROUND(monetary_value, 2)                         AS total_spent,
    CASE 
        WHEN monetary_value > 5000 AND frequency >= 5 THEN 'VIP Customer'
        WHEN monetary_value BETWEEN 1000 AND 5000 THEN 'Regular Customer'
        ELSE 'Low-Volume Customer'
    END                                              AS customer_segment
FROM customer_rfm
ORDER BY total_spent DESC;
-- ============================================================
-- 09_quality_checks_gold.sql
-- Not part of the pipeline - run manually (or wire into your
-- scheduler) after each load to catch regressions.
-- Every query below should return 0 rows on clean data.
-- ============================================================

-- Duplicate or NULL customer id after dedup
SELECT cst_id, COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Unwanted spaces left in text fields
SELECT cst_key FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)
   OR cst_lastname  != TRIM(cst_lastname);

-- prd_end_dt earlier than prd_start_dt (bad history recalculation)
SELECT * FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

-- sales_details rows where sales != quantity * price
SELECT * FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price;

-- fact_sales rows that failed to match a dimension (broken FK)
SELECT * FROM gold.fact_sales WHERE product_key  IS NULL;
SELECT * FROM gold.fact_sales WHERE customer_key IS NULL;

-- 1.1 Check for duplicate customer surrogate keys or missing customer IDs
SELECT customer_key, COUNT(*) AS dup_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1 OR customer_key IS NULL;

-- 1.2 Check for duplicate product surrogate keys
SELECT product_key, COUNT(*) AS dup_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1 OR product_key IS NULL;

SELECT 
    c.country,
    c.gender,
    p.category,
    p.subcategory,
    COUNT(DISTINCT f.order_number) AS total_orders,
    SUM(f.quantity)                AS total_units_sold,
    ROUND(SUM(f.sales_amount), 2)  AS total_revenue,
    ROUND(AVG(f.sales_amount), 2)  AS avg_order_value
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c 
    ON f.customer_key = c.customer_key
LEFT JOIN gold.dim_products p 
    ON f.product_key = p.product_key
GROUP BY 
    c.country,
    c.gender,
    p.category,
    p.subcategory
ORDER BY total_revenue DESC;

SELECT * FROM silver.crm_sales_details LIMIT 10;
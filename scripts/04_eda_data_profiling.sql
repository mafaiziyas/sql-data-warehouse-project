/*
Script Name   : 04_eda_data_profiling.sql
Description   : Exploratory Data Analysis on Bronze tables.
                Audits raw data to identify data quality issues
                in preparation for Silver layer transformations.
*/


-- Data integrity errors
SELECT cst_id AS "duplicated_IDs", 
COUNT(cst_id) AS "duplicated_ID count" FROM crm_cust_info 
GROUP BY cst_id
HAVING COUNT(cst_id) >1 OR cst_id IS NULL;

-- Formatting errors 
SELECT cst_gndr from crm_cust_info 
GROUP BY cst_gndr;

-- Leading and trailing space errors
SELECT cst_firstname, LENGTH(cst_firstname) AS actual_len, LENGTH(TRIM(cst_firstname)) AS trimmed_len
FROM crm_cust_info
WHERE LENGTH(cst_firstname) != LENGTH(TRIM(cst_firstname))
LIMIT 10;

-- Check Product Key Structure and Invalid Product Cost
SELECT * 
FROM crm_prd_info 
WHERE prd_cost IS NULL OR CAST(prd_cost AS DECIMAL(10,2)) < 0;

-- Check Date Integers (e.g., '20101229') vs Invalid Date Formats
SELECT sls_order_dt, sls_ship_dt, sls_due_dt
FROM crm_sales_details
WHERE LENGTH(sls_order_dt) != 8 OR sls_order_dt NOT REGEXP '^[0-9]+$'
LIMIT 10;

-- Audit ERP Customer Key Cleaning Rule (Strip 'NAS' prefix)
SELECT cid, SUBSTRING(cid, 4) AS cleaned_cid, BDATE, GEN
FROM erp_cust_az12
LIMIT 10;

-- Audit ERP Location Key Cleaning Rule (Strip '-' hyphen)
SELECT cid, REPLACE(cid, '-', '') AS cleaned_cid, CNTRY
FROM erp_loc_a101
LIMIT 10;

-- Testing if cleaned ERP keys successfully match CRM customer keys
SELECT 
    c.cst_id,
    c.cst_key,
    a.cid AS raw_erp_cid,
    l.cid AS raw_loc_cid
FROM crm_cust_info c
LEFT JOIN erp_cust_az12 a ON c.cst_key = SUBSTRING(a.cid, 4)
LEFT JOIN erp_loc_a101 l ON c.cst_key = REPLACE(l.cid, '-', '')
WHERE a.cid IS NULL OR l.cid IS NULL;
/*
===============================================================================
Script Name   : 07_quality_checks_silver.sql
Description   : Post-transformation data quality audit on the 'silver' schema.
                Validates deduplication, standardizations, numerical integrity, 
                and date consistency across all Silver tables.
===============================================================================
*/

USE silver;

-- ============================================================================
-- 1. PRIMARY KEY DEDUPLICATION & NULL CHECKS
-- Every result set below should return 0 ROWS (No errors)
-- ============================================================================

-- 1.1 crm_cust_info: Verify cst_id is unique and not null
SELECT cst_id, COUNT(*) AS duplicate_count
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- 1.2 crm_prd_info: Verify prd_id is unique and not null
SELECT prd_id, COUNT(*) AS duplicate_count
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- 1.3 erp_cust_az12: Verify cleaned cid is unique and not null
SELECT cid, COUNT(*) AS duplicate_count
FROM silver.erp_cust_az12
GROUP BY cid
HAVING COUNT(*) > 1 OR cid IS NULL;

-- 1.4 erp_loc_a101: Verify cleaned cid is unique and not null
SELECT cid, COUNT(*) AS duplicate_count
FROM silver.erp_loc_a101
GROUP BY cid
HAVING COUNT(*) > 1 OR cid IS NULL;


-- ============================================================================
-- 2. DOMAIN & VALUE STANDARDIZATION CHECKS
-- Verify that dirty text strings were normalized properly
-- ============================================================================

-- 2.1 Verify Marital Status only contains 'Single', 'Married', or 'n/a'
SELECT DISTINCT cst_marital_status FROM silver.crm_cust_info;

-- 2.2 Verify Gender across CRM and ERP contains clean standard values
SELECT DISTINCT cst_gndr FROM silver.crm_cust_info;
SELECT DISTINCT gen FROM silver.erp_cust_az12;

-- 2.3 Verify Product Lines are fully mapped
SELECT DISTINCT prd_line FROM silver.crm_prd_info;

-- 2.4 Verify Countries in ERP location are fully standardized
SELECT DISTINCT cntry FROM silver.erp_loc_a101;


-- ============================================================================
-- 3. DATE INTEGRITY CHECKS
-- Check for logical errors in calendar fields
-- ============================================================================

-- 3.1 Product Start vs End Date: Ensure no end dates precede start dates
SELECT prd_id, prd_start_dt, prd_end_dt
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

-- 3.2 Sales Order vs Ship/Due Date: Ensure order date is before ship/due date
SELECT sls_ord_num, sls_order_dt, sls_ship_dt, sls_due_dt
FROM silver.crm_sales_details
WHERE sls_ship_dt < sls_order_dt OR sls_due_dt < sls_order_dt;


-- ============================================================================
-- 4. FINANCIAL & NUMERICAL INTEGRITY CHECKS
-- Validate business calculations and math constraints
-- ============================================================================

-- 4.1 Verify Sales Math (Sales = Quantity * Price)
SELECT sls_ord_num, sls_sales, sls_quantity, sls_price,
       (sls_quantity * sls_price) AS expected_sales
FROM silver.crm_sales_details
WHERE sls_sales != (sls_quantity * sls_price)
   OR sls_sales <= 0 
   OR sls_price <= 0;


-- ============================================================================
-- 5. FOREIGN KEY / CROSS-SYSTEM JOIN INTEGRITY
-- Verify that Silver CRM records join smoothly with Silver ERP records
-- ============================================================================

-- Check for unmapped customer keys between CRM and ERP
SELECT 
    c.cst_id,
    c.cst_key,
    a.cid AS erp_cust_cid,
    l.cid AS erp_loc_cid
FROM silver.crm_cust_info c
LEFT JOIN silver.erp_cust_az12 a ON c.cst_key = a.cid
LEFT JOIN silver.erp_loc_a101 l ON c.cst_key = l.cid
WHERE a.cid IS NULL OR l.cid IS NULL;
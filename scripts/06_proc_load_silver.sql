-- ============================================================
-- 04_proc_load_silver.sql
-- Reads from bronze, writes cleaned rows into silver.
-- Every rule here is a real issue found in this dataset.
-- Run bronze.load_bronze() first.
-- ============================================================

USE silver;

DROP PROCEDURE IF EXISTS load_silver;

DELIMITER $$

CREATE PROCEDURE load_silver()
BEGIN

    -- ---------------------------------------------------------
    -- crm_cust_info
    -- Issues fixed: leading/trailing spaces on names, 1-letter
    -- codes -> readable values, duplicate cst_id (keep the row
    -- with the latest cst_create_date), blank cst_id excluded.
    -- ---------------------------------------------------------
    TRUNCATE TABLE crm_cust_info;
    INSERT INTO crm_cust_info
        (cst_id, cst_key, cst_firstname, cst_lastname,
         cst_marital_status, cst_gndr, cst_create_date)
    SELECT
        cst_id,
        cst_key,
        TRIM(cst_firstname),
        TRIM(cst_lastname),
        CASE UPPER(TRIM(cst_marital_status))
            WHEN 'M' THEN 'Married'
            WHEN 'S' THEN 'Single'
            ELSE 'n/a'
        END,
        CASE UPPER(TRIM(cst_gndr))
            WHEN 'M' THEN 'Male'
            WHEN 'F' THEN 'Female'
            ELSE 'n/a'
        END,
        cst_create_date
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY cst_id
                                   ORDER BY cst_create_date DESC) AS rn
        FROM bronze.crm_cust_info
        WHERE cst_id IS NOT NULL
    ) ranked
    WHERE rn = 1;

    -- ---------------------------------------------------------
    -- crm_prd_info
    -- Issues fixed: prd_key packs a category code + the actual
    -- sales-matching key ('CO-RF-FR-R92B-58' -> cat 'CO-RF' +
    -- key 'FR-R92B-58'); NULL prd_cost -> 0; 1-letter product
    -- line -> readable value; prd_end_dt recomputed as the day
    -- before the *next* version of that product starts, instead
    -- of trusting the source end date (which overlaps the next
    -- row's start date in this file).
    -- ---------------------------------------------------------
    TRUNCATE TABLE crm_prd_info;
    INSERT INTO crm_prd_info
        (prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line,
         prd_start_dt, prd_end_dt)
    SELECT
        prd_id,
        REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_'),
        SUBSTRING(prd_key, 7),
        prd_nm,
        COALESCE(prd_cost, 0),
        CASE UPPER(TRIM(prd_line))
            WHEN 'M' THEN 'Mountain'
            WHEN 'R' THEN 'Road'
            WHEN 'S' THEN 'Sport'
            WHEN 'T' THEN 'Touring'
            ELSE 'n/a'
        END,
        prd_start_dt,
        DATE_SUB(
            LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt),
            INTERVAL 1 DAY
        )
    FROM bronze.crm_prd_info;

    -- ---------------------------------------------------------
    -- crm_sales_details
    -- Issues fixed: dates stored as YYYYMMDD ints (and some as 0)
    -- -> real DATEs or NULL; sales/price recalculated when
    -- missing, zero, negative, or inconsistent with qty * price.
    -- ---------------------------------------------------------
    TRUNCATE TABLE crm_sales_details;
    INSERT INTO crm_sales_details
        (sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt,
         sls_ship_dt, sls_due_dt, sls_sales, sls_quantity, sls_price)
    SELECT
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        CASE WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt) != 8 THEN NULL
             ELSE STR_TO_DATE(sls_order_dt, '%Y%m%d') END,
        CASE WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt) != 8 THEN NULL
             ELSE STR_TO_DATE(sls_ship_dt, '%Y%m%d') END,
        CASE WHEN sls_due_dt = 0 OR LENGTH(sls_due_dt) != 8 THEN NULL
             ELSE STR_TO_DATE(sls_due_dt, '%Y%m%d') END,
        -- sales validated against the CORRECTED price (fixed_price),
        -- not the raw one - otherwise a blank price corrupts a
        -- perfectly good sales figure during recalculation
        CASE
            WHEN sls_sales IS NULL OR sls_sales <= 0
                 OR sls_sales != sls_quantity * ABS(fixed_price)
            THEN sls_quantity * ABS(fixed_price)
            ELSE sls_sales
        END,
        sls_quantity,
        fixed_price
    FROM (
        SELECT
            sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt,
            sls_ship_dt, sls_due_dt, sls_sales, sls_quantity,
            CASE
                WHEN sls_price IS NULL OR sls_price <= 0
                THEN sls_sales / NULLIF(sls_quantity, 0)
                ELSE sls_price
            END AS fixed_price
        FROM bronze.crm_sales_details
    ) staged;

    -- ---------------------------------------------------------
    -- erp_cust_az12
    -- Issues fixed: cid sometimes prefixed with 'NAS' (extra 3
    -- chars vs cst_key) -> stripped so it matches cst_key;
    -- birthdates in the future -> NULL; gen has 4 different
    -- spellings -> standardized.
    -- ---------------------------------------------------------
    TRUNCATE TABLE erp_cust_az12;
    INSERT INTO erp_cust_az12 (cid, bdate, gen)
    SELECT
        CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4) ELSE cid END,
        CASE WHEN bdate > CURDATE() THEN NULL ELSE bdate END,
        CASE UPPER(TRIM(gen))
            WHEN 'F' THEN 'Female'
            WHEN 'FEMALE' THEN 'Female'
            WHEN 'M' THEN 'Male'
            WHEN 'MALE' THEN 'Male'
            ELSE 'n/a'
        END
    FROM bronze.erp_cust_az12;

    -- ---------------------------------------------------------
    -- erp_loc_a101
    -- Issues fixed: cid has dashes ('AW-00011000') that cst_key
    -- doesn't ('AW00011000') -> stripped; country has codes and
    -- inconsistent spellings -> standardized; blanks -> 'n/a'.
    -- ---------------------------------------------------------
    TRUNCATE TABLE erp_loc_a101;
    INSERT INTO erp_loc_a101 (cid, cntry)
    SELECT
        REPLACE(cid, '-', ''),
        CASE
            WHEN TRIM(cntry) IN ('US', 'USA', 'United States') THEN 'United States'
            WHEN TRIM(cntry) = 'DE' THEN 'Germany'
            WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
            ELSE TRIM(cntry)
        END
    FROM bronze.erp_loc_a101;

    -- ---------------------------------------------------------
    -- erp_px_cat_g1v2
    -- Already clean in the source; trimmed defensively.
    -- ---------------------------------------------------------
    TRUNCATE TABLE erp_px_cat_g1v2;
    INSERT INTO erp_px_cat_g1v2 (id, cat, subcat, maintenance)
    SELECT TRIM(id), TRIM(cat), TRIM(subcat), TRIM(maintenance)
    FROM bronze.erp_px_cat_g1v2;

END$$

DELIMITER ;

-- Run it (after bronze.load_bronze()):
-- CALL silver.load_silver();
bronze.load_bronze()
CALL silver.load_silver();

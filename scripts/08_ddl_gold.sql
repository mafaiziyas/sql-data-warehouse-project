-- ============================================================
-- 05_ddl_gold.sql
-- Gold = business-facing star schema. Views only - always live
-- against silver, no separate load step. This is the first place
-- CRM and ERP data for the same customer/product actually meet,
-- so survivorship rules (which source wins) live here.
-- ============================================================

USE gold;

-- ---------------------------------------------------------
-- dim_customers
-- CRM is treated as the master for gender (it's the system
-- customers directly interact with); ERP fills the gap when
-- CRM has no value. Birthdate and country only exist in ERP.
-- ---------------------------------------------------------
CREATE OR REPLACE VIEW dim_customers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY ci.cst_id)  AS customer_key,
    ci.cst_id                                AS customer_id,
    ci.cst_key                               AS customer_number,
    ci.cst_firstname                         AS first_name,
    ci.cst_lastname                          AS last_name,
    la.cntry                                 AS country,
    ci.cst_marital_status                    AS marital_status,
    CASE
        WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr   -- CRM is master
        ELSE COALESCE(ca.gen, 'n/a')                  -- fallback to ERP
    END                                       AS gender,
    ca.bdate                                 AS birthdate,
    ci.cst_create_date                       AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101  la ON ci.cst_key = la.cid;

-- ---------------------------------------------------------
-- dim_products
-- Only current products (prd_end_dt IS NULL) go into the
-- dimension - historical versions stay in silver for lineage
-- but a dimension row per customer-facing product, not per
-- version, is what fact_sales should join against.
-- ---------------------------------------------------------
CREATE OR REPLACE VIEW dim_products AS
SELECT
    ROW_NUMBER() OVER (ORDER BY pi.prd_start_dt, pi.prd_key) AS product_key,
    pi.prd_id                                AS product_id,
    pi.prd_key                               AS product_number,
    pi.prd_nm                                AS product_name,
    pi.cat_id                                AS category_id,
    pc.cat                                   AS category,
    pc.subcat                                AS subcategory,
    pc.maintenance                           AS maintenance,
    pi.prd_cost                              AS cost,
    pi.prd_line                              AS product_line,
    pi.prd_start_dt                          AS start_date
FROM silver.crm_prd_info pi
LEFT JOIN silver.erp_px_cat_g1v2 pc ON pi.cat_id = pc.id
WHERE pi.prd_end_dt IS NULL;

-- ---------------------------------------------------------
-- fact_sales
-- Grain: one row per sales order line. Joins to the two
-- dimensions above via their surrogate keys.
-- ---------------------------------------------------------
CREATE OR REPLACE VIEW fact_sales AS
SELECT
    sd.sls_ord_num   AS order_number,
    dp.product_key,
    dc.customer_key,
    sd.sls_order_dt  AS order_date,
    sd.sls_ship_dt   AS shipping_date,
    sd.sls_due_dt    AS due_date,
    sd.sls_sales     AS sales_amount,
    sd.sls_quantity  AS quantity,
    sd.sls_price     AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products  dp ON sd.sls_prd_key = dp.product_number
LEFT JOIN gold.dim_customers dc ON sd.sls_cust_id  = dc.customer_id;
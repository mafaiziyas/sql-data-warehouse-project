/* 03_ddl_silver.sql
Silver = same grain as bronze, one table per source table,
but properly typed and standardized. Every table gets a
dwh_create_date so you can see when a row was last (re)loaded.
*/

USE silver;

DROP TABLE IF EXISTS crm_cust_info;
CREATE TABLE crm_cust_info (
    cst_id              INT,
    cst_key             VARCHAR(50),
    cst_firstname       VARCHAR(50),
    cst_lastname        VARCHAR(50),
    cst_marital_status  VARCHAR(10),   -- 'Married' / 'Single' / 'n/a'
    cst_gndr            VARCHAR(10),   -- 'Male' / 'Female' / 'n/a'
    cst_create_date     DATE,
    dwh_create_date     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS crm_prd_info;
CREATE TABLE crm_prd_info (
    prd_id           INT,
    cat_id           VARCHAR(50),      -- derived, joins to erp_px_cat_g1v2.id
    prd_key          VARCHAR(50),      -- derived, joins to sales_details.sls_prd_key
    prd_nm           VARCHAR(50),
    prd_cost         INT,
    prd_line         VARCHAR(50),      -- 'Mountain' / 'Road' / 'Sport' / 'Touring' / 'n/a'
    prd_start_dt     DATE,
    prd_end_dt       DATE,             -- recalculated from the next row's start date
    dwh_create_date  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS crm_sales_details;
CREATE TABLE crm_sales_details (
    sls_ord_num      VARCHAR(50),
    sls_prd_key      VARCHAR(50),
    sls_cust_id      INT,
    sls_order_dt     DATE,             -- real DATE now, not YYYYMMDD int
    sls_ship_dt      DATE,
    sls_due_dt       DATE,
    sls_sales        INT,              -- recalculated where inconsistent
    sls_quantity     INT,
    sls_price        INT,              -- recalculated where missing/invalid
    dwh_create_date  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS erp_cust_az12;
CREATE TABLE erp_cust_az12 (
    cid              VARCHAR(50),      -- standardized to match cst_key format
    bdate            DATE,             -- future dates nulled out
    gen              VARCHAR(10),      -- 'Male' / 'Female' / 'n/a'
    dwh_create_date  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS erp_loc_a101;
CREATE TABLE erp_loc_a101 (
    cid              VARCHAR(50),      -- standardized to match cst_key format
    cntry            VARCHAR(50),      -- standardized country names
    dwh_create_date  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS erp_px_cat_g1v2;
CREATE TABLE erp_px_cat_g1v2 (
    id               VARCHAR(50),
    cat              VARCHAR(50),
    subcat           VARCHAR(50),
    maintenance      VARCHAR(10),
    dwh_create_date  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- Indexes on every column the gold views join on. Without these,
-- MySQL falls back to a nested-loop scan - on this dataset that's
-- the difference between ~24s and well under a second per join.

CREATE INDEX idx_crm_cust_info_key   ON crm_cust_info (cst_key);
CREATE INDEX idx_crm_prd_info_key    ON crm_prd_info (prd_key);
CREATE INDEX idx_crm_prd_info_cat    ON crm_prd_info (cat_id);
CREATE INDEX idx_crm_sales_prd_key   ON crm_sales_details (sls_prd_key);
CREATE INDEX idx_crm_sales_cust_id   ON crm_sales_details (sls_cust_id);
CREATE INDEX idx_erp_cust_az12_cid   ON erp_cust_az12 (cid);
CREATE INDEX idx_erp_loc_a101_cid    ON erp_loc_a101 (cid);
CREATE INDEX idx_erp_px_cat_id       ON erp_px_cat_g1v2 (id);
/*
Script Name   : 02_proc_load_bronze.sql
Description   : Truncates and reloads every bronze table from the source CSVs.

NOTE: adjust the file paths below to wherever your CSVs live.
-- Requires local_infile enabled: SET GLOBAL local_infile=1;
-- and the client connected with --local-infile=1.

*/

SET GLOBAL local_infile = 1; # To enable local CSV imports

USE bronze;

-- Load crm_cust_info
TRUNCATE TABLE crm_cust_info;
LOAD DATA LOCAL INFILE '/Users/mohomedmafaiz/Downloads/cust_info.csv'
    INTO TABLE crm_cust_info
    FIELDS TERMINATED BY ','
    LINES TERMINATED BY '\r\n'
    IGNORE 1 ROWS
    (@cst_id, cst_key, cst_firstname, cst_lastname,
     cst_marital_status, cst_gndr, @cst_create_date)
    SET cst_id = NULLIF(@cst_id, ''),
        cst_create_date = NULLIF(@cst_create_date, '');

-- Load crm_prd_info
TRUNCATE TABLE crm_prd_info;
LOAD DATA LOCAL INFILE '/Users/mohomedmafaiz/Downloads/prd_info.csv'
    INTO TABLE crm_prd_info
    FIELDS TERMINATED BY ','
    LINES TERMINATED BY '\r\n'
    IGNORE 1 ROWS
    (prd_id, prd_key, prd_nm, @prd_cost, prd_line,
     prd_start_dt, @prd_end_dt)
    SET prd_cost   = NULLIF(@prd_cost, ''),
        prd_end_dt = NULLIF(@prd_end_dt, '');

-- Load crm_sales_details
TRUNCATE TABLE crm_sales_details;
LOAD DATA LOCAL INFILE '/Users/mohomedmafaiz/Downloads/sales_details.csv'
    INTO TABLE crm_sales_details
    FIELDS TERMINATED BY ','
    LINES TERMINATED BY '\r\n'
    IGNORE 1 ROWS
    (sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt,
     sls_ship_dt, sls_due_dt, @sls_sales, sls_quantity, @sls_price)
    SET sls_sales = NULLIF(@sls_sales, ''),
        sls_price = NULLIF(@sls_price, '');

-- Load erp_cust_az12
TRUNCATE TABLE erp_cust_az12;
LOAD DATA LOCAL INFILE '/Users/mohomedmafaiz/Downloads/CUST_AZ12.csv'
    INTO TABLE erp_cust_az12
    FIELDS TERMINATED BY ','
    LINES TERMINATED BY '\r\n'
    IGNORE 1 ROWS
    (cid, @bdate, gen)
    SET bdate = NULLIF(@bdate, '');

-- Load erp_loc_a101
TRUNCATE TABLE erp_loc_a101;
LOAD DATA LOCAL INFILE '/Users/mohomedmafaiz/Downloads/LOC_A101.csv'
    INTO TABLE erp_loc_a101
    FIELDS TERMINATED BY ','
    LINES TERMINATED BY '\r\n'
    IGNORE 1 ROWS
    (cid, cntry);

-- Load erp_px_cat_g1v2
TRUNCATE TABLE erp_px_cat_g1v2;
LOAD DATA LOCAL INFILE '/Users/mohomedmafaiz/Downloads/PX_CAT_G1V2.csv'
    INTO TABLE erp_px_cat_g1v2
    FIELDS TERMINATED BY ','
    LINES TERMINATED BY '\r\n'
    IGNORE 1 ROWS
    (id, cat, subcat, maintenance);
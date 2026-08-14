/*
Script Name   : 01_ddl_bronze.sql 
Description   : Bronze = raw copy of source files. Columns and types mirror the CSVs as closely as possible. 
				No cleaning, no renaming. Based on initial profiling, the source datasets were found to be mostly clean 
                and highly structured with consistent formatting. 
			    Therefore, strict target data types (INT, DATE, VARCHAR) are explicitly enforced.
                This ensures ingestion level data quality validation, optimizes storage.
*/

USE bronze;
 
DROP TABLE IF EXISTS crm_cust_info;


CREATE TABLE crm_cust_info (
  cst_id INT,
  cst_key VARCHAR(50),
  cst_firstname VARCHAR(50),
  cst_lastname VARCHAR(50),
  cst_marital_status VARCHAR(1),
  cst_gndr VARCHAR(1),
  cst_create_date DATE);
  
DROP TABLE IF EXISTS crm_prd_info;
CREATE TABLE crm_prd_info (
  prd_id INT,
  prd_key VARCHAR(50),
  prd_nm VARCHAR(50),
  prd_cost INT,
  prd_line VARCHAR(50),
  prd_start_dt DATE,
  prd_end_dt   DATE);
 
DROP TABLE IF EXISTS crm_sales_details;
CREATE TABLE crm_sales_details (
    sls_ord_num  VARCHAR(50),
    sls_prd_key  VARCHAR(50),
    sls_cust_id  INT,
    sls_order_dt INT,          -- raw YYYYMMDD as given, not a real date yet
    sls_ship_dt  INT,
    sls_due_dt   INT,
    sls_sales    INT,
    sls_quantity INT,
    sls_price    INT);
 
DROP TABLE IF EXISTS erp_cust_az12;
CREATE TABLE erp_cust_az12 (
    cid   VARCHAR(50),
    bdate DATE,
    gen   VARCHAR(50));
 
DROP TABLE IF EXISTS erp_loc_a101;
CREATE TABLE erp_loc_a101 (
    cid   VARCHAR(50),
    cntry VARCHAR(50));
 
DROP TABLE IF EXISTS erp_px_cat_g1v2;
CREATE TABLE erp_px_cat_g1v2 (
    id          VARCHAR(50),
    cat         VARCHAR(50),
    subcat      VARCHAR(50),
    maintenance VARCHAR(50));



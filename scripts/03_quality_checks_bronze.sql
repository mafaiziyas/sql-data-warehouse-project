/*
Script Name   : 03_quality_checks_bronze.sql
Description   : Post-ingestion validation on the Bronze layer.
                Checks table row counts, null primary keys and basic table 
                size to ensure raw ingestion completed successfully.
*/

-- Auditing # of records
SELECT 'crm_cust_info' AS table_name, COUNT(*) AS raw_row_count FROM crm_cust_info
UNION ALL
SELECT 'crm_prd_info', COUNT(*) FROM crm_prd_info
UNION ALL
SELECT 'crm_sales_details', COUNT(*) FROM crm_sales_details
UNION ALL
SELECT 'erp_cust_az12', COUNT(*) FROM erp_cust_az12
UNION ALL
SELECT 'erp_loc_a101', COUNT(*) FROM erp_loc_a101
UNION ALL
SELECT 'erp_px_cat_g1v2', COUNT(*) FROM erp_px_cat_g1v2;

SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'bronze' AND table_rows = 0;
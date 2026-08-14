SET GLOBAL local_infile = 1; # To enable local CSV imports

/*
Script Name   : 00_init_database.sql
Description   : Initializes the Data Warehouse database engine environment and 
                creates the Medallion Architecture schemas (bronze, silver, gold).

WARNING:
Running this script will drop the 'DataWarehouse' database if it exists.
All data within the database will be permanently deleted.          
*/

DROP DATABASE IF EXISTS bronze;
DROP DATABASE IF EXISTS silver;
DROP DATABASE IF EXISTS gold;
 
CREATE DATABASE bronze CHARACTER SET utf8mb4; #To support special accent utf8mb4 is used
CREATE DATABASE silver CHARACTER SET utf8mb4;
CREATE DATABASE gold   CHARACTER SET utf8mb4;
 
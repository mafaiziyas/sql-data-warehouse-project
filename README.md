# Data Warehouse and Analytics Project

This project demonstrates a comprehensive data warehousing and analytics solution, from building a data warehouse to generating actionable insights. Designed as a portfolio project, it highlights industry best practices in data engineering and analytics.

---
## 🏗️ Data Architecture

The data architecture for this project follows Medallion Architecture **Bronze**, **Silver**, and **Gold** layers:

1. **Bronze Layer**: Stores raw data as-is from the source systems. Data is ingested from CSV Files into SQL Server Database.
2. **Silver Layer**: This layer includes data cleansing, standardization, and normalization processes to prepare data for analysis.
3. **Gold Layer**: Houses business-ready data modeled into a star schema required for reporting and analytics.

![Medallian Architecture Data Pipeline](docs/medallion_architecture_data_pipeline.png)

---
## 📖 Project Overview

This project involves:

1. **Data Architecture**: Designing a Modern Data Warehouse Using Medallion Architecture **Bronze**, **Silver**, and **Gold** layers.
2. **ETL Pipelines**: Extracting, transforming, and loading data from source systems into the warehouse.
3. **Data Modeling**: Developing fact and dimension tables optimized for analytical queries.
4. **Analytics & Reporting**: Creating SQL-based reports and dashboards for actionable insights.

---
## 🛠️ Tech Stack & Tools
* **Database Engine:** MySQL Server
* **Database Management GUI:** MySQL Workbench
* **Architecture:** Medallion Architecture (Bronze, Silver, Gold)
* **Data Sources:** CRM and ERP CSV Datasets

 Raw CSV data from CRM and ERP source systems is ingested, cleansed, and modeled inside a MySQL relational database server on macOS using MySQL Workbench.

---

## 📁 Repository Structure

```text
sql-data-warehouse-project/
├── datasets/
│   ├── source_crm/
│   │   ├── cust_info.csv
│   │   ├── prd_info.csv
│   │   └── sales_details.csv
│   └── source_erp/
│       ├── CUST_AZ12.csv
│       ├── LOC_A101.csv
│       └── PX_CAT_G1V2.csv
├── docs/
│   ├── data_architecture.png
│   ├── medallion_architecture_data_pipeline.png
│   └── placeholder.txt
├── scripts/
│   ├── 00_init_database.sql          # Database & Schema Setup
│   ├── 01_ddl_bronze.sql             # Raw Schema Tables (CRM & ERP)
│   ├── 02_proc_load_bronze.sql       # Bulk Ingestion Stored Procedure
│   ├── 03_quality_checks_bronze.sql  # Post-ingestion Raw Counts & Audits
│   ├── 04_eda_data_profiling.sql     # Pre-load Exploration & Quality Audits
│   ├── 05_ddl_silver.sql             # Cleaned Schema Tables
│   ├── 06_proc_load_silver.sql       # Transformation Stored Procedure
│   ├── 07_quality_checks_silver.sql  # Data Quality & Constraint Validations
│   ├── 08_ddl_gold.sql               # Star Schema Dimensional Views
│   ├── 09_quality_checks_gold.sql    # Referential Integrity & BI Checks
│   └── 10_analytics_reporting.sql   # Business KPIs & Ad-hoc Queries
└── README.md

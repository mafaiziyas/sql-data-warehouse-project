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

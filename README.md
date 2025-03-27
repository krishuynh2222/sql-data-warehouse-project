# Data Warehouse and Analytics Project

Welcome to the **Data Warehouse and Analytics Project** repository! 🚀
This project demonstrates a comprehensive data warehousing and analytics solution, from building a data warehouse to generating actionable insights.

--- 
## 📖 Project Overview
This project involves:
1. **Data Architecture**: Designing a Modern Data Warehouse Using Medallion Architecture Bronze, Silver, and Gold layers.
2. **ETL Pipelines**: Extracting, transforming, and loading data from source systems into the warehouse.
3. **Data Modeling**: Developing fact and dimension tables optimized for analytical queries.
4. **Analytics & Reporting**: Creating SQL-based reports and dashboards for actionable insights.

## 🚀 Project Requirements

### Building the Data Warehouse (Data Engineering)

#### Objective 
Develop a modern data warehouse using PostgreSQL to consolidate sales data, enabling analytical reporting and informed decision-making. 

#### Specifications
- **Data Sources**: Import data from two source systems (ERP and CRM) provided as CSV files
- **Data Quality**: Cleanse and resolve data quality issues before the analysis phase.
- **Integration**: Combine both sources into a single, user-friendly data model designed for analytical
- **Scope**: Focus on the lastest dataset only; historizaition of data is not required
- **Documentation**: Provide detailed documentation of the data model to support business stakeholders and analytics teams.
---

### BI: Analytics & Reporting (Data Analytics)

#### Objective 
Develop SQL-based analytics to deliver detailed insights into:
- **Customer Behavior**
- **Product Performance**
- **Sales Trends**

- These insights empower stakeholders with key business metrics, enabling strategic decision-making
  
--- 
## 📏 Data Architecture 

The data architecture for this project follows Medallion Architecture Bronze, Silver, and Gold layers:  
![Image](https://github.com/user-attachments/assets/9d60e958-1c77-4e16-8f04-c563519ef4a3)
1. **Bronze Layer**: Stores raw data as-is from the source systems. Data is ingested from CSV Files into the PostgreSQL Database.
2. **Silver Layer**: This layer includes data cleansing, standardization, and normalization processes to prepare data for analysis.
3. **Gold Layer**: Houses business-ready data modeled into a star schema required for reporting and analytics.

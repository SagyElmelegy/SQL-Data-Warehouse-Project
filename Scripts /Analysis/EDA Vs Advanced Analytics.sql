-- Exploratory Data Analysis (EDA)

/*
SQL Projects:
1) Data Warehousing: Organize, Structure, Prepare
- ETL/ ELT Processing
- Data Architecture
- Data Integration
- Data Cleansing
- Data Load
- Data Modelling

2) Exploratory Data Analysis (EDA): Understanding the Data
- Basic Queries
- Data Profiling
- Simple Aggregations
- Subquery

3) Advanced Data Analytics: Answer Business Questions
- Complex Queries
- Window Functions
- CTE 
- Subqueries
- Reports
*/

-- Dimensions & Measures
/*
To differentiate between them, ask the following question:
Is the data integer and make sense to be aggregated?
If yes then it is a measure 
If no then it is a dimension (If any case of the previous answer is no then it is a dimension)
*/

-- Examples:

SELECT DISTINCT
category
FROM Gold.dim_products
-- It is dimension since it isn't a number 

SELECT DISTINCT
sales_amount
FROM Gold.fact_sales
-- It is a measure since it is a number and it makes sense to be aggregated 

SELECT DISTINCT 
DATEDIFF(YEAR,birth_date, GETDATE()) AS Age
FROM Gold.dim_customers
-- It is a measure since Age is a number and make sense to be aggregated 
-- Keep in mind that age is a measure but the birthdate itself is a  dimension since it is a date not an integer

SELECT DISTINCT
customer_id
FROM Gold.dim_customers
-- It is a dimension. Although it is an integer but it doesn't make sense to be aggregated since id is a unique identifier

/*
EDA:
1) Database Exploration 
2) Dimension Exploration
3) Date Exploration
4) Measures Exploration
5) Magnitude
6) Ranking (Top N - Bottom N)

Advanced Anaytics:
1) Change-Over-Time (Trends)
2) Cumulative Analysis
3) Performance Analysis
4) Part-To-Whole (Proportional)
5) Data Segmentation
6) Reporting
*/

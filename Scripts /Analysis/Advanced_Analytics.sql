-- Advanced Data Analytics
/*
Advanced Anaytics:
1) Change-Over-Time (Trends)
2) Cumulative Analysis
3) Performance Analysis
4) Part-To-Whole (Proportional)
5) Data Segmentation
6) Reporting
*/

-- 1) Change-over-Time 
-- Analyze how a measure evolves over time.
-- Helps in tracking trends and identify seasonality in data.
-- Formula: AggFunc [Measure] By [Date Dimension] -> Total Sales By Year

-- Task: Analyze sales performance over Time
SELECT 
YEAR(order_date) AS Order_Year,
MONTH(order_date) AS Order_Month,
SUM(sales_amount) AS Total_Sales,
COUNT(DISTINCT customer_key) AS Total_Customers,
SUM(quantity) AS Total_Quantity
FROM Gold.fact_sales
WHERE YEAR(order_date) IS NOT NULL
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY YEAR(order_date) , MONTH(order_date)
-- Or use DATETRUNC()
SELECT 
DATETRUNC(MONTH,order_date) AS Order_Date,
SUM(sales_amount) AS Total_Sales,
COUNT(DISTINCT customer_key) AS Total_Customers,
SUM(quantity) AS Total_Quantity
FROM Gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(MONTH,order_date)
ORDER BY DATETRUNC(MONTH,order_date)
-- Altering the format
SELECT 
FORMAT(order_date,'yyyy-MMM') AS Order_Date,
SUM(sales_amount) AS Total_Sales,
COUNT(DISTINCT customer_key) AS Total_Customers,
SUM(quantity) AS Total_Quantity
FROM Gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY FORMAT(order_date,'yyyy-MMM')
ORDER BY FORMAT(order_date,'yyyy-MMM')

-- 2) Cumulative Analysis
-- Aggregating the data progressively over time.
-- Helps in understanding whether the business is growing or declining.
-- Formula: AggFunc [Cumulative Measure] By [Date Dimension] -> Running Total Sales By Year

-- Task: Calculate the total sales per month and the running total of sales over time.
SELECT
Order_Date,
Total_Sales,
SUM(Total_Sales) OVER (ORDER BY Order_Date) AS Running_Total_Sales,
AVG(Avg_Price) OVER (ORDER BY Order_Date) AS Moving_Average
FROM
(
	SELECT
	DATETRUNC(MONTH,order_date) AS Order_Date,
	SUM(sales_amount) AS Total_Sales,
	AVG(price) AS Avg_Price
	FROM Gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY DATETRUNC(MONTH,order_date)
) t

-- 3) Performance Analysis
-- Comparing the current value to a target value
-- Helps measure success and compare performance
-- Formula: Current[Measure] - Target[Measure] -> Curremt Year Sales - Previous Year Sales (YOY Analysis)

-- Task: Analyze the yearly performance of products by comparing each product's sales 
--		 to both its average sales performance and the previous year's sales.
WITH Yearly_Product_Sales AS 
(
	SELECT
	YEAR(f.order_date) AS Order_Year,
	p.product_name,
	SUM(f.sales_amount) AS Current_Sales 
	FROM Gold.fact_sales f
	LEFT JOIN Gold.dim_products p
	ON f.product_key = p.product_key
	WHERE order_date IS NOT NULL
	GROUP BY YEAR(f.order_date), p.product_name
) 
SELECT 
Order_Year,
product_name,
Current_Sales,
AVG(Current_Sales) OVER (PARTITION BY product_name) AS Avg_sales,
Current_Sales - AVG(Current_Sales) OVER (PARTITION BY product_name) AS Diff_Avg,
CASE
	WHEN Current_Sales - AVG(Current_Sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Average'
	WHEN Current_Sales - AVG(Current_Sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Average'
	ELSE 'Average'
END AS Avg_Change,
-- Year-Ove-Year Analysis
LAG(Current_Sales) OVER (PARTITION BY product_name ORDER BY Order_Year) AS Prev_Year_Sales,
Current_Sales - LAG(Current_Sales) OVER (PARTITION BY product_name ORDER BY Order_Year) AS Diff_Prev_Year_Sales,
CASE
	WHEN Current_Sales - LAG(Current_Sales) OVER (PARTITION BY product_name ORDER BY Order_Year) > 0 THEN 'Increased'
	WHEN Current_Sales - LAG(Current_Sales) OVER (PARTITION BY product_name ORDER BY Order_Year) < 0 THEN 'Decreased'
	ELSE 'No Change'
END AS Prev_Year_Change
FROM Yearly_Product_Sales
ORDER BY product_name, Order_Year

-- 4) Part-to-Whole Analysis (Proportional Analysis)
/*
 Analyze how an individual part is performing compared to the overall which allows understanding 
 which category has the greatest impact on the business
*/
-- Formula: ([Measure] / Total[Measure]) * 100 By [Dimension] -> (Sales / Total Sales) * 100 By Category {Finding the Percentage}
 
-- Task: Which category contribute the most to the overall sales?
WITH Category_Sales AS
(
	SELECT
	p.category,
	SUM(f.sales_amount) AS Total_Sales
	FROM Gold.fact_sales f
	LEFT JOIN Gold.dim_products p
	ON f.product_key = p.product_key
	GROUP BY P.category
)
SELECT
category,
Total_Sales,
SUM(Total_Sales) OVER () AS Overall_Sales,
CONCAT(ROUND((CAST(Total_Sales AS FLOAT) / SUM(Total_Sales) OVER ()) * 100,2),' %') AS Percentage_of_Total
FROM Category_Sales
ORDER BY Total_Sales DESC

-- 5) Data Segmentation
-- Grouping the data based on a specific range.
-- Helps understanding the correlation between two measures.
-- Formula: [Measure] By [Measure] -> Total Customers By Age

-- Task: Segment products into cost ranges and count how many products fall into each segment
WITH Products_Segments AS 
(
	SELECT
	product_key,
	product_name,
	product_cost,
	CASE 
		WHEN product_cost < 100 THEN 'Below 100'
		WHEN product_cost BETWEEN 100 AND 500 THEN '100-500'
		WHEN product_cost BETWEEN 500 AND 1000 THEN '500-1000'
		ELSE 'Above 1000'
	END Cost_Range
	FROM Gold.dim_products 
)
SELECT
Cost_Range,
COUNT(product_key) AS Total_Products
FROM Products_Segments
GROUP BY Cost_Range
ORDER BY Total_Products DESC

/*
Task:
Group customers into three segments based on their spending behaviour:
- VIP: at least 12 months of history and spending more than 5000$
- Regular: at least 12 months of history but spending 5000$ or less
- New: lifespan less than 12 months
And find the total number of customers by each group
*/
WITH Customer_Spending AS 
(
	SELECT
	c.customer_key,
	SUM(f.sales_amount) Total_Spending,
	MIN(order_date) First_Order,
	MAX(order_date) Last_Order,
	DATEDIFF(MONTH,MIN(order_date),MAX(order_date)) AS Lifespan
	FROM Gold.fact_sales f
	LEFT JOIN Gold.dim_customers c
	ON f.customer_key = c.customer_key
	GROUP BY c.customer_key
)
SELECT
Customer_Segments,
COUNT(customer_key) AS Total_Customers
FROM
(
	SELECT
	customer_key,
	CASE 
		WHEN Lifespan >= 12 AND Total_Spending > 5000 THEN 'VIP'
		WHEN Lifespan >= 12 AND Total_Spending <= 5000 THEN 'Regular'
		ELSE 'New'
	END AS Customer_Segments
	FROM Customer_Spending
) t
GROUP BY Customer_Segments
ORDER BY Total_Customers DESC

-- 6) Building Customer Report
/*
=============================================================================
CUSTOMER REPORT
=============================================================================
Purpose:
	- This report consolidates key customer metrics and behaviours
Highlights:
	1) Gathers essential fields such as names, ages and transaction details
	2) Segments customers into categories (VIP, Regular, New) and age groups.
	3) Aggregates Customer-Level metrics:
		- Total Orders
		- Total Sales
		- Total Quantity Purchased
		- Total Products
		- Lifespan (in months)
	4) Calculates valuable KPIs:
		- Recency (Months since last order)
		- Average Order Value
		- Average Monthly spend
=============================================================================
*/

CREATE VIEW Gold.report_customers AS 
WITH base_query AS 
-- ===============================================================
-- 1] Base Query: Retrieving core columns from tables
-- ===============================================================
(
	SELECT
	f.order_number,
	f.product_key,
	f.order_date,
	f.sales_amount,
	f.quantity,
	c.customer_key,
	c.customer_number,
	CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
	DATEDIFF(YEAR,c.birth_date,GETDATE()) AS age
	FROM Gold.fact_sales f
	LEFT JOIN GOLD.dim_customers c
	ON f.customer_key = c.customer_key
	WHERE order_date IS NOT NULL
),
customer_aggregation AS (
-- ===============================================================
-- 2) Aggregating Customer level metrics
-- ===============================================================
	SELECT 
	customer_key,
	customer_number,
	customer_name,
	age,
	COUNT(DISTINCT order_number) AS total_orders,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_quantity,
	COUNT(DISTINCT product_key) AS total_products,
	MAX(order_date) AS last_order_date,
	DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan
	FROM base_query
	GROUP BY 
	customer_key,
	customer_number,
	customer_name,
	age
)
-- ===============================================================
-- 3) Segmenting Customers into Categories
-- ===============================================================
SELECT 
customer_key,
customer_number,
customer_name,
age,
CASE 
	WHEN age > 20 THEN 'Under 20'
	WHEN age BETWEEN 20 AND 29 THEN '20-29'
	WHEN age BETWEEN 30 AND 39 THEN '30-39'
	WHEN age BETWEEN 40 AND 49 THEN '40-49'
	ELSE '50 and Above'
END AS age_group,
CASE
	WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
	WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
	ELSE 'New'
END AS customer_segment,
last_order_date,
-- =============================================================
-- 4] Create KPIs
-- ===============================================================
DATEDIFF(MONTH, last_order_date, GETDATE()) AS recency,
total_orders,	
total_sales,
total_quantity,
total_products,
lifespan,
-- Compute Average Order Value (AVO)
CASE
	WHEN total_orders = 0 THEN 0
	ELSE total_sales / total_orders
END AS avg_order_value,
-- Compute Average Monthly Spent (AV1)
CASE 
	WHEN lifespan = 0 THEN total_sales
	ELSE total_sales / lifespan
END AS avg_monthly_spend
FROM customer_aggregation


SELECT * FROM Gold.report_customers
GO

-- 7) Building Product Report
/*
=============================================================================
PRODUCT REPORT
=============================================================================
Purpose:
	- This report consolidates key product metrics and behaviours
Highlights:
	1) Gathers essential fields such as product name, category, subcategory and cost.
	2) Segments products by revenue to identify High-Performers, Mid-Range or Low-Performers.
	3) Aggregates Product-Level metrics:
		- Total Orders
		- Total Sales
		- Total Quantity Sold
		- Total Customers (unique)
		- Lifespan (in months)
	4) Calculates valuable KPIs:
		- Recency (Months since last order)
		- Average Order Revenue (AOR)
		- Average Monthly Revenue
=============================================================================
*/
CREATE VIEW Gold.product_report AS 
WITH base_query AS 
(
	SELECT 
	f.order_number,
	f.customer_key,
	f.order_date,
	f.sales_amount,
	f.quantity,
	p.product_key,
	p.product_name,
	p.category,
	p.subcategory,
	p.product_cost
	FROM Gold.fact_sales f
	LEFT JOIN Gold.dim_products p
	ON f.product_key = p.product_key
)
, product_aggregation AS
(
	SELECT
	product_key,
	product_name,
	category,
	subcategory,
	product_cost,
	COUNT(DISTINCT order_number) total_orders,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_quantity_sold,
	COUNT(DISTINCT customer_key) AS total_customers,
	MAX(order_date) AS last_order,
	DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan
	FROM base_query
	GROUP BY 
	product_key,
	product_name,
	category,
	subcategory,
	product_cost
)
SELECT
product_key,
product_name,
category,
subcategory,
product_cost,
total_orders,
total_sales,
CASE
	WHEN total_sales <= 100000 THEN 'Low Performer' 
	WHEN total_sales >= 1000000 THEN 'High Performer'
	ELSE 'Mid-Range'
END AS product_segment,
total_quantity_sold,
lifespan,
DATEDIFF(MONTH, last_order, GETDATE()) AS recency,
-- Average Order Revenue (AOR)
CASE
	WHEN total_orders = 0 THEN 0
	ELSE total_sales / total_orders 
END AS avg_order_revenue,
-- Average Monthly Revenue (AMR)
CASE 
	WHEN lifespan = 0 THEN total_sales
	ELSE total_sales / lifespan
END AS average_monthly_revenue
FROM product_aggregation

SELECT * FROM Gold.product_report

-- Clean & Load to Silver.crm_sales_details
SELECT * FROM Bronze.crm_sales_details

-- Checking unwanted spaces
SELECT
sls_ord_num
FROM Bronze.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num) 

-- Checking invalid dates
SELECT
NULLIF(sls_order_dt,0) AS sls_order_dt
FROM Bronze.crm_sales_details
WHERE sls_order_dt <= 0 
OR LEN(sls_order_dt) != 8 
OR sls_order_dt > 20500101 
OR sls_order_dt < 19000101

SELECT 
sls_ship_dt
FROM Bronze.crm_sales_details
WHERE sls_ship_dt <= 0
OR LEN(sls_ship_dt) != 8
OR sls_ship_dt > 20500101
OR sls_ship_dt < 19000101

SELECT 
sls_due_dt
FROM Bronze.crm_sales_details
WHERE sls_due_dt <= 0
OR LEN(sls_due_dt) != 8
OR sls_due_dt > 20500101
OR sls_due_dt < 19000101

SELECT
sls_order_dt,
sls_ship_dt,
sls_due_dt
FROM Bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt

-- Business Rule: Sales = Quantity * Price (No Negative, Zeros, Nulls are Allowed)
-- Rules:
-- 1) If Sales are negative, zero, or null then derive it using the Quantity and Price
-- 2) If Prices are zero, or null then derive it using the Quantity and Sales
-- 3) If the Price is negative then convert it to a positive value
SELECT DISTINCT
sls_sales AS old_sales,
sls_quantity,
sls_price AS old_price,
CASE
	WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) 
		THEN sls_quantity * ABS(sls_price)
	ELSE sls_sales 
END AS sls_sales,
CASE 
	WHEN sls_price IS NULL OR sls_price <= 0 
		THEN ABS(sls_sales) / NULLIF(sls_quantity,0)
	ELSE sls_price
END AS sls_price
FROM Bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales,sls_quantity,sls_price

-- Update the DDL of the table (Done in each table after transformation)
IF OBJECT_ID ('Silver.crm_sales_details', 'U') IS NOT NULL
	DROP TABLE Silver.crm_sales_details;
CREATE TABLE Silver.crm_sales_details
(
	sls_ord_num NVARCHAR(50),
	sls_prd_key NVARCHAR(50),
	sls_cust_id INT,
	sls_order_dt DATE,
	sls_ship_dt DATE,
	sls_due_dt DATE,
	sls_sales INT,
	sls_quantity INT,
	sls_price INT,
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);



INSERT INTO Silver.crm_sales_details
(
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt,
	sls_sales,
	sls_quantity,
	sls_price
)
SELECT 
sls_ord_num,
sls_prd_key,
sls_cust_id,
CASE
	WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
	ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
	END AS sls_order_dt,
CASE
	WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
	ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
	END AS sls_ship_dt,
CASE
	WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
	ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
	END AS sls_due_dt,
CASE
	WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) 
		THEN sls_quantity * ABS(sls_price)
	ELSE sls_sales 
END AS sls_sales,
sls_quantity,
CASE 
	WHEN sls_price IS NULL OR sls_price <= 0 
		THEN ABS(sls_sales) / NULLIF(sls_quantity,0)
	ELSE sls_price
END AS sls_price
FROM Bronze.crm_sales_details



-- Now we check after transformation

-- Checking unwanted spaces
SELECT
sls_ord_num
FROM Silver.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num) 

-- Checking invalid dates
SELECT
sls_order_dt,
sls_ship_dt,
sls_due_dt
FROM Silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt

-- Business Rule: Sales = Quantity * Price (No Negative, Zeros, Nulls are Allowed)
SELECT DISTINCT
sls_sales,
sls_quantity,
sls_price 
FROM Silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales,sls_quantity,sls_price

-- Final look at the whole table 
SELECT * FROM Silver.crm_sales_details

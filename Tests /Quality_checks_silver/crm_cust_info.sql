-- Clean & Load to Silver.crm_cust_info

SELECT * FROM Bronze.crm_cust_info

-- Quality Checks: 
-- Checking for Nulls or Duplicates in the Primary Key (Expectation: No Result)

SELECT 
cst_id,
COUNT(*)
FROM Bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL 

-- Checking for unwanted spaces in string values (Expectation: No Result)

SELECT 
cst_firstname
FROM Bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)

SELECT 
cst_lastname
FROM Bronze.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname)

-- Data Standardization & Consistency

SELECT DISTINCT
cst_gndr
FROM Bronze.crm_cust_info

SELECT DISTINCT
cst_marital_status
FROM Bronze.crm_cust_info



-- To Solve the Problem
INSERT INTO Silver.crm_cust_info 
(
	cst_id,
	cst_key,
	cst_firstname,
	cst_lastname,
	cst_marital_status,
	cst_gndr,
	cst_create_date
)

SELECT 
cst_id,
cst_key,
TRIM(cst_firstname) AS cst_firstname,
TRIM(cst_lastname) AS cst_lastname,
CASE
	WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
	WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
	ELSE 'N/A'
END cst_marital_status, -- Normalize marital status values to readable format
CASE
	WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
	WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
	ELSE 'N/A'
END cst_gndr,	-- Normalize gender values to readable format
cst_create_date
FROM
(
	SELECT 
	*,
	ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
	FROM Bronze.crm_cust_info 
	WHERE cst_id IS NOT NULL
) t 
WHERE flag_last = 1	-- Select the most recent record per  customer



-- Checking for the silver table now 

-- Checking for Nulls or Duplicates in the Primary Key (Expectation: No Result)

SELECT 
cst_id,
COUNT(*)
FROM Silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL 

-- Checking for unwanted spaces in string values (Expectation: No Result)

SELECT 
cst_firstname
FROM Silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)

SELECT 
cst_lastname
FROM Silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname)

-- Data Standardization & Consistency

SELECT DISTINCT
cst_gndr
FROM Silver.crm_cust_info

SELECT DISTINCT
cst_marital_status
FROM Silver.crm_cust_info

SELECT * FROM Silver.crm_cust_info

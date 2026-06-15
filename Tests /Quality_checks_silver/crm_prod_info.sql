-- Clean & Load to Silver.crm_prod_info

SELECT * FROM Bronze.crm_prd_info

-- Checking NULLS & DUPLICATES in the PRIMARY KEY

SELECT 
prd_id,
COUNT(*)
FROM Bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL 

-- Checking for unwanted spaces

SELECT 
prd_nm
FROM Bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)

-- Checking for NULLS or Negative numbers

SELECT
prd_cost
FROM Bronze.crm_prd_info
WHERE prd_cost IS NULL OR prd_cost < 0

-- Data Standardization & Consistency

SELECT DISTINCT
prd_line
FROM Bronze.crm_prd_info

-- Check for Invalid Date Orders

SELECT 
*
FROM Bronze.crm_prd_info
WHERE prd_end_dt < prd_start_dt
-- End Date = Start Date of the NEXT Record - 1 
SELECT 
prd_id,
prd_key,
prd_nm,
prd_start_dt,
prd_end_dt,
LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS prd_end_dt_test
FROM Bronze.crm_prd_info
WHERE prd_key IN ('AC-HE-HL-U509-R', 'AC-HE-HL-U509','CL-SO-SO-B909-M')


INSERT INTO Silver.crm_prd_info
(
	prd_id,
	cat_id,
	prd_key,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt

)
SELECT
prd_id,
REPLACE(SUBSTRING(prd_key, 1, 5),'-','_') AS cat_id, -- Extract Category ID
SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key, -- Extract Product Key
prd_nm,
ISNULL(prd_cost, 0) AS prd_cost,
CASE UPPER(TRIM(prd_Line))
	WHEN 'M' THEN 'Mountain'
	WHEN 'R' THEN 'Road'
	WHEN 'S' THEN 'Other Sales'
	WHEN 'T' THEN 'Touring'
	ELSE 'N/A'
END AS prd_line, -- Map product line codes to descriptive values
CAST(prd_start_dt AS DATE) AS prd_start_dt,
CAST(
	LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS DATE
) AS prd_end_dt -- Calculate the end date as one day before the next start date
FROM Bronze.crm_prd_info



-- Now we check the silver table 

-- Checking Nulls & Duplicates
SELECT 
prd_id,
COUNT(*)
FROM Bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL 

-- Checking for unwanted spaces
SELECT 
prd_nm
FROM Silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)

-- Checking for NULLS or Negative numbers
SELECT
prd_cost
FROM Silver.crm_prd_info
WHERE prd_cost IS NULL OR prd_cost < 0

-- Data Standardization & Consistency
SELECT DISTINCT
prd_line
FROM Silver.crm_prd_info

-- Check for Invalid Date Orders
SELECT 
*
FROM Silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt

-- Showing the current status of the Silver.crm_prod_info
SELECT * FROM Silver.crm_prd_info

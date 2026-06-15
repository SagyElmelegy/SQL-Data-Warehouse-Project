-- Clean & Load to Silver.erp_cust_az12

-- Testing whether there is a mismatch between the cid and cust_info (Expectation: No Record)
SELECT 
CASE 
	WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))
	ELSE cid
END cid,
bdate,
gen
FROM Bronze.erp_cust_az12
WHERE CASE 
		WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))
		ELSE cid
END NOT IN (SELECT DISTINCT cst_key FROM Silver.crm_cust_info)

-- Identifying out-of-range dates
SELECT DISTINCT 
bdate
FROM Bronze.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > GETDATE()

-- Data Standardization & Consistency
SELECT DISTINCT
gen,
CASE 
	WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
	WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
	ELSE 'N/A'
END AS gen
FROM Bronze.erp_cust_az12



INSERT INTO Silver.erp_cust_az12
(
	cid,
	bdate,
	gen
)
SELECT 
CASE 
	WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid)) -- Remove 'NAS' prefix if present
	ELSE cid
END cid,
CASE 
	WHEN bdate > GETDATE() THEN NULL 
	ELSE bdate
END AS bdate, -- Set future birthdates to NULL 
CASE 
	WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
	WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
	ELSE 'N/A'
END AS gen -- Normalize gender values and handle unkown cases
FROM Bronze.erp_cust_az12



-- Quality check for the table 

-- Testing whether there is unmatching between the cid and cust_info (Expectation: No Record)
SELECT 
CASE 
	WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))
	ELSE cid
END cid,
bdate,
gen
FROM Silver.erp_cust_az12
WHERE CASE 
		WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))
		ELSE cid
END NOT IN (SELECT DISTINCT cst_key FROM Silver.crm_cust_info)

-- Identifying out of range dates
SELECT DISTINCT 
bdate
FROM Silver.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > GETDATE()

-- Data Standardization & Consistency
SELECT DISTINCT
gen,
CASE 
	WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
	WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
	ELSE 'N/A'
END AS gen
FROM Silver.erp_cust_az12

-- Final look at the table 
SELECT * FROM Silver.erp_cust_az12

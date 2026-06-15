-- Clean & Load to Silver.erp_loc_a101

SELECT * FROM Bronze.erp_loc_a101

-- Removing the '-' sign in the cid
SELECT 
REPLACE(cid,'-','') cid,
cntry
FROM Bronze.erp_loc_a101 
WHERE REPLACE(cid,'-','') NOT IN 
(
	SELECT cst_key FROM Silver.crm_cust_info
)

-- Data Standardization & Consistency 
SELECT DISTINCT 
cntry AS Old_cntry,
CASE	
	WHEN TRIM(cntry) = 'DE' THEN 'Germany'
	WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
	WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'N/A'
	ELSE TRIM(cntry)
END AS cntry
FROM Bronze.erp_loc_a101
ORDER BY cntry



INSERT INTO Silver.erp_loc_a101
(
	cid,
	cntry
)
SELECT 
REPLACE(cid,'-','') cid,
CASE	
	WHEN TRIM(cntry) = 'DE' THEN 'Germany'
	WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
	WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'N/A'
	ELSE TRIM(cntry)
END AS cntry	-- Normalize and Handling missing or blank country codes 
FROM Bronze.erp_loc_a101 



-- Quality Check

-- Removing the '-' sign in the cid
SELECT 
REPLACE(cid,'-','') cid,
cntry
FROM Silver.erp_loc_a101 
WHERE REPLACE(cid,'-','') NOT IN 
(
	SELECT cst_key FROM Silver.crm_cust_info
)

-- Data Standardization & Consistency 
SELECT DISTINCT 
cntry AS Old_cntry,
CASE	
	WHEN TRIM(cntry) = 'DE' THEN 'Germany'
	WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
	WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'N/A'
	ELSE TRIM(cntry)
END AS cntry
FROM Silver.erp_loc_a101
ORDER BY cntry

-- Final look at the table  
SELECT * FROM Silver.erp_loc_a101

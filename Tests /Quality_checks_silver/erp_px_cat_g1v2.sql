-- Clean & Load to Silver.erp_px_cat_g1v2

SELECT * FROM Bronze.erp_px_cat_g1v2

-- Removing unwanted spaces
SELECT
cat,
subcat,
maintenance
FROM Bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat) 
OR subcat != TRIM(subcat)
OR maintenance != TRIM(maintenance)

-- Data Standardization & Consistency
SELECT DISTINCT
cat
FROM Bronze.erp_px_cat_g1v2

SELECT DISTINCT
subcat
FROM Bronze.erp_px_cat_g1v2

SELECT DISTINCT
maintenance
FROM Bronze.erp_px_cat_g1v2



INSERT INTO Silver.erp_px_cat_g1v2
(
	id,
	cat,
	subcat,
	maintenance
)
SELECT 
id,
cat,
subcat,
maintenance
FROM Bronze.erp_px_cat_g1v2



-- Final look at the table 
SELECT * FROM Silver.erp_px_cat_g1v2

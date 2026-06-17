/*
===================================================================
Quality Checks 
===================================================================
Script Purpose:
    This script performs quality checks to validate the integrity,
    consistency and accuracy of the Gold layer.
    These checks ensured:
    - Uniqueness of surrogate keys in dimension tables.
    - Referential integrity between fact and dimension tables.
    - Validation of relationships in the data model for analytical
      purposes.
*/

-- ================================================================
-- Quality Checks Gold.dim_customers
-- ================================================================
-- Checking for uniqueness of Customer key
SELECT 
	customer_key,
	COUNT(*) AS duplicate_count
FROM Gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- ================================================================
-- Quality Checks Gold.dim_products
-- ================================================================
-- Checking for uniqueness of Product key
SELECT
	product_key,
	COUNT(*) AS duplicate_count
FROM Gold.dim_products
GROUP BY product_key
Having COUNT(*) > 1;

-- ================================================================
-- Quality Checks Gold.fact_sales
-- ================================================================
-- Checking the data model connectivity between fact and dimensions 
SELECT 
*
FROM Gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
LEFT JOIN Gold.dim_products p
ON p.product_key = f.product_key
WHERE p.product_key IS NULL OR c.customer_key IS NULL 

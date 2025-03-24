/*
================================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
================================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to
    populate the 'silver' schema tables from the 'bronze' schema.
  Actions Performed:
    - Truncates Silver tables
    - Inserts transformed and cleansed data from Bronze into Silver tables

Parameters:
    None.
    This stored procedure does not accept any parameters or return any values.

Usage Example:
    CALL silver.load_silver();
================================================================================
*/

CREATE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    batch_start_time TIMESTAMP;
    batch_end_time TIMESTAMP;
BEGIN
    -- Record batch start time
    batch_start_time := NOW();

    RAISE NOTICE '========================================';
    RAISE NOTICE 'Starting Bronze Layer Data Load at %', batch_start_time;
    RAISE NOTICE '========================================';

    -- CRM Customer Info Table
    start_time := NOW();

	RAISE NOTICE '>> Truncating Table: silver.crm_cust_info';
	TRUNCATE TABLE silver.crm_cust_info;
	RAISE NOTICE '>> Inserting Data Into: silver.crm_cust_info';
	INSERT INTO silver.crm_cust_info (
	    cst_id,
	    cst_key,
	    cst_firstname,
	    cst_lastname,
	    cst_material_status,
	    cst_gndr,
	    cst_create_data,
	    dwh_create_data
	)
	SELECT 
	    cst_id,
	    cst_key,
	    TRIM(cst_firstname) AS cst_firstname,  -- Clean trailing/leading spaces
	    TRIM(cst_lastname) AS cst_lastname,
	
	    -- Standardizing 'cst_material_status' values
	    CASE 
	        WHEN UPPER(TRIM(cst_material_status)) IN ('S', 'SINGLE') THEN 'Single'
	        WHEN UPPER(TRIM(cst_material_status)) IN ('M', 'MARRIED') THEN 'Married'
	        ELSE 'n/a'
	    END AS cst_material_status,
	
	    -- Standardizing 'cst_gndr' values
	    CASE 
	        WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
	        WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
	        ELSE 'n/a'
	    END AS cst_gndr,
	
	    cst_create_data,
	
	    NOW() AS dwh_create_data -- Tracks when data was inserted into `silver`
	FROM (
	    -- Deduplication logic using ROW_NUMBER()
	    SELECT *,
	           ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_data DESC) AS flag_last
	    FROM bronze.crm_cust_info
	    WHERE cst_id IS NOT NULL   -- Exclude null customer IDs for data quality
	) AS subquery
	WHERE flag_last = 1;  -- Keep only the most recent record for each `cst_id`
	-- Log duration
    end_time := NOW();
    RAISE NOTICE '>> CRM Customer Info Load Duration: % seconds', EXTRACT(EPOCH FROM (end_time - start_time));


	-- CRM Product Info Table
    start_time := NOW();
	RAISE NOTICE '>> Truncating Table: silver.crm_prd_info';
	TRUNCATE TABLE silver.crm_prd_info;
	RAISE NOTICE '>> Inserting Data Into: silver.crm_prd_info';
	INSERT INTO silver.crm_prd_info (
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
		REPLACE(SUBSTRING (prd_key, 1, 5), '-','_') AS cat_id,
		SUBSTRING(prd_key, 7, LENGTH(prd_key)) AS prd_key,
		prd_nm,
		COALESCE(prd_cost, 0) AS prd_cost,
		CASE UPPER(TRIM(prd_line))
			WHEN 'M' THEN 'Mountain'
			WHEN 'R' THEN 'Road'
			WHEN 'S' THEN 'Other Sales'
			WHEN 'T' THEN 'Touring'
			 ELSE 'n/a'
		END AS prd_line,
		CAST(prd_start_dt AS DATE) AS prd_start_dt,
	    -- Keep NULL for the last row in each partition
	    CAST(
	        LEAD(prd_start_dt) 
	        OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - INTERVAL '1day' 
	        AS DATE
	    ) AS prd_end_dt
	FROM bronze.crm_prd_info;
	  -- Log duration
    end_time := NOW();
    RAISE NOTICE '>> CRM Product Info Load Duration: % seconds', EXTRACT(EPOCH FROM (end_time - start_time));

	
	-- CRM Sales Details Table
    start_time := NOW();
	RAISE NOTICE '>> Truncating Table: silver.crm_sales_details';
	TRUNCATE TABLE silver.crm_sales_details;
	RAISE NOTICE '>> Inserting Data Into: silver.crm_sales_details';
	INSERT INTO silver.crm_sales_details (
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
		WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt::TEXT) != 8 THEN NULL
		ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
	END AS sls_order_dt,
	
	CASE 
		WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt::TEXT) != 8 THEN NULL
		ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
	END AS sls_ship_dt,
	
	CASE 
		WHEN sls_due_dt = 0 OR LENGTH(sls_due_dt::TEXT) != 8 THEN NULL
		ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
	END AS sls_due_dt,
	
	CASE 
		WHEN  sls_sales IS NULL 
			OR sls_sales <= 0 
			OR sls_sales != sls_quantity * ABS(sls_price)
		THEN sls_quantity * ABS(sls_price)
		ELSE sls_sales
	END AS sls_sales,
	
	sls_quantity,
	CASE 
		WHEN sls_price IS NULL 
			OR sls_price <= 0
		THEN ABS(sls_sales / NULLIF(sls_quantity,0))
		ELSE sls_price
	END AS sls_price
	
	FROM bronze.crm_sales_details;
	 -- Log duration
    end_time := NOW();
    RAISE NOTICE '>> CRM Sales Details Load Duration: % seconds', EXTRACT(EPOCH FROM (end_time - start_time));
	
	-- ERP Customer AZ12 Table
	start_time := NOW();
	RAISE NOTICE '>> Truncating Table: silver.erp_cust_az12';
	TRUNCATE TABLE silver.erp_cust_az12;
	RAISE NOTICE '>> Inserting Data Into: silver.erp_cust_az12';
	INSERT INTO silver.erp_cust_az12 (
		cid,
		bdate,
		gen
	)
	SELECT 
		CASE
			WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LENGTH(cid)) 
			ELSE cid
		END AS cid,
		CASE 
			WHEN bdate > NOW() THEN NULL
			ELSE bdate
		END AS bdate,
		CASE 
			WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
			WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
			ELSE 'n/a'
		END AS gen
	FROM bronze.erp_cust_az12;
	-- Log duration
	end_time := NOW();
	RAISE NOTICE '>> silver.erp_cust_az12 Load Duration: % seconds', EXTRACT(EPOCH FROM (end_time - start_time));

	-- ERP Location Table
	start_time := NOW();
	RAISE NOTICE '>> Truncating Table: silver.erp_loc_a101';
	TRUNCATE TABLE silver.erp_loc_a101;
	RAISE NOTICE '>> Inserting Data Into: silver.erp_loc_a101';
	INSERT INTO silver.erp_loc_a101 (
		cid,
		cntry
	)
	SELECT 
		REPLACE(cid, '-', '') cid,
		CASE
			WHEN TRIM(cntry) = 'DE' THEN 'Germany'
			WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
			WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
			ELSE TRIM(cntry)
		END AS cntry
	FROM bronze.erp_loc_a101 
	ORDER BY cntry;
	-- Log duration
	end_time := NOW();
	RAISE NOTICE '>> silver.erp_loc_a101 Load Duration: % seconds', EXTRACT(EPOCH FROM (end_time - start_time));


	-- ERP PX Catalog Table
	start_time := NOW();
	RAISE NOTICE '>> Truncating Table: silver.erp_px_cat_g1v2 ';
	TRUNCATE TABLE silver.erp_px_cat_g1v2 ;
	RAISE NOTICE '>> Inserting Data Into: silver.erp_px_cat_g1v2 ';
	INSERT INTO silver.erp_px_cat_g1v2 (
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
	FROM bronze.erp_px_cat_g1v2;
	-- Log duration
	end_time := NOW();
	RAISE NOTICE '>> silver.erp_px_cat_g1v2 Load Duration: % seconds', EXTRACT(EPOCH FROM (end_time - start_time));
	


 -- End Process
    batch_end_time := NOW();
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Loading Silver Layer is Completed %', batch_end_time;
    RAISE NOTICE 'Total Duration: % seconds', EXTRACT(EPOCH FROM (batch_end_time - batch_start_time));
    RAISE NOTICE '========================================';

	EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'ERROR OCCURRED DURING BRONZE LAYER DATA LOAD!';
    RAISE NOTICE 'Error Message: %', SQLERRM;
    RAISE NOTICE 'Error Code: %', SQLSTATE;
    RAISE NOTICE '========================================';
	
END $$;

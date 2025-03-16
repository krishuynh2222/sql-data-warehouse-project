/*
============================================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze
============================================================================================
Script Purpose:
  This stored procedure loads data into the 'bronze' schema from external CSV files.
  It performs the following actions:
  - Truncates the bronze tables before loading data.

Parameters:
  None.
  This stored procedure does not accept any parameters or return any values.

Usage Example:
CALL bronze.load_bronze();

============================================================================================
*/
CREATE PROCEDURE bronze.load_bronze()
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
    RAISE NOTICE '>> Truncating Table: bronze.crm_cust_info';
    TRUNCATE TABLE bronze.crm_cust_info;

    RAISE NOTICE '>> Inserting Data Into: bronze.crm_cust_info';
    INSERT INTO bronze.crm_cust_info
    SELECT * FROM bronze.crm_cust_info;

    end_time := NOW();
    RAISE NOTICE '>> Load Duration (CRM Cust Info): % seconds', EXTRACT(EPOCH FROM (end_time - start_time));

    -- CRM Product Info Table
    start_time := NOW();
    RAISE NOTICE '>> Truncating Table: bronze.crm_prd_info';
    TRUNCATE TABLE bronze.crm_prd_info;

    RAISE NOTICE '>> Inserting Data Into: bronze.crm_prd_info';
    INSERT INTO bronze.crm_prd_info
    SELECT * FROM bronze.crm_prd_info;

    end_time := NOW();
    RAISE NOTICE '>> Load Duration (CRM Product Info): % seconds', EXTRACT(EPOCH FROM (end_time - start_time));

    -- CRM Sales Details Table
    start_time := NOW();
    RAISE NOTICE '>> Truncating Table: bronze.crm_sales_details';
    TRUNCATE TABLE bronze.crm_sales_details;

    RAISE NOTICE '>> Inserting Data Into: bronze.crm_sales_details';
    INSERT INTO bronze.crm_sales_details
    SELECT * FROM bronze.crm_sales_details;

    end_time := NOW();
    RAISE NOTICE '>> Load Duration (CRM Sales Details): % seconds', EXTRACT(EPOCH FROM (end_time - start_time));

    -- ERP Cust Table
    start_time := NOW();
    RAISE NOTICE '>> Truncating Table: bronze.erp_cust_az12';
    TRUNCATE TABLE bronze.erp_cust_az12;

    RAISE NOTICE '>> Inserting Data Into: bronze.erp_cust_az12';
    INSERT INTO bronze.erp_cust_az12
    SELECT * FROM bronze.erp_cust_az12;

    end_time := NOW();
    RAISE NOTICE '>> Load Duration (ERP Cust): % seconds', EXTRACT(EPOCH FROM (end_time - start_time));

    -- ERP Loc Table
    start_time := NOW();
    RAISE NOTICE '>> Truncating Table: bronze.erp_loc_a101';
    TRUNCATE TABLE bronze.erp_loc_a101;

    RAISE NOTICE '>> Inserting Data Into: bronze.erp_loc_a101';
    INSERT INTO bronze.erp_loc_a101
    SELECT * FROM bronze.erp_loc_a101;

    end_time := NOW();
    RAISE NOTICE '>> Load Duration (ERP Loc): % seconds', EXTRACT(EPOCH FROM (end_time - start_time));

    -- ERP PX Table
    start_time := NOW();
    RAISE NOTICE '>> Truncating Table: bronze.erp_px_cat_g1v2';
    TRUNCATE TABLE bronze.erp_px_cat_g1v2;

    RAISE NOTICE '>> Inserting Data Into:  bronze.erp_px_cat_g1v2';
    INSERT INTO  bronze.erp_px_cat_g1v2
    SELECT * FROM bronze.erp_px_cat_g1v2;

    end_time := NOW();
    RAISE NOTICE '>> Load Duration (ERP PX): % seconds', EXTRACT(EPOCH FROM (end_time - start_time));

    -- End Process
    batch_end_time := NOW();
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Bronze Layer Data Load Completed Successfully at %', batch_end_time;
    RAISE NOTICE 'Total Duration: % seconds', EXTRACT(EPOCH FROM (batch_end_time - batch_start_time));
    RAISE NOTICE '========================================';

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'ERROR OCCURRED DURING BRONZE LAYER DATA LOAD!';
    RAISE NOTICE 'Error Message: %', SQLERRM;
    RAISE NOTICE 'Error Code: %', SQLSTATE;
    RAISE NOTICE '========================================';
END;
$$;

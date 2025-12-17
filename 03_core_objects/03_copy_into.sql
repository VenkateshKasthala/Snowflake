
-- Setup: warehouse, db, schema, table, and file format

USE WAREHOUSE WH_TRAINING;
USE DATABASE PROD_ANALYTICS;
USE SCHEMA STAGE;

CREATE OR REPLACE TABLE SALES_RAW (
  ID        NUMBER,
  PRODUCT   STRING,
  PRICE     NUMBER,
  STORE_ID  NUMBER,
  QTY       NUMBER
);

CREATE OR REPLACE FILE FORMAT FF_SALES_CSV
  TYPE = CSV
  SKIP_HEADER = 1
  FIELD_DELIMITER = ','
  FIELD_OPTIONALLY_ENCLOSED_BY = '"';

-- Assume there are CSV files in @STG_S3_SALES like sales_*.csv

-- 1. COPY with default behavior (ON_ERROR = ABORT_STATEMENT)

-- Any bad row stops the load; nothing is committed.
COPY INTO SALES_RAW
FROM @STG_S3_SALES
FILE_FORMAT = (FORMAT_NAME = FF_SALES_CSV)
PATTERN = '.*\\.csv';  -- default ON_ERROR = ABORT_STATEMENT

-- 2. COPY with ON_ERROR = CONTINUE (skip bad rows)

COPY INTO SALES_RAW
FROM @STG_S3_SALES
FILE_FORMAT = (FORMAT_NAME = FF_SALES_CSV)
PATTERN = '.*\\.csv'
ON_ERROR = CONTINUE;

-- After this you can inspect rejected rows later using VALIDATE().
SELECT * FROM 
         TABLE(VALIDATE(TABLE_NAME => 'SALES_RAW', JOB_ID => '_last'));

-- 3. COPY with ON_ERROR = SKIP_FILE
--    (skip entire files that have errors)

COPY INTO SALES_RAW
FROM @STG_S3_SALES
FILE_FORMAT = (FORMAT_NAME = FF_SALES_CSV)
PATTERN = '.*\\.csv'
ON_ERROR = SKIP_FILE;

-- Only completely clean files are loaded; files with any error are ignored.

-- 4. VALIDATION_MODE = RETURN_ERRORS (dry run)
--    No data is loaded; only errors are returned.

COPY INTO SALES_RAW
FROM @STG_S3_SALES
FILE_FORMAT = (FORMAT_NAME = FF_SALES_CSV)
PATTERN = '.*\\.csv'
VALIDATION_MODE = RETURN_ERRORS;

-- Use this first to debug format/data problems without touching the table.



-- 5. VALIDATION_MODE = RETURN_10_ROWS (preview)
--    No data is loaded; returns up to 10 rows that WOULD be loaded.
COPY INTO SALES_RAW
FROM @STG_S3_SALES
FILE_FORMAT = (FORMAT_NAME = FF_SALES_CSV)
PATTERN = '.*\\.csv'
VALIDATION_MODE = RETURN_10_ROWS;

-- If there are parsing errors before 10 rows, those error rows are returned.


-- 6. VALIDATION_MODE = RETURN_ALL_ERRORS (full error list)
--    No data is loaded; all error rows for these files are returned.

COPY INTO SALES_RAW
FROM @STG_S3_SALES
FILE_FORMAT = (FORMAT_NAME = FF_SALES_CSV)
PATTERN = '.*\\.csv'
VALIDATION_MODE = RETURN_ALL_ERRORS;

-- Use when you want to gather all bad rows across files and fix them in bulk.


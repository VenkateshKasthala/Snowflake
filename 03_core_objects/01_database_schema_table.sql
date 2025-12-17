
-- Create a permanent database for production data
CREATE OR REPLACE DATABASE PROD_ANALYTICS
  COMMENT = 'Production analytics database';

-- Create a transient database for staging / scratch work
CREATE OR REPLACE TRANSIENT DATABASE STAGE_RAW
  COMMENT = 'Transient database for raw ingested data';

-- List databases visible to the current role
SHOW DATABASES;

-- Describe a specific database
DESC DATABASE PROD_ANALYTICS;

-- Set current database in the session
USE DATABASE PROD_ANALYTICS;

-- Drop a database (be careful!)
DROP DATABASE IF EXISTS STAGE_RAW;






-- Create schemas in a database
USE DATABASE PROD_ANALYTICS;

CREATE OR REPLACE SCHEMA SALES
  COMMENT = 'Sales subject area';

CREATE OR REPLACE TRANSIENT SCHEMA STAGE
  COMMENT = 'Landing / staging area for raw data';

-- List schemas in the current database
SHOW SCHEMAS;

-- Describe a specific schema
DESC SCHEMA SALES;

-- Set current database and schema for the session
USE DATABASE PROD_ANALYTICS;
USE SCHEMA SALES;

-- Combined form
USE SCHEMA PROD_ANALYTICS.SALES;

-- Drop a schema (drops contained objects!)
DROP SCHEMA IF EXISTS STAGE;




-- In the SALES schema, create a customers table
USE DATABASE PROD_ANALYTICS;
USE SCHEMA SALES;

CREATE OR REPLACE TABLE CUSTOMERS (
  CUSTOMER_ID   NUMBER,
  CUSTOMER_NAME STRING,
  EMAIL         STRING,
  CITY          STRING,
  CREATED_AT    TIMESTAMP_NTZ
);


CREATE OR REPLACE TRANSIENT TABLE CUSTOMERS_RAW (
  CUSTOMER_ID   STRING,
  CUSTOMER_NAME STRING,
  EMAIL         STRING,
  CITY          STRING,
  CREATED_AT    STRING
);

-- List tables in the current schema
SHOW TABLES;

-- Describe a specific table
DESC TABLE SALES.CUSTOMERS;

-- Query data
SELECT * FROM SALES.CUSTOMERS LIMIT 10;

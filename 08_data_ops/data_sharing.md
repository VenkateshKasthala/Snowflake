# Data Sharing

Data Sharing in Snowflake enables secure, read-only access to data across accounts without copying or moving data, using Snowflake's marketplace and secure shares.​

## 1. Core Concepts

Data sharing works through Secure Data Shares - logical views of your data that providers publish and consumers query directly from your storage. Key principles:​

#### *Zero-copy*: Consumers see your live data; no duplication.

#### *Read-only*: Consumers cannot modify provider data.

#### *Cross-account/region*: Share data globally across Snowflake accounts.

#### *Granular security*: Share specific tables/views, not entire databases.​

Two main sharing patterns exist: direct account-to-account shares and Snowflake Marketplace listings.​

2. Provider Workflow (Publishing Data)
Step 1: Create a Share
sql
-- Create a secure share object
CREATE SHARE sales_data_share;

-- Add objects to share (tables, secure views, secure UDFs)
GRANT SELECT ON TABLE sales.transactions TO SHARE sales_data_share;
GRANT SELECT ON VIEW sales.customer_summary TO SHARE sales_data_share;
Step 2: Add Consumer Accounts
sql
-- Add specific Snowflake accounts as consumers
ALTER SHARE sales_data_share ADD ACCOUNTS = 'ABC12345';  -- Consumer account locator

-- List current consumers
SHOW GRANTS TO SHARE sales_data_share;
Step 3: Monitor and Manage
sql
-- View share usage
SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.SHARE_USAGE_HISTORY 
WHERE share_name = 'SALES_DATA_SHARE';

-- Revoke access
ALTER SHARE sales_data_share REMOVE ACCOUNTS = 'ABC12345';
3. Consumer Workflow (Accessing Shared Data)
Step 1: Create Database from Share
sql
-- Consumer runs this in their account
CREATE DATABASE sales_shared_db 
FROM SHARE <provider_account>.sales_data_share;

-- List available shares from providers
SHOW DATABASES LIKE '%SHARE%';
Step 2: Query Shared Data
sql
-- Query shared tables/views normally
USE DATABASE sales_shared_db;
SELECT * FROM transactions WHERE sale_date >= '2025-01-01';

-- Shared data appears as regular tables to consumer
DESC TABLE transactions;  -- Shows structure, not underlying provider details
4. Secure Views for Granular Control
Most shares use secure views to limit column access and add row-level security:

sql
-- Provider creates secure view (hides from SHOW VIEW)
CREATE SECURE VIEW sales.customer_summary AS
SELECT 
  customer_id,
  SUM(amount) as total_sales,
  COUNT(*) as order_count
FROM sales.transactions
WHERE customer_tier = 'GOLD'  -- Row filter
GROUP BY customer_id;

-- Only share the secure view, not raw table
GRANT SELECT ON VIEW sales.customer_summary TO SHARE sales_data_share;
Secure views prevent consumers from seeing underlying table structure or bypassing filters.​

5. Snowflake Marketplace (Public Sharing)
For broader distribution:

sql
-- Provider publishes to Marketplace
CREATE LISTING my_sales_listing
  IN MARKETPLACEPLACE 
  FOR SHARE sales_data_share
  COMMENT = 'Cleaned sales data for partners';

-- Consumer browses and subscribes via UI or:
CREATE DATABASE marketplace_sales 
FROM LISTING '<provider>.my_sales_listing';
Listings support free, standard, and premium pricing models.​

6. Key Limitations & Best Practices
Feature	Direct Share	Marketplace
Cross-region	Yes	Yes
Secure UDFs	Yes	Limited
Materialized views	No	No
Cost to provider	Storage only	Storage + listing fees
Best practices:​

Always use secure views instead of raw tables.

Implement row access policies for multi-tenant data.

Monitor usage with SHARE_USAGE_HISTORY.

Use reader accounts for high-volume sharing (separate compute).

7. Complete Example File Structure
Your first data_ops file could be:

text
sql/data_ops/
├── 01_data_sharing_complete.sql     # Full provider + consumer workflow
├── 02_secure_views_rls.sql          # Secure views + row access policies
└── 03_marketplace_demo.sql          # Marketplace listing simulation
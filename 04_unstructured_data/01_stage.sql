
-- JSON + VARIANT END‑TO‑END
USE WAREHOUSE WH_TRAINING;
USE DATABASE OUR_FIRST_DB;

-- 0. Setup: stage + file format

CREATE OR REPLACE STAGE EXT_STAGE_JSON_ORDERS
  URL = 's3://company-raw/orders-json/';

CREATE OR REPLACE FILE FORMAT FF_JSON_GENERIC
  TYPE = JSON; 

-- 1. Raw table: store full JSON in VARIANT
CREATE OR REPLACE TABLE ORDERS_RAW_JSON (
  RAW VARIANT,
  LOAD_TS TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

COPY INTO ORDERS_RAW_JSON (RAW)
FROM @EXT_STAGE_JSON_ORDERS
FILE_FORMAT = (FORMAT_NAME = FF_JSON_GENERIC)
ON_ERROR = CONTINUE;

-- Inspect raw data
SELECT * FROM ORDERS_RAW_JSON LIMIT 5;

-- 2. Basic querying from VARIANT
--    (top‑level fields, simple casting)

-- Example fields: order_id, customer_id, status, created_at
SELECT
  RAW:order_id::NUMBER          AS order_id,
  RAW:customer_id::NUMBER       AS customer_id,
  RAW:status::STRING            AS status,
  RAW:created_at::TIMESTAMP_NTZ AS created_at
FROM ORDERS_RAW_JSON;

-- Use aliases and casts for reuse in views, joins, filters
SELECT *
FROM (
  SELECT
    RAW:order_id::NUMBER          AS order_id,
    RAW:customer.id::NUMBER       AS customer_id,
    RAW:customer.name::STRING     AS customer_name,
    RAW:created_at::TIMESTAMP_NTZ AS created_at
  FROM ORDERS_RAW_JSON
)
WHERE customer_name IS NOT NULL;

-- 3. Nested objects inside VARIANT

-- View entire nested object
SELECT RAW:payment AS payment_object
FROM ORDERS_RAW_JSON;

-- Extract nested fields
SELECT
  RAW:order_id::NUMBER              AS order_id,
  RAW:payment.method::STRING        AS payment_method,
  RAW:payment.amount::NUMBER        AS payment_amount,
  RAW:payment.currency::STRING      AS payment_currency
FROM ORDERS_RAW_JSON;

-- Chained nesting works for any depth
-- RAW:level1.level2.level3...

-- 4. Arrays and ARRAY_SIZE

-- Assume RAW:items is an array of line items
SELECT RAW:items AS items_array
FROM ORDERS_RAW_JSON
LIMIT 5;

-- Size of the array
SELECT
  RAW:order_id::NUMBER                    AS order_id,
  ARRAY_SIZE(RAW:items)                   AS item_count
FROM ORDERS_RAW_JSON;

-- Access the first element directly
SELECT
  RAW:order_id::NUMBER                    AS order_id,
  RAW:items[0]                            AS first_item,
  RAW:items[0].product::STRING            AS first_product,
  RAW:items[0].qty::NUMBER                AS first_qty
FROM ORDERS_RAW_JSON;

-- 5. FLATTEN: explode array into rows

-- Basic FLATTEN of RAW:items
SELECT
  RAW:order_id::NUMBER        AS order_id,
  f.index                     AS item_index,
  f.value                     AS item_variant,
  f.value:product::STRING     AS product,
  f.value:qty::NUMBER         AS qty,
  f.value:price::NUMBER       AS price
FROM ORDERS_RAW_JSON,
     TABLE(FLATTEN(INPUT => RAW:items)) AS f
ORDER BY order_id, item_index;

-- Notes:
--  - f.value is a VARIANT representing each item object
--  - f.index is the array position (0‑based)
--  - FLATTEN requires VARIANT/OBJECT/ARRAY input.

-- 6. OUTER / PATH / RECURSIVE options (overview examples)

-- OUTER => TRUE : even if array is empty / null, keep one row
SELECT
  RAW:order_id::NUMBER AS order_id,
  f.index,
  f.value
FROM ORDERS_RAW_JSON,
     TABLE(
       FLATTEN(
         INPUT => RAW:items,
         OUTER => TRUE
       )
     ) AS f;

-- PATH => 'some.path' : flatten a nested array deeper in the doc
-- Example if RAW:details.lines is an array:
-- TABLE(FLATTEN(INPUT => RAW, PATH => 'details.lines')) f;

-- RECURSIVE => TRUE : walk all sub‑arrays/objects
-- TABLE(FLATTEN(INPUT => RAW, RECURSIVE => TRUE)) f;

-- 7. Building a curated relational table from JSON
-- 7.1 Header-level table (one row per order)
CREATE OR REPLACE TABLE ORDERS_CURATED (
  ORDER_ID        NUMBER,
  CUSTOMER_ID     NUMBER,
  CUSTOMER_NAME   STRING,
  STATUS          STRING,
  CREATED_AT      TIMESTAMP_NTZ,
  PAYMENT_METHOD  STRING,
  PAYMENT_AMOUNT  NUMBER,
  PAYMENT_CURRENCY STRING
);

INSERT OVERWRITE INTO ORDERS_CURATED
SELECT
  RAW:order_id::NUMBER              AS order_id,
  RAW:customer.id::NUMBER           AS customer_id,
  RAW:customer.name::STRING         AS customer_name,
  RAW:status::STRING                AS status,
  RAW:created_at::TIMESTAMP_NTZ     AS created_at,
  RAW:payment.method::STRING        AS payment_method,
  RAW:payment.amount::NUMBER        AS payment_amount,
  RAW:payment.currency::STRING      AS payment_currency
FROM ORDERS_RAW_JSON;

SELECT * FROM ORDERS_CURATED LIMIT 20;

-- 7.2 Line‑item table (one row per order line)
CREATE OR REPLACE TABLE ORDER_ITEMS_CURATED (
  ORDER_ID   NUMBER,
  LINE_NO    NUMBER,
  PRODUCT    STRING,
  QTY        NUMBER,
  PRICE      NUMBER
);

INSERT OVERWRITE INTO ORDER_ITEMS_CURATED
SELECT
  RAW:order_id::NUMBER        AS order_id,
  f.index + 1                 AS line_no,
  f.value:product::STRING     AS product,
  f.value:qty::NUMBER         AS qty,
  f.value:price::NUMBER       AS price
FROM ORDERS_RAW_JSON,
     TABLE(FLATTEN(INPUT => RAW:items)) AS f;

SELECT * FROM ORDER_ITEMS_CURATED
ORDER BY ORDER_ID, LINE_NO
LIMIT 50;

-- 8. Direct inserts using PARSE_JSON / TO_VARIANT (ad‑hoc)
CREATE OR REPLACE TABLE DEMO_VARIANT_INSERT (V VARIANT);

INSERT INTO DEMO_VARIANT_INSERT (V)
SELECT PARSE_JSON('{"a":1,"b":[77,88]}'); 

SELECT
  V:a::NUMBER          AS a,
  f.index              AS idx,
  f.value::NUMBER      AS b_element
FROM DEMO_VARIANT_INSERT,
     TABLE(FLATTEN(INPUT => V:b)) AS f;


USE DATABASE OUR_FIRST_DB;
USE SCHEMA PUBLIC;


CREATE OR REPLACE TABLE TT_DEMO (
  ID      NUMBER,
  VALUE   STRING
)
DATA_RETENTION_TIME_IN_DAYS = 3;  

INSERT INTO TT_DEMO VALUES (1, 'v1'), (2, 'v1');
UPDATE TT_DEMO SET VALUE = 'v2' WHERE ID = 1;
DELETE FROM TT_DEMO WHERE ID = 2;

SELECT * FROM TT_DEMO ORDER BY ID;


--  AT TIMESTAMP – state *at* that exact time
SELECT
  *
FROM TT_DEMO
AT (TIMESTAMP => '2025-12-18 16:10:00'::timestamp_ntz)
ORDER BY ID;

--  BEFORE TIMESTAMP – state *just before* that time
SELECT
  *
FROM TT_DEMO
BEFORE (TIMESTAMP => '2025-12-18 16:10:00'::timestamp_ntz)
ORDER BY ID;

-- Replace the timestamp above with a real time between your DML steps.

-- 
-- 2. Time Travel using OFFSET (relative to now)
-
-- Syntax:
--   AT (OFFSET => -<seconds>)
--   BEFORE (OFFSET => -<seconds>)
-- OFFSET is in seconds; negative = "ago". [web:305]

-- Example: 1 hour ago (3600 seconds)
SELECT
  *
FROM TT_DEMO
AT (OFFSET => -3600)   -- 1 hour ago
ORDER BY ID;

-- Example: 10 minutes ago
SELECT
  *
FROM TT_DEMO
BEFORE (OFFSET => -600)  -- 600 seconds = 10 minutes
ORDER BY ID;

-
-- Time Travel using STATEMENT (query id)
-- 
-- Syntax:
--   AT (STATEMENT => '<query_id>')
--   BEFORE (STATEMENT => '<query_id>')
--
-- This lets you see data as of or just before a specific DML
-- statement (INSERT / UPDATE / DELETE / MERGE).

-- 3.1 Find a relevant statement in query history
--     (Run this and grab a QUERY_ID for an UPDATE or DELETE.)

SELECT
  QUERY_ID,
  START_TIME,
  QUERY_TEXT
FROM TABLE(
  INFORMATION_SCHEMA.QUERY_HISTORY(
    RESULT_LIMIT => 20
  )
)
WHERE QUERY_TEXT ILIKE '%TT_DEMO%'
ORDER BY START_TIME DESC;

-- Suppose you copy a QUERY_ID from above, e.g.:
--   '01b1f32a-0601-9a12-0000-437b01be0a12'
-- Replace the placeholder below with your real id.

SET my_query_id = '01b1f32a-0601-9a12-0000-437b01be0a12';

-- AT STATEMENT – table *after* that statement completed
SELECT
  *
FROM TT_DEMO
AT (STATEMENT => $my_query_id)
ORDER BY ID;

--  BEFORE STATEMENT – table *just before* that statement ran
SELECT
  *
FROM TT_DEMO
BEFORE (STATEMENT => $my_query_id)
ORDER BY ID;

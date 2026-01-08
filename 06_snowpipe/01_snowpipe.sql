
-- Target table and file format


CREATE OR REPLACE TABLE EVENTS_RAW (
  RAW VARIANT,
  LOAD_TS TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE FILE FORMAT FF_EVENTS_JSON
  TYPE = JSON;

-- External stage for S3 bucket
-- 
-- Assume:
--   - S3 bucket: s3://company-events/raw/
--   - STORAGE_INTEGRATION INT_AWS_EVENTS is already created
--     and grants Snowflake access to the bucket.

CREATE OR REPLACE STAGE EXT_STAGE_EVENTS
  URL = 's3://company-events/raw/'
  STORAGE_INTEGRATION = INT_AWS_EVENTS
  FILE_FORMAT = (FORMAT_NAME = FF_EVENTS_JSON)
  COMMENT = 'External stage for raw JSON event files';

-- Optional: check that Snowflake can see files
LIST @EXT_STAGE_EVENTS;

-- Pipe definition (Snowpipe)
-- 
-- This defines *how* files from the stage are loaded into EVENTS_RAW.
-- Snowpipe uses this COPY INTO command when it ingests new files.
-- For auto-ingest, you will later connect this pipe to S3 notifications
-- (SNS/SQS) via the cloud console / Snowflake UI. 

CREATE OR REPLACE PIPE PIPE_EVENTS_RAW
  AUTO_INGEST = TRUE
AS
COPY INTO EVENTS_RAW (RAW)
FROM @EXT_STAGE_EVENTS
FILE_FORMAT = (FORMAT_NAME = FF_EVENTS_JSON)
ON_ERROR = CONTINUE;

-- Notes:
-- - AUTO_INGEST = TRUE tells Snowflake this pipe will be driven by cloud notifications (S3 event -> SNS/SQS -> Snowpipe).


-- Managing the pipe

-- Show all pipes available to the current role
SHOW PIPES;

-- Inspect details of this pipe (stage, copy statement, auto_ingest)
DESC PIPE PIPE_EVENTS_RAW;

-- Pause / resume ingestion if needed
ALTER PIPE PIPE_EVENTS_RAW SET PIPE_EXECUTION_PAUSED = TRUE;   -- pause
ALTER PIPE PIPE_EVENTS_RAW SET PIPE_EXECUTION_PAUSED = FALSE;  -- resume

==
-- Manual trigger (if not using auto-ingest)
-- If AUTO_INGEST = FALSE, you can trigger Snowpipe via:
--   - Snowflake REST API / client libraries (preferred in real setups), or
--   - CALL SYSTEM$PIPE_STATUS, SYSTEM$PIPE_FORCE_RESUME, etc.
-- Here we only show SQL-side pieces; REST calls are done from outside. [web:280][web:283]

-- Example pattern for checking status
SELECT SYSTEM$PIPE_STATUS('PIPE_EVENTS_RAW');


-- Monitoring load history
-- Check which files Snowpipe has loaded for a table

SELECT *
FROM TABLE(
  INFORMATION_SCHEMA.LOAD_HISTORY(
    TABLE_NAME => 'EVENTS_RAW',
    START_TIME => DATEADD('hour', -24, CURRENT_TIMESTAMP())
  )
)
ORDER BY LAST_LOAD_TIME DESC;

-- Or use COPY_HISTORY for the stage

SELECT *
FROM TABLE(
  INFORMATION_SCHEMA.COPY_HISTORY(
    TABLE_NAME => 'EVENTS_RAW',
    START_TIME => DATEADD('hour', -24, CURRENT_TIMESTAMP())
  )
)
ORDER BY START_TIME DESC;

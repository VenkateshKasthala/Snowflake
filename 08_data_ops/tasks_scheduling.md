# Tasks

Tasks = Snowflake's "set it and forget it" cron jobs - automated SQL that runs on a schedule (every minute, daily, weekly) without babysitting.

No more manual ETL scripts, Airflow DAGs, or cron jobs on EC2
Snowflake handles scheduling, retries, monitoring, ALL serverless.

### Core Architecture

┌─────────────────┐    ┌──────────────────┌
│   Task Tree     │    │ Snowflake        │
│ ┌─────────────┐ │    │ Serverless       │
│ │ Root Task   │◄──┐ │ Compute          │
│ └─────────────┘ │  │ ├──────────────────┤
│ ┌─────────────┐ │  └►│ Schedules +      │
│ │ Child Task  │◄──┘  │ Executes SQL     │
│ └─────────────┘ │    │ Retries + Logs   │
└─────────────────┘    └──────────────────┘
Key: Fully serverless - no VMs, no Kubernetes, no infrastructure management.


## 1. Root Tasks (Independent)

The "standalone cron job"
```
CREATE TASK daily_cleanup
  WAREHOUSE = my_wh
  SCHEDULE = 'USING CRON 0 2 * * * UTC'  -- 2 AM daily UTC
AS 
  DELETE FROM logs WHERE created_date < DATEADD(DAY, -30, CURRENT_DATE());
```

## 2. Child Tasks (Task Trees/Chains)

"after task X finishes, run Y"
```
-- Root task
CREATE TASK extract_data
  WAREHOUSE = xs_wh
  SCHEDULE = '5 MINUTE'
AS CALL sp_extract_data();

-- Child depends on parent
CREATE TASK transform_data
  WAREHOUSE = m_wh
  AFTER extract_data
AS CALL sp_transform_data();
```

## 3. Task DAGs (Complex Workflows)

extract → (transform1 + transform2) → load → notify

### Scheduling Syntax - Complete Reference

CRON Syntax (Most Common)

Format: "minute hour day_of_month month day_of_week"

```Examples:
        '0 2 * * * UTC'        → 2:00 AM daily
        '0 0 * * 1 UTC'        → Midnight every Monday
        '0 9-17 * * 1-5 UTC'   → 9AM-5PM weekdays
        '0 0 1 * * UTC'        → First day of every month
```

Interval Syntax (Simpler)
SCHEDULE = '1 MINUTE'     -- Every minute
SCHEDULE = '5 MINUTE'     -- Every 5 minutes  
SCHEDULE = '1 HOUR'       -- Hourly
SCHEDULE = '1 DAY'        -- Daily

### Complete Task Creation Syntax
```
CREATE [OR REPLACE] TASK task_name
  WAREHOUSE = warehouse_name
  SCHEDULE = 'USING CRON 0 2 * * * UTC'  -- or '1 HOUR'
  [AFTER task1, task2]                  -- Dependencies
  [WHEN condition]                       -- Conditional execution
  [ERROR_INTEGRATION = integration_name] -- Error notifications
  [ALLOW_OVERLAPPING_EXECUTIONS = TRUE]  -- Overlap allowed
  [SESSION_PARAMETERS = (param=value)]   -- Session settings
AS 
  SQL_statement_or_stored_procedure_call;
```
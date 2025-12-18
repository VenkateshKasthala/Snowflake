# Compute Warehouses

A virtual warehouse in Snowflake is a named, MPP compute cluster that provides the CPU, memory, and temporary storage required to execute queries, load data, and perform DML.

It does not store data itself; instead, it reads and writes data in the centralized storage layer and can be started, stopped, or resized independently.

## Key Characteristics

### Compute only, no data stored

- Data lives in Snowflake’s storage layer (databases, schemas, tables).

- The warehouse is purely a compute engine that processes SQL against that data.

### Independent, isolated clusters

- Each warehouse runs independently; restarting or resizing one does not affect others.

- Different teams (ETL, BI, data science) can have their own warehouses on the same data.

### Elastic and scalable

- Warehouse sizes (XS, S, M, L, XL, etc.) control how many compute resources are used.

- Size can be changed with a simple ALTER WAREHOUSE command; running queries will use the new size once the change is applied.

### Start/stop and auto‑suspend

- A warehouse can be resumed when work is needed and suspended when idle.

- AUTO_SUSPEND and AUTO_RESUME automatically stop and restart warehouses based on activity, helping control cost.

### Single‑cluster vs multi‑cluster

- Single‑cluster: one cluster handles all queries for that warehouse.

- Multi‑cluster: warehouse can automatically add or remove clusters between MIN_CLUSTER_COUNT and MAX_CLUSTER_COUNT to handle concurrency.

### Cost model

- Compute cost is based on warehouse size and time running (credits per hour).
- Suspending warehouses when not in use is the main way to save money.

## Warehouse properties

WAREHOUSE_SIZE – XS / S / M / L / XL / etc.

AUTO_SUSPEND – seconds of inactivity before the warehouse stops automatically.

AUTO_RESUME – whether a query automatically starts the warehouse if it is suspended.

MIN_CLUSTER_COUNT / MAX_CLUSTER_COUNT – min and max clusters for multi‑cluster mode.

SCALING_POLICY – e.g., STANDARD  or ECONOMY.

INITIALLY_SUSPENDED – whether the warehouse starts in a suspended state when created.

COMMENT – description of what the warehouse is used for (good for governance).

# Snowflake Architecture, Storage, Compute, and Cost Model

## Purpose

This document consolidates and clarifies key Snowflake concepts discussed: storage vs compute, micro-partitions, metadata, RAW/SILVER/GOLD layering, transformations, time travel, and **what actually costs money**.

---

## 1. High-Level Architecture

Snowflake uses a **multi-cluster shared data architecture** with clear separation of concerns:

* **Storage Layer**: Snowflake-managed cloud object storage (AWS S3 / Azure Blob / GCS)
* **Compute Layer**: Virtual Warehouses (query execution only)
* **Metadata & Services Layer**: Optimization, pruning, statistics, transactions

> **Key Principle:** You pay for **compute** and **storage**. Metadata operations are not billed separately.

---

## 2. Storage Layer (Where Data Lives)

### Physical Storage

* All data is stored in **Snowflake-managed cloud object storage**
* Stored in Snowflake’s **proprietary columnar format**
* Organized into **immutable micro-partitions** (typically 50–500 MB compressed)

### Logical Organization

RAW, SILVER, and GOLD are **logical layers**, not physical locations.

They are implemented using:

* Databases
* Schemas
* Tables / Views

**Example:**

```
DB_RAW.SCHEMA_RAW.orders
DB_SILVER.SCHEMA_SILVER.orders_clean
DB_GOLD.SCHEMA_GOLD.orders_metrics
```

All of these tables:

* Live in the **same Snowflake storage layer**
* Have independent micro-partitions
* Are differentiated by metadata

---

## 3. Compute Layer (Virtual Warehouses)

### What a Warehouse Is

* Compute-only (CPU + memory)
* Executes SQL queries
* Does **not** store data or metadata

### What Warehouses Do

* Load data (COPY INTO)
* Transform data (SELECT, JOIN, MERGE)
* Serve BI queries

### Best Practice

Use different warehouses for workload isolation:

* `WH_INGEST`
* `WH_TRANSFORM`
* `WH_BI`

All warehouses can access **any table**.

---

## 4. Micro-Partitions (Core Concept)

### What They Are

* Immutable columnar chunks of data
* Automatically created and managed by Snowflake

### Metadata Stored Per Micro-Partition

* Min / Max values per column
* Row counts
* File statistics

### Why They Matter

* Enable **automatic partition pruning**
* No indexes required
* No tuning required

> Creating micro-partitions does **not** incur a special charge. Only storage size and compute time matter.

---

## 5. Metadata (What It Is and Cost)

### Metadata Includes

* Partition statistics
* Table schemas
* Query plans
* Transaction state

### Cost

* **No direct cost** for metadata creation or updates
* Metadata is maintained automatically

> **Important:** Metadata updates themselves are free. Costs come from compute used to rewrite data.

---

## 6. RAW → SILVER → GOLD (Medallion Architecture)

### RAW Layer

* Minimal transformation
* Mirrors source data
* Used for replay, audits, and reprocessing

### SILVER Layer

* Cleaned, standardized
* Data quality checks applied
* Conformed dimensions

### GOLD Layer

* Aggregated
* Business metrics
* BI-ready

### Physical Reality

* Each layer creates **new tables**
* Each table has **new micro-partitions**
* Old data remains intact

---

## 7. What Happens During Transformations

### Example: RAW → SILVER

```sql
CREATE TABLE silver AS
SELECT ... FROM raw;
```

### Internals

* Warehouse scans RAW micro-partitions
* Applies transformations
* Writes new micro-partitions for SILVER
* Updates metadata pointers

### Costs Incurred

* **Compute**: Yes (query execution)
* **Storage**: Yes (new data)
* **Metadata**: No charge

Same pattern applies to SILVER → GOLD.

---

## 8. Updates, Deletes, and MERGE (Immutability)

Snowflake does **not** update data in place.

When you run:

* UPDATE
* DELETE
* MERGE

Snowflake:

* Creates new micro-partitions
* Marks old ones as inactive
* Updates metadata

### Cost Impact

* **Compute**: Yes (rewrite)
* **Storage**: Temporarily higher
* **Metadata**: Free

---

## 9. Time Travel & Fail-safe

### Time Travel

* Retains historical versions (1–90 days)
* Enables querying past states

### Fail-safe

* 7 additional days after Time Travel
* For disaster recovery only

### Cost Impact

* **Storage increases** while old partitions are retained
* No extra compute unless queried

---

## 10. Cost Breakdown Summary

### What You Pay For

* **Compute**: Warehouses running queries
* **Storage**: Size of RAW + SILVER + GOLD + retained versions

### What You Do NOT Pay For

* Metadata operations
* Micro-partition management
* Index creation
* Query optimization

---

## 11. Example Cost Flow (10 GB Raw Data)

1. COPY INTO RAW

   * Compute: Yes
   * Storage: ~10 GB

2. RAW → SILVER

   * Compute: Yes
   * Storage: ~8–12 GB

3. SILVER → GOLD

   * Compute: Yes
   * Storage: ~1–5 GB

Total ongoing cost = **Storage of all layers** + **Compute per run**

---

## 12. Key Mental Models

* **Metadata is free**
* **Compute is the real cost**
* **Data rewrites drive cost**
* **RAW/SILVER/GOLD are logical layers**
* **Warehouses never store data**

---

## 13. Final Takeaway

Snowflake abstracts complexity by managing storage, metadata, and optimization automatically. Cost efficiency depends primarily on **how often you transform data and how long you retain it**, not on metadata or micro-partition mechanics.

> **Snowflake Cost = Compute (queries) + Storage (data & versions)**

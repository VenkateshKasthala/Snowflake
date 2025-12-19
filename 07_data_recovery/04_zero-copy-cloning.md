# ZERO-COPY CLONE

Zero-copy clone creates an instant, logical copy of a database/schema/table that shares the same storage as the source until either side is modified.​


Cloning is metadata-only: Snowflake just creates new metadata pointers to the same micro-partitions; no data blocks are physically copied at clone time.​

Source and clone become independent objects: later DML on either object writes new micro-partitions only for changed data, so extra storage is used only for differences.​

This makes cloning very fast and initially almost free in storage.​

## syntax (tables, schemas, databases)

Common patterns:​
```
-- Table clone (current state)
CREATE TABLE dev.my_table_clONE
CLONE prod.my_table;
```
```
-- Schema clone
CREATE SCHEMA dev_clone
CLONE prod;
```
```
-- Database clone
CREATE DATABASE analytics_clone
CLONE analytics;
```


With Time Travel, you can clone past versions:

```
-- As of timestamp
CREATE TABLE my_table_t1 CLONE prod.my_table
  AT (TIMESTAMP => '2025-12-18 16:10:00'::timestamp_ntz);
```
```
-- Before a specific statement
CREATE TABLE my_table_before_bad_update CLONE prod.my_table
  BEFORE (STATEMENT => '01b1f32a-0601-9a12-0000-437b01be0a12');
```

Clones inherit data, structure, and many properties from the source at that point in time.​

## How storage and costs work

At creation: clone and source share exact same micro‑partitions, so no extra storage beyond tiny metadata.​

After changes: new or updated rows in either object generate new micro‑partitions paid as extra storage, but only for changed data, not the full table.​

Pricing docs highlight: cloning itself is free; storage cost grows as clones and sources diverge over time.​

This is why cloning is ideal for dev/test, sandboxing, and point‑in‑time backups.

## What can be cloned

You can zero‑copy clone many object types:​​

Databases, schemas, tables (permanent, transient, temporary).

Views, materialized views (with rules), sequences, file formats.

Streams, tasks, pipes, stages (with some limitations and dependencies).

Some special objects (e.g., external integrations, network policies) are not clonable; always check docs for edge cases.​​

## Common patterns in real projects:​

Dev/QA environments: clone prod DB or schema into dev in seconds for testing without touching production.

Safe experiments: clone a large table, try new transformations or indexes, then drop the clone.

Backups with Time Travel: before risky changes, clone prod.schema to backup.schema_yyyymmdd using AT or BEFORE to freeze a snapshot.

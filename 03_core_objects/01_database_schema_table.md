# Databases, Schemas, and Tables

All data in Snowflake is organized in a logical hierarchy:

Account → Database → Schema → Table / View / Other objects.

Databases and schemas are purely logical containers (namespaces) for organizing data; they do not affect query performance and are mainly for structure, security, and governance.

## Database

A database in Snowflake is a top‑level logical container that groups one or more schemas.
Each database belongs to a single Snowflake account and is used to separate data domains or environments (for example, SALES, MARKETING, RAW, PROD).​

A database contains schemas, and each schema contains tables, views, and other objects.​
Databases can be PERMANENT (default, full Time Travel + Fail-safe) or TRANSIENT (reduced retention, cheaper, often for staging or scratch data).

## Schema

A schema is a logical grouping of database objects (tables, views, sequences, stages, etc.) within a single database.​
Together, database + schema form a namespace that uniquely identifies objects, for example PROD_ANALYTICS.SALES.CUSTOMERS.​

Every database contains at least two schemas by default: INFORMATION_SCHEMA (metadata views) and PUBLIC.​

Schemas are often used to separate environments or layers, such as RAW, STAGE, CURATED, MART, or to group objects by business domain.​

Schemas can also be PERMANENT or TRANSIENT; a transient schema tends to hold transient tables by default.

## Table

A table is a named, two‑dimensional structure (rows and columns) that physically stores data within a schema.​
In Snowflake, table data is stored as compressed, columnar micro‑partitions in the storage layer, but users interact with it using standard SQL.​

Table types (high level)
Permanent table (default): full Time Travel and Fail-safe; used for production data.​

Transient table: reduced data retention, no Fail-safe; used for staging/scratch data where long‑term recovery is less critical.​

Temporary table: lives only for the session; data is dropped when the session ends.

## Hierarchy

Account = entire Snowflake environment for your company.​

Database = big container for a domain or environment (PROD_ANALYTICS, FINANCE, SANDBOX).​

Schema = sub‑container inside a database for organizing related objects (RAW, STAGE, SALES, MARKETING).​

Table = actual rows of data, where queries read/write.

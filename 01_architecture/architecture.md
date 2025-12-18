# Snowflake

Snowflake is a fully managed, cloud‑native SaaS data platform that re‑architects the traditional data warehouse by cleanly separating centralized cloud storage, elastic compute (virtual warehouses), and a shared services/metadata layer, enabling scalable, high‑concurrency analytics and data applications at low operational overhead.

## Cloud‑native & SaaS

Runs only on AWS, Azure, and GCP; Snowflake owns and manages all infrastructure, patching, and tuning, so users just use SQL and pay for consumption.​

## Decoupled layers

Storage: compressed, columnar data in cloud object storage, shared by all workloads.​
Compute: independent virtual warehouses that you can scale, pause, and run in parallel on the same data.​
Services/metadata: cloud services layer handling security, metadata, optimization, transactions, and governance.​

## Workload focus

Designed for analytical workloads (BI, reporting, data science, ML) and large‑scale data sharing, not OLTP transaction systems.​

## Architecture

Snowflake’s architecture has three main layers: Storage, Compute, and Cloud Services.​

## 1. Storage layer (Database Storage)

Data is stored in cloud object storage (S3, Azure Blob, GCS) in a proprietary, compressed, columnar format.​

Tables are broken into immutable “micro‑partitions” (typically tens of MB each) with metadata about ranges, statistics, and clustering, which lets Snowflake skip irrelevant partitions during queries (data pruning).​

Storage is fully managed: replication, encryption at rest, and availability are handled by Snowflake; users see only logical objects (databases, schemas, tables).​

## 2. Compute layer (Virtual Warehouses / Query Processing)

Compute is provided by “virtual warehouses”: independent MPP clusters of compute nodes that read data from the storage layer and execute SQL.​

Each warehouse can be sized (XS to multi‑XL), scaled up/down, set to auto‑suspend and auto‑resume, and multiple warehouses can run concurrently on the same data without copying it.​

Warehouses can be configured as single‑cluster or multi‑cluster; multi‑cluster warehouses automatically start additional clusters under heavy load to maintain performance for concurrent users.​

## 3. Cloud Services layer (Metadata & Control Plane)

The cloud services layer manages authentication, authorization (RBAC), metadata, query parsing and optimization, transaction management, and result caching.​

It holds metadata about objects (schemas, tables, micro‑partitions, statistics), decides which warehouse executes each query, and coordinates access to data in storage, giving a single logical interface to users and tools.​

It also powers advanced features such as Time Travel, Fail-safe, data sharing, governance policies, and usage metering/billing.​

## How the three layers work together

When a query runs, the cloud services layer parses and optimizes it, consults metadata to identify relevant micro‑partitions in storage, and schedules the work on a chosen virtual warehouse.​

The virtual warehouse nodes read only the needed micro‑partitions from storage, process them in parallel, and return results; frequently accessed results can be cached at the compute and services layers to speed up repeat queries.​

Because storage is shared and compute is independent, multiple warehouses (for ETL, BI, data science, etc.) can work on the same data simultaneously without resource contention or data duplication.​

## Key architectural advantages

Separation of storage and compute: scale and pay for each independently; large storage with small compute or many compute clusters on the same data.​

Elastic, multi‑cluster MPP: automatically handle concurrency spikes by adding clusters while keeping queries fast.​

Managed, cloud‑native control plane: offloads infrastructure, tuning, and metadata management, enabling features like Time Travel, data sharing, and fine‑grained security without extra components.​

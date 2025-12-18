# Optimization

Snowflake already handles indexing, statistics, and micro‑partitioning automatically; you don’t create indexes or manual partitions.​

Tuning focuses on:

Right‑sizing and scaling warehouses.

Maximizing caching.

Minimizing data scanned via pruning & clustering.

Writing efficient queries and using features like materialized views or search optimization when needed.

## Dedicated warehouses per team/workload

You typically create separate warehouses for different teams or workloads (ETL, BI, data science, ad‑hoc) instead of one giant shared warehouse.​

Warehouses are isolated from each other. Each has its own compute resources, but they all access the same underlying data.

### Why this helps

Isolation of performance: if ETL jobs spike, they don’t slow down dashboards, because they run on another warehouse.​

Isolation of cost: you can track and control spend per warehouse/team using resource monitors and role‑based ownership.​

Tailored sizing: ETL warehouse might be Medium/Large and short‑lived; BI warehouse might be Small multi‑cluster for concurrency; data‑science warehouse might be occasionally Large.​

So first design choice: split warehouses by workload, then decide scale up vs. scale out per warehouse.

## Scaling

### Scale up(change size)

Scale up = increase the size of a single cluster (e.g., WAREHOUSE_SIZE = 'XSMALL' → 'LARGE').​

This gives more resources per query(more parallelism, more memory), which can reduce runtime for heavy transformations or large joins.

Scale up : for faster individual queries.

Example :

```ALTER WAREHOUSE WH_ETL SET WAREHOUSE_SIZE = 'LARGE';```

#### Why it’s appropriate for heavy queries

One query still runs on one cluster

A single query is not split across multiple clusters in a multi‑cluster warehouse; it runs entirely on just one of the clusters.​

So if the query itself is huge (big joins, large aggregations), giving that one cluster more resources (scale up) directly helps.

Memory‑ and CPU‑bound workloads:
Big joins, window functions, large aggregations can spill to disk when memory is insufficient; a larger warehouse reduces spilling and increases parallelism inside that cluster.​

##### Diminishing returns for concurrency

A very large warehouse helps multiple queries a bit, but they’re still all queuing on the same CPUs; it doesn’t multiply concurrency, it just makes each query individually faster.​

So: scale up when individual queries are slow or spilling, even when concurrency is low.

### Scaling out (multi‑cluster) for concurrency

Definition:

Scale out = make the warehouse multi‑cluster: same size per cluster, but MIN_CLUSTER_COUNT and MAX_CLUSTER_COUNT > 1.​

Snowflake adds clusters when many queries are queued and removes them when load drops.​

Example:

```
ALTER WAREHOUSE WH_BI
  SET MIN_CLUSTER_COUNT = 1,
      MAX_CLUSTER_COUNT = 4,
      SCALING_POLICY    = 'STANDARD';
```

### What scaling policy does

A multi‑cluster warehouse has MIN_CLUSTER_COUNT and MAX_CLUSTER_COUNT.

Scaling policy decides when to add a new cluster and when to shut one down.

It is not about size (XS/S/M) and it does not change a single cluster’s speed; it changes how quickly Snowflake reacts to load.

Two options:

STANDARD – performance‑first (minimize queue time).

ECONOMY – cost‑first (minimize extra clusters).

#### STANDARD policy (performance‑focused)

Goal: keep queries from waiting in the queue.

Behavior (conceptually):
When queries start queueing, Snowflake quickly starts another cluster, as long as you haven’t hit MAX_CLUSTER_COUNT.

The first extra cluster is started immediately when queueing is detected; further clusters can be added after short checks (roughly tens of seconds).

For shutdown, it checks load frequently (roughly every minute); if one cluster is clearly under‑utilized and the remaining clusters can handle the load, it is shut down after a few checks.

Effect:
New clusters appear quickly → more queries run in parallel → very low queue times.

Because clusters spin up earlier and shut down sooner only after a short stability check, you generally use more credits than Economy.

##### Use STANDARD when

You care more about speed than small cost differences.

Workload is time‑sensitive (peak‑hour dashboards, SLAs, live reporting).

Mnemonic: Standard = “Don’t let my users wait; I’m okay paying more.”

#### ECONOMY policy (cost‑focused)

Goal: keep clusters busy and fewer in number, even if that means some queueing.

Behavior (conceptually):
Snowflake keeps the existing cluster(s) as full as possible.

It starts a new cluster only if it predicts there will be enough sustained load to keep that new cluster busy for several minutes (roughly 6 minutes).

That means queries may sit in the queue for a while instead of immediately starting a new cluster.

For shutdown, it is more conservative: it waits longer and performs more checks before removing a cluster, to avoid thrashing.

Effect:
Fewer clusters overall → lower credits consumed.

Higher chance of queue/wait time compared to STANDARD, especially during spikes.

##### Use ECONOMY when

Workloads are cost‑sensitive and can tolerate some delay (overnight jobs, off‑peak reporting, internal tools).

You want the warehouse to run “hot,” prioritizing utilization over response time.

Mnemonic: Economy = “Save credits; some waiting is okay.”

#### Why it’s appropriate for high concurrency

##### Each query uses one cluster

If you have 3 clusters, Snowflake can run ~3× as many queries in parallel (roughly), because each cluster handles different queries.​

This reduces queueing/“queued” time, which is the main symptom of concurrency issues.

##### No benefit to a single query

A single query does not become faster in a multi‑cluster setting; it still runs on just one cluster, so its speed is determined by the warehouse size, not cluster count.​

##### Cost control for BI/dashboards

Dashboards generate many small/medium queries; scaling out lets many users hit the system at once without stepping on each other, while keeping each cluster reasonably sized (S/M).​

So: scale out when queries are individually okay but many users are waiting/queued.

### Why not “big warehouse for everything”?

#### “Can’t we handle high concurrency with a larger warehouse since it has more CPU/memory?”

A larger warehouse does increase total resources, but all queries share the same cluster; you still hit contention and queueing at some point.​

Multi‑cluster spreads queries across multiple independent clusters, so concurrency scales more linearly.​

#### “For heavy queries we scale up – can’t we distribute them to multiple clusters by scaling out?”

Snowflake does not split a single query across multiple clusters; scaling out only lets different queries run on different clusters.​

A single heavy query must fit into the memory/CPU of one cluster, which is why you scale up to give that cluster more capacity.

### Simple decision rule

For each warehouse / workload:

Queries are individually slow, high bytes scanned, spilling, long run time even when no queue → scale up a level (or tune SQL/clustering).​

Queries are okay individually, but users see queueing and concurrency warnings, especially on BI/reporting → scale out with MAX_CLUSTER_COUNT > 1.

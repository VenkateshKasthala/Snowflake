# Snowpipe

Snowpipe is Snowflake’s serverless, continuous data ingestion service that automatically loads new files from cloud storage (S3, Azure Blob, GCS) into tables as soon as they arrive.​

It is file‑based and micro‑batch oriented: as files land in an external/internal stage, Snowpipe picks them up, loads them, and makes the data available with latency typically in seconds to a few minutes.​

Snowpipe uses Snowflake‑managed compute, so you do not run or size a warehouse; you pay per GB ingested under a fixed credit‑per‑GB model.​

## Why Snowpipe?

Avoids manual or scheduled COPY INTO jobs by automatically loading files as soon as they arrive.

Serverless: no need to provision, resize, or manage a warehouse for ingestion.

Provides near real‑time availability of file‑based data with a simple credits‑per‑GB cost model.

Handles file tracking and duplicate protection, simplifying ingestion pipelines.


## Main components

### Stages

Data files are first placed in a stage (usually an external stage on S3/Blob/GCS, sometimes an internal stage).​

Snowpipe watches these stages (or is triggered for them) and loads files into a target table using a COPY INTO statement defined in a pipe.​

### Pipes

A pipe is a Snowflake object that encapsulates  the COPY INTO command plus metadata about files that have already been loaded.

Example:

```
CREATE OR REPLACE PIPE my_db.public.mypipe
  AUTO_INGEST = TRUE
AS
COPY INTO my_db.public.mytable
FROM @my_db.public.mystage
FILE_FORMAT = (TYPE = 'JSON');
The pipe keeps track of which files have been loaded and supports pause/resume control.​
```

### Auto‑ingest vs. REST API

AUTO_INGEST = TRUE: Snowpipe is triggered by cloud notifications (S3 → SNS/SQS, Azure Event Grid, GCS Pub/Sub) when new files land.​

AUTO_INGEST = FALSE: Snowpipe loads when you call the Snowpipe REST API or use tools/SDKs that call it (useful when you want explicit control).​

## Snowpipe load flow 

Files are written into an external stage bucket/path (for example s3://mybucket/path).​

A cloud notification or REST call tells Snowpipe that new files are ready.​

Snowpipe queues those file references and runs the COPY INTO from the pipe definition using Snowflake‑managed compute.​

Successfully loaded files are marked as loaded so they are not processed again; metadata is available in LOAD_HISTORY views.​

### Auto‑ingest configuration (conceptual)

Create an external stage pointing to the bucket/prefix.​

Configure S3 event notifications to publish object‑created events to SNS or SQS.​

In Snowflake, create a pipe with AUTO_INGEST = TRUE and link it to the notification ARN.​

When new files are added, SNS/SQS notifies Snowpipe, which immediately ingests the files into the table defined in the pipe.​

Azure and GCS follow a similar pattern using Event Grid or Pub/Sub.​

### Key characteristics and behavior

#### Latency

Snowpipe is near real‑time, not millisecond streaming: typical latency is seconds to a few minutes from file arrival to data availability.​

It is ideal when you can tolerate minute‑level delays but want to avoid batch scheduling complexity.​

#### Serverless & scaling

Snowflake automatically scales Snowpipe’s internal compute up and down based on ingestion volume; you do not size a warehouse.​

Pricing is based on a fixed credit per GB ingested, simplifying cost estimation (no per‑second warehouse billing).​

#### Idempotency and file tracking

Snowpipe tracks which files have been loaded; re‑submitting the same file will not lead to duplicate loads unless the file name or path changes.​

## Monitoring & history

#### Load history views

You can query INFORMATION_SCHEMA.LOAD_HISTORY or COPY_HISTORY to see which files were loaded, rows ingested, errors, and timestamps.​

This is useful for debugging ingestion issues and verifying that auto‑ingest is working as expected.​

#### Pipe status

SHOW PIPES and DESC PIPE mypipe show pipe definitions and whether execution is paused.​

You can pause or resume ingestion with:
```
ALTER PIPE mypipe SET PIPE_EXECUTION_PAUSED = TRUE;   -- pause
ALTER PIPE mypipe SET PIPE_EXECUTION_PAUSED = FALSE;  -- resume
```

### When to use Snowpipe vs. other options

#### Snowpipe (file‑based continuous ingest)

Best when data lands as files in cloud storage (logs, CDC extracts, IoT batches) and minute‑level latency is acceptable.​

Good for automated ingestion without maintaining warehouses or schedulers.​

#### Snowpipe Streaming (row‑level streaming)

Snowpipe Streaming ingests rows directly via APIs (or connectors like Kafka), bypassing files and stages, achieving lower latency and often lower cost for high‑throughput streams.​

It is better when you need near‑real‑time ingestion (sub‑second to seconds) and are willing to run a producer application.​

Traditional batch COPY
Use COPY INTO with a warehouse when:

You are fine with scheduled hourly/daily loads, or

You want tight control over transformation, warehouse choice, or cost timing.​

## Cost considerations & best practices

Cost model
Snowpipe charges are credits per GB ingested using Snowflake’s serverless compute, independent of any virtual warehouse.​

Lots of very small files can increase overhead; grouping them into reasonable sizes (for example tens or hundreds of MB) typically yields better efficiency.​

### Good practices

Aim for reasonable file sizes (not thousands of tiny files per minute) to avoid overhead per file.​

Use AUTO_INGEST when your cloud storage can emit events; use the REST API when you want to trigger ingestion explicitly or when events are not available.​

Monitor load history and costs regularly to ensure ingestion patterns (file size, frequency) are aligned with performance and budget.​

### Practical checklist for “using Snowpipe”

Data lands as files in S3/Blob/GCS and you want them loaded automatically with minute‑level latency.​

Create:
External stage.

File format.

Pipe with COPY INTO and optionally AUTO_INGEST = TRUE.​

Configure cloud notifications (SNS/SQS, Event Grid, Pub/Sub) if using auto‑ingest.​

Validate with:
SHOW PIPES, DESC PIPE, and LOAD_HISTORY / COPY_HISTORY.​
.​


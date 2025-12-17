# Stage

A stage is a named location where data files are stored before being loaded into Snowflake tables or after being unloaded. Stages can be internal (inside Snowflake) or external (pointing to cloud storage like S3, Azure Blob, GCS).



## Why we need stages
Stages are critical because Snowflake does not allow you to "insert" raw external files directly into a permanent table.
They provide several essential functions:
## 1. Security and Access Control
   ### Secure Credential Management:
   The stage object securely stores the sensitive credentials. By embedding these credentials into a named object (stage), you only have to manage them in one place.
   ### Decoupled Permissions:
   We grant the Snowflake database user the permission to use @stage object, but not direct access to the underlying cloud credentials.
## 2. High Performance Parallelism
   Snowflake is built on parallel processing(Virtual Warehouses). To achieve massive scale during loading, it must break down the files into chunks and assign them to different compute    notes simultaneously.
## 3. Data Control & Transformation
   Users can inspect, validate, and even transform data (e.g., reordering columns or casting types) using SQL before it ever touches a permanent table.
## 4. File Tracking and idempotency
   Stages decouple where files live from how snowflake loads them, giving a consistent interface(@stage) regardless of internal vs external location.
   
## Internal stages
Managed and stored entirely within Snowflake's storage infrastructure.
Use Case - Loading files from a local machine or temporary processing.

- User stage: @~ (one per user).

- Table stage: @table_name (one per table).

- Named internal stage: created with CREATE STAGE.​

## External stages

External stage (S3): An external stage is a Snowflake object that points to files stored in an external cloud location (for example, Amazon S3). It stores the S3 URL, credentials, and default file format, and is used by COPY INTO to load or unload data.

## File format

A reusable object that tells Snowflake how to interpret files (CSV, JSON, Parquet, etc.), what type it is, what seperator it uses, how headers are handled, and how to treat nulls, quotes etc.

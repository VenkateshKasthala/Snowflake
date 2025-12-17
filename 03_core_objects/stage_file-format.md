# Stage

A stage is a named location where data files are stored before being loaded into Snowflake tables or after being unloaded. Stages can be internal (inside Snowflake) or external (pointing to cloud storage like S3, Azure Blob, GCS).

## Internal stages

- User stage: @~ (one per user).

- Table stage: @table_name (one per table).

- Named internal stage: created with CREATE STAGE.​

## External stages

External stage (S3): An external stage is a Snowflake object that points to files stored in an external cloud location (for example, Amazon S3). It stores the S3 URL, credentials, and default file format, and is used by COPY INTO to load or unload data.

## File format

A reusable object that tells Snowflake how to interpret files (CSV, JSON, Parquet, etc.), including delimiters, header rows, compression, and other options.

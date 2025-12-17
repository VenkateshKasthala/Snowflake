# COPY INTO

COPY INTO is Snowflake’s main command for bulk loading data from stages (internal/external) into tables, and for unloading data from tables to stages.​

It uses a file format plus options (errors, validation, truncation, etc.) to control how files are parsed and how problems are handled.

## Basic syntax (load into table)

```COPY INTO <table_name>
   FROM <stage_or_query>
   FILE_FORMAT = (FORMAT_NAME = <file_format_name>)
   ON_ERROR = <option>
   VALIDATION_MODE = <option>;
```

## ON_ERROR options

ON_ERROR controls behavior for bad rows (type mismatch, too many columns, invalid date, etc.).​

### Options

#### ON_ERROR = ABORT_STATEMENT (default)

First error stops the entire load; no rows are committed.​
Use when data quality must be perfect.

#### ON_ERROR = CONTINUE

Bad rows are skipped, good rows are loaded; errors are recorded in load history / validation views.​
Use for “best effort” loads where you handle rejects later.

#### ON_ERROR = SKIP_FILE / SKIP_FILE_<n>

Skip whole files that have errors (either any error or more than n errors); continue with other files.​​
Useful when some files are corrupt but you still want to process the others.

#### ON_ERROR = SKIP_FILE_NUM (older form)

Skips file after a certain number of error rows.​​

### Where errors go (when continuing)

When rows are skipped (with CONTINUE / SKIP_FILE), error details can be retrieved via:
VALIDATE(COPY INTO ...) table function.​

INFORMATION_SCHEMA.LOAD_HISTORY and COPY_HISTORY views.
​
```
SELECT *
FROM TABLE(
  VALIDATE(
    TABLE_NAME => 'SALES_RAW',
    JOB_ID     => '_last'    -- or a specific load job ID
  )
);
```

VALIDATE returns rows that failed to load for the specified job: error message, column, row data, etc.​
Useful when you ran COPY with ON_ERROR=CONTINUE and want to see what was rejected.​

## VALIDATION_MODE (dry run / diagnostics)

VALIDATION_MODE is an option on the COPY INTO command that lets you check files for load errors without actually loading any data.​

What VALIDATION_MODE does

- When you add VALIDATION_MODE to COPY INTO, Snowflake parses the staged files using the given file format and returns information instead of inserting rows.​
- This is mainly used to find bad records (type issues, wrong delimiters, column count mismatches) before running the real load.​​
- No data is loaded into the target table while VALIDATION_MODE is present.

```
 COPY INTO my_table
 FROM @my_stage
 FILE_FORMAT = (FORMAT_NAME = 'my_fmt')
 VALIDATION_MODE = RETURN_n_ROWS | RETURN_ERRORS | RETURN_ALL_ERRORS;
```

RETURN_n_ROWS
If data is valid, returns up to n sample rows that would be loaded.
If errors appear before n rows, returns the error rows instead.​​

RETURN_ERRORS
Returns only the rows that fail validation for this COPY run (error message, file, row number, column).​​

RETURN_ALL_ERRORS
Returns all errors for the candidate files, including rows that failed in previous loads where ON_ERROR=CONTINUE.​

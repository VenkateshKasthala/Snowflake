# Semi‑Structured data

What is semi‑structured data?
Semi‑structured data includes formats such as JSON, Avro, ORC, Parquet, and XML where records can be nested and do not all share an identical fixed schema.​

Instead of fixed columns, these formats use key–value pairs, arrays, and nested objects to represent data.​

## How Snowflake stores semi‑structured data

Snowflake uses the VARIANT data type to store semi‑structured values (objects, arrays, scalars) in columns.​

When you load files with a semi‑structured FILE_FORMAT (JSON / AVRO / ORC / PARQUET / XML), Snowflake automatically parses the input and stores each record as a VARIANT value.​

Internally, data is stored in a compressed binary representation optimized for query, not as plain text.​

## VARIANT data type – key properties

Can hold mixed types: number, string, boolean, null, object, array, including deeply nested combinations.​

Schema is flexible: different rows in the same column can have different fields or shapes; missing fields simply return NULL when queried.​

VARIANT columns participate in normal SQL: you can filter, join, aggregate, and create views over expressions that read from VARIANT.​

### Converting to and from VARIANT

PARSE_JSON(<string>) – converts a JSON string to VARIANT.​

TO_VARIANT(<value>) – wraps a scalar or object as VARIANT.​

TO_JSON(<variant>) – serializes VARIANT back to JSON text.​

## Accessing data inside VARIANT

Snowflake uses path syntax to navigate inside VARIANT values.

### Path and array operators

col:key – object field access (DATA:customer, DATA:job.salary).​
col['complex key'] – for keys with spaces or special characters.​
col:array[0] – array element at position 0 (DATA:items[0]).​

These expressions produce another VARIANT value; you almost always cast them.

### Casting to native types

Use ::TYPE to cast a VARIANT expression
for example:
            DATA:price::NUMBER
            DATA:customer.name::STRING
            DATA:created_at::TIMESTAMP_NTZ​

Casting is required for comparisons, joins, aggregations, and most functions.

### Typical select pattern

Select one or more paths from VARIANT and cast them with aliases, then treat them like normal columns in later queries or views.​

Example pattern (structure, not tied to a specific table name):

```
SELECT
  payload:id::NUMBER              AS id,
  payload:user.name::STRING       AS user_name,
  payload:status::STRING          AS status,
  payload:details.item_count::INT AS item_count
FROM some_raw_table;
```

## Working with arrays

Arrays commonly appear as lists of items, tags, or nested objects.

### Basic array functions

ARRAY_SIZE(variant_expr) – number of elements in an array.​
Direct indexing: payload:items[0], payload:items[1].
Indexing is 0‑based; out‑of‑range accesses return NULL.​

### FLATTEN – turning arrays into rows

FLATTEN expands an array within VARIANT into multiple rows so each element can be processed individually.​

Key points: FLATTEN(INPUT => <variant_array>) returns a table with columns such as VALUE, INDEX, PATH.
Use in the FROM clause with a lateral join: FROM table, TABLE(FLATTEN(...)) f.​

General pattern:

```
SELECT
  t.id,
  f.value                         AS element_variant,
  f.value:some_field::STRING      AS some_field
FROM raw_table t,
     TABLE(FLATTEN(INPUT => t.payload:array_field)) AS f;
```

## Constructing and reshaping semi‑structured data

Snowflake has functions for building JSON‑like structures from relational columns.​

### OBJECT functions

OBJECT_CONSTRUCT(key1, value1, key2, value2, ...) – builds a VARIANT object.
Useful for: returning nested JSON from relational data or building request payloads.

Example pattern:

```
SELECT
      OBJECT_CONSTRUCT(
      'id',      id,
      'name',    name,
      'city',    city,
      'salary',  salary
    ) AS employee_obj
  FROM employees;
```

## ARRAY functions

ARRAY_CONSTRUCT(value1, value2, ...) – builds an array VARIANT.
ARRAY_AGG(expr) – aggregates values into an array, often combined with GROUP BY.​

Example pattern:

```
SELECT
    dept_id,
    ARRAY_AGG(emp_name) AS employees
  FROM employees
  GROUP BY dept_id;
```

## Design patterns with semi‑structured data

### Raw + curated model

Common pattern

Raw table: one VARIANT column holding the entire document (often plus load metadata like file_name, load_ts).​
Curated tables/views: extract specific fields from VARIANT into typed columns using SELECT with path expressions and FLATTEN.​

Benefits:
Keeps the original document unchanged and available for future needs.
Curated structures are easy to query and index with clustering if needed.

### When to keep as VARIANT vs. normalize

Keep as VARIANT when:Schema changes frequently or is partially unknown.
                     You only need a few attributes occasionally.​

Normalize into columns/tables when:Fields are stable and heavily used in filters/joins.
                                   You need strong type guarantees and statistics for performance.​

### Quick mental checklist

When you see semi‑structured data in Snowflake:

Storage: use VARIANT columns in a raw table.​

Access: : and [] for paths, always ::TYPE cast.​

Arrays: use FLATTEN + lateral join to explode.​

Reshape: use OBJECT_CONSTRUCT, ARRAY_CONSTRUCT, ARRAY_AGG.​

Model: raw VARIANT layer + one or more curated relational layers/views.

# Fail-Safe

Fail-safe is Snowflake’s last‑resort recovery layer that kicks in after Time Travel is over, and only Snowflake Support can use it.​

## 1. What Fail‑safe is

Fail‑safe provides a non‑configurable 7‑day window after the Time Travel retention period ends, during which Snowflake may be able to recover historical data.​

It is designed for disaster / catastrophic scenarios (severe mistakes, system failures), not for normal querying or self‑service restores.​

During Fail‑safe:

Data is stored in a special internal area as a read‑only backup; users cannot query or clone it.​

Recovery, if needed, must be requested through Snowflake Support; there are no SQL commands for you to access Fail‑safe directly.​

## 2. Relationship with Time Travel and retention

Timeline for a permanent table:​

Active + Time Travel

From the moment data changes until the end of DATA_RETENTION_TIME_IN_DAYS, you can use Time Travel (AT/BEFORE, UNDROP, cloning).​

Fail‑safe (7 days)

After Time Travel expires, historical data transitions into Fail‑safe for 7 more days.​

Only Snowflake Support can restore during this period.

After Fail‑safe

When the 7‑day Fail‑safe window is over, that historical data is permanently unrecoverable.​

Example: if Time Travel is 3 days, then:

Days 0–3: you can self‑service restore/query via Time Travel.

Days 3–10: only Fail‑safe; Support might help you recover.

After day 10: data is gone.​

Fail‑safe applies only to permanent objects (tables, schemas, databases); transient and temporary objects have no Fail‑safe.​

## 3. What you can and cannot do

#### What you can do (user)

During Time Travel window:

Query past versions with AT/BEFORE.

Clone historical versions.

UNDROP dropped tables/schemas/databases.​

Once data is in Fail‑safe:

You cannot query, clone, or UNDROP it anymore.

Your only option is to open a support ticket asking Snowflake to perform a Fail‑safe recovery.​

#### What Snowflake can do (support)

In catastrophic cases (accidental drop beyond Time Travel, severe internal issue), Support may restore data from Fail‑safe copies for you, on a best‑effort basis.​

## 4. Costs and visibility

Fail‑safe storage is counted separately from active and Time Travel storage; you can see bytes in views such as ACCOUNT_USAGE.TABLE_STORAGE_METRICS (FAILSAFE_BYTES).​​

Documentation notes that Fail‑safe storage contributes to overall storage billing; it covers 7 days beyond your Time Travel window.​

Recovery itself uses Snowflake‑managed serverless compute, which is billed under the FAILSAFE_RECOVERY service type when used.​

Because Fail‑safe is not directly queryable and is meant for emergencies, it’s usually not the first place to focus when tuning costs; Time Travel retention and general storage usage are much more important day‑to‑day.​

## 5. Mental model (vs Time Travel)

### Time Travel

Configurable (0–90 days depending on edition).

User‑accessible via SQL (AT, BEFORE, UNDROP, CLONE).

Used for normal mistakes, audit, and historical analysis.​

### Fail‑safe

Fixed 7 days, non‑configurable.

Only Snowflake Support can access.

Used only for last‑resort recovery after Time Travel is exhausted.​

Time Travel = “rewind button I control.”
Fail‑safe = “emergency backup Snowflake controls for 7 days after Time Travel ends.

# Data Sampling

Extracts a small, representative subset of your massive table to analyze, test, or explore FASTER instead of scanning billions of rows.

## Sampling Types 

### 1. SAMPLE (n ROWS) or SAMPLE (p%)

How it works:
Picks exactly N random rows (like SAMPLE (10000 ROWS))

Or exactly p% of rows (like SAMPLE (5 PERCENT))

#### Characteristics:

Super fast - stops after finding N rows
Predictable size - always exactly 10K rows
Great for testing (same size every time)
Less "random" than true probability

```
SELECT * FROM sales SAMPLE (10000 ROWS);     -- Exactly 10K rows
SELECT * FROM sales SAMPLE (2 PERCENT);       -- Exactly 2% of rows
```

### 2. TABLESAMPLE BERNOULLI (p%) or ROW

The "Coin Flip for Every Row"

How it works:
Every single row gets a coin flip: heads = include (p% chance), tails = skip
True independent probability for each row

#### Characteristics:

Most statistically accurate
Perfect randomness (no bias)
Gold standard for ML training
Scans entire table (slower)
Row count varies slightly (~p% ± variance)

```
SELECT * FROM sales TABLESAMPLE BERNOULLI (5 PERCENT);  -- ~5% rows, true random
SELECT * FROM sales SAMPLE ROW (10);                    -- Same as Bernoulli 10%
```

### 3. TABLESAMPLE SYSTEM (p%) or BLOCK

The "Grab Whole Trays" 📦

How it works:

Snowflake stores data in micro-partitions (128MB trays of ~100K rows each)
Randomly picks p% of entire trays and takes EVERYTHING in those trays

#### Characteristics:

FASTEST method - skips tray scanning
Perfect for 10TB+ tables
Consistent performance
Less random (tray bias possible)
Row count varies by tray sizes

```
SELECT * FROM sales TABLESAMPLE SYSTEM (5 PERCENT);  -- 5% of micro-partitions
SELECT * FROM sales SAMPLE BLOCK (10);               -- Same as System 10%
```

### SAMPLE with SEED

It returns reproducible results

How it works:
Adds SEED (123) to any method above
Same random numbers every time = identical sample

#### Characteristics:

Reproducible results (run query 100x, same data)
Essential for testing/debugging
Works with any sampling method

```
SELECT * FROM sales SAMPLE SYSTEM (5) SEED (123);    -- Same 5% every time
SELECT * FROM sales SAMPLE (1000 ROWS) SEED (456);   -- Same 1K rows every time
```


Scenario: 10TB Sales Table (100M rows, 5000 micro-partitions)

Method           | Rows Returned | GB Scanned | Time | Randomness | Use When
-----------------|---------------|------------|------|------------|---------
SAMPLE (10K)     | Exactly 10K   | ~0.1GB     | 2s   | ⭐⭐⭐      | Fixed test sets
SYSTEM (1%)      | ~2M rows      | 100GB      | 20s  | ⭐⭐        | Fast exploration
BERNOULLI (1%)   | ~1M rows      | 10TB       | 10m  | ⭐⭐⭐⭐     | ML training
Full Scan        | 100M rows     | 10TB       | 15m  | ⭐⭐⭐⭐⭐   | Final production

Use SYSTEM when:
Table > 100GB
You want results in <30 seconds  
"Good enough" randomness OK
Exploring / profiling data

Use BERNOULLI when:
Building ML models
Need statistical perfection
Table < 50GB (or willing to wait)
Academic/research accuracy

Use fixed ROWS when:

Need exactly 10K rows for testing
Comparing query performance
Building reproducible demos

Always add SEED when:

Debugging ("Why different results?")
Sharing samples with team
Building dashboards/reports
Performance benchmarks

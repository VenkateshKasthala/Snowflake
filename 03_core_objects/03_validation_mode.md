# Validation Mode

VALIDATION_MODE is an option on the COPY INTO command that lets you check files for load errors without actually loading any data.​

What VALIDATION_MODE does

- When you add VALIDATION_MODE to COPY INTO, Snowflake parses the staged files using the given file format and returns information instead of inserting rows.​

- This is mainly used to find bad records (type issues, wrong delimiters, column count mismatches) before running the real load.​​

- No data is loaded into the target table while VALIDATION_MODE is present.

-- COPY INTO my_table
-- FROM @my_stage
-- FILE_FORMAT = (FORMAT_NAME = 'my_fmt')
-- VALIDATION_MODE = RETURN_n_ROWS | RETURN_ERRORS | RETURN_ALL_ERRORS;

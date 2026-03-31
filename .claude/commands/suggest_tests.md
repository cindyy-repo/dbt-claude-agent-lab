Suggest missing dbt tests for the model `$ARGUMENTS`.

1. Find and read the model's SQL file under `models/`.
2. Find and read the `_*__models.yml` file in the same folder to see which tests already exist.
3. Apply these rules to identify missing tests — only suggest tests not already present:
   - `_id` column with no upstream join context → `unique`, `not_null`
   - `_id` column that is a foreign key (joins to another model) → `not_null`, `relationships`
   - `_at` or `_date` columns → `not_null`
   - `status`, `type`, `method` columns → `not_null`, `accepted_values` (infer the values list from the SQL CASE statements or WHERE clauses)
   - Numeric / amount columns → `not_null`
   - Boolean columns → `not_null`, `accepted_values: [true, false]`

Respond with ready-to-paste YAML only — no prose, no explanation. Output only the columns that need new tests, in this format:

      - name: column_name
        tests:
          - test_name
          - relationships:
              arguments:
                to: ref('other_model')
                field: column_name

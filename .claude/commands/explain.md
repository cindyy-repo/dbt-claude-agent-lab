Explain the dbt model `$ARGUMENTS` in plain English.

1. Search for the model SQL file under `models/` (e.g. `models/staging/$ARGUMENTS.sql`, `models/intermediate/$ARGUMENTS.sql`, `models/marts/$ARGUMENTS.sql`). If not found, list all `.sql` files under `models/` and tell the user the valid model names.
2. Read the SQL file.
3. Find and read the `_*__models.yml` file in the same folder as the SQL file.

Respond in exactly this format:

## $ARGUMENTS  [<layer: staging | intermediate | marts>]

**Purpose:** <one sentence describing what this model produces>

**Inputs:** <comma-separated list of upstream models or seeds it reads from>

**Outputs / columns:**
- `column_name` — <what it represents in plain English>
(one bullet per column)

**Business meaning:** <2–3 sentences explaining what a business user would use this data for>

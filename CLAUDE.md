# Claude Code Rules — jaffle_shop

## Before Making Changes
- Always show planned changes before editing any file.

## After Making Changes
- Always run `dbt build` after making model changes.
- Always run `dbt test` after editing schema YAML files.

## Code Style
- Never hardcode values — use `{{ var() }}`, `{{ ref() }}`, and `{{ source() }}` instead.

---

## Ref and Source Rules

- Always use `{{ ref('model_name') }}` to reference other dbt models
- Always use `{{ source('source_name', 'table_name') }}` for raw source data
- Never use direct `schema.table` references in any model
- `ref()` ensures correct build order and environment awareness
- `source()` centralises raw data references so schema changes only need updating in one place

---

## YAML File Standards

- Every model must have a corresponding YAML entry in the folder's `_[layer]__models.yml`
- Every model must have: `name`, `description`
- Every column must have: `name`, `description`
- Tests are defined at column level, not model level (exception: `dbt_utils.unique_combination_of_columns` is model-level)
- **dbt 1.11+ test syntax:** dbt_utils tests require arguments nested under `arguments:`. Built-in dbt tests (unique, not_null, accepted_values, relationships) do NOT use `arguments:`.
  ```yaml
  # Built-in dbt test — no arguments: wrapper
  tests:
    - not_null
    - accepted_values:
        values: ['a', 'b']

  # dbt_utils test — requires arguments: wrapper (dbt 1.11+)
  tests:
    - dbt_utils.accepted_range:
        arguments:
          min_value: 0
  ```
- Sources defined in `_staging__sources.yml` in the staging folder only
- One YAML file per folder — never one giant `schema.yml`
- Column order in YAML must match column order in the SQL `select`

---

## When to Use Each Layer

**Staging** (`models/staging/`)
- 1-to-1 with a source table — rename and cast only, no business logic
- Always use `{{ source() }}` to select from raw data
- Never join to other models in staging
- Always materialized as `view`

**Intermediate** (`models/intermediate/`)
- Use for joins, complex transformations, and reusable CTEs
- Always use `{{ ref() }}` to select from staging models
- Create when a CTE is reused in 2+ downstream models
- Create when a CTE changes the grain of data
- Always materialized as `view`

**Marts** (`models/marts/`)
- Business-facing output — aggregations and final column naming
- Only select from intermediate or other mart models via `{{ ref() }}`
- Always materialized as `table`
- Use `fct_` prefix for facts, `dim_` prefix for dimensions

---

## Materialization Decision Guide

| Materialization | When to use |
|----------------|-------------|
| `view` | Staging and intermediate (default) |
| `ephemeral` | Lightweight transformations not exposed to end users — use sparingly, hard to debug |
| `table` | Marts, models queried by BI tools, models with multiple downstream dependencies |
| `incremental` | Only when table build time is too slow — never use by default |

**Incremental strategies:**

| Strategy | When to use |
|----------|-------------|
| `append` | Immutable event data where old records never change |
| `merge` | Records that can be updated (e.g. order status) — requires `unique_key` |
| `delete+insert` | Partition replacement |

**Rule:** Start with `table`. Migrate to `incremental` only when there is a clear, measured performance reason.

---

## Incremental Model Standards

Every incremental model must follow this template exactly:

```sql
{{ config(
    materialized='incremental',
    unique_key='[pk]',
    incremental_strategy='merge'
) }}

select ...

{% if is_incremental() %}
where updated_at > (select max(updated_at) from {{ this }})
{% endif %}
```

Checklist:
- [ ] `is_incremental()` filter block present, filtering on `updated_at` or `created_at`
- [ ] `unique_key` defined for merge strategy
- [ ] Full refresh tested with `dbt build --full-refresh` after creating
- [ ] Strategy and reason documented in the model's YAML description

---

## Macro Standards

- Create a macro when the same logic appears in 2+ models
- Macros live in `macros/` folder
- Name macros: `[action]_[subject]` — e.g. `cents_to_dollars`, `generate_surrogate_key`
- Always add a description comment at the top of every macro file
- Always document arguments inside the macro file
- Reference macros in models using `{{ macro_name(args) }}`
- **Current macros:** none yet — update this list when macros are added

---

## Development Standards

- Always develop in the `dev` environment, never `prod`
- Limit data in dev using `target.name` to speed up iteration:

```sql
{% if target.name == 'dev' %}
where created_at >= dateadd('day', -3, current_date)
{% endif %}
```

- Run only the model being worked on and its downstream dependents:
  ```bash
  dbt build --select model_name+
  ```
- Always run `dbt build --select [new_model]+` after creating a model
- Never run a full `dbt build` during development unless necessary

---

## Model Generator Rules

Rules the agent must follow when generating new models:

- Always read existing models before creating anything new — avoid duplication
- Always identify the correct layer before writing any SQL
- Always ask: can this reuse an existing intermediate model?
- Always create the YAML entry alongside the SQL file
- Always use `{{ ref() }}` or `{{ source() }}` — never raw table names
- Always run `dbt build --select [new_model]+` after creating
- Never generate incremental models without explicit user request
- Never hardcode values — use `{{ var() }}` or `{{ env_var() }}`
- If unsure about the correct layer, ask before proceeding
- If a new CTE could be reused downstream, extract it as an intermediate model

---

## CTE Style Standards

All models must follow this exact structure:

```sql
-- 1. Import CTEs at the top (raw references only, no transformations)
with

source_name as (
    select * from {{ ref('stg_model') }}
    -- or {{ source('source', 'table') }} in staging models
),

another_source as (
    select * from {{ ref('another_model') }}
),

-- 2. Transformation CTEs in the middle (business logic here)
transformed as (
    select
        column_one,
        column_two
    from source_name
),

-- 3. Final CTE always named 'final'
final as (
    select * from transformed
)

-- 4. Always end with select * from final
select * from final
```

Rules:
- First CTEs are always raw imports — no transformations mixed in
- Import CTEs are named after the model they reference
- All business logic goes in the middle transformation CTEs
- The last CTE is always named `final`
- Always end with `select * from final`
- To debug: swap `select * from final` with any intermediate CTE name to inspect mid-pipeline
- Never mix imports and transformations in the same CTE
- CTE names use `snake_case` — no prefixes needed inside a model

---

## dbt Agent Commands

### /dbt:explain [model_name]
**What it does:** Summarises what the model does in plain English — purpose, inputs, outputs, and business meaning.

**Files to read:**
- `models/**/<model_name>.sql`
- The `_*__models.yml` file in the same folder as the model

**Response format:**
```
## <model_name>  [<layer>]

**Purpose:** <one sentence>

**Inputs:** <upstream models or sources>

**Outputs / columns:**
- `column_name` — what it represents

**Business meaning:** <plain English explanation of what this data is used for>
```

**Validations:**
- Confirm the model file exists before responding
- If model not found, list valid model names

---

### /dbt:lineage [model_name]
**What it does:** Traces full upstream and downstream dependencies for a model.

**Files to read:**
- `target/manifest.json` — use `depends_on.nodes` for upstream, `child_map` for downstream

**Response format:**
```
Lineage for <model_name>:

Upstream (sources → model):
  raw_orders (seed)
    └── stg_jaffle_shop__orders
          └── int_order_payments
                └── fct_orders  ← you are here

Downstream (model → dependents):
  fct_orders
    └── (no downstream models)
```

**Validations:**
- Confirm manifest.json exists at `target/manifest.json`; if not, tell the user to run `dbt build`
- Confirm the model name exists in the manifest

---

### /dbt:coverage [model_name or "all"]
**What it does:** Shows test coverage per column — which columns have tests and which don't.

**Files to read:**
- `models/staging/_staging__models.yml`
- `models/intermediate/_intermediate__models.yml`
- `models/marts/_marts__models.yml`

**Response format:**
```
## Test coverage: <model_name>

| Column              | Tests                        |
|---------------------|------------------------------|
| customer_id         | unique, not_null             |
| first_name          | not_null                     |
| first_ordered_at    | ⚠️  none                     |

Coverage: 6/7 columns tested (86%)
```

**Validations:**
- Flag any column with no tests with ⚠️
- If `"all"` is passed, run the report for every model and show an overall summary table at the end

---

### /dbt:missing_docs
**What it does:** Finds all models and columns that have no description, prioritised by layer (marts first, then intermediate, then staging).

**Files to read:**
- All `_*__models.yml` files under `models/`
- `models/staging/_staging__sources.yml`

**Response format:**
```
## Missing documentation

### Marts (fix first)
- [ ] dim_customers.first_ordered_at — no description
- [ ] fct_orders.status — no description

### Intermediate
(none)

### Staging
- [ ] stg_jaffle_shop__payments.payment_method — no description

Total: 3 items missing descriptions
```

**Validations:**
- Only flag truly empty or missing descriptions (not whitespace-only)
- Include source tables from `_staging__sources.yml` in the check

---

### /dbt:suggest_tests [model_name]
**What it does:** Suggests missing tests for a model based on column names, types, and dbt best practices.

**Files to read:**
- The `_*__models.yml` file for the model (to see existing tests)
- The model's `.sql` file (to understand column semantics)

**Rules for suggestions:**
- `_id` columns → `unique`, `not_null`
- `_at` / `_date` columns → `not_null`
- `status`, `type`, `method` columns → `accepted_values` (infer values from SQL or existing data)
- Foreign key `_id` columns → `relationships`
- Amount / numeric columns → `not_null`

**Response format:** Ready-to-paste YAML only — no prose.
```yaml
- name: <column_name>
  tests:
    - unique
    - not_null
    - dbt_utils.accepted_range:
        arguments:
          min_value: 0
```

**Validations:**
- Only suggest tests that are not already present
- Do not suggest duplicate tests

---

### /dbt:health
**What it does:** Full project health check across tests, coverage, and documentation.

**Steps:**
1. Run `dbt test` and capture pass/fail counts
2. Read all `_*__models.yml` files to check test coverage
3. Read all `_*__models.yml` files to check for missing descriptions

**Response format:**
```
## dbt Project Health Report

### ✅ Tests          PASS  (65/65 passed)
### ⚠️  Coverage      WARN  (18/24 columns untested)
### ❌ Documentation  FAIL  (5 models or columns missing descriptions)

---
Details:

**Test failures:** none

**Untested columns:**
- dim_customers.first_ordered_at
- ...

**Missing descriptions:**
- fct_orders (model-level description missing)
- ...
```

**Validations:**
- Run actual `dbt test` via Bash — do not guess results
- Use ✅ PASS / ⚠️ WARN / ❌ FAIL based on: zero issues = PASS, 1–3 = WARN, 4+ = FAIL

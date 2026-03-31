# Claude Code Rules — jaffle_shop

## Before Making Changes
- Always show planned changes before editing any file.

## After Making Changes
- Always run `dbt build` after making model changes.
- Always run `dbt test` after editing schema YAML files.

## Code Style
- Never hardcode values — use `{{ var() }}`, `{{ ref() }}`, and `{{ source() }}` instead.

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

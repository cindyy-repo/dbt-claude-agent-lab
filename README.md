# dbt + Claude Code Agent Lab

A hands-on dbt project built on the classic [jaffle shop](https://github.com/dbt-labs/jaffle_shop_duckdb) dataset, restructured to follow official dbt best practices and extended with Claude Code agent commands that let you query, audit, and improve your dbt project using plain English. The sample data (customers, orders, payments) is included as dbt seeds — no external database needed.

---

## What this repo is

This is a learning project that combines two things:

1. **A properly structured dbt project** — staging, intermediate, and marts layers; correct naming conventions; full test coverage; documented sources and models.
2. **A Claude Code agent setup** — six slash commands that let Claude read your project files and answer questions about models, lineage, test coverage, and documentation gaps.

It's aimed at people who are learning dbt and want to use Claude Code as a pair programmer and project auditor.

---

## What was built

### Project structure

```
models/
  staging/
    _staging__sources.yml         # Source definitions (raw seed tables)
    _staging__models.yml          # Tests and docs for staging models
    stg_jaffle_shop__customers.sql
    stg_jaffle_shop__orders.sql
    stg_jaffle_shop__payments.sql
  intermediate/
    _intermediate__models.yml
    int_customer_orders.sql       # Order stats aggregated per customer
    int_customer_payments.sql     # Payment totals aggregated per customer
    int_order_payments.sql        # Payments pivoted by method per order
  marts/
    _marts__models.yml
    dim_customers.sql             # One row per customer with lifetime stats
    fct_orders.sql                # One row per order with payment breakdown
```

### Naming conventions (dbt style guide)

| Layer | Convention | Example |
|-------|-----------|---------|
| Staging | `stg_[source]__[table].sql` | `stg_jaffle_shop__orders.sql` |
| Intermediate | `int_[description].sql` | `int_order_payments.sql` |
| Facts | `fct_[entity].sql` | `fct_orders.sql` |
| Dimensions | `dim_[entity].sql` | `dim_customers.sql` |
| Primary keys | `[model]_id` | `order_id`, `customer_id` |
| Timestamps | `[event]_at` | `ordered_at`, `first_ordered_at` |

### Tests

78 tests across all layers:
- `unique` and `not_null` on all primary keys
- `relationships` on all foreign keys
- `accepted_values` on status and payment method columns
- `dbt_utils.accepted_range` on numeric fact columns (`number_of_orders`, `customer_lifetime_value`)
- Source-level tests on raw seed tables

### Agent commands

Six Claude Code slash commands stored in `.claude/commands/` that give Claude structured instructions for common dbt tasks.

---

## Getting started

### Prerequisites

- Python 3.13+
- [uv](https://docs.astral.sh/uv/) (Python package manager)
- [Claude Code](https://claude.ai/code) (for agent commands)

### Setup

```bash
# Clone the repo
git clone https://github.com/cindyy-repo/dbt-claude-agent-lab
cd dbt-claude-agent-lab

# Install dependencies (dbt-duckdb, dbt-utils, sqlfluff)
uv sync

# Install dbt packages
uv run dbt deps

# Load seed data and build all models
uv run dbt build
```

That's it. DuckDB runs in-process — no database server needed.

### Verify everything works

```bash
uv run dbt test
# Expected: 78 passed, 0 failed
```

---

## The 6 agent commands

Open this project in Claude Code, then use these commands directly in the chat.

### `explain [model_name]`
Summarises what a model does in plain English — purpose, inputs, columns, and business meaning.

**Example:** `explain fct_orders`

### `lineage [model_name]`
Traces full upstream and downstream dependencies as an ASCII tree.

**Example:** `lineage dim_customers`

### `coverage [model_name or "all"]`
Shows which columns have tests and which don't, with a coverage percentage.

**Example:** `coverage all`

### `missing_docs`
Finds all models and columns with no description, prioritised by layer (marts first).

**Example:** `missing_docs`

### `suggest_tests [model_name]`
Suggests missing tests based on column names and dbt best practices. Returns ready-to-paste YAML.

**Example:** `suggest_tests stg_jaffle_shop__payments`

### `health`
Runs a full project health check — executes `dbt test`, checks coverage, and scans for missing descriptions. Returns a ✅ / ⚠️ / ❌ summary report.

**Example:** `health`

---

## What to build next

- **Add more sources** — connect a second source (e.g. a marketing or support dataset) and practice the `stg_[source]__[table]` naming convention with a new source prefix.
- **Build more marts** — add `dim_payment_methods` or a `monthly_revenue` mart that aggregates `fct_orders` by month.
- **Add singular tests** — write custom SQL tests in `tests/` for business rules that generic tests can't cover (e.g. "most recent order date must not be before first order date").
- **Add exposures** — document which dashboards or tools consume `fct_orders` and `dim_customers` using dbt [exposures](https://docs.getdbt.com/docs/build/exposures).
- **Set up CI** — add a GitHub Actions workflow that runs `dbt build` on every pull request.
- **Extend the agent commands** — add a `generate_model` command that scaffolds a new staging model from a source table definition.

---

## Project rules (CLAUDE.md)

This repo includes a `CLAUDE.md` file that instructs Claude to:
- Always show planned changes before editing files
- Run `dbt build` after model changes
- Run `dbt test` after editing schema YAML files
- Never hardcode values — use `{{ ref() }}`, `{{ source() }}`, and `{{ var() }}`

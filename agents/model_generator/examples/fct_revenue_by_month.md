# Example: fct_revenue_by_month

A walkthrough of the model generator agent creating a new mart model
that aggregates monthly revenue by payment method.

---

## User prompt

> "Use the model generator. I need a model that shows total revenue per month,
> broken down by payment method."

---

## Phase 1 — Clarifying questions

**Agent:**

Before I plan this model, I need to confirm three things:

1. **Grain** — Should one row represent one calendar month across all orders,
   or one row per month per payment method?
2. **Source** — Should this draw from `fct_orders` (which already has
   payment method columns) or directly from `int_order_payments`?
3. **Consumer** — Is this for a BI dashboard, an analyst query, or will
   another dbt model depend on it?

**User:**

> One row per month. Pull from fct_orders. It's for a BI dashboard.

---

## Phase 2 — Plan

**Agent:**

## Model Generator Plan

```
Model name:        fct_revenue_by_month
Layer:             marts
Materialization:   table
File path:         models/marts/fct_revenue_by_month.sql
YAML file:         models/marts/_marts__models.yml

Inputs:
  - {{ ref('fct_orders') }}   — contains ordered_at and all payment method amounts

New intermediate models needed first:
  - none — fct_orders already has payment method breakdown from int_order_payments

Columns to generate:
  - month_start          [timestamp]   not_null
  - total_amount         [amount]      not_null
  - credit_card_amount   [amount]      not_null
  - coupon_amount        [amount]      not_null
  - bank_transfer_amount [amount]      not_null
  - gift_card_amount     [amount]      not_null
  - order_count          [numeric]     not_null, dbt_utils.accepted_range min_value=0

Materialization rationale:
  Marts are always materialized as table per CLAUDE.md; this model will be
  queried directly by a BI tool.

Layer rationale:
  This is a business-facing aggregation with no downstream dbt dependents yet —
  correct placement is marts with fct_ prefix.
```

Waiting for your approval before writing any files.

**User:**

> Approved.

---

## Phase 3 — SQL generated

**Agent:** Here is the SQL I will write to `models/marts/fct_revenue_by_month.sql`:

```sql
with

orders as (

    select * from {{ ref('fct_orders') }}

),

monthly_revenue as (

    select
        date_trunc('month', ordered_at) as month_start,
        sum(amount)               as total_amount,
        sum(credit_card_amount)   as credit_card_amount,
        sum(coupon_amount)        as coupon_amount,
        sum(bank_transfer_amount) as bank_transfer_amount,
        sum(gift_card_amount)     as gift_card_amount,
        count(order_id)           as order_count

    from orders

    group by date_trunc('month', ordered_at)

),

final as (

    select * from monthly_revenue

)

select * from final
```

No macros needed — no logic is duplicated from existing models.

Shall I write this file?

**User:** Yes.

---

## Phase 4 — YAML generated

**Agent:** Here is the YAML entry I will append to `models/marts/_marts__models.yml`:

```yaml
  - name: fct_revenue_by_month
    description: Monthly revenue aggregated from fct_orders, broken down by payment method. One row per calendar month.
    columns:
      - name: month_start
        description: First day of the calendar month (date truncated to month).
        tests:
          - unique
          - not_null
      - name: total_amount
        description: Total order revenue across all payment methods for the month, in dollars.
        tests:
          - not_null
      - name: credit_card_amount
        description: Revenue paid by credit card for the month, in dollars.
        tests:
          - not_null
      - name: coupon_amount
        description: Revenue paid by coupon for the month, in dollars.
        tests:
          - not_null
      - name: bank_transfer_amount
        description: Revenue paid by bank transfer for the month, in dollars.
        tests:
          - not_null
      - name: gift_card_amount
        description: Revenue paid by gift card for the month, in dollars.
        tests:
          - not_null
      - name: order_count
        description: Number of orders placed in the month.
        tests:
          - not_null
          - dbt_utils.accepted_range:
              arguments:
                min_value: 0
```

Shall I write this?

**User:** Yes.

---

## Phase 5 — Validation

```
dbt build --select fct_revenue_by_month+
  1 of 1 OK created sql table model main.fct_revenue_by_month  [OK in 0.12s]

dbt test --select fct_revenue_by_month+
  7 of 7 PASS
```

## Build Complete

```
Models created:
  - models/marts/fct_revenue_by_month.sql

YAML updated:
  - models/marts/_marts__models.yml

dbt build: ✅ 1 model built successfully
dbt test:  ✅ 7 tests passed
```

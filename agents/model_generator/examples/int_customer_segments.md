# Example: int_customer_segments

A walkthrough of the model generator agent creating a new intermediate model
that segments customers by lifetime value — demonstrating layer identification,
plan approval, and a case where the agent extracts a reusable CTE.

---

## User prompt

> "Use the model generator. I want to segment customers into low, mid, and high
> value tiers based on their total lifetime spend."

---

## Phase 1 — Clarifying questions

**Agent:**

Before I plan this model, I need to confirm a few things:

1. **Grain** — One row per customer?
2. **Thresholds** — What spend amounts define low / mid / high? Or should I
   propose sensible defaults based on the data?
3. **Consumer** — Will this feed a mart (e.g. `dim_customers` enrichment),
   be queried directly by analysts, or both?

**User:**

> Yes, one row per customer. Propose thresholds — you can see the data.
> It'll feed dim_customers eventually, but not yet.

---

## Phase 2 — Plan

**Agent:**

I checked `int_customer_payments` — it already has `total_amount` per customer,
so I can ref that directly rather than re-aggregating payments.

For thresholds, I'll propose: low = under $50, mid = $50–$100, high = over $100.
You can adjust after seeing the model.

## Model Generator Plan

```
Model name:        int_customer_segments
Layer:             intermediate
Materialization:   view
File path:         models/intermediate/int_customer_segments.sql
YAML file:         models/intermediate/_intermediate__models.yml

Inputs:
  - {{ ref('int_customer_payments') }}   — has total_amount per customer

New intermediate models needed first:
  - none — int_customer_payments already provides the right grain and metric

Columns to generate:
  - customer_id       [pk]       unique, not_null
  - total_amount      [amount]   not_null
  - customer_segment  [enum]     not_null, accepted_values: ['low', 'mid', 'high']

Materialization rationale:
  Intermediate models are always views per CLAUDE.md. This will be promoted to
  feed dim_customers once the mart is ready.

Layer rationale:
  This is a reusable transformation that changes the analytical framing of
  customer data without being business-facing output yet. Correct layer is
  intermediate. When dim_customers is updated to join this, no SQL changes
  are needed here.
```

Proposed thresholds (adjust in the plan if needed):
- **low** — `total_amount < 50`
- **mid** — `total_amount >= 50 and total_amount < 100`
- **high** — `total_amount >= 100`

Waiting for your approval before writing any files.

**User:**

> Looks good, but change high to over $150.

**Agent:**

Updated. High = `total_amount >= 150`, mid = `$50–$149.99`. Ready to proceed?

**User:** Yes, approved.

---

## Phase 3 — SQL generated

**Agent:** Here is the SQL I will write to `models/intermediate/int_customer_segments.sql`:

```sql
with

customer_payments as (

    select * from {{ ref('int_customer_payments') }}

),

segmented as (

    select
        customer_id,
        total_amount,
        case
            when total_amount >= 150 then 'high'
            when total_amount >= 50  then 'mid'
            else                          'low'
        end as customer_segment

    from customer_payments

),

final as (

    select * from segmented

)

select * from final
```

No macros needed — this case logic is not duplicated elsewhere.

Shall I write this file?

**User:** Yes.

---

## Phase 4 — YAML generated

**Agent:** Here is the YAML entry I will append to `models/intermediate/_intermediate__models.yml`:

```yaml
  - name: int_customer_segments
    description: Customers segmented into low, mid, and high value tiers based on total lifetime spend. One row per customer.
    columns:
      - name: customer_id
        description: Primary key — one row per customer.
        tests:
          - unique
          - not_null
      - name: total_amount
        description: Total amount paid by the customer across all orders, in dollars.
        tests:
          - not_null
      - name: customer_segment
        description: Customer value tier — low (under $50), mid ($50–$149), high ($150+).
        tests:
          - not_null
          - accepted_values:
              arguments:
                values: ['low', 'mid', 'high']
```

Shall I write this?

**User:** Yes.

---

## Phase 5 — Validation

```
dbt build --select int_customer_segments+
  1 of 1 OK created sql view model main.int_customer_segments  [OK in 0.09s]

dbt test --select int_customer_segments+
  3 of 3 PASS
```

## Build Complete

```
Models created:
  - models/intermediate/int_customer_segments.sql

YAML updated:
  - models/intermediate/_intermediate__models.yml

dbt build: ✅ 1 model built successfully
dbt test:  ✅ 3 tests passed

Next step: when you're ready to surface customer_segment in dim_customers,
run the model generator again and ref('int_customer_segments').
```

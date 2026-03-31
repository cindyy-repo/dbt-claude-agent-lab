Show test coverage for `$ARGUMENTS`. If `$ARGUMENTS` is "all", report on every model.

1. Read all three YAML files:
   - `models/staging/_staging__models.yml`
   - `models/intermediate/_intermediate__models.yml`
   - `models/marts/_marts__models.yml`
2. For each relevant model, collect every column and its list of tests.
3. A column counts as "tested" if it has at least one test entry.

For a single model, respond in exactly this format:

## Test coverage: $ARGUMENTS

| Column | Tests |
|--------|-------|
| column_name | test1, test2 |
| column_name | ⚠️  none |

Coverage: X/Y columns tested (Z%)

---

If `$ARGUMENTS` is "all", show the per-model table for every model (marts first, then intermediate, then staging), then end with:

## Overall summary

| Model | Layer | Tested | Total | Coverage |
|-------|-------|--------|-------|----------|
| ...   | ...   | ...    | ...   | ...%     |

Any column with no tests must be flagged with ⚠️.

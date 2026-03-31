Find all models and columns that are missing descriptions in this dbt project.

1. Read all YAML files:
   - `models/staging/_staging__sources.yml`
   - `models/staging/_staging__models.yml`
   - `models/intermediate/_intermediate__models.yml`
   - `models/marts/_marts__models.yml`
2. For each model: flag if the model-level `description` field is absent or empty (whitespace-only does not count as documented).
3. For each column within each model: flag if the column `description` field is absent or empty.
4. Include source tables from `_staging__sources.yml` in the same check.

Respond in exactly this format, prioritising marts first:

## Missing documentation

### Marts (fix first)
- [ ] model_name — no model description
- [ ] model_name.column_name — no description

### Intermediate
- [ ] ...

### Staging & Sources
- [ ] ...

Total: N items missing descriptions

If a section has no missing items, write `(none)` under it.

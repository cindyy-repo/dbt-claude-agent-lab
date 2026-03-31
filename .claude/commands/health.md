Run a full health check on this dbt project across three areas: tests, coverage, and documentation.

Follow these steps in order:

1. **Tests** — Run `dbt test` via Bash and capture the output. Count total tests, passed, and failed.

2. **Coverage** — Read all three model YAML files:
   - `models/staging/_staging__models.yml`
   - `models/intermediate/_intermediate__models.yml`
   - `models/marts/_marts__models.yml`
   Count every column across all models. Count how many have at least one test. List any untested columns.

3. **Documentation** — Using the same YAML files plus `models/staging/_staging__sources.yml`, find all models and columns with missing or empty descriptions.

Scoring rules:
- ✅ PASS — zero issues
- ⚠️  WARN — 1 to 3 issues
- ❌ FAIL — 4 or more issues

Respond in exactly this format:

## dbt Project Health Report

### ✅/⚠️/❌ Tests          PASS/WARN/FAIL  (X/Y passed)
### ✅/⚠️/❌ Coverage        PASS/WARN/FAIL  (X/Y columns tested)
### ✅/⚠️/❌ Documentation   PASS/WARN/FAIL  (X items missing descriptions)

---

**Test failures:**
<list failures, or "none">

**Untested columns:**
<list as model.column, or "none">

**Missing descriptions:**
<list as model or model.column, or "none">

Do not guess test results — always run `dbt test` for real.

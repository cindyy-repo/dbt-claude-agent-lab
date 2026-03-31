Trace the full upstream and downstream lineage for the dbt model `$ARGUMENTS`.

1. Read `target/manifest.json`. If it does not exist, stop and tell the user to run `dbt build` first.
2. Find the node for `$ARGUMENTS` in `manifest["nodes"]` where `resource_type == "model"`. If not found, list all model names from the manifest.
3. Build the upstream tree by recursively following `depends_on.nodes` — resolve seeds and sources by name from `manifest["sources"]`.
4. Build the downstream tree by following `manifest["child_map"]` for the model's unique_id, filtering to model nodes only.

Respond in exactly this format:

Lineage for $ARGUMENTS:

Upstream (sources → model):
<ASCII tree using └── and indentation, seeds/sources labelled with (seed) or (source), target model labelled with ← you are here>

Downstream (model → dependents):
<ASCII tree, or "(no downstream models)" if none>

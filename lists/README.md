# Lists

One tab-separated file per list, with a line here saying how it was built. Lists are built from the Visual Studio Marketplace's public extension query (sorted by installs, 100 per page), never from memory, with `tools/list_extensions.ps1`.

| file | built |
|---|---|
| `audit_list_2026_10_28_top300.tsv` | the 300 most-installed extensions for the VS Code target, 2026-10-28. Columns: order, installs, pkg, version, last_updated, name |
| `audit_list_2026_10_28_top2000.tsv` | the same query, 2,000 rows |

`data/bulk_triage_*.tsv` holds the static triage of these lists (what each package could do, no code run) and is how the next extension to test is chosen.

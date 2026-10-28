---
name: session-baton-2026-10-28-one-by-one
description: Current state of the VS Code extension audit after Donald restarted it as one-at-a-time real testing in the portable editor; START HERE
metadata:
  type: project
---

**State at the end of 2026-10-28.** The Windows Sandbox and the bulk smoke-test pipeline are gone (his orders: "tear it down", "start over", "no tasks or monitors"). Testing is one extension at a time, in the portable VS Code (`C:\Users\donal\tools\vscode_portable\app`, work folder `...\work`) driven through vscode-mcp 0.4.0 on port 9560.

**Done:** `RESULTS.tsv (repo root, like sublime-package-audit)` has 50 rows, all real tests (37 no defect, 13 findings). 8 issues posted (list in `README.md`): autoDocstring 315, doxdocgen 349/350/351, vsc-python-indent 135, indent-rainbow 208, B5-Snippets 18, vscode-ionic-snippets 32. Both audit repos and vscode-mcp are public; the audit repo is ONE commit per day, amended and force-pushed (`--force-with-lease`).

**Method that works:** read the README and the extension's code, install via `install_extension`, reload, then one `batch` call per group of cases (create_file, open_file with line/character, run_command, get_text), compare with exact expected text, uninstall, reload, verify clean, `tools\rec.ps1`, issue if the defect is real and not already reported. See `PROCEDURE.md` and the skill.

**Next candidates** (logic-heavy, testable without accounts): formatters and generators in `data\bulk_triage_*.tsv` rows with few flags; cschlosser-style parsers; markdown/CSV/JSON tools; snippet packs only when their snippets can be inserted and compared. Skip: anything needing an account, a cloud service, or a language runtime that is not on this PC (Java, .NET, Go...) - those are outcome 3.

**Still open:** 17 snippet packs that a static check flagged were never verified in the editor (the check script was deleted with the bulk pipeline; re-derive by reading each pack's snippets only if you test that pack). The docstring generator's settings and other formats are untested. Python Indent's three settings, Vim integration and Jupyter are untested.

**Never again:** startup-only "smoke tests" as results; static scans recorded as results; asking Donald questions a rule already answers; background tasks or monitors; leaving files out of the public repos.

## Update (end of Code Spell Checker)
Code Spell Checker fully tested (config files, German dictionary, user settings, multi-root, navigation, limits). One finding: maxFileSize ignored, issue #5602. 51 rows (37 clean, 14 findings). Both spell checker extensions removed; editor shows only dpc00.vscode-mcp. Lessons: a single 700k-char line is blocked by design (20000-char line limit), Latin filler fills the 100-problem cap, languageSettings.locale is a filter. Next: pick the next logic-heavy extension from lists/.

## Update (end of Markdown All in One)
Markdown All in One 3.6.3 re-tested properly (the earlier row was a one-check smoke test): list editing, toggles, TOC, section numbers, table formatter, completions, print to HTML. Issues vscode-markdown#1592 (toggle on inner selection) and #1593 (table formatter touches code blocks). Paste-link tested later (works as documented; clipboard saved and restored). Not tested: preview webview. The other old sandbox-era rows (prettier, yaml, toml, rainbow-csv, etc.) are smoke tests with an empty result and should be redone the same way.

## Update (end of Prettier)
Prettier 12.4.0 re-tested properly (defaults for js/ts/json/css/scss/less/md/yaml/html/graphql/vue, every prettier.* setting, 15 config file formats, precedence, overrides, editorconfig, ignore files, requireConfig, configPath/ignorePath, range, errors, format on save, line endings). Issue prettier-vscode#4015 (disableLanguages dead setting) and a root-cause comment on #3567 (rangeStart 0 falsy). Not bugs: prettier.enable needs reload (documented); force format only bypasses ignore files and requirePragma (code says so). prettier.createConfigFile opens a native Select Folder dialog: do not run it from a test. Range format of CSS and 'enable=false' raise VS Code 'Configure Default Formatter' dialogs: cancel them.

## Update: YAML (redhat.vscode-yaml 2.0.0) redone, no bug, uninstalled
- Network off in tests (schemaStore, kubernetesCRDStore, telemetry). About 120 checks, all correct: 30 syntax diagnostics; 16 schema keywords via modeline; yaml.schemas (glob, glob array, relative path); validate=false; yamlVersion 1.1; customTags; style.flowMapping/flowSequence; keyOrdering; format (indent, comments, multi-doc, CRLF, singleQuote, bracketSpacing, printWidth, trailingComma, proseWrap, format.enable, [yaml] tabSize/insertSpaces); completion (schema keys, enum, boolean, nested); hover on/off; completion off.
- Not bugs: unresolved alias is severity info; keyOrdering sorts case-insensitively. A plain editor.tabSize in workspace settings does not beat the extension's [yaml] default; use a [yaml] override. vscode.executeDocumentSymbolProvider returns only top-level symbols for every language through vscode-mcp (JSON control), so symbols nesting is untested.
- Harness: run_command wants {"$uri": path}, {"$pos": [line, ch]}.
- Next in the redo list: TOML (tamasfe.even-better-toml), then rainbow-csv and the rest.

## Update: TOML (tamasfe.even-better-toml 0.21.2) redone, 1 issue, uninstalled
- Filed tamasfe/taplo#894: reorderInlineTables / reorder_inline_tables does nothing (setting and taplo.toml; reorderKeys and reorderArrays work).
- Already reported, not filed again: formatter settings need a window reload (taplo#687); schema "Additional properties" error repeated on every node (taplo#711, #699).
- Correct: 30 diagnostics cases, schema association validation, all other formatter settings (alignEntries, alignComments, trailing comma, columnWidth, arrayAutoExpand/Collapse, compact*, indent*, reorderKeys/Arrays, allowedBlankLines, trailingNewline, inlineTableExpand). crlf=true wrote LF (VS Code keeps the document's EOL: not filed).
- Method change: Donald 2026-10-28 "no scripts, nothing in the background": use the vscode-mcp tools directly, one `batch` call per test (create, open, format, read). Reload drops the server; retry until it answers. Typing /mcp reconnect: this Sublime sheet (id 16) is my own terminal, type with ui_type_text, screenshot, then Return.
- Next in the redo list: rainbow-csv, then the rest.

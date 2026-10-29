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

## Update: rainbow-csv (mechatroner.rainbow-csv 3.24.1) redone, no bug, uninstalled
- Correct: Align/Shrink round trip (quotes, empty fields, ragged rows, CRLF, double-width), separator autodetection and language ids (csv, tsv, semicolon, pipe, tab, .tab, min line count, autodetect_separators, enable_separator_autodetection), column edit select/before/after, virtual alignment (inlay hints, mode, char), comment_prefix, hover tooltip and column names, RainbowSeparatorOff/On.
- Not tested: RBQL, CSV Lint (output not readable), Set header/virtual header, Go to column, head/tail preview (they open input boxes or dialogs), row highlighting (decorations).
- Harness: after writing .vscode/settings.json wait 3000 ms before the next step (the watcher lags; without the wait settings looked one step late). Unsaved edits leave a "save changes" dialog on closeAllEditors: click Don't Save with Computer Use (get_window_state, click the button index). Better: do not leave dirty tabs (undo or revert with workbench.action.files.revert).
- Next in the redo list: the next smoke-test row in RESULTS.tsv with an empty result (see lists/audit_list_2026_10_28_top300.tsv).

## Update: markdownlint (DavidAnson.vscode-markdownlint 0.62.1) redone, no bug, uninstalled
- Correct: about 25 rules on a sample file, Fix All (needs two runs for conflicting fixes, same as markdownlint's one-pass fixer), ignore comments (disable/enable/next-line/line/file/capture/restore/configure-file), settings config, severityForError/Warning, configFile, configPointer, customRules, run=onSave, toggleLinting, focusMode (true and N), lintWorkspace and lintWorkspaceGlobs; a .markdownlint.json beside the files overrides the settings (README says so).
- Not tested: appliesTo, the preview, MD051-MD056 table and fragment rules in detail.
- Harness: revert dirty edits with workbench.action.files.revert before closing; the Lint Workspace command opens a task terminal.
- Next in the redo list: EditorConfig (73) or the next row with an empty result in RESULTS.tsv not yet in the ledger as a full test.

## Update: EditorConfig (EditorConfig.EditorConfig 0.18.2) redone, no new bug, uninstalled
- Correct: indent_style/indent_size/tab_width (tab key), end_of_line lf/crlf, insert_final_newline, trim_trailing_whitespace, charset utf-8-bom/utf-16le/utf-16be/latin1 (only for files really in that encoding: the extension re-opens the file with that encoding, so a UTF-8 file marked utf-16le is shown as garbage by design), glob sections (*, **, {a,b}, [12], path sections), section order, nested .editorconfig, Generate command.
- Known, already reported (not filed): .editorconfig edits are not applied to open files (editorconfig-vscode#458); trim_trailing_whitespace=false loses against files.trimTrailingWhitespace=true (README links #153); end_of_line=cr is not supported by VS Code.
- Harness: after revert the cursor moves to the end, so open_file with line/character before pressing tab.
- Next in the redo list: PKief.material-icon-theme (38), twxs.cmake (30), formulahendry.code-runner (32), or the next empty-result row not yet a full test.

## Update: Auto Close Tag (formulahendry.auto-close-tag 0.5.15) redone, no new bug, uninstalled
- Correct: closing tag on > (xml, jsx, md, plaintext), attributes, Foo.Bar, fragment <></>, excluded tags (br, img), self-closing on / (with and without space), enableAutoCloseSelfClosingTag, insertSpaceBeforeSelfClosingTag, excludedTags, SublimeText3Mode, fullMode, disableOnLanguage, enableAutoCloseTag; no closing for => and comparisons.
- Known, already reported (not filed): closing tag inserted for TypeScript generics, Map<string> becomes Map<string></string> (vscode-auto-close-tag#17, #124, #229); fullMode adds a second closing tag when </ is typed after an auto-closed tag (#25-like).
- Harness: the extension edits asynchronously after >, so sleep 500 to 1000 ms between typed characters; fast typing gives garbled text that is a test artifact.
- Next in the redo list: formulahendry.auto-rename-tag (45), then PKief.material-icon-theme (38), twxs.cmake (30), formulahendry.code-runner (32).

## Update: Auto Rename Tag (formulahendry.auto-rename-tag 0.1.10) redone, no bug, uninstalled
- Correct: rename from opening and closing tag, backspace, nested same names, attributes (also with > in a value), Foo.Bar in jsx, hyphen and ns:tag names, case, multi-line, selected-name replacement, markdown and plaintext, multi-cursor, undo and redo in one step, script blocks, html with editor.linkedEditing on and off, activationOnLanguage.
- Not tested: Vue/PHP/other languages (not installed), pasting whole tags.
- Next in the redo list: PKief.material-icon-theme (38), twxs.cmake (30), formulahendry.code-runner (32), then the next empty-result row not yet a full test (ledger lists the full ones).

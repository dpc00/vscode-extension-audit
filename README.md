# VS Code extension audit (2026)

## The infrastructure wall: help wanted

The method works, and it finds real bugs: 51 extensions tested, 14 issues filed on 10 repositories. What stops it is speed. One machine tests one extension at a time, and the 51 records took about eleven hours of wall-clock time (2026-10-28 19:43 to 2026-10-29 06:28 UTC, idle gaps included). A full feature test ran from about 15 minutes to over an hour; the longest single episode was 144 minutes, roughly 80 of them waiting. The Marketplace's long tail cannot be covered like this.

**The arithmetic, for a Marketplace of about 50,000 extensions (a round figure, not counted):**

| pace per extension | where it comes from | total for 50,000 | nonstop on one machine |
|---|---|---|---|
| about 13 minutes | 51 records in about 645 minutes: the real average so far, quick checks included | about 10,500 hours | about 14 months |
| about 40 minutes | the length of a full feature test (typical of the 12 done in full) | about 33,000 hours | about 3.8 years |
| 65 minutes | the active time inside the single longest episode, a worst case | about 54,000 hours | about 6.2 years |

Even the best of these is more than a year of continuous running, which is why this needs many machines at once. (All times are estimates from the session transcript timestamps, not measured by the pipeline.)

Already built and public: the [vscode-mcp](https://github.com/dpc00/vscode-mcp) server, the install ledger, the result and issue records, a static triage of the 2,000 most-installed extensions (`tools/bulk_triage.js`, about 1.5 seconds per extension, nothing run) and a Windows Sandbox batch runner for disposable installs.

Where cloud, DevOps and automation engineers could help most:

- **Containers or disposable VMs.** A clean, stateless environment per extension, so installs never leave residue and tests can run side by side.
- **Parallel runners.** A queue and workers (a VM fleet, Kubernetes or a large GitHub Actions matrix) that take an extension id, run the checks and write a row to `RESULTS.tsv`.
- **Hang detection.** A stuck extension host or stalled install is noticed by hand today. A watchdog that detects it, records "hung" with the log and moves on would remove most of the idle time.
- **Better static triage.** Reading a package without running it already found missing snippet files and bloated packages; more such checks would choose what to test live.

To take part, open an issue or a discussion on this repository. `PROCEDURE.md` and `data/` describe what exists.

An audit of Visual Studio Code extensions from the Visual Studio Marketplace, started on 2026-10-28 by Donald Chitester (GitHub: dpc00) together with Claude, an AI agent that drove a real VS Code through [vscode-mcp](https://github.com/dpc00/vscode-mcp). Each extension was installed the way a user installs it, used one feature at a time, and checked against what its README says it does. Problems were reported to the maintainers as short issues. It is the counterpart of [sublime-package-audit](https://github.com/dpc00/sublime-package-audit), which did the same for Sublime Text packages.

This repository holds the data and the method. It is a draft: the numbers will be updated.

## In numbers (to 2026-10-28)

- **51 test records** for **51 different extensions** (`RESULTS.tsv`). A row is written only for an extension that was used in a real VS Code; the result column is empty when no bug was found.
- **12 of the 51 have had the full test** (every feature and setting, one at a time; the "full feature test" lines in `data/installs_ledger.md`): doxdocgen, Python Indent, Code Spell Checker, Markdown All in One, Prettier, YAML, TOML, rainbow-csv, markdownlint, EditorConfig, Auto Close Tag and Auto Rename Tag. YAML had about 120 checks and no bug. The other rows come from earlier quick checks and are being redone one extension at a time.
- **14 issues** filed on **10 repositories** (`ISSUES.tsv`), all still open. Defects that were already reported, or whose repository is archived or abandoned, are not filed again; those that were found but not filed are written out in `findings/`.
- The extension lists used, and what built each one: `lists/`. Static facts about the 2,000 most-installed extensions (read from the package, nothing run) are in `data/bulk_triage_*.tsv` and were used only to choose what to test next.

## What was found

Small, concrete defects that a maintainer can fix in a few minutes. Typical kinds, each with a real example:

- **A snippet that inserts broken text.** A choice placeholder that is never closed is inserted as literal text ([B5-Snippets#18](https://github.com/HansUXdev/B5-Snippets/issues/18), [vscode-ionic-snippets#32](https://github.com/fivethree-team/vscode-ionic-snippets/issues/32)).
- **A package that points at files that are not there.** Four snippet packs list snippet files that are misspelled or missing in the published package, so those snippets never load (`findings/`).
- **A generator that writes wrong output.** A docstring indented by the guessed tab size, which is invalid Python after an aligned `def` ([autoDocstring#315](https://github.com/NilsJPWerner/autoDocstring/issues/315)); `constexpr` left in `@return`, a C++20 `requires` clause read as the return type, and no `@param` for a reference to an array with a template bound ([doxdocgen#349](https://github.com/cschlosser/doxdocgen/issues/349), [#350](https://github.com/cschlosser/doxdocgen/issues/350), [#351](https://github.com/cschlosser/doxdocgen/issues/351)).
- **An editing rule that fires when it should not.** A comment ending in `(` makes Enter indent the next line ([vsc-python-indent#135](https://github.com/kbrose/vsc-python-indent/issues/135)).
- **A setting that does nothing, or breaks everything.** `cSpell.maxFileSize` is ignored ([vscode-spell-checker#5602](https://github.com/streetsidesoftware/vscode-spell-checker/issues/5602)); a non-numeric `minWordLength` silently turns off all spell checking ([#5603](https://github.com/streetsidesoftware/vscode-spell-checker/issues/5603)).
- **A formatter that touches what it should not.** The table formatter also rewrites tables inside fenced code blocks, indented code, HTML comments and math blocks ([vscode-markdown#1593](https://github.com/yzhang-gh/vscode-markdown/issues/1593)); toggling bold or italic on a word selected inside its markers adds a second layer, and `*word*` + Ctrl+I turns into bold ([vscode-markdown#1592](https://github.com/yzhang-gh/vscode-markdown/issues/1592)).
- **A setting that does nothing, or a range that is ignored.** `prettier.disableLanguages` is declared but never read ([prettier-vscode#4015](https://github.com/prettier/prettier-vscode/issues/4015)); the TOML formatter option that sorts inline tables does nothing, in settings or in `taplo.toml` ([taplo#894](https://github.com/tamasfe/taplo/issues/894)); Format Selection formats the whole file when the selection starts at the first character, because offset 0 is falsy (cause added to [prettier-vscode#3567](https://github.com/prettier/prettier-vscode/issues/3567)).
- **A bloated package.** 1,217 `node_modules` files shipped because a test tool is listed in `dependencies` ([vscode-indent-rainbow#208](https://github.com/oderwat/vscode-indent-rainbow/issues/208)).

Most extensions had nothing to report; their rows have an empty result.

## Limits

- One machine: Windows 11, a portable VS Code (zip build) with vscode-mcp loaded in development mode. Linux and macOS behaviour was not tested.
- Extensions that need an account, a paid licence, a cloud service or administrator rights were skipped and not recorded.
- An empty result means no bug found in the checks made (a quick check for the rows not yet redone, see "In numbers"), not that there are none. Features that vscode-mcp cannot read (for example colouring done with decorations, or a webview) were not checked.
- The reports were written by an AI agent and are marked as such ("Claude reports:"). Every report states what was observed and what was not.
- The audit made mistakes, and said so when it found them: several early "findings" came from the test harness and were withdrawn before anything was filed.

## Files

| file | what it is |
|---|---|
| `PROCEDURE.md` | the method: setup, safety, what is tested and how, how a defect is reported |
| `.claude/skills/vscode-extension-audit/SKILL.md` | the same method as a step-by-step skill for an AI agent (Claude Code loads it when you open this repository); needs [vscode-mcp](https://github.com/dpc00/vscode-mcp) |
| `RESULTS.tsv` | one row per test record: package, date, result, line |
| `ISSUES.tsv` | every issue filed on an extension's repository: repository, number, title, state, dates, link (from GitHub) |
| `findings/` | full texts of defects that were not filed |
| `lists/` | the extension lists the audit works through, as tab-separated files |
| `data/` | the install ledger, static triage of the 2,000 most-installed extensions, and `samples/` (test files in a dozen formats) |
| `scripts/`, `tools/` | helpers: record a result, list the next untested extensions, commit the day, build a list, triage a package without running it |
| `notes/` | working notes and session batons |

The data comes from the audit's own notes and from GitHub's public records of the issues; extension metadata comes from the Marketplace. Notes in `RESULTS.tsv` have had local file paths and personal names removed.

## License

MIT, see `LICENSE`.

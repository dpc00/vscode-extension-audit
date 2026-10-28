# VS Code extension audit

This project tests popular VS Code extensions by hand. Each extension is
installed, exercised, and then removed, one at a time.

It is the VS Code counterpart of
[`sublime-package-audit`](https://github.com/SudoKillMe/sublime-package-audit),
which does the same thing for Sublime Text packages.

## How a test works

1. Install the extension into a portable copy of VS Code
   (`C:\Users\donal\tools\vscode_portable`) with default settings and workspace
   trust turned off.
2. Drive it through [`vscode-mcp`](https://github.com/SudoKillMe/vscode-mcp),
   an MCP bridge that calls the editor's commands and API directly. Typing and
   keyboard shortcuts go in as real keypresses. Before each round, vscode-mcp's
   own test suite must pass.
3. Check every claim the extension makes — its README, the settings it
   declares, its documentation — by actually using the feature.
4. When something is wrong, find the cause in the extension's source code
   before reporting it.
5. Uninstall the extension and put the editor back the way it was.

We never run an extension's own test suite. Every check is something a user
could do in the editor.

## Stats

| | |
| --- | --- |
| Rows in `RESULTS.tsv` | 124 |
| Rows beginning "Full test of" | 94 |
| Other rows (smoke, partial or method-limited) | 30 |
| Issues in `ISSUES.tsv` | 35 (31 open, 4 closed) |

The full record is [`RESULTS.tsv`](RESULTS.tsv); filed bugs are in
[`ISSUES.tsv`](ISSUES.tsv).

## Coverage and a completion estimate (measured 2026-11-19)

Counted against the two candidate lists, not remembered:

| List | With a row | Remaining |
| --- | --- | --- |
| `data/audit_list_2026_10_28_top300.tsv` | 102 / 300 | 198 |
| `data/audit_list_2026_10_28_top2000.tsv` | 124 / 2000 | 1876 |

The remaining top-300 splits into three classes whose costs differ by an order of
magnitude, so an estimate has to be stated per class rather than as one rate:

| Class | Count (estimated) | Per round | Why |
| --- | --- | --- | --- |
| Full code test | ~62 | 1–1.5 h | install, fixture, every command and setting checked by effect, debugger if it has one, uninstall (the `xdebug.php-debug` and `golang.Go` rounds) |
| Cheap — theme, snippets, language pack, extension pack | ~95 | 15–25 min | rule 8b queues them last, but one install/reload pass can carry 10–20 |
| Gate-skipped — account, paid cloud, Docker engine, .NET or Flutter SDK | ~55 | 0 | rule 8; the identifications are in `data/installs_ledger.md`, and the head of the queue is dominated by them (ranks 24, 31, 33, 36, 44, 49, 50, 56, 58, 66, 67, 74) |

That gives **85–135 hours** of session time for the top-300 (≈3–5 weeks at four
hours a day) and **950–1 400 hours** for the full 2000 — a year-scale project
unless the cheap classes are batched hard or the scope is declared finished at
the top 300.

Two caveats worth as much as the numbers:

- **The variance is the bridge, not the extensions.** A round that meets a new
  feature family first has to close a `vscode-mcp` gap before the feature can be
  read at all (rule 2): this project spent most of one session on DAP passthrough,
  breakpoints, cursor placement, port fallback, the cross-window instance registry
  and forwarding, and those now serve every later round. Estimate a session as
  **1–2 full rounds plus bridge work**, not 6 rounds.
- **One decision changes the count.** A Docker engine turns ranks 24, 33, 56 and
  the containers tooling into ~6 full rounds; without one they stay gate-skipped,
  which is what the table above assumes.

## What kinds of bugs we found

- **Settings that do nothing.** Declared in `package.json` but never read by
  the code (`prettier.disableLanguages`,
  `evenBetterToml.formatter.reorderInlineTables`).
- **Off-by-one-style logic errors.** `rangeStart 0` is treated as "no
  selection", so Format Selection formats the whole file (prettier-vscode).
- **Parsers that ignore comments.** CSS selectors inside comments are offered
  as completions and pass validation (vscode-html-css).
- **Data loss on round trips.** `JSON.stringify` silently corrupts integers
  above 2^53 (prettify-json).
- **Documentation that overpromises.** `liveServer.settings.host` claims to
  set the bind address but the server still listens on `0.0.0.0`.
- **Packaging problems.** 1,217 `node_modules` files shipped inside an
  extension; a missing `.wasm` file that stops another from activating at all.
- **Crashes on valid input.** Snippet bodies containing `${1:…}` placeholders
  crash the prettier-based generator (es7-react-js-snippets).
- **Windows path bugs.** Path casing differences make the same folder get
  served twice (open-in-browser).

## Limits

- **Windows only.** All results come from portable VS Code on Windows. Nothing
  is claimed about Linux or macOS.
- **No accounts or remote services.** These are local extensions; anything
  needing a paid account or a live backend is out of scope.
- **Some UI is unreachable.** A few surfaces can't be driven through the API
  (for example a save-changes dialog, or keys the background browser drops).
  Those rows say "not covered" rather than guessing.
- **Dead upstreams.** Bugs in unmaintained extensions are written down in the
  results but not filed.

## Files

Every path in this repository, and nothing else:

| Path | What it is | Files |
| --- | --- | --- |
| [`CLAUDE.md`](CLAUDE.md) | Project memory: the rules of this repo, where each kind of file lives, current state. This is the only memory file | 1 |
| [`AGENTS.md`](AGENTS.md) | One-screen pointer for harnesses that look for AGENTS.md first | 1 |
| [`.claude/skills/vscode-extension-audit/`](.claude/skills/vscode-extension-audit/SKILL.md) | The agent skill: how to drive the editor through vscode-mcp, the techniques, the traps. The only skills directory | 1 |
| [`PROCEDURE.md`](PROCEDURE.md) | The audit method in full detail | 1 |
| [`RESULTS.tsv`](RESULTS.tsv) | The dones, one row per extension: date, what was tested, what is wrong, install count | 1 |
| [`ISSUES.tsv`](ISSUES.tsv) | Every bug filed: repo, issue number, state, date | 1 |
| [`LICENSE`](LICENSE), [`.gitignore`](.gitignore) | MIT; ignore rules | 2 |
| [`data/`](data/) | Machine data and documents, no session notes: the queue (`audit_list_*.tsv`, install-count order), the install ledger, the retired triage tables, samples, and the unfiled findings | 38 |
| [`data/samples/`](data/samples/) | Fixture files an extension was pointed at (schemas, config files) | 22 |
| [`data/findings/`](data/findings/) | Defects found but **not** filed, one file each, written as the issue would have been; first line `Status: not filed`, `Filed: <link>` or `Dropped: <reason>` | 11 |
| [`tools/`](tools/) | PowerShell scripts that record results and rebuild the issue table (`rec.ps1`, `issues_tsv.ps1`, `triage.ps1`, `recycle.ps1`, `pixdiff.ps1` — changed pixels and their bounding box between two window captures, for DOM-only toggles, …) | 9 |
| [`.github/`](.github/) | Repository metadata (`FUNDING.yml`) | 1 |

There is no fixture directory and no notes directory: probes are created in the portable editor's
work folder (`C:\Users\donal\tools\vscode_portable\work`), used, and recycled at the end of the
round; the record is `RESULTS.tsv`, `ISSUES.tsv`, `CLAUDE.md` and the skill, not git history — each
audit repo is a single amended commit.

vscode-mcp, the editor bridge, lives in its own repo:
<https://github.com/SudoKillMe/vscode-mcp>.

## License

MIT

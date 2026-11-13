# VS Code extension audit

Independent security and functionality testing of the most-installed VS Code
extensions, one install-test-uninstall round each.

This is the counterpart of
[`sublime-package-audit`](https://github.com/SudoKillMe/sublime-package-audit)
(the same method on Sublime Text packages).

## How it works

- Each extension is installed into **portable VS Code**
  (`C:\Users\donal\tools\vscode_portable`, stock user settings, workspace trust
  disabled) and driven headlessly through
  [`vscode-mcp`](https://github.com/SudoKillMe/vscode-mcp) (MCP bridge over the
  generated command tools + the extension API), with **real user keypresses**
  sent via `SendInput`/`SendMessage` for editor typing and chords. Before each
  round `node --test` in `vscode-mcp` must pass.
- Every behavior is checked **against the extension's own claims**: its README,
  its `package.json` settings, its docs. Deviations are findings, each with a
  reproducible root cause read from the source.
- Results are classified as **verified** (seen to work), **defect** (does not
  work), **partial** (works in some paths, fails in others), or **not covered**
  (nothing reachable proves it). A defect is only filed when its root cause is
  confirmed in code.
- Each extension is uninstalled and the host restored after its round.

## Scale

| Metric | Count |
| --- | --- |
| Extensions tested | 57 |
| Full test rounds | 38 |
| Remaining smoke-test rows | 1 (`tomoki1207.pdf`, deliberately untested) |
| Issues filed (all open) | 16 |
| Tests run | none, ever |

## What was found

Failures cluster into a few shapes:

| Shape | Example |
| --- | --- |
| Declared but unread | `prettier.disableLanguages`, `evenBetterToml.formatter.reorderInlineTables` |
| Falsy-coercion bugs | `rangeStart 0` disables Format Selection (prettier-vscode) |
| Comment-blind parsing | selectors inside CSS comments offered as completions (vscode-html-css) |
| Lossy serialization | `JSON.stringify` round trip silently corrupts large integers (prettify-json) |
| Host overclaim | `liveServer.settings.host` documented as bind address, actually 0.0.0.0 |
| Packaging rot | 1,217 `node_modules` files shipped via `dependencies`; missing `.wasm` breaks activation |
| Placeholder crash | snippet body with `${1:…}` fed to prettier crashes generation (es7-react-js-snippets) |
| Case-sensitive path keys | Windows path casing spawns duplicate servers (open-in-browser) |

## What this audit could not test

- **Anything needing paid accounts or remote services.** These are local-first
  extensions.
- **Windows only.** Every result is from portable VS Code on Windows; nothing is
  claimed for Linux or macOS.
- **What the UI hid.** Where a surface is unreachable from the API (e.g. a
  dirty-file save dialog, Alt+B keys Chromium drops in the background), the row
  says so instead of guessing.
- **Dormant upstreams.** Defects in unmaintained extensions are recorded in the
  ledger, not filed.

## Files

| File | Purpose |
| --- | --- |
| [`PROCEDURE.md`](PROCEDURE.md) | The full audit method, step by step |
| [`RESULTS.tsv`](RESULTS.tsv) | One row per tested extension: date, result, ledger line |
| [`ISSUES.tsv`](ISSUES.tsv) | Every filed issue: repository, number, state, date |
| [`notes/`](notes/) | Working notes, one file per topic, each dated |
| [`vscode-mcp/`](https://github.com/SudoKillMe/vscode-mcp) | The MCP bridge used to drive the editor |
| [`scripts/`](scripts/) | Audit helpers (`check-results.py`, `reinstall-all.ps1`, smoke/install logs) |
| [`work/`](work/) | Fixtures used by the rounds |

## Status

Testing runs in rounds when asked; `RESULTS.tsv` is the live record — check it
before naming what is left. Rounds run on portable VS Code builds 1.144–1.146
with vscode-mcp 0.8.4–0.9.1.

## License

MIT

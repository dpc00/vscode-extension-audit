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

## Results so far

| | |
| --- | --- |
| Extensions tested | 56 |
| Fully tested | 38 |
| Smoke-tested or untestable leftovers | 18 |

The full record is [`RESULTS.tsv`](RESULTS.tsv); filed bugs are in
[`ISSUES.tsv`](ISSUES.tsv).

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

| File | What it is |
| --- | --- |
| [`PROCEDURE.md`](PROCEDURE.md) | The audit method in full detail |
| [`RESULTS.tsv`](RESULTS.tsv) | One row per extension: date, what happened, where the notes are |
| [`ISSUES.tsv`](ISSUES.tsv) | Every bug filed: repo, issue number, state, date |
| [`notes/`](notes/) | Working notes, one file per topic |
| [`scripts/`](scripts/) | Helper scripts and logs |
| [`work/`](work/) | Test fixtures |

vscode-mcp, the editor bridge, lives in its own repo:
<https://github.com/SudoKillMe/vscode-mcp>.

## Status

Testing happens in rounds, when asked. `RESULTS.tsv` is the current record.
Recent rounds ran on VS Code 1.144–1.146 with vscode-mcp 0.8.4–0.9.1.

## License

MIT

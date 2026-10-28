# Procedure

## Setup

- A portable VS Code (the zip build with a `data` folder next to `Code.exe`), in its own folder outside any repository. Nothing is written to the registry or PATH, and no administrator rights are used. Removing it is deleting one folder.
- vscode-mcp loaded in that VS Code in development mode: `Code.exe --extensionDevelopmentPath=<vscode-mcp folder> <work folder>`. The agent works only through its tools: `install_extension`, `run_command`, `open_file`, `create_file`, `get_text`, `get_diagnostics`, `complete`, `hover`, `definitions`, `read_log`, `batch` and the rest (`get_help` lists them). A whole test (create files, open, act, read the result) goes in one `batch` call.
- A work folder outside any repository with sample files in the languages the extension targets (`data/samples/` here has a start).

## Safety (read first)

Installing an extension does not run its code; activating it does, and an active extension has the full rights of the user. The marketplace has carried malicious extensions. So:

1. **Triage without running.** Download the extension package (`.vsix`, a zip) into its own empty folder and read `package.json`: publisher, activation events, declared commands, dependencies, and any `scripts` that run at install. Look in the code for network calls, `child_process`, reading of credentials or browser profiles, and obfuscated bundles. `tools/triage.ps1` does this for one extension, `tools/bulk_triage.js` for a list (in memory, writes only the result file).
2. **Live test only after triage is clean**, one extension at a time, in the portable copy, with nothing in the work folder except the test files.
3. Anything needing an account, a paid licence, a cloud service or administrator rights is recorded as "prerequisite not installed" and skipped.

## Testing one extension

1. Check the extension is not already in `RESULTS.tsv` (match on the exact id, case-insensitively).
2. Read what it promises (the README, `package.json` contributes, settings) and, where the code is readable, how it is triggered.
3. Write the ledger line, then install with `install_extension` (VS Code's own CLI; the in-app route raises a publisher-trust dialog that nothing can answer). Reload the window with `reload_window`.
4. Use every documented feature on realistic input and compare the exact output with what the documentation says. A few dozen inputs is normal; include the edge cases the documentation is silent about (unusual syntax, non-ASCII text, CRLF files, nesting). Compare text exactly, not by eye, and say what was expected before looking at the result.
   - Completions and snippets: `complete` (position in a file, optional filter). Hover: `hover`. Go to definition: `definitions`. Diagnostics: `get_diagnostics`.
   - Commands and formatters: `run_command` with the command id, then `get_text`.
   - Features triggered by typing (indent on Enter, comment generators): put the cursor with `open_file` (line and character), then `run_command type` with the text, as a keypress would.
   - Snippets: `editor.action.insertSnippet`.
5. **Do not mistake a test artifact for a defect.** Forcing activation of an extension that expects an open editor, testing a feature the documentation never promised, or a file created with the wrong line endings is a mistake in the test. Reproduce a suspected defect a second way, and find the cause in the extension's code, before reporting it.
6. Uninstall with `uninstall_extension`, reload, and check that `list_extensions` shows nothing left over. Write the ledger line for the removal.
7. Record one row in `RESULTS.tsv` with `tools/rec.ps1`: what was exercised, what was correct, what was not tested.

## What counts as a finding

- Wrong output for valid input, a crash, a documented feature that does nothing, a setting that is documented but not read.
- A package that does not match its manifest: files listed but missing, a test tool shipped as a dependency.
- Anything vscode-mcp could not do that a person could: record it as a gap in vscode-mcp.

A static observation (a startup check, a flag from triage) is not a result.

## Reporting

For each finding on a repository that is alive:

1. Search the repository's issues for the same defect (several phrasings), and look at whether it is archived or the extension is deprecated. If it is already reported, or the project is dead, record the link in the row and file nothing.
2. Otherwise file one issue per distinct defect, with the extension version and VS Code version, a minimal reproduction, the actual and the expected result, and what was found about the cause. A short "Claude reports:" opening says where it came from. No pull requests and no forks.
3. Put the issue link in the row.

## Records

`RESULTS.tsv` columns (same as sublime-package-audit): `package` (the extension id), `date`, `result`, `line` (the `order` of the extension in the list used). `result` is empty when no bug was found; otherwise it says only what bugs were found, with the issue link. It does not list what was tested. Defects not filed get a file in `findings/`; filed ones are in `ISSUES.tsv`. Notes carry no local paths or personal names.

---
name: vscode-extension-audit
description: How to run the VS Code extension audit through vscode-mcp: test one extension at a time by using its documented features in the portable VS Code, compare exact output, report real defects. Use whenever installing, testing or removing VS Code extensions, or building the extension lists.
---

# VS Code extension audit

Public method: `PROCEDURE.md` in this repository. This file is the working copy with Donald's local rules, paths and the traps found so far.

## Where things are

- Portable VS Code: `C:\Users\donal\tools\vscode_portable\app` (`Code.exe`, `data` folder inside), work folder `C:\Users\donal\tools\vscode_portable\work`. Not in any repo. Remove = recycle that folder (skill `recycle-delete`).
- vscode-mcp: `C:\Users\donal\projects\vscode-mcp` (public repo `dpc00/vscode-mcp`), served at `http://127.0.0.1:9560/mcp`. Start the editor with `Code.exe --extensionDevelopmentPath=C:\Users\donal\projects\vscode-mcp --disable-workspace-trust <work folder>`; the extension is not installed, so a plain start has no MCP. `package.json` must have no byte-order mark (Windows PowerShell's `Set-Content -Encoding utf8` adds one and VS Code then silently skips the extension).
- This repo (public repo `dpc00/vscode-extension-audit`): `RESULTS.tsv`, `ISSUES.tsv`, `data\installs_ledger.md`, `data\samples\`, `findings\`, `lists\`, `tools\`, notes in `notes\`.
- The MCP tools may not be in the Claude Code tool list (a server added mid-session needs `/mcp reconnect`). A PowerShell helper that posts JSON-RPC to `http://127.0.0.1:9560/mcp` works as well: write the body to a file and use `curl.exe --data-binary @file`.

## Rules (Donald)

1. **One extension at a time, tested for real.** Use every documented feature on realistic input and compare exact output with what the documentation promises. Starting an extension (activation, a startup log) proves nothing and is never a result. He has twice thrown away work that was only startup checks or static scans: do not rebuild a bulk smoke-test pipeline.
2. **Work through vscode-mcp.** A step it cannot do is a gap in vscode-mcp: write it in the baton and in `vscode-mcp\README.md`, and fix the tool when it is cheap (0.4.0 added `batch`, `complete`, `hover`, `definitions`, `insert_text` that way).
3. **Installs:** only extensions, only in the portable VS Code, only through `install_extension`. No admin, nothing outside `vscode_portable`. Write the ledger line BEFORE each install; after each test uninstall, reload, verify `list_extensions` is clean, write the removal line. No Windows Sandbox, no VM, no background tasks, no monitors, no scheduled jobs (his orders 2026-10-28).
4. **Safety first (PROCEDURE.md):** triage without running, then live test. An extension that needs an account, a paid licence, a cloud service or admin rights: skip it and record nothing (RESULTS.tsv has only extensions that were tested).
5. **Reporting (his go, 2026-10-28: "find all the bugs and post issues"):** search the upstream issues first (several phrasings, `gh search issues --repo OWNER/REPO "words" --json number,title,state`), skip archived repos and deprecated extensions, one issue per distinct defect, body starting "Claude reports (found while ...)" with versions, minimal repro, actual and expected, cause. Link in the row. **No pull requests and no forks.**
6. **Do not mistake a test artifact for a defect.** Forcing activation with no editor open produced three false findings; a wrong cursor column or CRLF vs LF in a new file produced false failures. Reproduce a suspect result a second way and read the extension's code for the cause before reporting.
7. **Git in this repo:** ONE commit per day, which you amend after each piece of work (`git add -A; git commit --amend --no-edit; git push --force-with-lease origin main`). He asked for exactly this, public on GitHub. A new calendar day starts a new commit. `git add -A` and publish everything except real secrets and junk (`.gitignore` is minimal). No `Co-Authored-By` change needed on amend.
8. **No Bash tool.** Use Read, Grep, Glob, Edit, Write; PowerShell only for real commands, one tool call at a time when a permission prompt can appear. Deletes go to the Recycle Bin with `recycle.ps1`, one path per call.
9. **Check "already tested" before every extension:** `RESULTS.tsv` by exact id, case-insensitively.
10. **Say what you will do in one line and do it; do not ask questions he can answer by a rule above.** Reports are short: what was tested, what is wrong, the link.

## Testing techniques (vscode-mcp)

- A whole test in one `batch` call: `create_file`, `open_file` (with `line` and `character` to place the cursor), `{sleep: ms}`, `run_command`, `get_text`. Build the call list in PowerShell, `ConvertTo-Json -Depth 10 -Compress`, write to a file, post it.
- Put a marker character in test text to mark the cursor and compute line/column from it; compare the file text after the action with an expected string exactly, normalising line endings (new files in this editor are CRLF; only compare CRLF deliberately).
- Completions, snippets, hover, definition: `complete` (path, line, character, optional `filter`, `limit`), `hover`, `definitions`. `run_command vscode.executeCompletionItemProvider` is capped at 20,000 characters and a JS/TS file returns every global.
- Features triggered by typing (Enter indentation, comment generators such as `/**` + Enter): place the cursor with `open_file`, then `run_command type` with `[{"text": "\n"}]`. Extension commands bound to a key (such as `pythonIndent.newlineAndIndent`) can be run directly.
- Snippet bodies: `editor.action.insertSnippet` with `[{"snippet": "..."}]` or `{"name": "...", "langId": "..."}`.
- Diagnostics: `get_diagnostics` (optionally `source`). Another extension's output or log: `read_log` (pattern). Formatting and transform commands: `run_command` then `get_text`.
- JSON bodies with non-ASCII characters: escape them as `\uXXXX` before posting (Windows PowerShell 5.1 writes the console codepage otherwise). PowerShell 5.1 has no `` `u{e9} `` escape: use `[char]0xE9`.
- Not readable at all: inline decorations, tree views, webviews (those need a screenshot tool, and are out of reach of the extension API).
- An extension pack installs its members too: triage the members and record a row for each.

## Traps

- `install_extension` goes through VS Code's own CLI; `workbench.extensions.installExtension` opens a "trust the publisher?" dialog that nothing can answer.
- A freshly installed extension appears in `list_extensions` only after `reload_window`; an uninstalled one stays listed until the same reload, and its folder is deleted at VS Code's next start (`data\extensions\.obsolete`). Uninstalling an extension that others depend on can fail.
- `reload_window` answers first and the server restarts; wait about 12 s before the next call.
- Extension ids come back with the publisher's own capitalisation; paths in results use a lower-case drive letter.
- The MCP server refuses requests with an `Origin` header and names other than localhost or an IP.

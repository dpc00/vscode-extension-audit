---
name: session-baton-2026-10-28-project-created
description: START HERE (vscode-extension-audit): project created, nothing tested; the safety question about running 50000 third-party extensions is open and needs Donald's decision before any live test
metadata:
  type: project
---

**Donald, 2026-10-28:** "audit all the (50000) VS Code extensions", "you install VS Code, we install MCP, you control VS Code with it", then "make a 'vscode-extension-audit' project like 'sublime-package-audit'".

**Built this session**
- Portable VS Code 1.144.0 in `C:\Users\donal\tools\vscode_portable\app`.
- vscode-mcp 0.1.0 in `projects\vscode-mcp` (commit ccddbe8, local only), registered in Claude Code, all 16 tools tested.
- This repo: README, PROCEDURE, skill, data\RESULTS.tsv (header only), installs_ledger, lists\README, tools\rec.ps1.

**Windows Sandbox history (Donald reminded me 2026-10-28; found in transcripts 38ae22cc, 1020c008 and the sublime-mcp baton project_session_baton_2026_10_16_profile_probe.md):** on 2026-10-16 the feature `Containers-DisposableClientVM` was enabled with admin through the run-as-admin skill plus a restart, a sandbox kit was built (`C:\Users\donal\tools\agent-audit\sandbox\*.wsb`, `sandbox_run.ps1`), it worked, and Donald had it removed the same day (15:33, "remove it", `Disable-WindowsOptionalFeature`) because he was uneasy: the Wi-Fi tray icon vanished while a sandbox ran (Wi-Fi itself fine) and a Default Switch adapter appeared. Machine: Windows 11 Pro 26300, 11.7 GB RAM. The kit is not runnable until the feature is enabled again. Nothing recorded the install itself, which is why I did not remember it.

**Sandbox kit prepared (2026-10-28, not run):** Donald said the MCP was reachable and worked fine from the sandbox last time, so networking stays Enabled. `tools\sandbox\`: `vscode_batch.wsb` (maps app_sandbox, vscode-mcp, the kit read-only and `out\` read-write), `start_vscode.ps1` (logon script: sets `vscodeMcp.bind` 0.0.0.0, opens firewall 9560, writes the sandbox IP to `out\ip.txt`, starts VS Code with vscode-mcp in development mode), `forward.js` (host: 127.0.0.1:9561 to the sandbox). vscode-mcp got a `vscodeMcp.bind` setting and a Host check that accepts IP literals only. Still to do: enable the Sandbox feature (admin click + restart, his go and timing), register `claude mcp add --transport http --scope user vscode-mcp-sandbox http://127.0.0.1:9561/mcp`, launch the .wsb, run `node tools\sandbox\forward.js`, test one extension end to end.

**Sandbox feature ENABLED 2026-10-28 13:14 (his go, he clicked Yes; ledger line written); RESTART PENDING (his timing).** After the restart: (1) check `Get-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM` and that `WindowsSandbox.exe` exists; (2) say "hands off for a moment", then start `tools\sandbox\vscode_batch.wsb` (double-click equivalent: `Start-Process` the .wsb); (3) wait for `tools\sandbox\out\ip.txt`; (4) `node tools\sandbox\forward.js` in the background; (5) `claude mcp add --transport http --scope user vscode-mcp-sandbox http://127.0.0.1:9561/mcp`, then `/reload-plugins` and `/mcp reconnect vscode-mcp-sandbox` typed into my own tab; (6) test one extension end to end, then close the sandbox (nothing in it survives). The host test VS Code window (portable, dev mode) can be closed first; the old Wi-Fi tray-icon oddity may reappear (cosmetic last time). To remove the feature again: Disable-WindowsOptionalFeature via run-as-admin plus restart.

**Open: safety (his decision needed before any live test).** Activating an extension runs third-party code with his user rights, and the marketplace has carried malicious extensions. The procedure therefore does static triage first (download the .vsix, read package.json and code, run nothing) and goes live only when clean. Real isolation (Windows Sandbox or a VM) needs administrator rights to enable, which he has ruled out. Ask him whether static triage plus selective live tests is acceptable, or whether the audit should stay static-only.

**Next (after his answer)**
1. Build the list (marketplace query API, sorted by installs, 100 per page) into `lists\` with a line in `lists\README.md`; write `tools\list_extensions.ps1`; write `tools\commit_day.ps1` (copy the sublime audit's one-commit-per-day idea).
2. First batch: 5 to 8 extensions from the top, triage then live test, `rec.ps1` per row.
3. No remote yet: create the GitHub repo only when he says so.

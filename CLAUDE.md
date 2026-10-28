# VS Code extension audit — project memory

The method is `PROCEDURE.md`; the working procedure for an agent is the skill
`.claude/skills/vscode-extension-audit/SKILL.md`. This file holds what is true about the project and
how work is done here — nothing else in the repo is a memory store.

## Where everything lives

| | |
| --- | --- |
| Method, public | `PROCEDURE.md` |
| Results, one row per extension | `RESULTS.tsv` |
| Filed bugs | `ISSUES.tsv` |
| Install/removal record | `data/installs_ledger.md` |
| Candidate lists (by install count) | `data/audit_list_2026_10_28_top300.tsv`, `…top2000.tsv` |
| Defects found but **not** filed | `data/findings/<extension>-<topic>.md` |
| Fixtures an extension was pointed at | `data/samples/` |
| Scripts | `tools/` |
| Agent skill | `.claude/skills/vscode-extension-audit/SKILL.md` |

No `notes/`, no scratch directory: a round's probes live in the portable editor's `work` folder and
are recycled when the round ends. History is not kept in a baton note *or* in git: the repo is one
amended commit (rule 6), and what a round taught lives in the skills and in this file.

## Rules

0. **Only the mounted MCP tools. No scripts, no HTTP** (Donald, 2026-11-15, said again after
   repeated violations: "you are strictly forbidden to use scripts of any kind for testing when the
   MCP tools are sufficient. no covert use of http for mcp usage"). Drive the editor through
   `mcp__vscode_mcp_*` — `batch`, `run_command`, `get_text`, `expect`, `complete`, `open_file`, … —
   never through a hand-written HTTP client, a JSON-RPC call, a PowerShell pipeline or a helper
   script that calls the server. `tools/recycle.ps1` is for deleting files only, never for testing.
0b. **Proof before any keystroke.** `activate_window` must report `ok:true` for the VS Code window
   and `foreground_after` must be that window; otherwise send nothing. Untargeted `send_keys` lands
   in the agent's own console — twice it typed into Donald's GhostShell / Sublime tab, which he
   called out as stupid and dangerous. No exceptions, no "it probably has focus".
1. **One extension at a time, tested for real.** Every documented feature, on realistic input,
   compared with exact output. Activation or a startup log is never a result.
2. **A gap in `vscode-mcp` is a bug in `vscode-mcp`** (Donald, 2026-11-14: "cannot do's are just
   bugs to fix in the mcp. There are no can't"). Fix it there (`C:\Users\donal\projects\vscode-mcp`,
   plain JS loaded with `--extensionDevelopmentPath`), reload, verify live, commit, push. Writing a
   gap down is the last resort, never the deliverable.
3. **Extension installs are normal work; giant toolsets are not** (Donald, 2026-11-16: "i can't have
   you installing and uninstalling large downloads all night long", then the boundary - "when I say
   installs, I am only referring to giant toolsets, like C++ or CLang"). A `.vsix` through
   `install_extension` is fine. What is banned is the giant toolset a round would drag in: a C/C++
   compiler chain, Clang, a .NET SDK, a Gradle or Maven distribution, anything worth hundreds of MB or
   written into `Program Files`. Those are asked about first, and if he says no the row records the
   limit instead. Ledger line before the install, removal line after, then reload and check
   `list_extensions` is clean.
   Anything that can elevate (machine-wide MSI, SDK, driver) is announced in chat *before* it runs: the
   UAC box appears only on Donald's screen, the secure desktop is invisible to `computer.windows`,
   `list_dialogs` and window captures, so consent is read from the effect and from his word - never
   inferred from the absence of a dialog - and an approval is never quietly reversed.
   **Nothing may need his attention silently** (Donald, 2026-11-16: "If there is some approval dialog
   on the taskbar, I won't notice it. You have to scream 'Hey, handle the taskbar!' at me or I will do
   nothing"). He does not watch the taskbar, so the duty is mine, and it is to speak, not to wait:
   prefer the no-dialog route (a user-local install over a machine-wide MSI); when a dialog is
   unavoidable, announce it in chat *before* it appears, in those words - "Hey, handle the taskbar!" -
   say what the box is and what to answer, then stop and wait for him. Never leave a dialog up while
   acting as if the call merely timed out, and never assume he saw it. And nothing goes on the taskbar
   unannounced: no UAC, no foreground window, no pending input box, no visible long job.
4. **Cleanup is part of the test** (Donald, 2026-11-13): uninstall what was installed, close every
   tab, close every browser tab a command opened, recycle every probe. Leftovers from earlier
   sessions count too.
5. **Never run anything in the background** (Donald, 2026-10-28): no background shell, script, task,
   monitor or scheduled job. Long tests get split into short foreground steps.
6. **Exactly one commit in this repo, amended, never appended** (Donald, 2026-10-28; restated
   2026-11-16: "both of those repos are squashed commits, one commit per repo"). The two audit repos
   are **not code repositories** - they are ledgers, and git is not suited to them: history, branches,
   blame and diffs carry nothing here, so the commit is only a way to publish the current record
   (Donald, 2026-11-16: "the 2 audit repos are not 'code' repos because git is not suited to them").
   `git add -A && git commit --amend --no-edit && git push --force-with-lease origin main`.
   Both repos are public. **Git history is not kept**, so nothing is recoverable from `git log`: the
   durable record is `RESULTS.tsv`, `ISSUES.tsv`, `CLAUDE.md`/`CLAUDE.local.md` and the skills - never
   point at history as where a session, a decision or a lesson survives. `vscode-mcp` is the opposite:
   a real product repo with normal commits, never squashed.
7. **Report bugs, don't fix them elsewhere**: one issue per distinct defect, cause read from the
   extension's source, body starts "Claude reports (found while …)". No pull requests, no forks.
8. **Skip what cannot run here** without recording it: anything needing an account, a paid licence,
   a cloud service or admin rights (rule 4 of the skill). A feature that exists is either tested or
   recorded as unreachable with the evidence that nothing can observe it.
8b. **Code first; snippet packs go to the END of the queue** (Donald, 2026-11-15: "just put snippet last on
   any queue"). Extensions whose whole contribution is snippets, a grammar, a theme or icons are not
   skipped and not deleted — they are queued behind every code extension, whatever their install
   count. Records already in `RESULTS.tsv` are never removed (his words: "i did not say remove the
   results, that is cruel").
8c. **Deprecated, or replaced by a built-in, is not a round** (Donald, 2026-11-18, after
    `msjsdiag.debugger-for-chrome` was tested anyway). A marketplace name that says Deprecated, or an
    extension whose job a built-in now does, is skipped and not recorded. Those two facts are the
    reason to move on, not the questions the round answers. The row already written for that debugger
    stays: rows are not removed.
9. **Notes are not results.** A row is finished only when every documented feature was exercised.
   **A capture is evidence only when the model can read it** (Donald, 2026-11-16: "this model doesn't
   not support vision. I am confused that you keep taking screenshots"). On `deepseek-v4-flash` the
   model has no vision, and the theme and Copilot rounds both claimed things "verified by capture" that
   were never observed - all withdrawn. The session later switched to `deepseek-v4-flash-vision-exp`,
   where captures are readable. So: check which model is running before trusting or forbidding a
   screenshot; prefer text (command results, `wait_config`, files, logs) regardless; and treat a window
   capture's chrome as possibly stale - a desktop capture is the tie-breaker.
10. **Close every round by writing down what it taught** (Donald, 2026-11-15: "Do any skill updating if
    you have learned anything... And make a routine out of doing so"): technique or trap → `SKILL.md`
    with the date and the evidence; durable rule or fact → this file; missing or awkward MCP
    capability → code in `vscode-mcp` plus its README; then commit both repos. Anything learned that
    is not written down there is lost, and repeating it is the failure mode he has already paid for.

## Toolchains on this machine (checked 2026-11-18 with Get-Command, not assumed)

A build or debugger round has a compiler; "there is no toolchain" is never a reason to skip one without
looking first.

| tool | where |
| --- | --- |
| gcc / g++ 16.1.0 — WinLibs MinGW-w64, UCRT, POSIX SEH — with `gdb`, `cmake` and `ninja` beside it | `%LOCALAPPDATA%\Microsoft\WinGet\Packages\BrechtSanders.WinLibs.POSIX.UCRT_Microsoft.Winget.Source_…\mingw64\bin` (on PATH) |
| rustc and the rest of the Rust toolchain | `%USERPROFILE%\.cargo\bin` |
| go 1.26.5 | on PATH |
| JDK 25 (Eclipse Adoptium) | `C:\Program Files\Eclipse Adoptium\jdk-25.0.3.9-hotspot` |
| node 26.13.1, npm | on PATH |

The first CodeLLDB attempt assumed there was no C toolchain and went after a Go debuggee, which cost a
pass: LLDB has no Go line tables and every breakpoint answered "Resolved locations: 0". The C program
built with that gcc is what proved breakpoints, stepping and locals.

## Harness (omp)

Rules written into this repo during the Claude sessions that were answers to *that* harness, not to this
project, and that therefore do not bind omp:

- **"No Bash tool."** Donald, 2026-11-16: the reason was the number of mistakes Claude made with bash,
  "not reason at all for them with bash. It does not apply to omp." What survives is the rule it was
  standing in for: no scripts and no HTTP for driving the MCP server (rule 0), and `read`/`grep`/`glob`
  in preference to shell text tools. A shell running git or `powershell -NoProfile -Command` is ordinary
  work here.
- **One tool call at a time.** It serialized Claude's per-call permission prompts; omp has none.
  Independent reads and checks go together.
- **`Claude reports (found while …)`** in rule 7 is the wording already used in filed issues, kept for
  those issues' sake; a new issue may name the agent that found the defect.

Other rules in this file are Donald's, about this project, and stay: rule 0 and 0b above all.

## Where a lesson belongs

- Technique, trap, recipe → `SKILL.md` (Techniques / Traps). Every session loads it.
- A durable fact about the project → this file.
- State — the queue and what is done — is never written as prose: the queue is `data/audit_list_*.tsv` in install-count order and each done is one row in `RESULTS.tsv`. `README.md` carries stats only (counts, limits, the file map); `ISSUES.tsv` counts the filed bugs. A status paragraph anywhere goes stale and contradicts the record (Donald, 2026-11-14).

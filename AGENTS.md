# VS Code extension audit — agent entry point

This file is the pointer so every harness loads the operating rules (harnesses that read
`AGENTS.md` first would otherwise skip the Claude-local files).

Read, in this order, at the start of any session:

1. `CLAUDE.local.md` — operating rules, including the first action: read the newest baton note in
   `notes/` (file name contains "baton"), then say the plan in two lines; check `RESULTS.tsv`
   before naming what is left, because a baton can be stale.
2. `.claude/skills/vscode-extension-audit/SKILL.md` — the audit procedure.
3. `PROCEDURE.md` — the public method.
4. `notes/MEMORY.md` — the working-notes index (one file per note, each with a date; check the
   date before relying on it).

This project is the counterpart of `C:\Users\donal\projects\sublime-package-audit`; the same
global rules apply here (no Bash tool, one tool call at a time, recycle-delete, installs only as
allowed).

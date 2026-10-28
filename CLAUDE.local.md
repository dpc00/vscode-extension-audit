# VS Code extension audit: notes for Claude

The audit procedure is the skill `vscode-extension-audit` (`.claude/skills/vscode-extension-audit/SKILL.md`) and the public `PROCEDURE.md`. Results are in `RESULTS.tsv`, installs in `data/installs_ledger.md`, scripts in `tools/` (`rec.ps1` records one extension). Working notes, one file each with a date, are in `notes/` (git-ignored). Check a note's date before relying on it.

First action of a session: read the newest baton note in `notes/` (file name contains "baton"), then say the plan in two lines. Before naming what is left to do, check `RESULTS.tsv`: a baton can be stale.

This project is the counterpart of C:\Users\donal\projects\sublime-package-audit; Donald's global rules (no Bash tool, one tool call at a time, recycle-delete, installs only as allowed) apply here too.

@notes/MEMORY.md

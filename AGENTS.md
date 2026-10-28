# VS Code extension audit — agent entry point

Harnesses that look for `AGENTS.md` first need a pointer, so this file is one. The content lives
in the two standard places:

1. [`CLAUDE.md`](CLAUDE.md) — project memory: the rules of this repo, where each kind of file
   lives, and the current state. Read it first.
2. [`.claude/skills/vscode-extension-audit/SKILL.md`](.claude/skills/vscode-extension-audit/SKILL.md)
   — the working procedure: how to drive the portable editor through `vscode-mcp`, the techniques
   and the traps.

Then [`PROCEDURE.md`](PROCEDURE.md) for the public method and [`RESULTS.tsv`](RESULTS.tsv) for what
has been tested. Nothing is kept in `notes/`, a baton or any other memory file: this repository has
`CLAUDE.md` for memory and `.claude/skills/` for skills, and nothing else.

This project is the counterpart of `C:\Users\donal\projects\sublime-package-audit`; the same global
rules apply here (recycle-delete, installs only as allowed, no scripts and no HTTP for driving the MCP
server). Two rules written into this repo are **Claude-harness artifacts and do not bind omp** — the
Bash-tool ban and the one-call-at-a-time permission serialization; `CLAUDE.md`, section "Harness", says
why and what replaces them.

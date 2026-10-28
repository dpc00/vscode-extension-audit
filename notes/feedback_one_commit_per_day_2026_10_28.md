---
name: audit-one-commit-per-day
description: The vscode-extension-audit repo gets one commit per day, not one per batch or per extension
metadata:
  type: feedback
---

Donald (2026-10-28): "audit gets one commit per day."

**Why:** on 2026-10-28 I made about 15 small commits in this repo (a commit per bulk run, per hand-tested extension, per ledger fix). He asked whether I was amending commits for a day; the answer was no (reflog shows 0 amends), but the pile of commits was the problem.

**How to apply:** in `vscode-extension-audit`, one commit per calendar day. He then said (same day): "no, amend the commit until the next day." So when today's commit already exists, finish each piece of work with `git commit --amend` on that latest commit (update its message to cover the day's work; local only, never pushed), instead of new commits and instead of leaving work uncommitted. Next calendar day: start a new commit, amend that one for the rest of the day. This is his explicit instruction for this repo; do not squash or rewrite the earlier commits of 2026-10-28 unless he says to. This narrows the standing rule in `~/.claude/rules/commits.md` (commit finished work) for this repo only. Related: [[session-baton-2026-10-28-sandbox-running]].

**Public (Donald, same day: "neither should be only local. Both should be public on github"):** both `dpc00/vscode-extension-audit` and `dpc00/vscode-mcp` are public on GitHub (created and pushed 2026-10-28; secret scan of tracked files was clean). In the audit repo, after each `git commit --amend`, push with `git push --force-with-lease origin main` (an amended commit cannot be pushed any other way; this is his explicit instruction, limited to the audit repo). vscode-mcp: ordinary commits and plain `git push`. Never push `.claude/`, `notes/`, `*.vsix` or scratch files (already ignored in the audit repo; vscode-mcp has an untracked `.claude/`, leave it out).

2026-10-28 state when the rule was given: today's commits already exist (last one cd284de); uncommitted work after that: none yet, but `tools/` and `data/` changes from now on wait for tomorrow's commit.

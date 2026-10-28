---
name: never-run-things-in-background
description: Donald 2026-10-28: never run anything in the background (shell, script, task, monitor), always in the foreground
metadata:
  type: feedback
---

Donald (2026-10-28), after a long TOML formatter test script was moved to the background by the harness: "don't run things in the background, in a shell, script or anything like that EVER".

**Why:** he cannot follow work he cannot see, and long silent runs made him ask whether something was wrong.

**How to apply:** run every command in the foreground with a timeout; split long tests into short scripts (a few reloads each, under about 2 minutes) so the tool never hands the call to the background. Never use run_in_background, Monitor or a scheduled job. If a call is moved to the background anyway, stop it with TaskStop and re-run it in smaller pieces.

Status: not filed - the option demonstrably has no effect in this rig, but the cause is not isolated, so it is not a defect claim.

# PHP Debug (xdebug.php-debug 1.40.2): skipFiles does not suppress a step-into stop in a matching file

## What the code intends
`out/phpDebug.js` (stop handler) re-issues the same step when a step stop lands in a skipped path:

```js
else if (response.command.startsWith('step')) {
    await this._processLogPoints(response);
    // check just my code
    if (this._args.skipFiles &&
        isPositiveMatchInGlobs(convertDebuggerPathToClient(response.fileUri).replace(/\\/g, '/'), this._args.skipFiles)) {
        if (!this._skippingFiles.has(connection.id)) this._skippingFiles.set(connection.id, true);
        if (this._skippingFiles.get(connection.id)) {
            let stepResponse;
            switch (response.command) {
                case 'step_out':  stepResponse = await connection.sendStepOutCommand(); break;
                case 'step_over': stepResponse = await connection.sendStepOverCommand(); break;
                default:          stepResponse = await connection.sendStepIntoCommand();
            }
            await this._checkStatus(stepResponse);
            return;                     // the stop is never reported
        }
        this._skippingFiles.delete(connection.id);
    }
    stoppedEventReason = 'step';
}
```

## What was observed (VS Code 1.146.0, PHP 8.4.25, Xdebug 3.5.3, 2026-11-18)
Fixture `work/phpdbg/{index.php,calc.php}`; `index.php:15` calls `describe($total)` defined in `calc.php`.

* Launch config `"skipFiles": ["**/calc.php"]`, breakpoint at `index.php` line 14 (0-based), start, then DAP `stepIn`:
  the session stops at **`calc.php:6`** inside `describe`, i.e. the stop the option is supposed to suppress.
* The same step with `"skipFiles": ["**/phpdbg/*"]` (which also matches `index.php`): no user-visible stop at all; the adapter sent five consecutive `step_into` (DBGp log) and the script ran to the end. That is consistent with "every stop matched", not with a working skip of one file.
* The matcher itself is not the problem: with the extension's own code,
  `minimatch(convertDebuggerPathToClient('file:///C:/Users/donal/tools/vscode_portable/work/phpdbg/calc.php').replace(/\\/g,'/'), '**/calc.php')` returns **true** (measured with the bundled minimatch 3.x), so the string the glob is compared against matches the pattern.

## Why it is not filed
The code path and the string both look correct in isolation, so the runtime path reaching `isPositiveMatchInGlobs` (or `this._args.skipFiles`) must differ from what was measured - and `response.fileUri` at that moment is not observable from outside the adapter. Filing "skipFiles has no effect" without knowing why would be a guess; the note carries the repro instead.

## What would settle it
Instrumenting the extension (a console.log of the exact path and glob list inside that branch) or `--inspect` on the adapter while stepping, then comparing with the value measured above.

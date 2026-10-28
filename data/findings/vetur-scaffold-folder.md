# Vetur 0.37.3 — `vetur.openUserScaffoldSnippetFolder` throws ENOENT on a portable install

Found 2026-11-18 while testing `octref.vetur` 0.37.3 on the portable VS Code 1.146.0
(`--user-data-dir app\data\user-data`, workspace `...\vscode_portable\work`). **Not filed upstream**:
the repository is in maintenance mode (its README points at Volar) and the trigger needs a
user-data-dir that is not `%APPDATA%\Code`, so a report there is unlikely to be acted on. Recorded
here with the cause instead of guessed at in the RESULTS row.

## Observed

Running the palette command **Vetur: Open User Scaffold Snippet Folder**
(`vetur.openUserScaffoldSnippetFolder`) rejects:

```
ENOENT: no such file or directory, mkdir 'C:\Users\donal\AppData\Roaming\Code\User\snippets\vetur'
```

Nothing opens; no folder is created.

## Cause (read from source, commit 96aaa707)

`client/userSnippetDir.ts`:

```ts
if (process.platform === 'win32') {
  return resolve(process.env['APPDATA'] || '', appName, 'User/snippets/vetur');
}
```

The path is derived from `%APPDATA%` and a hardcoded app name, so it ignores the running instance's
`--user-data-dir` entirely. On this rig the command therefore targets a different installation's tree
(`...\AppData\Roaming\Code\User\snippets\vetur`), which does not exist.

`client/commands/openUserScaffoldSnippetFolderCommand.ts`:

```ts
if (!fs.existsSync(uri.fsPath)) {
  fs.mkdirSync(uri.fsPath);          // not { recursive: true }
}
vscode.commands.executeCommand('vscode.openFolder', uri, true);
```

`mkdirSync` without `recursive` throws `ENOENT` when any **parent** is missing. `%APPDATA%\Code\User\snippets`
is created by VS Code's own first run, so the defect only appears where that tree is absent — a portable
build, a custom `--user-data-dir`, or a profile that never wrote snippets.

## Two distinct faults

1. **Path**: the global snippet dir ignores the instance's user-data-dir, so the command acts on another
   installation's directory (and, in a portable rig, on the user's real editor tree).
2. **Error handling**: the non-recursive `mkdirSync` turns a missing parent into an unhandled rejection
   instead of creating the tree (`{ recursive: true }` would fix it).

## Fix that would work here

`fs.mkdirSync(uri.fsPath, { recursive: true })`, and compute the directory from
`vscode.env.appName`/`context.globalStorageUri` rather than `process.env['APPDATA']`.

## Separate observation, cause not established

`vetur.showCorrespondingVirtualFile` states in its own output that *"Hover, semantic diagnostics, jump to
definition and find references are run on this file"*, yet `definitions` from `{{ message }}` in the
template returned `[]`, and `hover` on the same position returned empty while `hover` on a tag and on a
script member both worked. `vetur.validation.template` A/B was clean, so this is not the validator.
Not filed and not called a defect: the definition path runs through `HTMLMode.findDefinition`, which did
throw earlier in the same session (before a `package.json` with `vue` existed), and the failure did not
reproduce as an exception afterwards — Vetur's docs put template-expression navigation behind VTI, so the
empty result may be a documented limitation rather than a bug.

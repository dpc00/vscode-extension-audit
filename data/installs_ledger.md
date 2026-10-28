# Installs ledger

One line per install and per removal, written BEFORE the install. Everything lives in the portable VS Code (`C:\Users\donal\tools\vscode_portable`); removing that folder removes all of it.

2026-10-28 ADD (Windows, per-user, no admin): VS Code 1.144.0 portable zip unpacked to C:\Users\donal\tools\vscode_portable\app (own data folder), allowed by Donald for this audit. Remove: recycle.ps1 on C:\Users\donal\tools\vscode_portable; nothing is written outside it (no registry, no PATH).
2026-10-28 ADD (VS Code portable): extension pkief.material-icon-theme through vscode-mcp install_extension, to test the tool.
2026-10-28 REMOVED (VS Code portable): pkief.material-icon-theme through uninstall_extension; its folder is deleted at VS Code's next start (verify then).
2026-10-28 ADD (Windows, per-user, no admin): second unpack of the same VS Code zip to C:\Users\donal\tools\vscode_portable\app_sandbox (no data folder), to be mapped read-only into the Windows Sandbox. Inside tools\vscode_portable, so removed with it.
2026-10-28 ADD (Windows, admin via run-as-admin, Donald's go): optional feature Containers-DisposableClientVM (Windows Sandbox), enabled with -NoRestart; takes effect after a restart (his timing). Remove: Disable-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM via run-as-admin, then restart (done this way on 2026-10-16 15:33). Verify: Get-WindowsOptionalFeature State = Disabled.
2026-10-28 ADD (Windows Sandbox, disposable): esbenp.prettier-vscode 12.4.0 through vscode-mcp-sandbox install_extension, twice (once into the CLI's default folder by the bug fixed in vscode-mcp b8e4143, once into C:\vsext); written after the fact; nothing survives closing the sandbox.
2026-10-28 ADD (Windows Sandbox, disposable): ritwickdey.LiveServer through vscode-mcp-sandbox install_extension, after static triage (own code clean). Remove: close the sandbox.
2026-10-28 ADD (Windows Sandbox, disposable): PKief.material-icon-theme, twxs.cmake, formulahendry.code-runner through vscode-mcp-sandbox install_extension, after static triage (tools\triage.ps1, nothing run). Remove: close the sandbox.
2026-10-28 REMOVED (Windows Sandbox closed, his word "do your own closing/opening"): all five extensions of batch 1 (Live Server, Prettier, Code Runner, CMake, Material Icon Theme) were discarded with the sandbox; the host forwarder (forward.js) was stopped.
2026-10-28 ADD (Windows Sandbox, disposable, batch 2): formulahendry.auto-rename-tag, mechatroner.rainbow-csv, christian-kohler.path-intellisense, EditorConfig.EditorConfig, aaron-bond.better-comments through vscode-mcp-sandbox install_extension, after static triage (tools\triage.ps1, nothing run). Remove: close the sandbox.
2026-10-28 ADD (Windows Sandbox, disposable, batch 3, same sandbox as batch 2): yzhang.markdown-all-in-one, DavidAnson.vscode-markdownlint, usernamehw.errorlens, Gruntfuggly.todo-tree, redhat.vscode-yaml through vscode-mcp-sandbox install_extension, after static triage. Remove: close the sandbox.
2026-10-28 ADD (Windows Sandbox, disposable, batch 4, same sandbox): HookyQR.beautify, DotJoshJohnson.xml, mikestead.dotenv, alefragnani.project-manager, oderwat.indent-rainbow through vscode-mcp-sandbox install_extension, after static triage. Remove: close the sandbox.
2026-10-28 ADD (Windows Sandbox, disposable, batch 5, same sandbox): tamasfe.even-better-toml, shardulm94.trailing-spaces, mohsen1.prettify-json, alefragnani.Bookmarks, ZainChen.json through vscode-mcp-sandbox install_extension, after static triage. Remove: close the sandbox.
2026-10-28 ADD (Windows Sandbox, disposable, batch 6, same sandbox): wayou.vscode-todo-highlight, formulahendry.auto-complete-tag (an extension pack: also pulls formulahendry.auto-close-tag, triaged too), sidthesloth.html5-boilerplate, bierner.markdown-mermaid, codezombiech.gitignore through vscode-mcp-sandbox install_extension, after static triage. Remove: close the sandbox.
2026-10-28 ADD/REMOVED (Windows Sandbox, disposable, BULK run, tools\bulk_live.js): about 270 extensions of the top-300 list (see data\bulk_live_2026_10_28.tsv and data\bulk_live_retry_2026_10_28.tsv for ids), installed in groups and uninstalled again by the runner after each group (leftovers checked: Dart-Code.dart-code stayed once and was cleaned by --clean); three sandboxes were used and closed; the sandbox firewall is now switched off by tools\sandbox\start_vscode.ps1 inside the sandbox only. Everything is discarded when the sandbox closes.
2026-10-28 ADD (Windows Sandbox, disposable, batch 7, same sandbox): vscodevim.vim, jeff-hykin.better-cpp-syntax, naumovs.color-highlight, tomoki1207.pdf, techer.open-in-browser through vscode-mcp-sandbox install_extension, after static triage. Remove: close the sandbox.

2026-10-28: bulk live smoke test of 180 quiet extensions (ranks 301-2000, no EXEC/NET/CRED/BIN/HOSTS/EVAL flags) in the Windows Sandbox via bulk_live.js; scope: sandbox only, discarded on close; removal: automatic (--clean) and sandbox close.

2026-10-28: bulk live smoke test of about 992 flagged extensions (ranks 301-2000; excluded: NOCODE and the 129 with HOSTS+CRED+BIN) in the Windows Sandbox via bulk_live.js; scope: sandbox only, discarded on close; removal: automatic (--clean) and sandbox close.

2026-10-28 correction: the run of 992 flagged extensions was stopped by Donald's decision after about 385 (activation-only smoke tests, not recorded in RESULTS.tsv). About 64 of those extensions are still installed in the running sandbox (some blocked from uninstalling by dependencies); they vanish when the sandbox closes. From here on extensions are tested one at a time, by exercising their features.

2026-10-28 (Donald: run it in the editor, no sandbox): tests now run in the portable VS Code at tools\vscode_portable\app (data inside it), work folder tools\vscode_portable\work, vscode-mcp 0.4.0 loaded with --extensionDevelopmentPath. Extensions are installed there one at a time via install_extension and each is uninstalled, the window reloaded and data\extensions checked clean afterwards; removal lines follow each test.
2026-10-28 removal: njpwerner.autodocstring 0.6.1 uninstalled from the portable VS Code, window reloaded, extensions list shows only dpc00.vscode-mcp; folder marked obsolete in data\extensions\.obsolete, deleted by VS Code at its next start.

2026-10-28: install in the portable VS Code (one by one, with a file of the right language open): tht13.python, Syler.sass-indented, hzgood.dart-data-class-generator, to re-check activation errors seen in the sandbox smoke test. Removal follows.
2026-10-28 removal: tht13.python, Syler.sass-indented, hzgood.dart-data-class-generator uninstalled from the portable VS Code (marked obsolete; VS Code deletes the folders at its next start).

2026-10-28: install cschlosser.doxdocgen in the portable VS Code (full feature test, C/C++ declarations). Removal follows the test.
2026-10-28 removal: cschlosser.doxdocgen 1.4.0 uninstalled from the portable VS Code, window reloaded, extensions list shows only dpc00.vscode-mcp (folder marked obsolete, deleted at next start).

2026-10-28: install KevinRose.vsc-python-indent in the portable VS Code (full feature test of the Enter-key indentation). Removal follows the test.
2026-10-28 removal: KevinRose.vsc-python-indent 1.21.0 uninstalled from the portable VS Code, window reloaded, extensions list shows only dpc00.vscode-mcp (folder marked obsolete, deleted at next start).

2026-10-28: install streetsidesoftware.code-spell-checker in the portable VS Code (full feature test through diagnostics). Removal follows the test.
2026-10-28 removal: streetsidesoftware.code-spell-checker 4.10.0 uninstalled from the portable VS Code, window reloaded, extensions list shows only dpc00.vscode-mcp (folder marked obsolete, deleted at next start).

2026-10-28: install streetsidesoftware.code-spell-checker and streetsidesoftware.code-spell-checker-german in the portable VS Code again (the untested parts: cspell config files, dictionaries, user settings, multi-root, large files, navigation commands). Removal follows.
2026-10-28 removal: streetsidesoftware.code-spell-checker-german 3.0.1 and streetsidesoftware.code-spell-checker 4.10.0 uninstalled from the portable VS Code (dictionary first, it depends on the base), window reloaded, extensions list shows only dpc00.vscode-mcp. The portable's user settings.json created for the user-level tests and recycled; test folders in the work folder recycled.

2026-10-28: install streetsidesoftware.code-spell-checker in the portable VS Code once more (reproduce the invalid minWordLength turning checking off, in workspace settings and cspell.json, before filing). Removal follows.
2026-10-28 removal: streetsidesoftware.code-spell-checker 4.10.0 uninstalled again, window reloaded, extensions list shows only dpc00.vscode-mcp.

2026-10-28: install yzhang.markdown-all-in-one in the portable VS Code (full feature test: TOC, section numbers, list editing, table formatter, toggles, checkboxes; the earlier row was a one-check smoke test). Removal follows the test.
2026-10-28 removal: yzhang.markdown-all-in-one 3.6.3 uninstalled from the portable VS Code, window reloaded, extensions list shows only dpc00.vscode-mcp. No user settings or config files were created outside the work folder.

2026-10-28: install yzhang.markdown-all-in-one in the portable VS Code once more (paste link on a selection, which needs the clipboard; Donald said the clipboard is fine to use). Removal follows.
2026-10-28 removal: yzhang.markdown-all-in-one 3.6.3 uninstalled again, window reloaded, extensions list shows only dpc00.vscode-mcp. The clipboard was saved before the paste tests and restored after.

2026-10-28: install esbenp.prettier-vscode in the portable VS Code (full feature test: formatting of js/ts/json/css/md/yaml/html, settings, .prettierrc, .prettierignore, range format, errors; the earlier row was a smoke test). Removal follows.
2026-10-28 removal: esbenp.prettier-vscode 12.4.0 uninstalled from the portable VS Code, window reloaded, extensions list shows only dpc00.vscode-mcp. Test config files lived only in subfolders of the work folder; the work folder's settings were reset.

2026-10-28: install redhat.vscode-yaml in the portable VS Code (full feature test: diagnostics, schema validation with local schemas, completion, hover, formatter settings, folding, symbols; the earlier row was a smoke test). Removal follows.
2026-10-28 removal: redhat.vscode-yaml 2.0.0 uninstalled from the portable VS Code, window reloaded, extensions list shows only dpc00.vscode-mcp. The folder stays on disk marked obsolete in .obsolete (VS Code deletes it at the next restart, same as the earlier ones). Work folder settings reset; test files only in the work folder. No bug found.

2026-10-28: install tamasfe.even-better-toml in the portable VS Code (full feature test: diagnostics, formatter settings, schema, completion, hover, folding; the earlier row was a smoke test). Removal follows.
2026-10-28 removal: tamasfe.even-better-toml 0.21.2 uninstalled from the portable VS Code, window reloaded, extensions list shows only dpc00.vscode-mcp (folder stays on disk marked obsolete until the next restart). Work folder settings reset; my test taplo.toml went to the Recycle Bin. Filed taplo#894.

# ms-vscode.live-server — serverRoot breaks the server, and hostIP "0.0.0.0" serves 401 to everyone

Status: filed — https://github.com/microsoft/vscode-livepreview/issues/893 (serverRoot); the
hostIP evidence went in as a comment on the existing
https://github.com/microsoft/vscode-livepreview/issues/333 rather than as a duplicate.

Found 2026-11-18 on `ms-vscode.live-server` 0.4.20, portable VS Code 1.146.0, single-folder
workspace `C:\Users\donal\tools\vscode_portable\work` containing `liveprobe\index.html`,
`liveprobe\sub\page2.html` and `liveprobe\style.css`.

## 1. `livePreview.serverRoot` makes the server serve nothing

Its description: *"The relative path from the workspace root that the files are served from.
Files will be previewed as if the workspace root is at this relative path. If this directory path
doesn't exist in your workspace, it will default to the workspace root."*

A/B, each with `workbench reload` so the host re-reads the setting, then `livePreview.start`:

| setting | `GET /` | `GET /index.html` | `GET /liveprobe/index.html` |
| --- | --- | --- | --- |
| absent | 200, listing titled `Index of /` | 404 (file really is in the subfolder) | 200 |
| `"serverRoot": "liveprobe"` | 404, page titled **No Server Root** | 404, resolved path `"\index.html"` | 404, resolved path `"\liveprobe\index.html"` |
| `"serverRoot": "/liveprobe"` | 404, **No Server Root** | 404, `"\index.html"` | 404, `"\liveprobe\index.html"` |

Every request resolves against the drive root (`\…`) instead of the workspace, so nothing is
served; the preview panel opens on a page it cannot load. Both spellings of the value break it, and
the folder does exist, so the documented fallback ("default to the workspace root") does not
apply — the setting is simply unusable here.

Code, from the shipped bundle (`out/extension.js`):

```js
static async GetValidServerRootForWorkspace(e) {
  const t = u.SettingUtil.GetConfig(e).serverRoot;
  return (await d.FileExistsStat(c.join(e.uri.fsPath, t))).exists ? t : "";
}
```

so the value is kept verbatim (relative, and never prefixed with the workspace folder) and handed
to the connection as `_rootPrefix`; the request handler then serves `createNoRootServer()` for `/`
when the resolved root is empty.

## 2. `hostIP: "0.0.0.0"` binds every interface but answers 401 to every client

Its description: *"The local IP host address to host your files on."* The handler checks the Host
header against the configured value:

```js
if (t.headers.host !== v || (t.headers.origin && t.headers.origin !== `${h.scheme}://${v}`)) return void d(401);
```

Measured with `portNumber: 4123`, hostIP `0.0.0.0`:

| request | result |
| --- | --- |
| `GET http://127.0.0.1:4123/` | **401** |
| `GET http://10.0.0.56:4123/` (the machine's LAN address) | **401** |
| `GET http://0.0.0.0:4123/` with `Host: 0.0.0.0:4123` (curl `--connect-to` to loopback) | 200 |

`netstat` shows `0.0.0.0:4123 LISTENING`, so the bind is right; the allow-list makes the server
answer only to a request whose Host is literally `0.0.0.0:4123`, which no browser or other machine
sends. Setting `hostIP` to the machine's own address works as expected: with `10.0.0.56` the server
listens on `10.0.0.56:4123`, `GET http://10.0.0.56:4123/` is 200, `127.0.0.1:4123` refuses
(nothing bound there), and the `httpHeaders` probe arrived (`X-Audit-Probe: live-preview-4123`).

The trap is that `0.0.0.0` is the obvious value for "serve to my LAN", and it produces a server that
is bound to everything and usable from nowhere.

## 3. Minor: ~60 configuration-scope warnings per activation

`exthost.log` gets, on activation, one warning per setting of the form

```
[ms-vscode.live-server] Accessing a window scoped configuration for a resource is not expected.
To associate 'livePreview.portNumber' to a resource, define its scope to 'resource' in
configuration contributions in 'package.json'.
```

for every key in the section (and `Accessing a resource scoped configuration without providing a
resource` for `serverRoot` / `defaultPreviewPath`). `SettingUtil.GetConfig(uri)` reads the whole
section with a resource, while only two keys are `scope: resource`.

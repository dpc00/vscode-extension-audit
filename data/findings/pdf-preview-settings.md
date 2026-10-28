# tomoki1207.pdf — the five "PDF Preview" defaults do nothing

Status: filed — https://github.com/tomoki1207/vscode-pdfviewer/issues/223 (scrollMode; it carries
the shared cause), with the rest of the family already upstream: #75 (scale, initial-open evidence
added as a comment), #177 (spreadMode), #187 and #79 (sidebar).

Found 2026-11-18 while auditing `tomoki1207.pdf` 1.2.2 on portable VS Code 1.146.0
(vscode-mcp 0.9.7).

## What the extension promises

`package.json` → `contributes.configuration` ("PDF Preview"):

| key | default | effect promised |
| --- | --- | --- |
| `pdf-preview.default.cursor` | `select` | cursor tool on load (`hand` or `select`) |
| `pdf-preview.default.scale` | `auto` | `auto`, `page-actual`, `page-fit`, `page-width`, or a scale number |
| `pdf-preview.default.sidebar` | `false` | sidebar shown on load |
| `pdf-preview.default.scrollMode` | `vertical` | `vertical`, `horizontal`, `wrapped` |
| `pdf-preview.default.spreadMode` | `none` | `none`, `odd`, `even` |

## What happens (measured)

Each setting was put in `app\data\user-data\User\settings.json`, the app was given 3–5 s to
reload configuration, and the PDF was opened through `vscode.openWith` on a path that had **never
been opened before** — pdf.js keeps its own per-fingerprint view history in the webview's
localStorage and the extension fakes the fingerprint from the file path, so a reused path replays
the old view and proves nothing.

| setting | value tested | observed |
| --- | --- | --- |
| `default.scale` | `page-actual`, `0.5`, `page-width` | zoom select reads "Automatic Zoom" every time |
| `default.scrollMode` | `horizontal` | page groups still at the same x, y = 203 / 1248 / 2293 (vertical) |
| `default.spreadMode` | `odd` | page groups still stacked, not paired side by side |
| `default.sidebar` | absent (default `false`), then `true` | sidebar with "Thumbnail of Page 1..3" present in **both** cases, including after a full window reload with the key absent |
| `default.cursor` | — | not exercised: it only sets a CSS cursor, which neither vscode-mcp nor the UIA tree exposes |

Numbers come from the UIA bounds of the `group "Page 1..3"` nodes, so the layout claims are
measurements, not impressions.

## Cause, read from the installed code

`lib/main.js` applies every default inside a handler for pdf.js's `documentloaded`:

```js
PDFViewerApplication.eventBus.on('documentloaded', optsOnLoad)
// optsOnLoad: pdfCursorTools.switchTool(...), pdfViewer.currentScaleValue = defaults.scale,
//             pdfViewer.scrollMode = ..., pdfViewer.spreadMode = ..., pdfSidebar.open()/close()
```

`documentloaded` is dispatched from `firstPagePromise` (`lib/web/viewer.js:1649`), i.e. **before**
the viewer's own initial view is applied. `pagesPromise.then(...)` then runs
`pdfViewer.currentScaleValue = pdfViewer.currentScaleValue; this.setInitialView(hash)`
(`viewer.js:1777-1779`), and `setInitialView` re-applies the stored/AppOptions values for scroll
mode, spread mode and — through the `pdfViewer` defaults — scale. The sidebar is the same story
in reverse: the handler closes it, the later initial view opens it again.

Fix shape for a patch (not submitted, this repo takes no PRs from here): apply the defaults on a
later event (`pagesinit`, or `documentloaded` plus a `setTimeout(0)`), or set
`AppOptions.set('defaultScale', …)` / `('scrollModeOnLoad', …)` / `('spreadModeOnLoad', …)` /
`('sidebarViewOnLoad', …)` before `PDFViewerApplication.initialize()` runs, which is what pdf.js
consults at the end of its own init.

## What is not a defect in this round

* The internal link on page 1 did not navigate: the fixture was printed by headless Chrome, which
  emits `/Dest /beta` while its own `/Dests` name tree only holds `node0000001x` names — the
  destination is dangling in any reader.
* The viewer's Open / Print / Download buttons were not clicked (native dialogs, out of scope for
  a display test).

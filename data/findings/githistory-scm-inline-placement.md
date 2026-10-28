Status: not filed - the observation is real but not decidable in this rig, so it is not a defect claim.

# Git History (donjayamanne.githistory 0.6.20): sourceCodeProviderIntegrationLocation has no visible "Inline" placement at the sidebar width used

## What the documentation promises
`package.json` → `contributes.configuration.properties["gitHistory.sourceCodeProviderIntegrationLocation"]`:

* `"Inline"` (default): *"Show the 'Git: View History' action on the title of SCM Providers"*
* `"More Actions"`: *"Show the 'Git: View History' action in the 'More Actions...' menu on the title of SCM Providers"*

and `contributes.menus["scm/title"]` binds `git.viewHistory` twice, each guarded by one of the two values.

## What was observed (VS Code 1.146.0, portable rig, 2026-11-17)
* Setting `"gitHistory.sourceCodeProviderIntegrationLocation": "Inline"` in workspace settings, the Source Control view's provider row for `gh_probe` contained exactly three toolbar buttons - `main, Checkout Branch/Tag...`, `Publish to GitHub`, `More Actions...` - and **no** `Git: View History` button.
* The action was present one level down, inside the provider's `More Actions...` menu, labelled `Git View History (git log)`.
* Repeating with `"gitHistory.sourceCodeProviderIntegrationLocation": "More Actions"` produced the same three buttons in the toolbar.

## Why this is not filed
VS Code demotes overflowed title actions into the `...` menu, and the sidebar was ~250 px wide for both readings, so "Inline" and "More Actions" cannot be told apart at that width: the same menu item is where an overflowed Inline action and a deliberately menu-placed action both end up. Deciding it needs the sidebar sash dragged wide (a mouse drag the harness cannot issue) or a second datapoint at a wider default.

## What would settle it
With the sidebar dragged to ~600 px, `"Inline"` should add a `Git: View History` toolbar button next to `Publish to GitHub`, and `"More Actions"` should not.

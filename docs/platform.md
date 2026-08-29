# Platform notes

Everything an agent needs about the Omarchy plugin system, in one place, so nobody
re-derives it from the web mid-task. **Verified 2026-08-27 against `basecamp/omarchy@quattro`.**

If a fact here contradicts the machine you're on, the machine wins — fix this file.

## The model

Omarchy Quattro runs one long-lived Quickshell process, `omarchy-shell`. The bar, panels,
overlays, the lock screen, and headless services are all plugins inside it. There is no
second process, and you must not create one.

| Where | What lives there |
|---|---|
| `$OMARCHY_PATH/shell/plugins/` | First-party plugins, flagged `__isFirstParty: true` |
| `~/.config/omarchy/plugins/<id>/` | Everything you install or write |
| `~/.config/omarchy/shell.json` | Bar layout + enabled state + per-widget settings |

Both locations are discovered identically at startup. Files under
`~/.config/omarchy/plugins/` hot-reload on change — you edit, the shell picks it up.

## Kinds

| Kind | `entryPoints` key | Conventional file | What it is |
|---|---|---|---|
| `bar-widget` | `barWidget` | `BarWidget.qml` | An item in the active bar |
| `panel` | `panel` | `Panel.qml` | Floating surface, persistent or summoned |
| `overlay` | `overlay` | `Overlay.qml` | Fullscreen surface |
| `menu` | `menu` | `Menu.qml` | Summoned menu |
| `service` | `service` | `Service.qml` | Headless singleton, no UI |
| `bar` | `bar` | `Bar.qml` | Replaces the built-in bar entirely |

A plugin may declare several. `omarchy.media` is both `service` and `bar-widget`.

## Manifest

Required: `schemaVersion`, `id`, `name`, `version`, `kinds`, `entryPoints`.
The marketplace additionally wants `author`, `description`, and a `license` file.

Real first-party manifest, `omarchy.clock`:

```json
{
  "schemaVersion": 1,
  "id": "omarchy.clock",
  "name": "Clock",
  "version": "1.0.0",
  "author": "Omarchy",
  "description": "Date/time label with a calendar popup",
  "kinds": ["bar-widget"],
  "entryPoints": { "barWidget": "BarWidget.qml" },
  "barWidget": {
    "displayName": "Clock",
    "description": "Date/time label with a calendar popup",
    "category": "Time",
    "allowMultiple": false
  }
}
```

The `barWidget` block is what the widget picker shows. `defaultSection` and
`allowMultiple` also live there.

**Our namespace is `brownfamilysports.*`.** `omarchy.*` is reserved and the validator
rejects it.

## Validation rules

The validator checks: JSON parses; `schemaVersion` is understood; required fields are
present; the id is not in the reserved namespace; every declared kind has an entry point;
every referenced path exists and is a safe relative path; **no symlinks anywhere inside
the plugin folder**.

(The plugin *directory* itself may be a symlink — that's how `bin/dev-link` works, and
removal explicitly "unlinks symlinks". The prohibition is on symlinks *within*.)

## Commands

```bash
omarchy plugin list [--json]
omarchy plugin add <git-url> [--enable]
omarchy plugin enable|disable <id>
omarchy plugin update [<id>]
omarchy plugin remove <id>
omarchy plugin validate <path>
omarchy plugin clone omarchy.clock --edit    # best way to learn; copies to <user>.<name>

omarchy-shell shell summon <id> '{}'
omarchy-shell shell hide <id>
omarchy-shell shell rescanPlugins

qmllint -I "$OMARCHY_PATH/shell" BarWidget.qml
```

`omarchy plugin add` clones to staging, validates, refuses on id collision, then moves
into place. It never executes anything from the plugin and never asks for sudo. `update`
is a fast-forward pull that shows a diff, refuses on local changes, and rolls back if
validation fails.

## QML idioms

From `shell/plugins/panels/clock/BarWidget.qml`:

```qml
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons        // Style, and other shared singletons
import qs.Ui             // BarWidget, WidgetButton, OpticalGlyph, ...

BarWidget {
  id: root
  moduleName: "brownfamilysports.example"   // must equal the manifest id
  ...
}
```

Things the base type gives you, observed in use:

- `bar` — the host bar. `bar.run("<cmd>")` executes a shell command; `bar.shell.updateEntryInline(id, entry)` persists a settings change.
- `settings` / `setting(key, default)` — per-instance config out of `shell.json`.
- `vertical` — true in a side bar. Handle it.
- `broadcast(name)` — notify other instances.
- `implicitWidth` / `implicitHeight` — you set these from your content.

`WidgetButton` supplies `foreground`, `fontFamily`, `fontSize`, `labelWidth`,
`tooltipText`, and an `onPressed(button)` that hands you `Qt.LeftButton` /
`Qt.RightButton` / `Qt.MiddleButton`.

`Style` supplies `Style.space(n)` and `Style.bar.iconSlot`. Use them instead of numbers.

### Popup contract

`Bar.findPanelWidget` requires `opened`, `open()`, `close()` on the bar-widget root for
`shell summon` / `hide` / `toggle` routing to work. The clock forwards all three into a
`Loader`-hosted `Panel.qml`, plus `closeForPopoutSwitch()` and `popoutSwitchClosing` so
the bar can swap one popout for another cleanly.

Don't hand-roll a panel. Run `omarchy plugin clone omarchy.clock --edit` and lift
`Panel.qml` — it's the sanctioned way to learn the surface, and it's already correct.

## Verified gotchas

**One QML file per third-party plugin (verified 2026-08-29 on this box).** A
third-party plugin's panel/overlay/menu entry point — or any second `.qml`
loaded from its directory — fails to load with a QML `File name case mismatch`
error, even for a minimal `Item {}`. Reproduced through the dev-link symlink,
through a real directory copy, and under a different file name; the bar-widget
entry loads fine through `BarWidgetRegistry` the whole time. Compounding it,
the shell's panel-loader error path crashes on a bare `errorString`
(`shell.qml` ~645, `ReferenceError`), so the real load error never reaches the
log. Until both are fixed upstream: ship third-party plugins as a SINGLE
`BarWidget.qml` and let it own its `PanelWindow` overlay directly — which also
turns summon routing into plain function calls. Tracked in this repo's issues.

## First-party coverage (don't rebuild these)

`bar` `image-picker` `emojis` `clipboard` `reminders` `menu` `notifications` `audio`
`bluetooth` `clock` `monitor` `network` `power` `tailscale` `agents` `weather` `media`
`battery` `idle` `nightlight` `lock` `osd` `polkit` — plus panels for `disk-speedtest`,
`dropbox`, `speedtest`, `wifiqr`. `omarchy.theme-switcher` is listed as coming soon.

## Distribution

One plugin, one public git repo, `manifest.json` at the repo root. There is no
subdirectory support — this is why this lab graduates plugins out to their own repos.

Users install with `omarchy plugin add https://github.com/<owner>/<repo>.git --enable`.

## The marketplace

Community directory at <https://omarchyplugins.com>, run by HANCORE
(`HANCORE-linux/omarchy-plugin-marketplace`), MIT, not affiliated with Omarchy or
37signals. Listing is via a GitHub issue template: `submit-plugin.yml`. Automated
validation runs against the current commit, then a maintainer approves.

The marketplace validates listings, not security. Our README carries the disclosure —
see rule 10 in `TASTE.md`.

**As of 2026-08-29 the registry lists 500+ community plugins** — it was zero on
2026-08-27, which is the best proof this file will ever offer for its own
re-verification rule. Omarchy ran its first plugin competition in August 2026
($2.5k/$1k/$500, judged by the Omarchy Core team; listed plugins were
automatically eligible). The distribution playbook for our plugins lives in
`omarchy-terminal-delight-theme/docs/DISTRIBUTION.md`.

## Re-verifying this file

```bash
gh api repos/basecamp/omarchy/contents/shell/plugins/README.md?ref=quattro \
  --jq '.content' | base64 -d
gh api repos/basecamp/omarchy/contents/shell/plugins/panels/clock/BarWidget.qml?ref=quattro \
  --jq '.content' | base64 -d
```

Once a workstation has Omarchy on it, prefer the local copy at `$OMARCHY_PATH/shell/`.
It's the version you're actually running.

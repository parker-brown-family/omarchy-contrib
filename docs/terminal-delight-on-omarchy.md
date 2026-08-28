# terminal-delight on Omarchy

Verified 2026-08-27 against `basecamp/omarchy@quattro` and `Software/terminal-delight`
at HEAD.

## What this is not

**Not a port.** terminal-delight is gpui/wgpu on Wayland; Omarchy is Arch + Hyprland +
Wayland. It runs there today. Nothing is being ported.

**Not a Quickshell plugin.** Quickshell renders its own QML into layer-shell surfaces.
Wayland has no XEmbed — a client cannot hand its surface to another client's scene graph
— so no plugin can host a terminal emulator, ours or anyone's. A plugin that knows *about*
terminal-delight is possible and interesting; a plugin that *is* terminal-delight is not.

The integration surface is the **theme system**, and it turns out to be an unusually good
fit.

## Why the fit is good

Omarchy's theme flow: a theme ships `colors.toml`, `omarchy-theme-set <name>` renders
`default/themed/*.tpl` against that palette into
`~/.local/state/omarchy/current/theme/`, then runs `post_theme_commands` to retint every
running app.

Two things fall out that are worth saying out loud, because they're the argument for
upstreaming this.

**1. terminal-delight retints without a restart.** `theme::init` polls the theme file's
mtime every 300ms on a resolved *path*, then reparses and calls `bump_theme_gen` +
`refresh_windows`:

```rust
let mut last = mtime(&path);
cx.spawn(async move |cx| loop {
    cx.background_executor().timer(Duration::from_millis(300)).await;
    let now = mtime(&path);
    if now != last { /* reparse, bump, refresh */ }
})
```

Because it re-stats the path rather than watching an inode, it survives the staging-dir
`mv` that `omarchy-theme-set` does. Every other terminal in `post_theme_commands` needs
`omarchy-restart-terminal`. This one needs no entry at all — write the file, and within
300ms the running terminal has already changed colour.

**2. terminal-delight's theme file is pure data.** `INSTALLED_THEME_DENIED` exists because
`alacritty.toml`, `foot.ini`, `ghostty.conf` and `kitty.conf` each name the program the
terminal launches, so a theme cloned from a stranger's repo can't be allowed to ship one.
terminal-delight's `ThemeFile` is `name`, `icon`, `[colors]`, `[effects]`, `[font]` — no
command, no shell, no exec surface anywhere. It's the one terminal whose theme file is
colour-only and therefore safe to stage from an installed theme.

That's a real, checkable claim, and it's the sentence the upstream PR opens with.

## Palette mapping

Omarchy's canonical palette is semantic and named (confirmed against
`themes/tokyo-night/colors.toml`); the `colorN` names are legacy fallbacks.

| terminal-delight | Omarchy `colors.toml` | Note |
|---|---|---|
| `colors.bg` | `background` | |
| `colors.surface` | `lighter_background` | dark themes; see the `mode` caveat below |
| `colors.text` | `foreground` | |
| `colors.accent` | `accent` | falls back to `color4` when absent |
| `colors.faint` | `muted` | |
| `colors.cursor` | `bright_foreground` | the theming doc is explicit: terminal cursors use this |
| `colors.human` | *(omit)* | td derives it from the accent's bright complement |
| `ansi[0]` | `darker_background` | |
| `ansi[1..7]` | `red` `green` `yellow` `blue` `magenta` `cyan` `foreground` | |
| `ansi[8]` | `muted` | the doc states `muted` also serves as ANSI `color8` |
| `ansi[9..15]` | `bright_*` + `bright_foreground` | |

The ready-to-use template is at
[`../templates/omarchy-theme/terminal-delight.toml.tpl`](../templates/omarchy-theme/terminal-delight.toml.tpl).

## One open problem

It's real and it's worth solving before the upstream PR, not after.

### The `[effects]` stomp

`FileEffects` is `#[serde(default)]` with every field `Option`. A generated file that
carries only `[colors]` resets scanlines, bloom, curvature, flicker — terminal-delight's
whole visual identity — to defaults on every theme switch. Baking an `[effects]` block
into the template is worse: it means Omarchy decides how much CRT you get.

The right fix is in terminal-delight, not in the template: **separate palette from
identity.** A `$TD_PALETTE` overlay, read on top of the active theme, so an external
system can own colour without owning the look. File this against terminal-delight before
writing the upstream PR — the PR is much weaker without it.

### Settled: palette coverage

Every key the template references was checked against all 22 first-party themes on
2026-08-27. All 22 define `accent`, `muted`, `lighter_background`, `darker_background`,
`bright_foreground`, and all six `bright_*` hues. No gaps, no derived fallbacks needed.

Re-run if Omarchy adds themes:

```bash
for t in $(gh api repos/basecamp/omarchy/contents/themes?ref=quattro --jq '.[].name'); do
  c=$(gh api "repos/basecamp/omarchy/contents/themes/$t/colors.toml?ref=quattro" --jq '.content' | base64 -d)
  for k in bright_red bright_green bright_yellow bright_blue bright_magenta bright_cyan \
           bright_foreground lighter_background darker_background muted accent; do
    printf '%s' "$c" | grep -q "^$k *=" || echo "$t missing $k"
  done
done
```

Light themes (`catppuccin-latte`, `flexoki-light`, `white`, and anything with
`mode = "light"`) still want an eyeball. The neutral ramp inverts in light mode, so
`lighter_background` as `surface` is one step along the ramp in both directions — correct
in principle, unverified in practice.

## The path, in three tiers

### Tier 0 — works today, nothing upstream

Two files and an env var. Do this on the new workstation the day Omarchy lands.

1. Drop the template at `~/.config/omarchy/themed/terminal-delight.toml.tpl`. The theming
   doc: user templates in that directory are processed before the built-ins and apply
   across every theme.
2. Export `TD_THEME=$HOME/.local/state/omarchy/current/theme/terminal-delight.toml`
   in the Hyprland/uwsm environment. `theme_path()` honours `$TD_THEME` first, and skips
   the first-run seed when it's set, so it won't clobber the generated file.
3. Switch themes. The terminal follows within 300ms, no hook, no restart.

That's the whole thing. If it doesn't work, the fault is in one of the two open problems
above, not in the approach.

### Tier 1 — upstream PR to `basecamp/omarchy`

Once Tier 0 has run for a week across all 22 themes:

- `default/themed/terminal-delight.toml.tpl`
- record it as colour-only in `test/shell.d/theme-staging-test.sh` — that test fails on
  any generated theme file that is neither denied nor recorded, so the decision has to be
  made explicitly
- **no** `post_theme_commands` entry, and say why in the PR body
- **no** `INSTALLED_THEME_DENIED` entry, and say why in the PR body

This is the highest-value thing in this document. A merged template in `basecamp/omarchy`
is worth more than any number of marketplace listings, and the two arguments above are the
kind a maintainer can verify in thirty seconds.

Requires terminal-delight to be installable first — see Tier 2.

### Tier 2 — packaging

Omarchy is Arch. An AUR `PKGBUILD` (`terminal-delight-bin` off a release tarball, plus a
`-git` VCS package) is the prerequisite for both the upstream template and any Install >
Terminal listing. The terminal menu currently offers Ghostty, Alacritty and Kitty; asking
to join that list is a conversation to have *after* the template merges and the package
has some install count behind it, not before.

## The actual plugin opportunity

Separate from all of the above, and this is what belongs in this lab.

terminal-delight has agent-aware rendering — `SyntaxScheme` with markers for callouts,
tool calls and structure, a distinct `human` colour for the operator's own input in a
Claude/Codex session. Omarchy ships `omarchy.agents` as a bar widget with a panel.

A `brownfamilysports.td-sessions` bar widget — live terminal-delight panes and their agent
state, click to focus the pane — sits exactly in the gap between those two, is genuinely
useful rather than decorative, and is the sort of thing that makes people install the
terminal to get the widget.

Score it through `docs/triage.md` like anything else. It does not get a pass for being
ours.

## Shipped from this gap: `brownfamilysports.td-palette` (2026-08-28)

The first plugin out of that gap is not the sessions widget — it is the painter.
terminal-delight grew a control socket (`$XDG_RUNTIME_DIR/terminal-delight/ctl-<pid>.sock`,
branch `feat/td-paint-mode`) and a PAINT mode: every pane overlays a glyph grid of the
theme tray's colour sets (🦇 ☢ 🤡 🌊 …); clicking a glyph recolours **that pane only**,
CRT identity untouched, persisted in the terminal's own per-pane state. The
`incubator/td-palette` bar widget is the doorbell: 🎨 in the tray, left-click paints the
active workspace's terminals (`terminal-delight ctl paint toggle`), middle paints
everywhere, right lowers every brush, and an `IpcHandler` gives keybinds the same verbs.

The division of labour is the Wayland-honest one from the top of this file: the shell
cannot paint into the terminal's surface, so the shell owns the *button* and the terminal
owns the *overlay*. The ctl client resolves "active workspace" against the Hyprland IPC
socket by window class + pid, which is also why the widget itself never needs to talk to
Hyprland at all.

## Sources

- `basecamp/omarchy@quattro:docs/theming.md`
- `basecamp/omarchy@quattro:bin/omarchy-theme-set` (`INSTALLED_THEME_DENIED`, `post_theme_commands`)
- `basecamp/omarchy@quattro:themes/tokyo-night/colors.toml`
- `Software/terminal-delight/app/src/theme.rs` (`ThemeFile`, `theme_path`, `init`)
- <https://learn.omacom.io/2/the-omarchy-manual/106/terminal>

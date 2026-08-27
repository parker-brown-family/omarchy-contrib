# Taste

The review gate. Nothing ships from this lab until it passes every rule below.

These aren't invented. They're read off the Omarchy source — `shell/plugins/` on the
`quattro` branch — and off the manual. Where a rule has a citation, the citation is the
authority; where it doesn't, it's a judgment call and says so.

---

## 1. One plugin, one job

`omarchy.clock` shows the date and opens a calendar. `omarchy.nightlight` shifts the
colour temperature. Every first-party plugin names itself in a noun and does that noun.

If your description needs the word "and" twice, you have two plugins. Split them.

## 2. Zero config, or it isn't done

The first-party plugins work the moment they're enabled. Settings exist — the clock reads
`format` out of `shell.json` — but they exist *on top of* a default that's already right.

> ```qml
> setting("format", "dddd HH:mm")
> ```
> — `shell/plugins/panels/clock/BarWidget.qml`

Ship the default first. If you cannot pick a sensible default, you don't understand the
problem well enough to ship. A settings panel is not a feature; it's a decision you
declined to make.

## 3. Colours come from the theme. Always.

Omarchy has a theme system and users switch themes constantly. A hardcoded hex is the
single loudest signal that a plugin was written by someone who doesn't use Omarchy.

Pull colour off the component you're given:

> ```qml
> color: button.foreground
> fontFamily: button.fontFamily
> ```

The image-picker docs put it flatly: *"Colors come from the central shell theme
singleton; there is no per-call override surface."*

`bin/verify` greps for `#rrggbb` literals and fails the build. Override only with a
comment explaining why, on the line above.

## 4. Spacing comes from `Style`, not from your eye

> ```qml
> Math.max(Style.space(10), Math.round(Style.bar.iconSlot * 0.55))
> ```

Magic pixel values break at other bar heights and in vertical bars. Use the tokens.

## 5. Handle the vertical bar

Every bar widget gets a `vertical` property. The clock keeps a whole second format ring
for it. If your widget only looks right horizontally, it's half-finished — a meaningful
share of Omarchy users run a side bar.

## 6. Never start a second Quickshell

The whole point of Quattro is one long-lived process. The manual is explicit that the
menu lives in-process "instead of starting a second Quickshell instance." Spawning
another one is an instant rejection, and so is a background daemon you didn't tell the
user about.

Shelling out for data is fine — that's what `Quickshell.Io.Process` is for. Shelling out
on a 1-second timer is not; you're spending someone's battery on your widget.

## 7. Speak the IPC contract

Bar widgets that own a popup expose `opened`, `open()`, `close()` on the root, and an
`IpcHandler` targeted at the plugin id:

> ```qml
> IpcHandler {
>   target: "omarchy.clock"
>   function toggle(): void { root.togglePanel() }
>   function open(): void   { root.open() }
>   function close(): void  { root.close() }
> }
> ```

This is what makes `omarchy-shell shell summon <id>` and a user's Hyprland keybind work.
Skip it and your plugin is mouse-only in a keyboard-first desktop.

## 8. Comments explain why, never what

The house style in the Omarchy source is prose. Real example, verbatim:

> ```qml
> // Left click reveals the calendar — asking "what is the date?" is what a
> // click on a clock means — right click walks the common label formats, and
> // middle click opens the timezone picker.
> ```

and:

> ```qml
> // A seconds label needs the clock to tick sixty times as often, and a
> // repaint a second is a price only the formats that print seconds pay.
> ```

That's the bar. Not `// set the format`. If a comment restates the line under it, delete
the comment. If a line took you twenty minutes to get right, say why in a sentence a
stranger can read.

## 9. Earn the click

Omarchy assigns left / right / middle click to three *different* meanings on one widget.
Users learn a bar widget by poking it. A widget that swallows two of three buttons is
leaving affordance on the table. Add a `tooltipText` that says what the non-obvious
buttons do.

## 10. Be honest about what you run

Plugins are unsandboxed. The manual: *"A plugin isn't a config file — it's code that runs
for as long as your session does, with everything your user account can reach."*

So the README says, near the top and in plain language: what it executes, what it reads,
what it sends over the network, and what it writes to disk. No network call the README
doesn't name. No telemetry, ever. Pin or vendor anything you don't control.

A plugin that touches the network needs a stated failure mode too — Wi-Fi drops and your
widget must not hang the shell.

---

## The ship checklist

Copy this into the graduation issue. Every line gets checked by hand, on hardware.

- [ ] `bin/verify <plugin>` passes clean — no warnings, not just no errors
- [ ] `omarchy plugin validate` passes
- [ ] `qmllint -I "$OMARCHY_PATH/shell"` silent on every `.qml`
- [ ] Works in a horizontal bar **and** a vertical bar
- [ ] Survives a theme switch with no restart, in a light theme and a dark one
- [ ] Click / Escape / `omarchy-shell shell summon` / `... hide` all behave
- [ ] Disable → re-enable, and shell restart, leave no orphan state
- [ ] `omarchy plugin remove` leaves nothing behind
- [ ] Idles at ~0% CPU. Check it. `top -p $(pgrep -f omarchy-shell)` for a minute.
- [ ] `README.md` states what it runs, reads, and sends (rule 10)
- [ ] `LICENSE` present (MIT unless there's a reason)
- [ ] `preview.png` — the actual widget in a real bar, in the default theme, not a mockup
- [ ] Version is a real semver and matches the git tag
- [ ] A stranger can go from `omarchy plugin add <url>` to working in one command

---

## Sources

- Omarchy Manual — Shell Plugins: <https://omarchy.org/manual/shell-plugins/>
- First-party plugin catalogue: `basecamp/omarchy@quattro:shell/plugins/README.md`
- Reference implementation read for this doc: `shell/plugins/panels/clock/BarWidget.qml`
- Marketplace dev guide: <https://omarchyplugins.com/develop.html>
- Marketplace publish guide: <https://omarchyplugins.com/publish.html>

Verified 2026-08-27 against the `quattro` branch. Re-verify before trusting a rule that
costs you real work — see `docs/platform.md` for the re-check procedure.

# Agent instructions — omarchy-lab

This repo builds Omarchy Quattro shell plugins. Read `docs/platform.md` before touching
QML; it holds the verified platform facts so you don't re-derive them from the web.
`TASTE.md` is the review gate and it is not advisory.

## Ground rules

**Don't guess at the API.** Quickshell + the Omarchy shell singletons (`qs.Ui`,
`qs.Commons`) are not in your training data in any reliable form. If you need to know what
`BarWidget` or `Style` exposes, read a real first-party plugin:

```bash
gh api repos/basecamp/omarchy/contents/shell/plugins/panels/clock/BarWidget.qml?ref=quattro \
  --jq '.content' | base64 -d
```

or, on a machine with Omarchy installed, `$OMARCHY_PATH/shell/plugins/`. A fabricated
property name looks exactly like a real one until it silently does nothing at runtime.

**Never write a plugin id outside `brownfamilysports.*`.** `omarchy.*` is reserved and the
validator rejects it.

**Never introduce a second Quickshell process, a background daemon, or a sub-second
timer.** See `TASTE.md` rule 6.

**Never hardcode a colour or a pixel spacing.** Rules 3 and 4. `bin/verify` fails on this.

**Never leave follow-up work in a code comment.** It becomes a GitHub issue with the
`follow-up` label and the falsifiable format — use `/escalate-issue`, or the
`follow-up.yml` template here.

## The loop

```
bin/idea "<title>"                 capture, 5 seconds, no design
bin/triage                         weekly; score, lane, or close
bin/new-plugin <slug> "<desc>"     scaffold into incubator/
bin/dev-link <slug>                symlink into ~/.config/omarchy/plugins, rescan
  ... edit; QML hot-reloads on save, no restart ...
bin/verify <slug>                  the gate — clean means zero warnings too
  ... a week of daily use ...
bin/graduate <slug>                own repo, tag, release, marketplace submission
```

Do not skip the week. A widget that's delightful on day one and noise on day four is the
most common failure mode here, and no test catches it.

## Verifying your own work

Claiming a plugin works means you ran it. Specifically:

1. `bin/verify <slug>` exits 0.
2. You saw it in a real bar, horizontal and vertical.
3. You switched themes with it running and nothing went the wrong colour.
4. `top -p $(pgrep -f omarchy-shell)` shows it idling near zero.

"Should work" is not a result. If you're on a machine without Omarchy, say so plainly and
stop at step 1 rather than implying the rest.

## Writing

QML comments explain **why**, in prose, the way the Omarchy source does. A comment that
restates the line beneath it gets deleted. See `TASTE.md` rule 8 for real examples from
the upstream codebase — match that register.

READMEs disclose what the plugin runs, reads, writes, and sends over the network. Plugins
are unsandboxed; that disclosure is the price of asking someone to install one.

## Layout

| Path | What |
|---|---|
| `TASTE.md` | the review gate |
| `docs/platform.md` | verified platform facts — the reference |
| `docs/triage.md` | backlog, scoring, stages, labels |
| `incubator/<slug>/` | WIP plugins; not published |
| `templates/<kind>/` | scaffolds used by `bin/new-plugin` |
| `bin/` | the whole toolchain, plain bash |

Published plugins are **not** in this repo. They graduate to
`parker-brown-family/omarchy-<slug>` because `omarchy plugin add` clones a repo root.

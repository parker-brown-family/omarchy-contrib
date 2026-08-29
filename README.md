# omarchy-lab

A workshop for [Omarchy](https://omarchy.org) Quattro shell plugins: where the ideas get
caught, scored, built, and — if they survive a week of daily use — pushed out to their own
repos and listed.

Published plugins don't live here. `omarchy plugin add` clones a repo root and expects
`manifest.json` there, so every shipped plugin gets its own repo. This is the place
before that.

## Published

| Plugin | id | What it does |
|---|---|---|
| [Terminal Paint](https://github.com/parker-brown-family/omarchy-td-palette) | `brownfamilysports.td-palette` | Per-tile terminal painting from the bar — Terminal Delight variants, saturate, fully keyboard-playable |

## In the incubator

Whatever is under [`incubator/`](incubator/) is unfinished by definition. Read it, don't
install it.

## The loop

```bash
bin/idea "gpu temp in the bar, colour-shifts when it's cooking"
bin/triage                                    # weekly: score, lane, or close
bin/new-plugin gpu-temp "GPU temperature at a glance"
bin/dev-link gpu-temp                         # live-reload against your running shell
bin/verify gpu-temp                           # the gate
bin/graduate gpu-temp                         # own repo, tag, release, listing
```

Ideas are GitHub issues, never a markdown list — see [`docs/triage.md`](docs/triage.md)
for the scoring rubric, the stages, and why the `lane:now` cap is two.

## The gate

[`TASTE.md`](TASTE.md) is the standard everything is measured against, read off the
Omarchy source rather than invented: one plugin does one job, it works with zero config,
colours come from the theme and never from a hex literal, spacing comes from `Style`, the
vertical bar is handled, there is exactly one Quickshell process, and the README says
plainly what the thing runs on your machine.

`bin/verify` enforces the mechanical half. The rest is a checklist you tick by hand, on
hardware.

## Setting up

```bash
bin/bootstrap-repo     # creates the GitHub repo and the label taxonomy; idempotent
```

You need `gh` and `jq` everywhere; `omarchy` and `qmllint` only on a machine running
Omarchy. `bin/verify` degrades gracefully off-Omarchy and tells you what it skipped.

## Reference

[`docs/platform.md`](docs/platform.md) — manifest schema, the six plugin kinds, the CLI,
the QML idioms, what the validator actually checks, and which plugins Omarchy already
ships so you don't rebuild one. Verified against `basecamp/omarchy@quattro`, with the
commands to re-verify it.

## License

MIT. Plugins carry their own.

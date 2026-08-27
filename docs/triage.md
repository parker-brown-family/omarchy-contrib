# Backlog and triage

Ideas are cheap and arrive at bad moments. The system has one job: catch an idea in five
seconds without derailing whatever you were doing, then decide about it later, on purpose.

**Every idea is a GitHub issue in this repo.** Not a markdown list, not a chat scrollback,
not a code `TODO`. Issues are searchable, assignable, linkable from a commit, and they
already feed the cross-repo `/followups` rollup.

## Capture (5 seconds, no thinking)

```bash
bin/idea "gpu temp in the bar, colour-shifts when it's cooking"
bin/idea "pomodoro widget" --kind bar-widget
```

Files an issue labelled `stage:idea`. That's the whole obligation. Don't design it, don't
estimate it, don't check whether it already exists — a duplicate costs less than a lost
idea, and triage merges duplicates for free.

## Triage (weekly, ~15 minutes)

```bash
bin/triage           # lists everything still labelled stage:idea
```

Score each one 1–3 on three axes, then subtract a cost tier. Write the numbers into the
issue as a comment so a future you can see the reasoning, not just the verdict.

**Pain** — how often does the absence of this hurt?
: 1 = a novelty. 2 = mildly annoying, occasionally. 3 = you work around it daily.

**Fit** — does this belong in the shell at all?
: 1 = belongs in a terminal app or a browser tab. 2 = plausible. 3 = the desktop is the
only place it makes sense, and Omarchy doesn't already ship it.

**Taste** — can it be zero-config and theme-native, per `TASTE.md`?
: 1 = needs a settings screen to be usable. 2 = one sensible default plus one knob.
3 = it has exactly one correct behaviour.

**Cost** — hours to a shippable v0.1.0, as a subtraction: `≤4h → 0`, `≤16h → 1`, `more → 2`.

```
score = Pain + Fit + Taste − Cost
```

| Score | Lane | What it means |
|---|---|---|
| 7–9 | `lane:now` | Build next. Cap the lane at **two** — WIP limits are the point. |
| 5–6 | `lane:next` | Real, not now. Revisit at the next triage. |
| 3–4 | `lane:someday` | Parked. No guilt, no rotting in your head. |
| ≤2 | close `wontfix` | Say why in one line, then close it. |

A `Fit` of 1 is an automatic close no matter what the total says. So is anything
duplicating a first-party plugin — check the coverage list in `docs/platform.md` first.

Ties break toward the smaller one. A shipped small plugin beats an unshipped good one.

## Stages

An issue carries exactly one `stage:` label and moves left to right.

```
stage:idea → stage:incubating → stage:polish → stage:published
```

| Stage | Where the code is | Exit condition |
|---|---|---|
| `stage:idea` | nowhere | survives triage with a lane |
| `stage:incubating` | `incubator/<name>/` | it works on your own machine, daily, for a week |
| `stage:polish` | `incubator/<name>/` | every box in the `TASTE.md` ship checklist is ticked |
| `stage:published` | its own repo + marketplace | listing is live |

Promotion out of `stage:polish` is `bin/graduate <name>`, which refuses to run until
`bin/verify` is clean.

The week of daily use in `stage:incubating` is not padding. It's the only reliable way to
find out that a widget you loved on day one is noise on day four.

## Labels

Created by `bin/bootstrap-repo`.

| Label | Meaning |
|---|---|
| `stage:idea` `stage:incubating` `stage:polish` `stage:published` | position in the pipeline |
| `lane:now` `lane:next` `lane:someday` | triage verdict |
| `kind:bar-widget` `kind:panel` `kind:overlay` `kind:menu` `kind:service` `kind:bar` | which manifest kind |
| `taste:risk` | flagged against a `TASTE.md` rule; must be resolved before graduation |
| `follow-up` | deferred work; feeds the cross-repo `/followups` rollup |
| `upstream` | belongs in `basecamp/omarchy`, not here — a PR, not a plugin |

`upstream` matters. Some of the best things you'll notice aren't plugins at all, they're
a fix to Omarchy itself. Sending those upstream is worth more than a widget, and it's how
you become a name in the project rather than a listing in a directory.

## Deferred work

Anything noticed and not fixed becomes its own issue with `follow-up`, following the
falsifiable format: what's wrong and where, proof it's real *today*, how to reproduce, the
check that would prove it **isn't** real, and what "done" looks like. Use `/escalate-issue`.

Never leave it in a code comment. A `TODO` in QML is a note to nobody.

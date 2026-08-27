# __NAME__

__DESC__

![__NAME__ in the Omarchy bar](preview.png)

## Install

```bash
omarchy plugin add __REPO__.git --enable
```

## Use

<!-- One short paragraph. What it shows, what each mouse button does, what the
     keybind is. If this section needs subheadings, the plugin does too much. -->

| Action | What happens |
|---|---|
| Left click | |
| Right click | |
| Middle click | |

## Configuration

None needed. It works as installed.

<!-- If you genuinely need a knob, document it here and keep the default right
     for someone who never reads this section. -->

| Key | Default | What it does |
|---|---|---|
| `refreshSeconds` | `30` | |

Set it in the widget's entry in `~/.config/omarchy/shell.json`.

## What this plugin does on your machine

Omarchy plugins run unsandboxed, inside your shell process, for as long as your session
lasts. So, plainly:

- **Runs:** <!-- every command it shells out to, or "nothing" -->
- **Reads:** <!-- files, sysfs paths, or "nothing" -->
- **Writes:** <!-- its entry in shell.json, and anything else -->
- **Network:** <!-- the exact hosts, or "none" -->
- **Telemetry:** none.

Read the source before you enable it. It's short.

## Uninstall

```bash
omarchy plugin remove __ID__
```

Leaves nothing behind.

## License

MIT — see [LICENSE](LICENSE).

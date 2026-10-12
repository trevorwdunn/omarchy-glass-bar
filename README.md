# Glass Bar for Omarchy

Turns the [Omarchy](https://omarchy.org) bar into a liquid-glass rod: a copy of the wallpaper behind the bar is bent at the rim and lit along the edge.

> **A note on how this was made:** I am not a software engineer or programmer. I built this with an AI assistant (Claude) for my own Omarchy setup and I am sharing it as is. It works on my machine; I cannot promise more than that. Issues and pull requests are welcome, but I may not be able to fix things myself.

**Status: experimental.** Tested on Omarchy 4.0.4 with Hyprland 0.56.2 only.

## How it works

Nothing can read the pixels behind a layer surface, so the widget draws its own copy of the wallpaper, lined up with the real one, and bends that with a shader. It only looks right where the wallpaper really is what sits behind it, which is true for the bar. The widget itself takes no room on the bar.

It can also make the bar's text bold, so labels stay readable against the glass.

## Install

```
omarchy plugin add https://github.com/trevorwdunn/omarchy-glass-bar --enable
```

The bar has to be transparent for the glass to show: set `"transparent": true` under `bar` in `~/.config/omarchy/shell.json`.

## Settings

Set in the widget's entry in `shell.json`: `glass`, `boldText`, `refraction`, `chroma`, `specular`, `tint`. See `manifest.json` for ranges and defaults.

## Known limits

- The glass shows the wallpaper only. A window is never behind the bar, but anything else that draws there would not be refracted.
- A wallpaper change is picked up within a few seconds, not instantly.
- The compiled shader (`shaders/glass.frag.qsb`) is checked in. To rebuild it after editing `glass.frag`, use Qt's `qsb` tool.

## Credits

The lens model is a port of the optics described in [gentpan/liquidglass](https://github.com/gentpan/liquidglass) (MIT), which does the same thing for the web.

## Licence

GPL-3.0-or-later. You may use, change and share this for any purpose; if you distribute a changed version, its source has to be available under the same licence. See `LICENSE`.

The lens model comes from liquidglass, which is MIT licensed; its copyright notice and licence are kept in `THIRD-PARTY-NOTICES.md`.

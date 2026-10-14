# Matching the author's terminal

A terminal demo should look like the terminal the author actually uses. The font, size, and palette are inputs to the renderer, not decoration: a substituted family changes advance widths and box-drawing glyphs, a substituted size changes the cell grid, and an assumed palette changes every semantic color in the screenshot. Recover these values from the author's own config and theme files before rendering anything.

## Where each terminal keeps its config

| Terminal | Config path | Notes |
|---|---|---|
| ghostty | `$XDG_CONFIG_HOME/ghostty/config`, else `~/.config/ghostty/config`, else `~/Library/Application Support/com.mitchellh.ghostty/config` | Themes: `~/.config/ghostty/themes/<name>`, else `${GHOSTTY_RESOURCES_DIR:-/Applications/Ghostty.app/Contents/Resources/ghostty}/themes/<name>` |
| wezterm | `~/.config/wezterm/wezterm.lua`, else `~/.wezterm.lua` | Lua program. Best-effort extraction only; never assume a match |
| alacritty | `~/.config/alacritty/alacritty.toml` | Older `alacritty.yml` exists; only TOML is parsed |
| kitty | `~/.config/kitty/kitty.conf` | Follows `include` one level for a theme file |
| iTerm2 | `~/Library/Preferences/com.googlecode.iterm2.plist` | `plutil -convert json -o -` then read the active profile |

Run the bundled helper instead of re-deriving this by hand:

```sh
./scripts/terminal-theme.sh                    # report every configured terminal
./scripts/terminal-theme.sh --terminal ghostty --json
./scripts/terminal-theme.sh --terminal ghostty --config /tmp/config --theme-file /tmp/theme
```

It is read-only. When several terminals are configured it reports all of them and states the ambiguity; confirm which one produced the capture rather than picking the first. When nothing is found it says so and leaves the palette unresolved. Use the emitted `Set FontFamily` / `Set FontSize` / `Set Theme { ... }` lines directly in the VHS tape.

## Precedence rules that bite

- **Repeated `font-family` is a fallback chain and the first entry wins.** `font-family = Maple Mono NL` followed by `font-family = IBM Plex Mono` renders with Maple Mono NL; the second only covers glyphs the first lacks. Do not report or set the last one.
- **A config `background` overrides the theme's own background.** Resolving `theme = Catppuccin Mocha` gives `background = #1e1e2e`, but a config `background = #11111b` is what the window actually uses. Report both and state which one won.
- **`theme =` is a name, not a palette.** It must be resolved to the emulator's theme file (see above). A name that does not resolve is an unresolved palette, not permission to substitute a lookalike.
- **Opacity in the config is not the whole story.** `background-opacity` can be absent or differ from the capture, and macOS blur can sit underneath it. Treat the config as a hint and the capture as ground truth.

## Resolve the palette from the emulator's theme file

Published palettes are marketing artifacts; emulator theme files are the truth. Catppuccin's widely published ANSI pink is `#f5c2e7`, but Ghostty's own `themes/Catppuccin Mocha` defines:

```ini
palette = 5=#f5c2e7
palette = 13=#f2aede
```

An app that emits SGR 13 (`38;5;13`) gets `#f2aede`, not `#f5c2e7`. Brights are not lightened base colors: the same file lists `9=#f37799`, `10=#89d88b`, `11=#ebd391`, and `12=#74a8fc` against `1=#f38ba8`, `2=#a6e3a1`, `3=#f9e2af`, and `4=#89b4fa`. Sampling a real Ghostty capture confirmed `#f2aede` and `#585b70` for ANSI 13 and 8.

So: parse the theme file the emulator would load, map ANSI 0–7 to the base theme keys and 8–15 to the `bright*` keys (ANSI 5 → `purple`, 13 → `brightPurple`), and treat a difference from the published palette as expected rather than an error in your sampling.

Theme files differ by emulator: ghostty uses `palette = N=#rrggbb` plus `background`, `foreground`, `cursor-color`, `selection-background`; kitty uses `colorN #rrggbb`; wezterm stores schemes in Lua tables with separate `ansi` and `brights` arrays. Prefer a renderer that accepts the resolved values directly (VHS `Set Theme`) over re-typing hex codes.

## 256-colour indices use the standard xterm table

Themes remap ANSI 0–15 only. An app that emits a 256-colour index (`48;5;237`, `38;5;237`) is resolved through the standard xterm 256-colour table, so index 237 is `#3a3a3a` even when the theme remaps low indices. Do not "correct" that value to fit the theme, and do not sample index 237 to infer the theme palette.

Indices 16–231 are the 6×6×6 cube (levels 0, 95, 135, 175, 215, 255) and 232–255 are the 24-step gray ramp (`#080808` + 10 per step, so 237 is `#3a3a3a`); neither range is affected by the theme. If a semantic color matters, prefer capturing the app's truecolor output and diffing that.

## Opacity: the capture is ground truth

A numeric setting in the config can be absent or wrong. A Ghostty config with no `background-opacity` at all produced a capture with the wallpaper clearly visible through the window.

Measure the alpha instead. With the wallpaper and window region aligned to a wallpaper-only reference (`W` = wallpaper pixel, `C` = the terminal's own background color, `S` = the capture pixel), solve per pixel and channel:

```text
S = a*C + (1-a)*W        a = (S - W) / (C - W)
```

Sanity checks that say the fit is real, not coincidence:

- the fitted `a` is identical across the R, G, and B channels of the same pixel (identical transmittance is the tell that alignment and the model are right);
- `a` is stable across many pixels of the window, including pixels over different wallpaper colors;
- a wrong wallpaper offset, crop, or `C` produces scattered or out-of-range `a`.

On this machine the fit gave `a = 0.80` with identical transmittance across all three channels, for a terminal whose config set no opacity at all.

Use the fitted value as the compositor's `--base-opacity`, and set `--base-color` equal to the captured source background that is being keyed, exactly as `references/composition-transparency.md` requires. Pre-blended antialiased glyph edges were blended into that background; a different base color exposes a fringe. The natural pipeline is: render the terminal deterministically with the resolved palette and its own background, key that background, then place the result over the base at the fitted alpha — or use a real-alpha renderer and skip keying entirely.

Do not attempt exact-color keying of a translucent capture. In a translucent window, terminal pixels are `S = a*C + (1-a)*W`, so the "background color" is not present in the image as a flat color and a color key will either match nothing or eat glyph edges.

## Fidelity limits: report, do not fake

Name what the rasterizer cannot reproduce instead of approximating it silently:

- **Stroke thickening.** Ghostty's `font-thicken = true` (with `font-thicken-strength`) renders glyphs with extra stroke weight. A browser rasterizer renders the same font thinner; VHS has no stroke-thickening setting, and `Set FontWeight` selects another weight in the family rather than reproducing the transform. Report the setting and expect slightly lighter text.
- **Ligature/feature settings.** `font-feature = -calt,-liga,-dlig` disables ligatures and contextual alternates. VHS exposes no font-feature setting, so those features stay on and advances can differ.
- **Emulator blending modes.** A setting such as `alpha-blending = linear-corrected` changes how translucent pixels blend; a browser blends in sRGB.
- **macOS window blur.** iTerm2's `Blur`, wezterm's `macos_window_background_blur`, and emulator window materials blur the desktop behind the window. A flat base color cannot reproduce them.
- **Terminal window chrome.** Title bars, proxy icons, tab strips, and traffic lights must not be synthesized. If the chrome is the evidence, capture it natively; otherwise compose only the content area. See `references/composition-transparency.md`.
- **Emulator-side shaders and cursor behaviors.** Bloom, cursor trails, and window padding quirks are not part of the palette. Keep the harness's own geometry rules: set rows/columns and pixel geometry explicitly and never infer the grid from screenshot pixels.

## Verification loop

Close the loop against a capture instead of trusting the report:

1. Render the demo with the resolved theme, then capture a still.
2. Sample the capture's **text pixels**: pixels well above their local row background (for example, luminance above the row's modal background by a clear margin). This excludes background and antialiasing skirts and keeps glyph cores.
3. Cluster the sampled colors and diff each cluster against the intended palette entry. Report matches and mismatches explicitly, including which ANSI index each color came from.
4. A mismatch is a finding, not a rounding error: check for a substituted font, the wrong theme file, a keyed/quantized capture, and for a published palette that was assumed instead of resolved.

Sample from a lossless still. GIF and video encodes quantize colors — an MP4 frame rendered from these settings turned `#11111b` into `#101119` — so compare exact values only from a PNG and allow a small tolerance (±2 per channel) for anything that passed through a lossy encoder.

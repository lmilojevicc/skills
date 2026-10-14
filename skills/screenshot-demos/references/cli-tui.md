# CLI and TUI captures

Use this route for shell commands, terminal output, TUIs, and text-mode applications. If the user only needs a still, produce a static screenshot—not a GIF with one extracted frame.

## Preferred pipeline

Choose the first route that represents the real product faithfully:

1. **Pure app renderer** — use an application-supported image/snapshot/export mode when it renders the same UI.
2. **Deterministic ANSI** — run the real command against fixtures with fixed environment and capture its ANSI stream or terminal state.
3. **Local rasterizer** — render that state at fixed geometry. If VHS is available, use its direct `Screenshot` instruction; do not record a GIF and extract a frame.
4. **Compositor** — apply exact canvas, margin, padding, alpha, and wallpaper after capture.
5. **Native terminal window capture** — last resort, only when terminal-emulator behavior itself is the subject.

Check `command -v` and repository manifests/config before suggesting installation. Reuse checked-in tapes, fixtures, themes, and fonts.

## Deterministic terminal contract

Record these alongside the harness:

- command and fixture/seed;
- terminal columns and rows (set before launch, never inferred from pixels);
- pixel geometry and device scale used by the rasterizer;
- terminal type with truecolor support, normally `TERM=xterm-256color` plus `COLORTERM=truecolor` when the app honors it;
- UTF-8 locale and a fixed time zone;
- theme, background behavior, font family, font size, and line height;
- Nerd Font or icon fallback requirement and exact installed face;
- cursor visibility, shape, blink state, and position;
- shell prompt, working-directory display, timing, and any redaction fixture.

Use a clean, non-login shell where possible. Replace timestamps, durations, random IDs, hostnames, usernames, paths, branch state, and network data with deterministic fixture values. Set terminal geometry before starting the app so it lays out once.

## VHS still example

Adapt this template to the real app and installed VHS version:

```tape
Output /tmp/demo.png
Set Shell "bash"
Set Width 1200
Set Height 700
Set FontSize 18
Set TypingSpeed 0
Set Theme { "background": "#111318" }
Hide
Type "env NO_COLOR=0 TZ=UTC LC_ALL=C.UTF-8 ./bin/demo --fixture docs/demo.json"
Enter
Sleep 2s
Show
Screenshot /tmp/demo.png
```

Use the shortest wait that is backed by stable content. Prefer an app-ready sentinel or known final text over a blind sleep when the harness supports it. Verify that the installed VHS supports direct `Screenshot`; syntax can change.

## Match the author's terminal

Render with the terminal the author actually uses, not a stand-in: the font family (first of any fallback chain), size, and palette are inputs to the rasterizer. Resolve them from the author's emulator config and its theme file instead of guessing:

```sh
./scripts/terminal-theme.sh
```

The helper is read-only, reports every configured terminal when the source is ambiguous instead of silently picking one, and emits `Set FontFamily` / `Set FontSize` / `Set Theme { ... }` lines for the tape. It resolves the palette from the emulator's own theme file: Ghostty's `Catppuccin Mocha` defines ANSI 13 as `#f2aede`, not the published `#f5c2e7`. Confirm the result by sampling the capture's text pixels against the intended palette.

Window alpha comes from the capture, not the config: fit `S = a*C + (1-a)*W` against the known wallpaper, use the fitted `a` as the compositor's `--base-opacity`, and keep `--base-color` equal to the keyed source background so pre-blended glyph edges do not fringe. Precedence traps, the xterm 256-colour rule, and the settings a browser rasterizer cannot reproduce (stroke thickening, window blur, font features) are in [`terminal-theme-fonts.md`](terminal-theme-fonts.md).

## Transparency and text quality

- Prefer a renderer that produces actual alpha and verify it; an alpha channel whose pixels are all opaque is not transparent.
- If the only available capture is opaque with one known uniform terminal background, use explicit source-background extraction in the compositor. Start at exact matching (`--source-fuzz 0`) and raise fuzz only enough for measured capture variation; the helper caps it at 3%. Never guess the background from pixels.
- Chroma keying is global: the same color inside an intentional panel, icon, or glyph can also be removed. Avoid keying when the background color is reused by styled surfaces, or choose a unique capture-only background. Keep compositor base color equal to the captured source background so preblended antialiased edges do not fringe; use a real-alpha renderer if the base color must change. Inspect the alpha result at 100%.
- Place translucent base color beneath the extracted terminal render; do not reduce opacity on the entire screenshot. Glyphs, cursor, icons, antialiased edges, and opaque application surfaces must retain full opacity. If they do not, lower fuzz or use a real-alpha renderer.
- Confirm truecolor gradients and semantic colors against expected values.
- Inspect icon cells and box drawing at 100%; missing Nerd Font glyphs usually appear as tofu or alignment shifts.
- Freeze or hide a blinking cursor. If shown, place it intentionally and keep it opaque.
- For an opaque screenshot that should remain a rectangular foreground, use `--base-opacity 1`; the compositor refuses a translucent-base claim without real source alpha or explicit extraction.
- Do not synthesize terminal chrome unless requested. Native capture is preferable when terminal-emulator chrome is itself the evidence.

## Last-resort native capture

When a pure/ANSI route cannot represent the behavior, isolate one terminal window, close notifications, verify ownership/title, fix its content size, stop cursor blink if possible, and follow the desktop reference. Native capture adds font smoothing, compositor scale, shadows, wallpaper, and permission state; record those variables.

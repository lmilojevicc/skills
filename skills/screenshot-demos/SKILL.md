---
name: screenshot-demos
description: "Create or update polished, repeatable static screenshot demos for CLIs/TUIs, browsers, desktop apps, and mobile simulators. Use for README showcase images, transparent terminal or app captures, wallpaper-backed product screenshots, and deterministic screenshot harnesses. Route by capture surface instead of forcing one tool."
license: MIT
compatibility: "Capture tools vary by surface. Bundled shell helpers require ImageMagick 7; browser guidance uses Playwright when already available."
metadata:
  version: "1.1.0"
---

# Screenshot Demos

Create static evidence by default. Do not build a live demo when one image communicates the state.

## Decide the route

1. Confirm the destination, exact display size/aspect, theme/platform variants, and whether the request is **capture**, **composition**, or both.
2. Choose by rendered surface:
   - CLI/TUI or terminal output → [`references/cli-tui.md`](references/cli-tui.md)
   - Terminal font, size, and palette fidelity → [`references/terminal-theme-fonts.md`](references/terminal-theme-fonts.md)
   - Browser/web UI → [`references/browser-web.md`](references/browser-web.md)
   - Native desktop/window → [`references/native-desktop.md`](references/native-desktop.md)
   - Mobile app/simulator → [`references/mobile-simulator.md`](references/mobile-simulator.md)
3. For framing, transparency, wallpaper, or exact output dimensions, also read [`references/composition-transparency.md`](references/composition-transparency.md).
4. Before publishing, read [`references/validation-privacy-provenance.md`](references/validation-privacy-provenance.md).

Check installed tools before asking to install anything. Prefer a repository's existing harness and dependencies.

## Preview-first workflow

1. **Specify** — record source state, output dimensions, intended rendered/display size, variants, and acceptance details. Keep outer margin and internal padding as separate numbers.
2. **Sanitize** — use fixtures or synthetic data. Remove names, tokens, history, notifications, private URLs, device identifiers, and unrelated windows.
3. **Stabilize** — fix geometry, theme, fonts, locale, time zone, content, data, and randomness. Wait for fonts/assets and stable content; disable or settle motion.
4. **Match the author's terminal** — for terminal surfaces, run `./scripts/terminal-theme.sh` and render with the font family, size, and palette it resolves from the author's emulator config and theme file, using the emitted `Set FontFamily` / `Set FontSize` / `Set Theme` lines. Report the settings it flags as unreproducible ([`references/terminal-theme-fonts.md`](references/terminal-theme-fonts.md)).
5. **Capture** — use the surface-specific route. Preserve the source aspect ratio. Never infer a terminal row/column grid from screenshot pixels.
6. **Compose to a preview path** — previews must be new files outside the published asset path and must not overwrite existing assets. Use the bundled compositor when useful:

   ```sh
   ./scripts/compose.sh --input terminal.png --output /tmp/demo-preview.png \
     --width 1600 --height 900 --outer-margin 80 --padding 32 \
     --source-background '#10141a' --source-fuzz 0 --dry-run
   ```

   Use source extraction only for a known uniform opaque background. Prefer real-alpha input; otherwise pass the exact `--source-background` with zero or minimal bounded fuzz. The compositor refuses fully opaque input with a translucent base unless extraction is explicit; use `--base-opacity 1` when the foreground should remain an opaque rectangle. Remove `--dry-run` only after reviewing the plan. Keep shadow off unless requested; do not add glow.
7. **Preview and approve** — open the image at 100% and at its actual README/site display size. Obtain explicit approval before replacing a published asset.
8. **Publish atomically** — rerun the same deterministic command with the approved destination. Use `--overwrite` only for this approved replacement.
9. **Validate and record evidence** — dimensions, bytes, metadata, alpha, hash, visual review, capture command/config, tool versions, source revision/state, credits, and cleanup.

## Deterministic evidence

Keep a copyable capture/composition command or small harness beside project documentation when repeatability matters. Pin viewport/window geometry and visible data. Record versions and hash the final artifact. A passing command is not enough: visually compare the final file with the approved preview at intended display size.

For terminal images, prefer pure app renderers → deterministic ANSI → local rasterizer (for example VHS direct `Screenshot`) → compositor. For browsers, prefer an existing Playwright setup. Use native screen capture only when the target surface cannot be rendered or captured more deterministically.

## Safety and privacy

- Treat screenshots as data exports. Never include secrets, real customer/private data, shell history, notification banners, unrelated tabs/windows, clipboard contents, or identifying paths.
- Do not widen app, filesystem, browser, simulator, or OS permissions beyond the selected capture.
- Own every process you start: bind development servers locally, record the PID, and stop them. Do not kill by broad process name.
- Exact-window capture must verify ownership and title immediately before capture. Never rely on stale window indexes.
- Preserve third-party asset licenses and credit wallpaper, fonts, icons, and device frames when required.
- Strip metadata deliberately, then verify what remains. Do not claim privacy from visual inspection alone.

## Final checklist

- [ ] Static image is sufficient; no unnecessary GIF/video pipeline
- [ ] Correct surface route and least-invasive capture method used
- [ ] Fixed geometry, deterministic data, loaded fonts/assets, settled motion/content
- [ ] Truecolor/font/icon/cursor states verified; no tofu, clipping, or transient UI
- [ ] Terminal font family (first of any fallback chain), size, and palette resolved from the author's emulator config and its theme file, not from a published palette
- [ ] Resolved palette checked against the capture's text pixels; matches and mismatches reported
- [ ] Settings a browser rasterizer cannot reproduce (stroke thickening, window blur, font features) reported as limits rather than approximated silently
- [ ] Outer margin and internal padding recorded separately; aspect preserved
- [ ] Transparency is real alpha when requested; opaque sources use explicit verified background extraction or an opaque base
- [ ] Keyed background/base pixels are fractional while glyphs, cursor, icons, and styled surfaces remain opaque
- [ ] Wallpaper crop/dim, rounded mask, and exact canvas verified; shadow/glow absent unless requested
- [ ] Preview path did not overwrite an asset; approval obtained before replacement
- [ ] Final dimensions, bytes, metadata, alpha, SHA-256, and actual display-size rendering checked
- [ ] No private data; provenance, third-party credit, commands, versions, and cleanup recorded

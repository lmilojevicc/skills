# Composition and transparency

Composition is a separate, deterministic stage after capture. Keep the raw capture unchanged until approval.

## Geometry model

Use distinct terms and values:

- **Canvas** — final exact pixel dimensions.
- **Outer margin** — distance from canvas edge to the product/base rectangle.
- **Internal padding** — distance from the base rectangle to the foreground capture.
- **Foreground** — source capture, fitted without changing aspect ratio.

Never call outer margin “padding” in a harness. Never stretch the foreground to fill both axes. Do not infer a terminal grid from pixel dimensions; obtain rows/columns from its harness.

The bundled compositor uses a fixed base rectangle of `canvas − 2 × outer-margin` and fits the foreground inside `base − 2 × padding`. It does not upscale by default. Use `--allow-upscale` only after checking text sharpness.

## Alpha model

“Transparent” means an alpha channel with pixels below full opacity, not a checkerboard or an opaque color that resembles a background.

Layer order:

1. transparent canvas, or an opaque wallpaper;
2. optional shadow (off by default);
3. base color with configured alpha;
4. foreground with its original alpha;
5. rounded mask intersecting the combined product layer.

Do not lower opacity on the combined screenshot. That fades glyphs, cursor, icons, and surfaces. Apply opacity to the base layer only; opaque foreground pixels stay opaque. PNG is the safe default for real alpha. A wallpaper-backed final image is naturally opaque even though its base layer may be translucent.

An opaque foreground hides the base beneath it. The helper therefore refuses fully opaque input when `--base-opacity` is below `1` unless `--source-background` is explicit. Choose one honest path:

- supply a real-alpha capture;
- extract one known uniform source background with `--source-background COLOR` and conservative `--source-fuzz`; or
- keep the source rectangular and set `--base-opacity 1`.

Source extraction uses ImageMagick's color match before resize. Fuzz is a percentage capped at `3`, defaults to exact matching (`0`), and makes matching pixels transparent while leaving nonmatching glyphs/surfaces opaque. Low fuzz avoids eroding antialiased edges. For edges already blended into the captured background, keep `--base-color` equal to `--source-background`; changing the base can reveal a fringe, and a real-alpha renderer is required for clean recoloring. Keying cannot understand semantics: the same color in an intentional surface will also be removed, gradients/noisy/JPEG backgrounds may not extract cleanly, and excessive fuzz can erase edge pixels. Prefer a unique capture-only background or native renderer alpha. Always inspect keyed pixels, antialiasing, glyphs, cursor, icons, and styled surfaces at 100%.

## Wallpaper and decoration

Crop wallpaper to fill the exact canvas from center unless art direction specifies another focal point. Apply a recorded dim amount to the wallpaper, not the foreground. Keep contrast sufficient at actual display size.

Rounded corners must be an actual alpha mask, not a same-color corner patch. Keep radii proportional and verify the corner pixels. Shadow defaults off; if requested, use a restrained neutral shadow. Do not add glow unless explicitly requested.

Respect wallpaper/image licenses and preserve required credit. Do not use private desktop wallpaper accidentally.

## Bundled compositor

From this skill directory:

```sh
./scripts/compose.sh --help
./scripts/compose.sh --self-check
./scripts/compose.sh \
  --input raw.png \
  --output /tmp/product-preview.png \
  --wallpaper wallpaper.jpg \
  --width 1600 --height 900 \
  --outer-margin 80 --padding 32 \
  --base-color '#10141a' --base-opacity 0.82 \
  --source-background '#10141a' --source-fuzz 0 \
  --wallpaper-dim 0.25 --radius 28 \
  --dry-run
```

The script requires ImageMagick 7's `magick`, strips output metadata, excludes PNG time chunks, protects existing outputs unless `--overwrite` is explicit, and always emits an exact-size PNG. It checks source alpha before dry-run, rejects fake translucency, rejects a source key that matches nothing or leaves no fully opaque foreground, and bounds fuzz to 0–3%. Dry-run validates and prints the plan without writing. Preview to a fresh path; reserve `--overwrite` for a user-approved published replacement.

## Exact dimensions

Validate the final output, not only intermediate layers. Compare its pixel aspect ratio with the intended README/CSS display box and inspect at that rendered size. Downsampling can hide clipping or make fine text illegible; upsampling in HTML adds no detail.

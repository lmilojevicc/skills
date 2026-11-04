# Design system: Monochrome

The house style for any page a skill renders in a browser — a form, a report, a
diagram, a comparison. One ink ramp, one type family, and no decoration that
competes with the content. Vercel/Linear in structure, Apple in restraint:
near-white paper, hairline rules, tight tracking, one filled action.

This file is canonical. Skills carry their own copy of the token block, because
each skill installs on its own and the repository's link checker rejects links
that leave a skill directory.

Derived from the palettes already in use — `bb-ui/themes/palettes/monochrome.css`,
`vicinae/monochrome-{light,dark}.toml`, `neru/config.toml` — and from the
measured rules in the `better-typography`, `better-colors`, `better-ui` and
`better-layout` skills. Where this file and a skill disagree, this file wins for
skill pages.

Reference page: `design/demo.html` in this repository.

## Tokens

Self-contained, no build step. Paste into a `<style>` block, then never hard-code
a colour, size, radius or shadow outside it.

```css
:root {
  color-scheme: light dark;

  /* Ink ramp — the whole palette. No hue except status. */
  --canvas:            #fbfbfa;   /* page */
  --surface:           #ffffff;   /* cards, panels, popovers */
  --surface-recessed:  #f7f7f5;   /* inset panels, code blocks */
  --ink:               #111111;   /* text, primary fill, focal marks */
  --muted:             #6b6b66;   /* secondary text — 5.2:1 */
  --subtle:            #9c9c96;   /* decoration only, never text */
  --border:            #e4e4e1;   /* structural rules, dividers */
  --border-hairline:   #eeeeec;   /* dividers inside a surface */
  --border-strong:     #8a8a85;   /* control outlines — 3.4:1 */
  --primary:           #111111;
  --primary-hover:     #000000;
  --primary-foreground:#ffffff;
  --ring:              #11111180;
  --danger:            #a4342c;   /* 6.5:1 on canvas */
  --warning:           #8a6a16;   /* 4.9:1 */
  --success:           #4a6b4f;   /* 5.8:1 */

  /* Geist when installed; system grotesque otherwise. */
  --font-sans:  "Geist", "Geist Sans", ui-sans-serif, system-ui, -apple-system,
                "Segoe UI", sans-serif;
  --font-mono:  "Geist Mono", ui-monospace, "SFMono-Regular", Menlo, monospace;
  --font-pixel: "Geist Pixel", "Geist Mono", ui-monospace, monospace;

  --text-display: 1.75rem;   /* 28 */
  --text-title:   1.25rem;   /* 20 */
  --text-body:    0.9375rem; /* 15 */
  --text-small:   0.8125rem; /* 13 */
  --text-micro:   0.6875rem; /* 11 */

  --space-1: 4px; --space-2: 8px; --space-3: 12px; --space-4: 16px;
  --space-5: 24px; --space-6: 32px; --space-7: 48px; --space-8: 64px;

  --radius-sm: 6px; --radius: 10px; --radius-lg: 14px; --radius-pill: 999px;
  --ease: cubic-bezier(0.2, 0, 0, 1);
  --duration: 150ms;

  /* Elevation: layered transparent shadows, floating surfaces only */
  --shadow-1: 0 1px 2px rgb(0 0 0 / .05), 0 1px 3px rgb(0 0 0 / .04);
  --shadow-2: 0 4px 14px -4px rgb(0 0 0 / .12), 0 2px 6px -3px rgb(0 0 0 / .08);
  --shadow-3: 0 16px 40px -12px rgb(0 0 0 / .22), 0 4px 12px -6px rgb(0 0 0 / .12);

  /* Liquid glass: popovers, menus, sheets */
  --glass-bg: rgb(255 255 255 / .60);
  --glass-border: rgb(17 17 17 / .08);
  --glass-rim: rgb(255 255 255 / .65);
}

@media (prefers-color-scheme: dark) {
  :root {
    --canvas:            #0b0b0c;
    --surface:           #141416;
    --surface-recessed:  #111113;
    --ink:               #ededed;
    --muted:             #9d9da4;   /* 7.3:1 */
    --subtle:            #67676d;
    --border:            #25252a;
    --border-hairline:   #1f1f23;
    --border-strong:     #6a6a73;   /* 3.4:1 */
    --primary:           #ededed;
    --primary-hover:     #ffffff;
    --primary-foreground:#0b0b0c;
    --ring:              #ededed80;
    --danger:            #d98079;
    --warning:           #d8bb7a;
    --success:           #93b79a;

    --shadow-1: 0 1px 2px rgb(0 0 0 / .40), 0 1px 3px rgb(0 0 0 / .30);
    --shadow-2: 0 6px 18px -6px rgb(0 0 0 / .55), 0 2px 6px -3px rgb(0 0 0 / .40);
    --shadow-3: 0 20px 48px -16px rgb(0 0 0 / .70), 0 6px 16px -8px rgb(0 0 0 / .50);

    --glass-bg: rgb(22 22 26 / .55);
    --glass-border: rgb(255 255 255 / .14);
    --glass-rim: rgb(255 255 255 / .18);
  }
}
```

A page that needs a manual theme switch uses `html[data-theme="dark"]` on the
same block instead of a media query.

## Fonts

All three faces come from Bunny Fonts — one stylesheet, no Google:

```html
<link rel="preconnect" href="https://fonts.bunny.net" crossorigin>
<link rel="stylesheet" href="https://fonts.bunny.net/css?family=geist:400,500,600|geist-mono:400,500|geist-pixel:400&display=swap">
```

They are an enhancement, not a dependency: the stack falls back to the platform
grotesque and the page still reads correctly offline. Note that Bunny's Geist CSS
resolves the woff2 binaries to `cdn.jsdelivr.net/fontsource`; if a page must make
zero third-party requests, self-host the three files (~166 KB) and point
`@font-face` at them.

## Type

| Role | Face | Size / line-height | Tracking | Weight |
| --- | --- | --- | --- | --- |
| Display | Sans | `--text-display` / 1.15 | `-0.02em` | 600 |
| Title | Sans | `--text-title` / 1.3 | `-0.01em` | 600 |
| Body | Sans | `--text-body` / 1.55 | `0` | 400 |
| Small | Sans | `--text-small` / 1.5 | `0` | 400 |
| Micro label | Pixel | `--text-micro` / 1.4 | `0.12em`, uppercase | 400 |
| Code / identifiers | Mono | `--text-small` / 1.45 | `0` | 400–500 |

Rules that are findings, not taste:

- Line-height is unitless.
- Never below weight 400 under 18px; 300 needs 28px and a contrast check.
- Body measure 60–75 characters; forms are a single 520px column, reports 960px.
- `font-variant-numeric: tabular-nums` on any number that changes.
- Inputs are at least 16px on mobile, or iOS zooms the page.
- Geist Pixel is a brand accent: one per page, as an eyebrow, a section index or a
  footer stamp. Never a heading, never twice. With the pixel face missing, the
  mono fallback keeps the same cadence.

## Space and structure

- One 4px-based scale: 4, 8, 12, 16, 24, 32, 48, 64.
- Group with space first, background shapes second, separators last.
- Gap between groups is at least 2× the gap inside one: 16px between fields,
  32px between sections.
- Align everything to one leading edge. No centred form labels.
- Direction-dependent properties as `margin-inline`, `padding-inline`,
  `inset-inline`, `text-align: start`.
- One primary action per view.

## Layering

| Step | Token | Use |
| --- | --- | --- |
| Page | `--canvas` | the ground |
| Inset | `--surface-recessed` + `--border` | panels, code blocks, empty states |
| Raised | `--surface` + `--shadow-1` | a card that sits on the page |
| Floating | `--surface` + `--shadow-2` | popover, menu, dropdown |
| Glass | `--glass-bg` + blur + `--shadow-3` | sheet, modal, command palette |

- **Nested radius follows `outer = inner + padding + border`.** A 5px control
  inside 8px of padding and a 1px border sits in a 14px outer corner. When padding
  exceeds 24px, treat the layers as separate surfaces instead.
- **Borders carry structure, shadows carry elevation.** Dividers are 1px
  `--border` (or `--border-hairline` inside a surface). A shadow on something that
  is not floating is a defect.
- **Glass only over content.** `backdrop-filter: blur(20px) saturate(180%)` plus
  `inset 0 1px 0 var(--glass-rim)` for the lit edge. Over an empty page it is just
  a tinted panel, so use it where something scrolls beneath. Never on page chrome.

## Components

**Primary button** — `--primary` fill, `--primary-foreground` text, `--radius`,
44px tall, weight 600. Hover `--primary-hover`, active `scale(0.96)`, focus 2px
`--ring` outline with a 2px offset. One per view.

**Secondary / ghost** — transparent, `1px solid var(--border)`, `--muted` text.

**Input** — `1px solid var(--border-strong)`, `--radius`, 44px tall, 16px text,
`--surface` fill. Focus: border `--ink` plus a 2px `--ring` outline. Invalid:
`--danger` border and a `--danger` message at `--text-small`, never colour alone.

**Field label** — identifier in mono, `--text-micro`, uppercase, tracked; the
description below it at `--text-small`, `--muted`. Label 6px above the input.

**Panel** — `--surface-recessed`, `1px solid var(--border)`, `--radius`, 16px
padding. The one piece of context the reader must not miss.

**Badge** — mono, `--text-micro`, `0.04em`, `--border`, pill radius, a 6px status
dot and a word. One per status, not decoration.

**Divider** — 1px `--border-hairline`, 32px of space above and below.

**Footer** — `--text-small` or mono micro, `--muted` or `--subtle` only for
decoration, one hairline above, 32px of space.

## Diagrams

- Mermaid renders through **Pele** (`pele@1.3.0`), which reads `--pele-*` CSS
  variables: set `--pele-bg/fg/line/surface/border/accent/font/radius` from the
  tokens and it recolors on a theme flip without re-rendering.
- Excalidraw scenes render through **`ExcalidrawUtils.exportToSvg`**, from element
  JSON — never as hand-authored paths pretending to be a sketch.
- Diagram status colours are their own trio, measured to pass 3:1 on both
  backgrounds: `#6f8f76`, `#a8873a`, `#c05a52`, with 12% alpha fills. Pele
  rejects `var()` inside `classDef`, so these are literal values.
- Maximum ~9 nodes; beyond that, split into an overview and a detail.

## Motion

- Interactive state: `150ms var(--ease)`, transitions only.
- Press: `transform: scale(0.96)`.
- One entrance at most, 200–400ms, opacity and 8px of translate.
- Honor `prefers-reduced-motion: reduce` by removing transforms and durations.

## Contrast

- Body and label text: at least 4.5:1 against the surface it renders on.
- Control outlines and other non-text UI: at least 3:1.
- Measure the rendered pair, never estimate. `--subtle` fails 4.5:1 by design and
  is therefore not a text colour.
- Status colour always carries a label or an icon as well.

## Don't

- No gradients, glows or blur on the page. Glass belongs to floating surfaces.
- No second accent hue. Emphasis is ink.
- No shadow on anything that is not floating over content.
- No pixel heading, no two ornamental devices on one page.
- No emoji as UI, no icon set mixed with text glyphs.
- No remote assets other than the font stylesheet.

## Checklist for a new page

1. Tokens pasted verbatim; nothing hard-coded outside them.
2. One column, one primary action, one filled element.
3. Geist stack, unitless line-height, weights ≥400 under 18px.
4. Inputs 44px tall, 16px text, visible focus ring, labelled.
5. Dark mode checked against the same tokens; no pair below its threshold.
6. Keyboard tab reaches every control in reading order.
7. `scripts/secretform.py --check` style self-test, or the skill's own, passes.

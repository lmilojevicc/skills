# Style — one quiet system for every page

Explainer pages share one look with every other skill that renders a browser
page: one ink ramp, one type family, one filled action. The visual carries the
meaning and the page stays out of the way. The canonical source is `DESIGN.md` at
the repository root; the templates in [`../templates/`](../templates/) implement
what follows, so start from one and change content, not styling.

## Type — sans text, mono figures, one pixel accent

Three cuts of one family, loaded from Bunny Fonts:

| Role | Face | Size | Weight |
|---|---|---|---|
| Page title (`h1`) | Geist Sans | `--fs-title` (28–40px fluid), `-0.02em` | 600 |
| Section heading, option name (`h2`) | Geist Sans | `--fs-head` (20px), `-0.01em` | 600 |
| Figures in KPIs, code, IDs, axis ticks | Geist Mono | as needed | 400–500 |
| Body, lede, takeaways | Geist Sans | `--fs-body` (15px) | 400 |
| Labels, captions, legends, notes | Geist Sans | `--fs-small` (13px) | 400 |
| Eyebrow, wordmark | Geist Pixel | 12px, `0.12em`, uppercase | 400 |

```html
<link href="https://fonts.bunny.net/css?family=geist:400,500,600|geist-mono:400,500|geist-pixel:400&display=swap" rel="stylesheet">
```

- **Pixel is the only ornament, and it appears once per page** — an eyebrow, an
  index, a footer stamp. Never a heading, never twice.
- Headings: line height 1.15, sentence case, two lines at most. `h1` max width
  `22ch`. No eyebrow above the title unless it carries real scope information.
- Body: line height 1.55, measure 56–64ch, running text in full `--ink`. Grey
  (`--muted`) is only for secondary notes.
- Four sizes on a page. Do not add a fifth to solve a layout problem.
- `font-variant-numeric: tabular-nums` on every number that lines up or updates.
- Left-aligned. Nothing centred except the diagram itself.

## Colour — one ramp, ink as the accent

Hex tokens. The same values go into CSS, SVG attributes, Pele variables and
Chart.js, so there is one palette to keep in sync.

| Token | Light | Dark | Use |
|---|---|---|---|
| `--bg` | `#fbfbfa` | `#0b0b0c` | Page ground |
| `--surface` | `#ffffff` | `#141416` | Panels: diagram, chart, KPI and option surfaces |
| `--surface-2` | `#f7f7f5` | `#111113` | Hover on a surface, mock elements, subgraphs |
| `--line` | `#e4e4e1` | `#25252a` | Node borders, KPI dividers, chart gridlines |
| `--border-strong` | `#8a8a85` | `#6a6a73` | Input outlines, anything that must read at 3:1 |
| `--bar` | `#d8d8d3` | `#3a3a3f` | Non-focal data marks |
| `--ink` | `#111111` | `#ededed` | Text, chart baseline |
| `--muted` | `#6b6b66` | `#9d9da4` | Secondary text, labels, connectors. 5.2:1 / 7.3:1 |
| `--subtle` | `#9c9c96` | `#67676d` | Decoration only — it fails 4.5:1, never text |
| `--accent` | `#111111` | `#ededed` | Ink itself: the focal element and the focus ring |
| `--danger` | `#a4342c` | `#d98079` | Status, with a label |
| `--warning` | `#8a6a16` | `#d8bb7a` | Status, with a label |
| `--success` | `#4a6b4f` | `#93b79a` | Status, with a label |

Dark tokens live under `html[data-theme="dark"]` and under
`@media (prefers-color-scheme: dark) { html:not([data-theme]) { … } }`.

**Accent discipline.** There is no accent hue. The focal bar, node or path is
`--ink` while everything around it is `--bar` or `--muted`. One or two focal
elements per visual. Status colour is the only hue allowed, it is desaturated,
and it always carries a label or an icon.

**Banned:** cream or beige ground with terracotta or rust, violet, indigo and
fuchsia, neon on dark, gradients of any kind, a different hue for every bar or
node.

## Surfaces, elevation and glass

- **Tone steps first.** A panel is `--surface` on `--bg`. Prefer a tone step to a
  border, and space to both.
- **One radius: `--radius: 10px`.** Small inner parts use 6px. Nested surfaces
  follow `outer = inner + padding + border`: a 5px control inside 8px of padding
  gets a 14px outer corner.
- **Elevation only for things that float.** `--shadow-1` for a raised card,
  `--shadow-2` for a popover, `--shadow-3` for a modal or a glass panel. The page
  itself never casts a shadow.
- **Glass is for popovers, menus and sheets** — surfaces that overlap content.
  `--glass-bg` (white 60% / ink 55%), `backdrop-filter: blur(20px) saturate(180%)`,
  a 1px `--glass-border`, and `inset 0 1px 0 var(--glass-rim)` for the lit edge.
  Never on page chrome; with nothing behind it, glass is just a tinted panel.
- **Group, don't box.** A KPI row is one surface split by 1px gaps, not separate
  cards. No card inside a card.
- **Frame:** `main` max width 960px, 24px side padding (16px on phones), equal on
  both sides. Sections are 64px apart (48px on phones); gaps inside a section are
  8–24px.
- `html, body { overflow-x: clip; }` and `min-width: 0` on grid and flex
  children. No horizontal scroll at any width.

## Ornaments — one system, repeated

The pixel eyebrow and the hairline are the only decoration. Each of these reads
as generated; leave it out.

| Don't | Instead |
|---|---|
| A pixel heading | Sans heading; pixel is an eyebrow or a footer stamp, once |
| An eyebrow that paraphrases the title (`SECRET REQUEST` over `Secrets requested`) | Delete it. One pixel stamp per page, in the footer or an index |
| An eyebrow over every section | One page index at the top, then space |
| Tiny uppercase letter-spaced labels in sans | Mono for identifiers, sentence case for prose |
| Pill badges everywhere | A mono badge for one status, with a dot and a label |
| Hairline dividers between every section | Space; keep the rule where two things genuinely separate |
| Shadows and glows on things at rest | A tone step; shadow only on floating surfaces |
| Gradients, glows, blur on the page | Flat ink; glass only on a floating surface |
| Icons in tinted circles, emoji | Words, or nothing |
| Coloured accent word in a heading | The words carry the emphasis |

## Page structure

1. **Header:** `h1` naming what is shown, then one plain sentence (`.lede`). No
   eyebrow unless it names real scope.
2. **The visual:** on a `--surface` panel and visible in the first viewport. It is
   the hero, not the header.
3. **Legend or source note** under the panel, 13px muted, never floating inside
   the visual.
4. **"What to notice":** `h2` and 2–3 short takeaways. No paragraphs; the
   explanation stays in chat.
5. **Footer:** one 13px muted line, no rule.

The theme toggle is a 36px icon button, top right: monitor for system (the
default), sun for light, moon for dark. Muted until hover, hidden until JS runs.

## Motion

Restrained: one staggered fade-up (`.ve-in`, 400ms, 60ms steps) on the
first-screen blocks, a grow-in for bars, a draw-in for hand-built connectors.
`transform` and `opacity` only, `cubic-bezier(0.2, 0, 0, 1)`. Under
`prefers-reduced-motion` everything is instant. No loops, pulses or hover lifts.
Patterns are in [`interactivity.md`](interactivity.md).

## Diagrams

Mermaid renders through **Pele**, which reads CSS variables (`--pele-*`), so it
recolors on a theme flip without a re-render. Excalidraw scenes render through
`ExcalidrawUtils.exportToSvg` (jsDelivr UMD), not hand-drawn paths. Diagram
status colours are a separate mid-tone trio measured to pass 3:1 on both
backgrounds: `#6f8f76`, `#a8873a`, `#c05a52`, with 12% fills.

## Favicon

A data-URI SVG, an ink square: `<rect width='16' height='16' rx='3' fill='%23111111'/>`. No 404.

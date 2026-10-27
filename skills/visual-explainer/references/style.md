# Style — one quiet system for every page

Explainer pages share one look: plain, minimal, and easy to read. The visual carries the meaning, and the page around it stays out of the way. The rules follow the anti-slop house style of [taste-skill](https://github.com/leonxlnx/taste-skill): no ornaments, few sizes, one ground, one ink, one accent. There is one deliberate exception: **headings are set in monospace.**

Templates in [`../templates/`](../templates/) already implement everything below. Start from one and change content, not styling.

## Type — sans text, mono headings

Two faces from one superfamily, so they match without effort:

| Role | Face | Size | Weight |
|---|---|---|---|
| Page title (`h1`) | IBM Plex Mono | `--fs-title` (28–40px fluid) | 500 |
| Section heading, option name (`h2`) | IBM Plex Mono | `--fs-head` (18px) | 500 |
| Figures in KPIs, code, IDs | IBM Plex Mono | as needed | 500 |
| Body, lede, takeaways | IBM Plex Sans | `--fs-body` (16px) | 400 |
| Labels, captions, axis ticks, legends, notes | IBM Plex Sans | `--fs-small` (13px) | 400 |

```html
<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@500&family=IBM+Plex+Sans:wght@400;500&display=swap" rel="stylesheet">
```

- **Mono only for headings, figures and code.** Labels, axis ticks, captions and legends are sans. Mono labels everywhere is the costume this system avoids.
- Headings: tracking `-0.03em`, line height 1.15, sentence case, two lines at most. `h1` max width `22ch`.
- Body: line height 1.55, measure 56–64ch, running text in full `--ink`. Grey (`--muted`) is only for secondary notes.
- Four sizes on a page. Do not add a fifth to solve a layout problem.
- `font-variant-numeric: tabular-nums` on every number that lines up or updates.
- Left-aligned. Nothing centred except the diagram itself.

## Colour — one ground, one ink, one accent

Hex tokens. The same values go into CSS, SVG attributes, Pele variables and Chart.js, so there is one palette to keep in sync.

| Token | Light | Dark | Use |
|---|---|---|---|
| `--bg` | `#fafaf9` | `#111111` | Page ground |
| `--surface` | `#f1f1ef` | `#1b1b1b` | Panels: the diagram, chart, KPI and option surfaces |
| `--surface-2` | `#e6e6e3` | `#262626` | Hover on a surface, mock elements, subgraphs |
| `--line` | `#d6d6d2` | `#333333` | Node borders, KPI dividers, chart gridlines. Never section dividers |
| `--bar` | `#cfcfca` | `#444444` | Non-focal data marks |
| `--ink` | `#171717` | `#ececec` | Text, chart baseline |
| `--muted` | `#5c5c5c` | `#a1a1a1` | Secondary text, labels, connectors. Passes 4.5:1 on `--bg` and `--surface` |
| `--accent` | `#0b62d6` | `#5b9cf5` | The focal element, focus ring, nothing else |

Dark tokens live under `html[data-theme="dark"]` and under `@media (prefers-color-scheme: dark) { html:not([data-theme]) { … } }`. Only lightness moves between modes, never the hue.

**Accent discipline.** The accent marks what the user should look at first: the focal bar, the focal node or path, the recommended option. One or two elements per visual. Everything else is ink, muted or `--bar`. Never use the accent as a background block, on chrome, or for decoration.

**Banned:** cream or beige ground with terracotta or rust (the assistant look), violet, indigo and fuchsia, neon on dark, gradients of any kind, a different hue for every bar or node.

## Surfaces and space

- **Tone steps, not lines.** A panel is `--surface` on `--bg`. No borders around panels, no hairline rules between sections, no shadows.
- **One radius:** `--radius: 6px` for panels and cards, 4px for small inner parts. No pills.
- **Group, don't box.** A KPI row is one surface split by 1px gaps, not separate cards. No card inside a card.
- **Frame:** `main` max width 960px, 24px side padding (16px on phones), equal on both sides. Sections are 64px apart (48px on phones); gaps inside a section are 8–24px.
- `html, body { overflow-x: clip; }` and `min-width: 0` on grid and flex children. No horizontal scroll at any width.

## No ornaments

Each of these reads as generated. Leave it out and let space, size and the visual do the work.

| Don't | Instead |
|---|---|
| Eyebrow label above the title (`DATA · LAST 6 MONTHS`) | Put the scope in the title: "Monthly active users, January to June" |
| Tiny uppercase letter-spaced labels | Sentence case at 13px |
| Pill badges, chips | Plain text, in accent if it marks the recommendation |
| Index numbering (01 / 02 / 03) | Order by position. A real `<ol>` if the order matters |
| Hairline dividers between sections | Space |
| Shadows and glows on things at rest | A tone step. Shadows only on things that float |
| Gradients, glass, blur | Flat fills |
| Icons in tinted circles, emoji | Words, or nothing |
| Coloured accent word in a heading | The words carry the emphasis |
| Decorative bullets in accent | An en dash in `--muted` |

## Page structure

1. **Header:** `h1` naming what is shown, then one plain sentence (`.lede`). Nothing above the title.
2. **The visual:** on a `--surface` panel and visible in the first viewport. It is the hero, not the header.
3. **Legend or source note** under the panel, 13px muted, never floating inside the visual.
4. **"What to notice":** `h2` and 2–3 short takeaways. No paragraphs; the explanation stays in chat.
5. **Footer:** one 13px muted line, no rule.

The theme toggle is a 36px icon button, top right: monitor for system (the default), sun for light, moon for dark. Muted until hover, hidden until JS runs.

## Motion

Restrained: one staggered fade-up (`.ve-in`, 400ms, 60ms steps) on the first-screen blocks, a grow-in for bars, a draw-in for hand-built connectors. `transform` and `opacity` only. Under `prefers-reduced-motion` everything is instant. No loops, pulses or hover lifts. Patterns are in [`interactivity.md`](interactivity.md).

## Favicon

A data-URI SVG, an ink square: `<rect width='16' height='16' rx='3' fill='%23171717'/>`. No 404.

# Style — design system for visual explainer pages

Every page commits to one aesthetic direction before HTML is written. This file encodes the Hallmark system applied to explainer pages: warm editorial palette, Fraunces display, hairlines instead of card borders, one accent used sparingly. Simple, warm, crowd-appealing.

## Palette — warm-oat editorial

OKLCH only for CSS custom properties. Tinted paper, tinted ink, one warm accent. No pure black or white. When colors go into SVG presentation attributes, Mermaid `themeVariables`, Chart.js options, or data-URI favicons, use the hex equivalents below — those contexts parse OKLCH inconsistently.

```css
:root {
  --color-paper:    oklch(96%  0.012 80);   /* #f8f5ef — page background, warm oat */
  --color-paper-2:  oklch(93%  0.014 80);   /* #eee9de — surface / container */
  --color-rule:     oklch(82%  0.010 80);   /* #cfc9bc — hairlines */
  --color-neutral:  oklch(56%  0.008 80);   /* #88817a — secondary text */
  --color-muted:    oklch(40%  0.008 70);   /* #58534c — labels, captions */
  --color-ink:      oklch(18%  0.010 60);   /* #2b2824 — primary text */
  --color-accent:   oklch(55%  0.19  45);   /* #c23c14 — terracotta, ONE accent */
  --color-focus:    oklch(55%  0.19  55);   /* #d66a40 — focus ring */
  --color-series-1: oklch(45%  0.05  60);   /* #6f6352 — secondary data series */
  --color-series-2: oklch(60%  0.04  70);   /* #9a8f79 — tertiary data series */
  --color-series-3: oklch(72%  0.03  75);   /* #bcb3a4 — quaternary data series */
}
```

**Hex equivalents** (for SVG attributes, Mermaid, Chart.js, favicons):

| Token | Hex | Token | Hex |
|---|---|---|---|
| paper | `#f8f5ef` | muted | `#58534c` |
| paper-2 | `#eee9de` | ink | `#2b2824` |
| rule | `#cfc9bc` | accent | `#c23c14` |
| neutral | `#88817a` | series-1/2/3 | `#6f6352` / `#9a8f79` / `#bcb3a4` |

### Accent discipline

The accent is a **highlighter, not a colour block**. It occupies **≤ 3% of any viewport**:

- The focal bar in a chart, the focal node in a diagram
- The recommended option's border or letter marker
- Eyebrow text and takeaway bullet markers
- Focus rings and active nav states

Never: accent as a background fill, accent on more than 1–2 elements per visual, accent as a decorative gradient.

### Dark mode (only when the content calls for it)

```css
:root {
  --color-paper:    oklch(14%  0.008 80);
  --color-paper-2:  oklch(18%  0.010 80);
  --color-rule:     oklch(30%  0.008 80);
  --color-neutral:  oklch(58%  0.008 80);
  --color-muted:    oklch(72%  0.006 80);
  --color-ink:      oklch(94%  0.006 80);
  --color-accent:   oklch(65%  0.16  55);   /* lighten + desaturate slightly */
  --color-focus:    oklch(70%  0.19  55);
}
```

Never switch the hue between modes — only lightness and chroma move. Elevation: higher surfaces are *lighter* in dark mode.

### Forbidden palettes

- `#8b5cf6`, `#7c3aed`, `#a78bfa` (indigo/violet) as primary
- `#d946ef` (fuchsia)
- Cyan + magenta + purple neon combos
- Gradient-mesh blobs, purple-to-cyan gradients
- Pure `#000` or `#fff` anywhere
- Flat grey (zero chroma) — always tint toward the anchor hue (80)

## Typography — 2+1 faces

**Fraunces (display) + IBM Plex Sans (body) + JetBrains Mono (outlier).** Three families is the ceiling. The outlier is a register, not a third surface — it tags technical content: labels, captions, axis ticks, code, colophon.

```css
:root {
  --font-display: "Fraunces", ui-serif, Georgia, serif;
  --font-body:    "IBM Plex Sans", ui-sans-serif, system-ui, sans-serif;
  --font-mono:    "JetBrains Mono", ui-monospace, monospace;
}
```

Google Fonts load (all weights used, `display=swap`):

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,600;9..144,700&family=IBM+Plex+Sans:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
```

### Type scale — major third (1.25)

```css
:root {
  --text-xs:   0.64rem;   /* 10.24px — axis ticks, colophon */
  --text-sm:   0.8rem;    /* 12.8px  — labels, captions */
  --text-base: 1rem;      /* 16px    — body */
  --text-md:   1.25rem;   /* 20px    — option names */
  --text-lg:   1.5625rem; /* 25px    — section headings */
  --text-xl:   1.9531rem; /* 31.25px — page title */
  --text-2xl:  2.4414rem;
}
```

| Role | Size | Weight | Face |
|---|---|---|---|
| Page title (h1) | `--text-xl` | 600 | Fraunces |
| Section heading (h2) | `--text-lg` | 600 | Fraunces |
| Option names, node names | `--text-md` | 600 | IBM Plex Sans |
| Body text | `--text-base` | 400 | IBM Plex Sans |
| Labels, axis ticks, captions | `--text-sm` / `--text-xs` | 400–500 | JetBrains Mono, uppercase, `letter-spacing: 0.08em` |
| Eyebrow | `--text-xs` | 500 | JetBrains Mono, uppercase, tracked, accent color |

### Typography rules

- **Body weight contrast**: headings at 600–700 against body 400 — at least 200 units apart, never 400 vs 500
- **Line-height**: display 1.2, body 1.6
- **Measure**: `max-width: 65ch` for prose blocks
- **Tabular numbers** on all data: `font-variant-numeric: tabular-nums`
- **Never** all-caps paragraphs, justified text, or letter-spacing above 0.05em on body
- **Never** synthetic bold — load every weight the CSS uses
- **No gradient text** on headings

### Banned fonts

Inter, Roboto, Open Sans, Lato, Poppins, Montserrat, DM Sans, Arial, Helvetica, bare system-ui, Merriweather, Lora as body, Courier New as body.

## Layout — left-biased editorial

- **Primary axis: left.** Headers left-aligned, content left-flush. No centred-everything heroes
- **Hairlines, not card borders.** Section separation via thin rules (`--color-rule` at 1px), not heavy borders. Diagram containers use `--color-paper-2` background + hairline border
- **No shadows** — depth comes from weight, size, and color contrast. If absolutely needed, one whisper shadow: `0 1px 2px oklch(20% 0.01 80 / 0.05)`
- **Asymmetric rhythm** — vary section spacing. Generous top, tight bottom or vice versa. Never equal padding everywhere
- **Spacing scale** (4pt base, named by role):

```css
:root {
  --space-xs:  0.5rem;   /*  8px */
  --space-sm:  0.75rem;  /* 12px */
  --space-md:  1rem;     /* 16px */
  --space-lg:  1.5rem;   /* 24px */
  --space-xl:  2.5rem;   /* 40px */
  --space-2xl: 4rem;     /* 64px */
  --space-3xl: 6rem;     /* 96px */
}
```

- Use `gap` for sibling spacing, `margin` only for optical adjustments
- `html { overflow-x: clip; }` and `body { overflow-x: clip; }` at the top — never `hidden` (breaks sticky)
- `min-width: 0` on all grid/flex children
- Max content width 1100px, generous horizontal padding
- Border radius: 6–8px max. Never `rounded-2xl`

### Bans

- Centre-aligned everything
- Card-in-card (bordered container inside bordered container)
- Three equal-width icon-tile grids — vary column widths or use a different pattern
- `z-index: 9999` — use the named scale: base 1, raised 10, dropdown 100, sticky 200, modal 400, toast 500, tooltip 600
- Equal padding on everything
- Box shadows as the depth system

## Motion

Motion tokens, easing curves, entrance animation, draw-in, and count-up patterns live in [`interactivity.md`](interactivity.md) — read it when wiring any page.

- Default: restrained. Entrance stagger on first-viewport elements, grow-in for bars, draw-in for SVG lines
- Max 500ms per animation, `--ease-out` / `--ease-in-out` only, `transform` and `opacity` only
- Always `prefers-reduced-motion: reduce` — collapse to instant
- Never: continuous glow, pulse, breathing, bounce on static content

## Visual hierarchy

- The main idea visible in the first viewport — no scrolling to find the point
- The diagram/chart is the hero, not the header
- Sparse prose: labels, captions, ≤ 3 takeaway bullets. No paragraphs of explanation — the explanation lives in chat
- Footer: one hairline rule + tiny mono colophon line

## Page skeleton

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Page title</title>
  <link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'><rect width='16' height='16' rx='3' fill='oklch(55%25 0.19 45)'/></svg>" />
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,600;9..144,700&family=IBM+Plex+Sans:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
  <style>
    :root { /* tokens above */ }
    html { overflow-x: clip; }
    body { overflow-x: clip; }
    /* page styles */
  </style>
  <!-- CDN scripts only if needed (Mermaid, Excalidraw, Chart.js) -->
</head>
<body>
  <main>...</main>
</body>
</html>
```

The favicon is a data-URI SVG — self-contained, no 404.

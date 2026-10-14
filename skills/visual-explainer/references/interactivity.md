# Interactivity — theme toggle, motion, and interaction patterns

Every explainer page ships with a small interaction layer. All of it is optional per page; the base template wires what every page should have. This file is the single source of truth for the JS in the templates — follow the patterns verbatim.

**Core principle:** the page must be complete and meaningful **without JavaScript**. No-JS users get the default (light) theme, full static content, and no animations — just no toggle, hover, or step controls. Reduced-motion users get no movement but keep full interactivity. CDN failure (Mermaid/Excalidraw/Chart.js unreachable) must not blank the page.

---

## 1. Theme toggle (light / dark / auto)

Three-state toggle. Positioned top-right, minimal chrome — a mono `Aa`-style button with moon/sun glyphs. The toggle:

- Cycles **auto → light → dark → auto**
- Persists to `localStorage` key `visual-explainer:theme`
- Applies `data-theme="light"` / `data-theme="dark"` on `<html>`; CSS switches tokens under `[data-theme]`
- In **auto** mode, follows `prefers-color-scheme` live via `matchMedia('change')` listener
- On script load, if Mermaid diagrams exist, re-render them after the theme settles (Mermaid initializes once and can't react)

### HTML

```html
<button class="theme-toggle" id="themeToggle" aria-label="Toggle color theme" title="Theme: auto">
  <span class="tt-glyph tt-auto">◐</span>
  <span class="tt-glyph tt-light">☀</span>
  <span class="tt-glyph tt-dark">☾</span>
  <span class="tt-label" id="ttLabel">auto</span>
</button>
```

### CSS

```css
.theme-toggle {
  position: fixed;
  top: var(--space-lg);
  right: var(--space-lg);
  display: inline-flex;
  align-items: center;
  gap: var(--space-xs);
  font-family: var(--font-mono);
  font-size: var(--text-xs);
  letter-spacing: 0.04em;
  color: var(--color-muted);
  background: transparent;
  border: 1px solid var(--color-rule);
  border-radius: 999px;
  padding: var(--space-xs) var(--space-md);
  cursor: pointer;
  z-index: 600;                 /* --z-tooltip from the z-scale */
  transition: border-color 150ms var(--ease-out), color 150ms var(--ease-out);
}
.theme-toggle:hover { border-color: var(--color-accent); color: var(--color-accent); }

.tt-glyph { display: none; }
[data-theme="dark"] .theme-toggle .tt-dark { display: inline; }
[data-theme="light"] .theme-toggle .tt-light { display: inline; }
html:not([data-theme]) .theme-toggle .tt-auto { display: inline; }
html:not([data-theme]) .theme-toggle .tt-label::after { content: 'auto'; }
[data-theme="dark"]  .theme-toggle .tt-label::after { content: 'dark'; }
[data-theme="light"] .theme-toggle .tt-label::after { content: 'light'; }
```

### CSS token structure — tokens move under a theme attribute

```css
:root { ...light tokens... }                       /* light is also the no-JS default */

html[data-theme="dark"] { ...dark tokens... }      /* manual dark override */

@media (prefers-color-scheme: dark) {
  html:not([data-theme]) { ...dark tokens... }     /* system dark, only when user hasn't picked */
}
```

Mermaid's `themeVariables` follow the same split: read `document.documentElement.dataset.theme`, else the media query.

### JS

```html
<script>
(function () {
  const KEY = 'visual-explainer:theme';
  const ORDER = ['auto', 'light', 'dark'];
  const mq = window.matchMedia('(prefers-color-scheme: dark)');

  function apply(theme) {
    if (theme === 'auto') {
      document.documentElement.removeAttribute('data-theme');
    } else {
      document.documentElement.setAttribute('data-theme', theme);
    }
    const btn = document.getElementById('themeToggle');
    if (btn) btn.title = 'Theme: ' + theme;
    document.documentElement.dispatchEvent(new CustomEvent('themechange', { detail: theme }));
  }

  const saved = localStorage.getItem(KEY);
  if (saved && ORDER.includes(saved)) apply(saved);

  mq.addEventListener('change', () => {
    if (!document.documentElement.dataset.theme) {
      document.documentElement.dispatchEvent(new CustomEvent('themechange', { detail: 'auto' }));
    }
  });

  const btn = document.getElementById('themeToggle');
  if (btn) btn.addEventListener('click', () => {
    const current = document.documentElement.dataset.theme || 'auto';
    const next = ORDER[(ORDER.indexOf(current) + 1) % ORDER.length];
    localStorage.setItem(KEY, next);
    apply(next);
  });
})();
</script>
```

**Mermaid re-render on theme change** (diagram pages only):

```html
<script type="module">
  import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';

  function isDark() {
    return document.documentElement.dataset.theme
      ? document.documentElement.dataset.theme === 'dark'
      : window.matchMedia('(prefers-color-scheme: dark)').matches;
  }

  function initMermaid() {
    mermaid.initialize({
      startOnLoad: true,
      theme: 'base',
      look: 'classic',
      themeVariables: isDark() ? DARK_VARS : LIGHT_VARS
    });
    mermaid.run({ nodes: [document.getElementById('mermaid-diagram')] });
  }

  initMermaid();

  document.documentElement.addEventListener('themechange', () => {
    const el = document.getElementById('mermaid-diagram');
    el.removeAttribute('data-processed');     // strip Mermaid's rendered output
    el.innerHTML = el.textContent;            // restore the raw diagram source
    initMermaid();                            // re-render with the new theme
  });
</script>
```

**Chart.js re-render on theme change** (chart pages only): keep a reference to the `Chart` instance and call `.destroy()` + recreate with the new palette, or simpler — reload the page (charts are cheap to redraw, but reload loses scroll position; prefer destroy/recreate).

---

## 2. Motion system

### Tokens

```css
:root {
  --ease-out:    cubic-bezier(0.16, 1, 0.3, 1);   /* exits, entrances */
  --ease-in-out: cubic-bezier(0.65, 0, 0.35, 1);  /* property changes */
  --dur-fast:    150ms;
  --dur-base:    300ms;
  --dur-slow:    500ms;
}
```

### Entrance animations

Elements get a reveal-up on load, staggered. `.ve-in` class:

```css
.ve-in { opacity: 0; animation: ve-in var(--dur-slow) var(--ease-out) forwards; }

@keyframes ve-in {
  from { opacity: 0; transform: translateY(8px); }
  to   { opacity: 1; transform: translateY(0); }
}

@media (prefers-reduced-motion: reduce) {
  .ve-in { animation: none; opacity: 1; }
}
```

Stagger via inline `style="animation-delay: 60ms"` per element (first viewport elements only — never stagger things far below the fold, it looks broken). Keep `animation-delay` under ~400ms total.

### SVG draw-in (diagram connectors, chart lines)

`stroke-dasharray`/`stroke-dashoffset` draw animation for hand-built SVG lines:

```css
.ve-draw {
  stroke-dasharray: 1;
  stroke-dashoffset: 1;
  animation: ve-draw 800ms var(--ease-in-out) forwards;
}
@keyframes ve-draw { to { stroke-dashoffset: 0; } }
```

Set `pathLength="1"` on the `<path>` so the dash math is normalized. Reduced-motion: no animation, full stroke visible.

### Count-up (KPI numbers)

```html
<script>
document.querySelectorAll('[data-count]').forEach(el => {
  const target = parseFloat(el.dataset.count);
  const reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  if (reduced) return;   // static value is already in the markup
  const dur = 900;
  const start = performance.now();
  function tick(now) {
    const p = Math.min((now - start) / dur, 1);
    const eased = 1 - Math.pow(1 - p, 3);   // easeOutCubic
    el.textContent = Math.round(target * eased).toLocaleString();
    if (p < 1) requestAnimationFrame(tick);
  }
  requestAnimationFrame(tick);
});
</script>
```

Static value stays in the markup so no-JS users see the real number.

### Hard rules

- Animate **`transform` and `opacity` only** — never layout properties (height, top, margin)
- Use the two named easings — never the browser default `ease`, never bounce/overshoot
- No continuous glow, pulse, or breathing on static content
- Reduced motion: everything instant, no exceptions
- Max one orchestrated entrance per page (staggered, not cascading)

---

## 3. Chart interactivity

### Hover tooltips (pure CSS, zero JS)

Position a tooltip with a `data-tip` attribute; show on hover/focus:

```css
[data-tip] { position: relative; cursor: default; }
[data-tip]::after {
  content: attr(data-tip);
  position: absolute;
  bottom: calc(100% + 8px);
  left: 50%;
  transform: translateX(-50%);
  background: var(--color-ink);
  color: var(--color-paper);
  font-family: var(--font-mono);
  font-size: var(--text-xs);
  padding: 4px 8px;
  border-radius: 4px;
  white-space: nowrap;
  opacity: 0;
  pointer-events: none;
  transition: opacity 150ms var(--ease-out);
}
[data-tip]:hover::after, [data-tip]:focus-visible::after { opacity: 1; }
@media (prefers-reduced-motion: reduce) { [data-tip]::after { transition: none; } }
```

Bars in the hand-built SVG get `data-tip="Jan — 360 users"` + `tabindex="0"` + `role="img"` so they're hoverable and keyboard-focusable. (SVG child elements can't reliably do CSS `::after`, so the `data-tip` pattern applies to HTML wrappers; for SVG use a sibling `<title>` element or a JS tooltip. The chart template uses HTML overlays — see it.)

### Bar highlight

Hovering a bar dims the others (via a group-level class) and raises the hovered bar's opacity to full + accent border. `:hover` on the SVG group with `.bar-group:hover .bar:not(:hover) { opacity: 0.4; }` — only works when bars are HTML elements or SVG with CSS vars; the chart template does this with HTML-positioned bars.

### Chart.js (only for complex data)

Chart.js gives tooltips, hover, and legends for free. Theme change = destroy + recreate with the new palette colors. CDN failure = chart doesn't render, but the page's takeaways and source note still tell the story.

---

## 4. Diagram interactivity

### Mermaid

- Mermaid's default: hover highlights edges/nodes in its own way — acceptable as-is
- **Re-render on theme change** is mandatory (pattern above)
- Zoom/pan controls only for genuinely complex diagrams (15+ nodes) — see visual-explainer's `diagram-shell` pattern; overkill for explainer-scale diagrams

### Hand-built SVG

- `data-tip` hover annotations for node explanations
- Optional **step-through** for processes: prev/next buttons that cycle a `data-step` attribute on the SVG, CSS reveals/hides stages:

```html
<div class="stepper">
  <button id="stepPrev" aria-label="Previous step">←</button>
  <span id="stepLabel" class="stepper-label">Step 1 of 4</span>
  <button id="stepNext" aria-label="Next step">→</button>
</div>
```

```css
.svg-stage [data-stage] { opacity: 0.15; transition: opacity 300ms var(--ease-in-out); }
.svg-stage[data-step="1"] [data-stage="1"] { opacity: 1; }
.svg-stage[data-step="1"] [data-stage="1"].focal { /* accent stroke */ }
```

```html
<script>
const stages = 4;
let step = 1;
const el = document.getElementById('stage');
function show(n) {
  step = Math.min(Math.max(n, 1), stages);
  el.dataset.step = step;
  document.getElementById('stepLabel').textContent = 'Step ' + step + ' of ' + stages;
}
document.getElementById('stepPrev').addEventListener('click', () => show(step - 1));
document.getElementById('stepNext').addEventListener('click', () => show(step + 1));
</script>
```

Only when motion clarifies ordered change — static diagrams stay static.

---

## 5. Options interactivity

The options page (UI mockup comparison) gets click-to-select:

- Each option card is a `<button class="option-card">` (button, not div — keyboard accessible)
- Click toggles `.selected` — accent border + check marker in the header
- Exactly one selected at a time (radio behavior); clicking the selected one deselects
- **The selection is NOT persisted and NOT recorded** — this is a visual aid, not a form. The user still tells the agent their pick in chat. Say this on the page: *"Click to mark a favourite — your choice is visual only; tell me in chat."*
- The recommended option (if any) starts with `.selected`

```js
document.querySelectorAll('.option-card').forEach(card => {
  card.addEventListener('click', () => {
    document.querySelectorAll('.option-card.selected').forEach(c => c.classList.remove('selected'));
    card.classList.add('selected');
  });
});
```

---

## 6. What never gets interactivity

- Explainer prose, takeaway bullets — static text
- Any content the user will screenshot — a toggle or tooltip shouldn't move the pixels
- Charts with <5 data points — a tooltip adds nothing over a value label
- Pages for print/export — no toggle, no animations

---

## 7. No-JS and reduced-motion contract

| User | Theme toggle | Animations | Tooltips | Step-through | Option select |
|---|---|---|---|---|---|
| No JS | None (light default) | None — content fully visible | None — value labels carry the info | All stages visible | No selection — cards read as static options |
| JS + reduced motion | Works | None — instant | Works | Works (instant transitions) | Works |
| JS + normal | Works | Works | Works | Works | Works |

Static markup must carry the complete meaning in every case. The interaction layer is enhancement, never the content.

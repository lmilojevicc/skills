# Interactivity — theme toggle, motion, and interaction patterns

Every page ships a small interaction layer. The templates already wire it; this file explains the patterns so you can extend them without breaking them.

**Core principle:** the page is complete and meaningful **without JavaScript**. No-JS users get the light theme, full static content and the Mermaid source as text. Reduced-motion users get no movement but keep every interaction. A CDN failure (Pele, Chart.js) must never blank the page.

---

## 1. Theme toggle (system / light / dark)

An icon button, top right: a monitor for system, a sun for light, a moon for dark. **System is the default**: the page follows `prefers-color-scheme` until the user picks. The button is `hidden` in the markup and shown by the script, so no-JS users never see a dead control.

- Cycles **system → light → dark → system**, persisted to `localStorage` key `visual-explainer:theme` (wrapped in `try`, storage can throw)
- Sets `data-theme="light" | "dark"` on `<html>`; system removes the attribute and the media query takes over
- The icon shown is chosen by CSS from `data-theme`; `aria-label` and `title` name the current theme
- Dispatches a `themechange` event on `<html>` for anything drawn from JS colours (Chart.js)

```html
<button class="theme-toggle" id="themeToggle" type="button" aria-label="Theme: system" title="Theme: system" hidden>
  <svg class="tt-system" viewBox="0 0 24 24" aria-hidden="true"><rect x="3" y="4" width="18" height="12" rx="2"/><path d="M8 20h8M12 16v4"/></svg>
  <svg class="tt-light" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/></svg>
  <svg class="tt-dark" viewBox="0 0 24 24" aria-hidden="true"><path d="M20 14.5A8 8 0 0 1 9.5 4a8 8 0 1 0 10.5 10.5z"/></svg>
</button>
```

```css
.theme-toggle {
  position: fixed; top: 16px; right: 16px; width: 36px; height: 36px;
  display: grid; place-items: center;
  color: var(--muted); background: none; border: 0; border-radius: var(--radius); cursor: pointer;
  transition: color 150ms var(--ease), background 150ms var(--ease);
}
.theme-toggle[hidden] { display: none; }   /* display: grid would override the hidden attribute */
.theme-toggle:hover { color: var(--ink); background: var(--surface); }
.theme-toggle svg {
  display: none; width: 18px; height: 18px;
  fill: none; stroke: currentColor; stroke-width: 1.5; stroke-linecap: round; stroke-linejoin: round;
}
html:not([data-theme]) .tt-system,
html[data-theme="light"] .tt-light,
html[data-theme="dark"] .tt-dark { display: block; }
```

Token structure:

```css
:root { /* light tokens: also the no-JS default */ }
html[data-theme="dark"] { /* dark tokens: manual override */ }
@media (prefers-color-scheme: dark) {
  html:not([data-theme]) { /* dark tokens: system, only when the user hasn't picked */ }
}
```

```html
<script>
  (function () {
    const KEY = 'visual-explainer:theme';
    const ORDER = ['system', 'light', 'dark'];
    const root = document.documentElement;
    const btn = document.getElementById('themeToggle');

    function apply(theme) {
      if (theme === 'system') root.removeAttribute('data-theme');
      else root.setAttribute('data-theme', theme);
      btn.setAttribute('aria-label', 'Theme: ' + theme);
      btn.title = 'Theme: ' + theme;
      root.dispatchEvent(new CustomEvent('themechange', { detail: theme }));
    }

    let saved = null;
    try { saved = localStorage.getItem(KEY); } catch (e) {}
    if (ORDER.includes(saved)) apply(saved);

    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
      if (!root.dataset.theme) root.dispatchEvent(new CustomEvent('themechange', { detail: 'system' }));
    });

    btn.hidden = false;
    btn.addEventListener('click', () => {
      const next = ORDER[(ORDER.indexOf(root.dataset.theme || 'system') + 1) % ORDER.length];
      try { localStorage.setItem(KEY, next); } catch (e) {}
      apply(next);
    });
  })();
</script>
```

**Diagrams need nothing here.** Pele draws with CSS variables, so a theme change recolours the SVG instantly. Hand-built SVG that uses `var(--…)` in its attributes behaves the same way.

**Chart.js** reads colours once. Listen for `themechange`, then `destroy()` and recreate the chart with colours read from the tokens. The pattern is in [`charts.md`](charts.md).

---

## 2. Motion

```css
:root { --ease: cubic-bezier(0.16, 1, 0.3, 1); }
```

### Entrance

One staggered fade-up on the first-screen blocks: header, then the visual, then the takeaways.

```css
.ve-in { animation: ve-in 400ms var(--ease) both; }
@keyframes ve-in { from { opacity: 0; transform: translateY(8px); } }
```

Stagger with inline `style="animation-delay: 60ms"` steps, at most ~300ms in total. Never stagger content far below the fold.

### Bars grow in

```css
.ve-bar { animation: ve-bar 600ms var(--ease) both; }
@keyframes ve-bar { from { transform: scaleY(0); } }
```

`transform-origin: bottom` on the bar; delays step 40ms per bar.

### SVG draw-in (hand-built connectors)

```css
.ve-draw { stroke-dasharray: 1; stroke-dashoffset: 1; animation: ve-draw 700ms var(--ease) forwards; }
@keyframes ve-draw { to { stroke-dashoffset: 0; } }
```

Set `pathLength="1"` on the path or line so the dash maths is normalised.

### Rules

- Animate `transform` and `opacity` only, never layout properties
- No bounce, pulse, glow, breathing, hover lifts or count-up numbers. The number in the markup is the number
- Reduced motion: everything instant, no exceptions

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after { animation: none !important; transition: none !important; }
}
```

---

## 3. Chart interactivity

### Hover tooltips (pure CSS)

A plain box, no arrow, label and value on one line:

```css
.bar-tip {
  position: absolute; bottom: calc(100% + 8px); left: 50%; transform: translateX(-50%);
  background: var(--ink); color: var(--bg);
  font-size: var(--fs-small); padding: 4px 8px; border-radius: 4px;
  white-space: nowrap; opacity: 0; pointer-events: none;
  transition: opacity 150ms var(--ease);
}
.bar-col:hover .bar-tip, .bar-col:focus-visible .bar-tip { opacity: 1; }
```

Each bar column gets `tabindex="0"` so keyboard users get the same tooltip. Value labels above the bars carry the data without hover.

### Dim the others on hover

```css
.chart:hover .bar-col:not(:hover) .bar { opacity: 0.45; }
```

---

## 4. Diagram interactivity

### Pele

- Diagrams that shrink to fit their container get zoom automatically (`zoom: 'auto'`, the default in `mount()`)
- `mount()` re-lays the diagram out when the container resizes; nothing to wire
- No re-render on theme change (see §1)

### Hand-built SVG: step-through

Only when an ordered change is the point. Prev and next buttons cycle `data-step`, and CSS shows each stage:

```html
<div class="stepper">
  <button id="stepPrev" type="button" aria-label="Previous step">←</button>
  <span id="stepLabel">1 of 4</span>
  <button id="stepNext" type="button" aria-label="Next step">→</button>
</div>
```

```css
.svg-stage [data-stage] { opacity: 0.2; transition: opacity 300ms var(--ease); }
.svg-stage[data-step="1"] [data-stage="1"] { opacity: 1; }
```

```html
<script>
  const stages = 4;
  let step = 1;
  const el = document.getElementById('stage');
  function show(n) {
    step = Math.min(Math.max(n, 1), stages);
    el.dataset.step = step;
    document.getElementById('stepLabel').textContent = step + ' of ' + stages;
  }
  document.getElementById('stepPrev').addEventListener('click', () => show(step - 1));
  document.getElementById('stepNext').addEventListener('click', () => show(step + 1));
</script>
```

Without JS no `data-step` is set, so add a rule that shows every stage in that case (`.svg-stage:not([data-step]) [data-stage] { opacity: 1; }`).

---

## 5. Option selection

- Each option is a `<button type="button" class="option" aria-pressed>`, keyboard accessible
- A click selects it: `.selected` draws a 2px accent outline. Exactly one at a time
- The recommended option (if any) ships selected
- **Nothing is recorded.** The page says so: *"Clicking a card only marks it on this page. Tell me your pick in chat."*

```js
document.querySelectorAll('.option').forEach(card => {
  card.addEventListener('click', () => {
    document.querySelectorAll('.option.selected').forEach(c => {
      c.classList.remove('selected');
      c.setAttribute('aria-pressed', 'false');
    });
    card.classList.add('selected');
    card.setAttribute('aria-pressed', 'true');
  });
});
```

---

## 6. What never gets interactivity

- Prose and takeaways
- Anything the user will screenshot: a toggle or tooltip shouldn't move pixels
- Charts with fewer than 5 values: a tooltip adds nothing over a value label
- Pages meant for print or export

## 7. No-JS and reduced-motion contract

| User | Theme toggle | Animations | Diagrams | Tooltips | Step-through | Option select |
|---|---|---|---|---|---|---|
| No JS | Hidden (follows system) | CSS only, content always visible | Mermaid source shown as text | Value labels carry the data | All stages visible | Cards read as static options |
| JS + reduced motion | Works | None | Rendered | Work | Works, instant | Works |
| JS | Works | Work | Rendered | Work | Works | Works |

# Diagrams — Mermaid, Excalidraw, and hand-built SVG

Choose the right tool for the diagram. Mix tools on one page when they serve different parts of the explanation.

## Tool selection

| Content shape | Tool | Why |
|---|---|---|
| Flows, pipelines, sequences, state machines, ER, class, mindmaps | **Mermaid** | Automatic layout, editable source, consistent look |
| Whiteboard-style sketches, non-technical concepts, hand-drawn feel, content the user will want to edit or extend | **Excalidraw** | Freeform, human, approachable. Users feel ownership over hand-drawn diagrams |
| Before/after states, layered cross-sections, mass/depth comparisons, editorial visuals Mermaid can't express | **Hand-built SVG/CSS** | Full layout control, editorial weight |
| 15+ elements | **Hybrid**: small Mermaid overview + CSS detail cards | One big diagram is unreadable |

**Mermaid vs Excalidraw:**

- Mermaid when the structure is the point — relationships, flow, connections matter more than position
- Excalidraw when the *feeling* is the point — brainstorming, non-technical explanation, "let me sketch this out"
- Excalidraw when the user is likely to say "can you add X" — it's editable by hand later
- Never render Mermaid to an image and call it "a diagram" — either let Mermaid render (interactive) or draw by hand

**Hand-built SVG** beats both when:
- You need a specific editorial composition (before/after split, layered depth)
- The diagram's meaning comes from visual weight, not connectivity
- Mermaid's automatic layout would fight the story you're telling

---

## Mermaid

### Loading

```html
<script type="module">
  import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';

  mermaid.initialize({
    startOnLoad: true,
    theme: 'base',
    look: 'classic',
    themeVariables: {
      primaryColor: '#e8f0ea',
      primaryBorderColor: '#5b7f6e',
      primaryTextColor: '#1c2a23',
      secondaryColor: '#f5efe6',
      secondaryBorderColor: '#a08a68',
      secondaryTextColor: '#3a2f20',
      tertiaryColor: '#eef0f4',
      tertiaryBorderColor: '#6b7a99',
      tertiaryTextColor: '#232a3a',
      lineColor: '#8a94a6',
      fontSize: '15px',
      fontFamily: 'var(--font-body)',
      noteBkgColor: '#fdf6e3',
      noteTextColor: '#3a2f20',
      noteBorderColor: '#c9a227'
    }
  });
</script>
```

Match `themeVariables` to the page palette. Never use `theme: 'default'`, `'dark'`, or `'neutral'` — they ignore most variable overrides. Never set `color:` in `classDef` or per-node `style` — it hardcodes text color and breaks dark/light switching.

### Type selection

| You want to show… | Mermaid type |
|---|---|
| Process flow, decisions, pipelines | `flowchart TD` |
| Request/response, temporal interactions | `sequenceDiagram` |
| Database tables and relationships | `erDiagram` |
| States and transitions | `stateDiagram-v2` |
| Class structure | `classDiagram` |
| Hierarchical breakdowns | `mindmap` |
| C4-style system context | `flowchart TD` + `subgraph` (never native `C4Context` — it hardcodes styling) |

### Layout direction

- `flowchart TD` (top-down) for anything with 5+ nodes, branching, or hierarchy — the default
- `flowchart LR` only for simple linear flows of 3–4 nodes

### Validity rules (Mermaid parse failures are the #1 issue)

- **Multi-line labels**: use `<br/>` in quoted labels, never escaped `\n`
- **Quote labels** containing `()`, `:`, `,`, `&`, `[]`, or `/` — wrap in double quotes
- **Node IDs**: alphanumeric, no spaces or punctuation. Readable name goes in the label: `userSvc["User Service"]`
- **Edge labels**: `-->|label|`, no pipe characters inside the label itself
- **Sequence diagram messages**: plain text only. No braces, brackets, angle brackets, or `&`. `A->>B: sends the request` — never code snippets
- **State diagram labels**: no `<br/>`, no parentheses, no extra colons. Use a `flowchart` instead if you need multi-line labels
- **Escape pipes** in labels with `#124;` or rephrase

### Arrow semantics

| Arrow | Meaning |
|---|---|
| `-->` | Primary flow |
| `-.->` | Optional, async, fallback |
| `==>` | Critical path |
| `--x` | Rejected or blocked |

### Complexity budgets

- Max 10–12 nodes per Mermaid diagram. Beyond that: split or use hybrid pattern (overview Mermaid + detail cards)
- Max 5 lifelines in a sequence diagram
- Max 8 entities in an ER diagram
- Subgraphs group related nodes: `subgraph Auth ... end`

### CSS overrides (after render)

```css
.mermaid .nodeLabel { color: var(--color-ink) !important; font-family: var(--font-body) !important; }
.mermaid .edgeLabel { color: var(--color-muted) !important; background-color: var(--color-paper) !important; font-family: var(--font-mono) !important; font-size: 12px !important; }
.mermaid .edgeLabel rect { fill: var(--color-paper) !important; }
.mermaid .focal rect, .mermaid .focal circle, .mermaid .focal polygon {
  stroke: var(--color-accent) !important;
  stroke-width: 2px !important;
}
```

Because these reference CSS variables, a theme toggle re-colors the rendered SVG instantly — no re-render needed for the accent stroke.

**Theme change:** Mermaid initializes once and can't react to CSS-only theme changes. On `themechange`, strip `data-processed`, restore the raw source from `textContent`, and call `mermaid.run()` again with the new `themeVariables`. Full pattern in [`interactivity.md`](interactivity.md) §1 and shipped in [`templates/diagram.html`](../templates/diagram.html).

Never define a page-level `.node` class — Mermaid uses it internally. Use namespaced classes (`.ve-node`, `.ve-card`).

---

## Excalidraw

Excalidraw is for hand-drawn-style diagrams. Two ways to embed:

### Option A: Full embedded canvas (interactive)

Load the Excalidraw npm package from CDN and render an editable canvas in an iframe-style container:

```html
<div id="excalidraw-container" style="height: 500px; border: 1px solid var(--border); border-radius: 8px;"></div>
<script type="module">
  import { Excalidraw } from 'https://esm.sh/@excalidraw/excalidraw@0.18.0';

  const App = () => {
    return React.createElement(Excalidraw, {
      initialData: {
        elements: [
          { type: 'rectangle', x: 100, y: 100, width: 200, height: 80, backgroundColor: '#e8f0ea', strokeColor: '#5b7f6e', strokeWidth: 2, roughness: 1 },
          { type: 'text', x: 130, y: 125, width: 140, height: 30, text: 'User Request', fontSize: 18, fontFamily: 1 },
          // ... more elements
        ],
        appState: { viewBackgroundColor: '#fafaf8', currentItemFontFamily: 1 }
      },
      langCode: 'en',
      viewModeEnabled: false
    });
  };

  // Requires React and ReactDOM from CDN too — see templates/diagram.html for the full pattern
</script>
```

The embedded canvas is fully editable — the user can move, add, delete elements. This is a feature: tell them so.

### Option B: Hand-drawn SVG (static, no dependency)

Render the Excalidraw aesthetic as hand-crafted SVG: rough strokes, hand-written-feel fonts, slightly irregular shapes:

```svg
<svg viewBox="0 0 800 400" style="font-family: 'Comic Neue', 'Segoe Print', cursive;">
  <!-- Hand-drawn box with rough stroke -->
  <path d="M100,100 L300,96 L302,180 L98,184 Z" fill="#e8f0ea" stroke="#5b7f6e" stroke-width="2.5" stroke-linejoin="round"/>
  <text x="200" y="145" text-anchor="middle" font-size="18">User Request</text>
  <!-- Hand-drawn arrow -->
  <path d="M305,140 C350,138 360,142 395,140" fill="none" stroke="#5b7f6e" stroke-width="2.5" stroke-linecap="round"/>
  <path d="M390,132 L398,140 L390,148" fill="none" stroke="#5b7f6e" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
```

Use fonts like **Comic Neue**, **Patrick Hand**, **Gochi Hand**, or **Architects Daughter** (Google Fonts) for the hand-written feel. Slightly irregular coordinates (100,100 vs 100,102) sell the sketch.

Use Option B for static diagrams that don't need editing, or when you can't guarantee the CDN dependency chain. Use Option A when user editing matters.

### Excalidraw file output

When the user wants to edit later in the Excalidraw app, write a `.excalidraw` JSON file alongside the HTML:

```json
{
  "type": "excalidraw",
  "version": 2,
  "source": "https://excalidraw.com",
  "elements": [
    {
      "type": "rectangle",
      "version": 1,
      "versionNonce": 1,
      "isDeleted": false,
      "id": "rect-1",
      "fillStyle": "hachure",
      "strokeWidth": 2,
      "strokeStyle": "solid",
      "roughness": 1,
      "opacity": 100,
      "angle": 0,
      "x": 100,
      "y": 100,
      "strokeColor": "#5b7f6e",
      "backgroundColor": "#e8f0ea",
      "width": 200,
      "height": 80,
      "seed": 1,
      "groupIds": [],
      "frameId": null,
      "roundness": null,
      "boundElements": [],
      "updated": 1,
      "link": null,
      "locked": false
    }
  ],
  "appState": {
    "gridSize": null,
    "viewBackgroundColor": "#fafaf8"
  },
  "files": {}
}
```

---

## Hand-built SVG diagrams

For editorial visuals Mermaid can't do. Common patterns:

### Before/after split

Two columns with a central arrow or divider. Same elements in both, changed parts highlighted in accent vs muted:

```
[ Before ]  →  [ After ]
```

Grey out removed elements, accent the changed ones. The *delta* is the story.

### Cross-section / layer stack

Horizontal bands showing layers a process passes through. Thin bands = shallow, thick bands = substantial:

```html
<div class="layers">
  <div class="layer" style="height: 28px;">Validation</div>
  <div class="layer" style="height: 28px;">Transformation</div>
  <div class="layer" style="height: 96px;">Core business logic</div>
  <div class="layer" style="height: 28px;">Persistence</div>
</div>
```

### Mass/depth comparison

Interface surface vs implementation size shown as two paired rectangles. Wide interface + thin implementation = shallow. Narrow interface + tall implementation = deep.

### Timeline

Horizontal line with events as dots, alternate above/below to save space. Use for processes, histories, roadmaps.

### Connector rules (any hand-built diagram)

- Arrows behind boxes (paint order: arrows first, then nodes)
- Orthogonal elbows (rounded right-angles) between off-axis nodes — never diagonal slants
- Arrow labels need an opaque background rect and a visible gap above the line
- Two connectors must never overlap or share an attach point — fan attach points ≥12px apart
- A connector must not pass behind a box that isn't its source or destination

---

## Diagram page structure

Copy [`templates/diagram.html`](../templates/diagram.html). Structure:

1. **Header** — eyebrow (small mono uppercase), title, one-sentence subtitle
2. **Diagram container** — the visual centerpiece, card-framed, max ~70vh so it's visible without scrolling
3. **Optional legend** — horizontal strip below the diagram, not floating inside it
4. **Optional summary** — 2–3 short takeaway bullets, not a paragraph
5. **Footer** — tiny mono colophon

For 4+ major sections, add a sticky TOC nav (see visual-explainer's `responsive-nav.md` pattern: fixed-position sidebar or top bar with anchor links).

**Accessibility**: every diagram gets `<title>` and `<desc>`. SVG diagrams get `role="img"` and `aria-labelledby`.

---

## Anti-patterns (diagram-specific)

- Reproducing Mermaid's default renderer layout in hand-built SVG — make editorial decisions instead
- Dark mode + cyan/purple glow as "technical" styling
- Identical boxes for every node — use fill/stroke/type to show hierarchy
- Legend floating inside the diagram area
- Vertical `writing-mode` text on arrows
- More than 2 accent-colored nodes ("everything is important" = nothing is)
- Diagonal slanted connectors between off-axis nodes
- One giant diagram with 20+ nodes when overview + detail cards would work

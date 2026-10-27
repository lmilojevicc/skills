# Diagrams — Mermaid, Excalidraw, and hand-built SVG

Choose the right tool for the diagram. Mix tools on one page when they serve different parts of the explanation.

## Tool selection

| Content shape | Tool | Why |
|---|---|---|
| Flows, pipelines, sequences, state machines, ER, class, mindmaps | **Mermaid via Pele** | Automatic layout, editable source, follows the page theme |
| Whiteboard-style sketches, non-technical concepts, hand-drawn feel, content the user will want to edit or extend | **Excalidraw** | Freeform, human, approachable. Users feel ownership over hand-drawn diagrams |
| Before/after states, layered cross-sections, mass/depth comparisons, editorial visuals Mermaid can't express | **Hand-built SVG/CSS** | Full layout control, editorial weight |
| 15+ elements | **Hybrid**: small Mermaid overview + detail panels | One big diagram is unreadable |

**Mermaid vs Excalidraw:**

- Mermaid when the structure is the point — relationships, flow, connections matter more than position
- Excalidraw when the *feeling* is the point — brainstorming, non-technical explanation, "let me sketch this out"
- Excalidraw when the user is likely to say "can you add X" — it's editable by hand later
- Never render Mermaid to an image and call it "a diagram": let Pele render it, or draw by hand

**Hand-built SVG** beats both when:
- You need a specific editorial composition (before/after split, layered depth)
- The diagram's meaning comes from visual weight, not connectivity
- Mermaid's automatic layout would fight the story you're telling

---

## Mermaid, rendered with Pele

Write diagrams in Mermaid syntax and render them with **[Pele](https://github.com/obsidianmd/pele)**, not Mermaid.js. Pele is a small renderer with no dependencies that supports every Mermaid diagram type and outputs SVG coloured by CSS variables. That means:

- The diagram takes the page tokens directly: no `themeVariables` block, no hex copies of the palette
- Theme changes recolour it instantly, with no re-render
- Its default look is already quiet: flat fills, thin borders, no shadows
- `mount()` fits the diagram to its container, switches wide flowcharts to vertical on phones, and adds zoom when the diagram has to shrink

### Loading

Put the Mermaid source in a `<pre class="mermaid">`. Without JS, or if the CDN fails, the source stays readable as text.

```html
<div class="diagram">
  <pre class="mermaid" data-label="Short description of the diagram for screen readers">
flowchart TD
  A["Login form"] --> B["Auth service"]
  class B focal
  </pre>
</div>

<script type="module">
  import { mount } from 'https://cdn.jsdelivr.net/npm/pele@1.3.0/dist/pele.js';

  await document.fonts.ready;
  for (const el of document.querySelectorAll('pre.mermaid')) {
    const source = el.textContent;
    const box = document.createElement('div');
    box.setAttribute('role', 'img');
    box.setAttribute('aria-label', el.dataset.label || 'Diagram');
    try {
      el.replaceWith(box);
      mount(box, source, { fontSize: 14 });
    } catch (err) {
      box.replaceWith(el);   // leave the source visible
      console.error(err);
    }
  }
</script>
```

Pin an exact version. Pele is new and moves fast; bump the pin deliberately after checking a release.

### Theming

Map the page tokens onto Pele's variables once, on the container:

```css
.diagram {
  --pele-bg: var(--surface);
  --pele-fg: var(--ink);
  --pele-muted: var(--muted);
  --pele-line: var(--muted);
  --pele-surface: var(--bg);
  --pele-surface-alt: var(--surface-2);
  --pele-border: var(--line);
  --pele-accent: var(--accent);
  --pele-font: var(--font-sans);
  --pele-font-mono: var(--font-mono);
  --pele-heading-weight: 500;
  --pele-title-weight: 500;
  --pele-radius: 4px;
}
/* The focal node: `class X focal` in the source adds .focal to the node */
.pele-node.focal :is(rect, path, polygon, circle, ellipse) { stroke: var(--accent); stroke-width: 2px; }
```

- Mark the focal path with `class A,B focal` in the source. One or two nodes, never more
- **Never** set colours in the source with `style`, `classDef … fill:` or `linkStyle`. Pele keeps those fixed, so they break dark mode
- Charts drawn by Pele (pie, xychart) use `--pele-series-1…8`. Set `--pele-series-1` to `var(--accent)` and the rest to greys, or draw the chart by hand (see [`charts.md`](charts.md))
- Class names for finer styling: `.pele-node`, `.pele-edge`, `.pele-edge-label`, `.pele-cluster`, `.pele-label`. Target one node with `.pele-node[data-id="start"]`

### Syntax check before delivery

A bad diagram renders as an error message, so check each diagram before it ships. Pele's `render()` throws a `PeleError` with the line at fault, and it runs in Node. Check in a **temp directory**, never in the project:

```bash
mkdir -p "$TMPDIR/pelecheck" && cd "$TMPDIR/pelecheck"
npm i pele@1.3.0
node --input-type=module -e "
  import { render } from 'pele';
  import { readFileSync } from 'node:fs';
  try { render(readFileSync(process.argv[1], 'utf8')); console.log('ok'); }
  catch (e) { console.error(e.message); process.exit(1); }
" diagram.mmd   # exit 0 + "ok", else the parse error and the line
```

Keep each diagram in its own `.mmd` first; that is what you paste into the page. The check uses the same parser the page uses, so a pass here means the page will render.

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

- Max ~9 nodes per Mermaid diagram. Beyond that: split, or use the hybrid pattern (Mermaid overview + detail panels)
- Max 5 lifelines in a sequence diagram
- Max 8 entities in an ER diagram
- Subgraphs group related nodes: `subgraph Auth ... end`

Never define a page-level `.node` class; use namespaced classes (`.ve-node`, `.ve-card`).

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
          { type: 'rectangle', x: 100, y: 100, width: 200, height: 80, backgroundColor: '#f1f1ef', strokeColor: '#171717', strokeWidth: 2, roughness: 1 },
          { type: 'text', x: 130, y: 125, width: 140, height: 30, text: 'User Request', fontSize: 18, fontFamily: 1 },
          // ... more elements
        ],
        appState: { viewBackgroundColor: '#fafaf9', currentItemFontFamily: 1 }
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
  <path d="M100,100 L300,96 L302,180 L98,184 Z" fill="#f1f1ef" stroke="#171717" stroke-width="2.5" stroke-linejoin="round"/>
  <text x="200" y="145" text-anchor="middle" font-size="18">User Request</text>
  <!-- Hand-drawn arrow -->
  <path d="M305,140 C350,138 360,142 395,140" fill="none" stroke="#171717" stroke-width="2.5" stroke-linecap="round"/>
  <path d="M390,132 L398,140 L390,148" fill="none" stroke="#171717" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
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
      "strokeColor": "#171717",
      "backgroundColor": "#f1f1ef",
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
    "viewBackgroundColor": "#fafaf9"
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

1. **Header** — `h1` naming what is shown, one-sentence lede. Nothing above the title
2. **Diagram panel** — the centerpiece on a `--surface` panel, max ~70vh so it's visible without scrolling
3. **Optional legend** — horizontal strip below the diagram, not floating inside it
4. **Optional summary** — 2–3 short takeaway bullets, not a paragraph
5. **Footer** — one small muted line

Keep a page to one or two visuals. If it needs four sections, it is two pages.

**Accessibility**: Pele diagrams get a `data-label` on the `<pre>`, which becomes the `aria-label`. Hand-built SVG gets `role="img"`, `<title>`, `<desc>` and `aria-labelledby`.

**Colours in hand-built SVG**: use the tokens in attributes (`fill="var(--bg)"`, `stroke="var(--line)"`), so the theme toggle works with no script. Nodes are `--bg` on the `--surface` panel with a `--line` border; connectors are `--muted`; the focal node gets an `--accent` stroke.

---

## Anti-patterns (diagram-specific)

- Reproducing Mermaid's default renderer layout in hand-built SVG — make editorial decisions instead
- Dark mode + cyan/purple glow as "technical" styling
- Identical boxes for every node — use fill/stroke/type to show hierarchy
- Legend floating inside the diagram area
- Vertical `writing-mode` text on arrows
- More than 2 accent-colored nodes ("everything is important" = nothing is)
- Diagonal slanted connectors between off-axis nodes
- One giant diagram with 20+ nodes when overview + detail panels would work
- Colours hard-coded in Mermaid source (`style`, `classDef fill:`); they won't follow the theme

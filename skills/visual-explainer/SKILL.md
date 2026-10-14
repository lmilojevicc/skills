---
name: visual-explainer
description: "Generate self-contained HTML pages with diagrams (Mermaid or Excalidraw), charts, and side-by-side visual comparisons to aid explanations. Use when an explanation would be clearer seen than read — comparing UI options or design directions, architecture or flow diagrams (technical or non-technical), spatial relationships, or numerical data the user is actively exploring or comparing. Do not use for files that merely exist, plain text answers, simple choices describable in words, or content a table or paragraph covers fine."
license: MIT
metadata:
  version: "1.0.0"
---

# Visual Explainer

Generate self-contained HTML pages that make explanations visual. One page per explanation, opened in the browser, with the conversation continuing in chat.

This skill is invoked by the model when it believes a visual would genuinely aid an explanation — not by explicit user request, though explicit requests are also handled.

---

## 1. The gate — invoke only when seeing beats reading

Before generating anything, run this test honestly:

> **Would the user understand this better by seeing it than by reading it?**

If yes, generate. If no, don't. If maybe, one short question: *"Want me to show this visually?"*

**Passes the gate (generate):**

- Comparing 2–4 UI layouts, design directions, or mockups side by side
- Architecture diagrams, system flows, request paths, state machines
- Spatial or relational content: entity relationships, hierarchies, org structures, before/after states
- Technical processes that are hard to follow in prose (pipelines, sequences, data flows)
- Non-technical concepts that benefit from a drawing (business processes, decision flows, concept maps)
- Numerical data the user is **actively exploring** — asking about trends, comparing categories, analyzing distributions, wanting to see the shape of the data
- Multi-dimensional comparisons that collapse into mush as text (5+ items across 2+ dimensions)

**Fails the gate (don't generate):**

- A CSV file, JSON dump, or dataset that merely exists or was mentioned. **Existence is not exploration.**
- "Summarize this data" where a short text summary or a small table does the job
- Single numbers, one-off facts, or data with fewer than ~5 comparable values
- Simple A/B choices fully describable in words ("sync or async?" — one sentence answers)
- Tradeoff lists, pros/cons, requirements clarifications
- Content that fits in a 3-column table or a short paragraph
- Questions about code that prose or a code block answers fine

**Invocation signals during a conversation:**

- The user says "show me", "visualize", "draw", "diagram", "compare options", "what are the alternatives"
- The explanation you're about to write needs "and then X calls Y which returns to Z" — that's a diagram
- You catch yourself writing a long description of layout, flow, or spatial arrangement
- The user is asking about the shape, trend, or distribution of data that has been loaded or queried

**Anti-signals (do NOT invoke):**

- A data file appears in the project or conversation without the user asking about its contents
- The user asked a yes/no or one-word question
- The answer is a paragraph or less
- The user is reading or discussing prose, not structure

**Escalation rule:** if you're unsure, ask once. *"This might be clearer as a quick visual — want me to render it?"* One question, not a debate.

---

## 2. Workflow

### 2.1 Pick the representation

Route by what the content *is*:

| Content | Representation | Reference |
|---|---|---|
| Graph-shaped: flows, pipelines, sequences, ER, state machines, class, mindmap | **Mermaid** in an HTML page | [`references/diagrams.md`](references/diagrams.md) |
| Spatial, hand-drawn feel, whiteboard-style, non-technical audience, user will want to edit | **Excalidraw** (embedded canvas or `.excalidraw` file) | [`references/diagrams.md`](references/diagrams.md) |
| Editorial visuals Mermaid can't express: before/after states, mass/depth diagrams, layered cross-sections | **Hand-built SVG/CSS** | [`references/style.md`](references/style.md) |
| Numerical data being explored: trends, comparisons, distributions, parts of a whole | **Chart** (hand-built SVG for simple, Chart.js for complex) | [`references/charts.md`](references/charts.md) |
| 2–4 genuinely different options: UI mockups, architectures, approaches | **Side-by-side comparison** | [`references/options.md`](references/options.md) |
| 15+ element architecture or mixed content | **Hybrid**: small Mermaid overview + CSS detail cards | [`references/diagrams.md`](references/diagrams.md) |

Mix representations on one page when it serves the explanation. Don't lean on one renderer for everything — a Mermaid diagram next to a hand-built before/after SVG is more effective than two Mermaid diagrams.

**Technical vs non-technical:**

- **Technical audience**: Mermaid, mono labels for ports/paths, precise terminology, denser information
- **Non-technical audience**: Excalidraw or simplified visuals, plain-language labels, fewer nodes, human metaphors, no jargon. A hand-drawn style reads friendlier than a graph-rendered flowchart
- When unsure, match the vocabulary the user has been using in the conversation

### 2.2 Pick the style

Commit to one aesthetic direction before writing HTML. The default system is **Hallmark editorial** — warm-oat OKLCH palette, Fraunces display + IBM Plex Sans body + JetBrains Mono outlier, hairlines over card borders, one terracotta accent, left-biased layout. Simple and crowd-appealing on purpose. Full system in [`references/style.md`](references/style.md) — load it first, every time.

**Every page also ships an interaction layer** (theme toggle, restrained motion, hover affordances). Read [`references/interactivity.md`](references/interactivity.md) and wire the patterns that fit the page — the templates already include them.

Style must fit the content voice:

| Content | Aesthetic |
|---|---|
| Technical architecture, code-adjacent | Hallmark editorial default — clean, precise, mono accents |
| Business process, non-technical | Hallmark editorial + hand-drawn lean (Excalidraw, Comic Neue annotations) |
| Data exploration | Hallmark editorial, data-dense, restrained, no decoration |
| UI option comparison | Hallmark editorial frame; options carry their own style |

Default is light editorial (warm oat paper, ink text, terracotta accent). Dark mode auto-applies via `prefers-color-scheme` — the templates ship both.

### 2.3 Write the HTML

Copy the matching template from [`templates/`](templates/):

- [`templates/base.html`](templates/base.html) — minimal scaffold, fill in the visual
- [`templates/diagram.html`](templates/diagram.html) — Mermaid and/or Excalidraw centerpiece
- [`templates/chart.html`](templates/chart.html) — data chart centerpiece
- [`templates/options.html`](templates/options.html) — side-by-side comparison

**Every page must be a complete, self-contained HTML document**: embedded CSS, data-URI favicon, CDN scripts only for Mermaid/Excalidraw/Chart.js, no other dependencies. Pages must render meaningfully even if a CDN fails — put the Mermaid source or a text fallback in the page.

**Prose discipline**: diagrams carry the weight. Sparse labels, short captions, no paragraphs. If the visual needs a paragraph to be understood, redraw the visual. The detailed explanation stays in chat.

### 2.4 Write and open

1. Write to `~/.visual-explainer/<slug>-<timestamp>.html` (descriptive slug: `auth-flow.html`, `sidebar-options.html`). If home isn't writable, use the OS temp dir and tell the user the path.
2. Open in the browser: `open <path>` (macOS), `xdg-open <path>` (Linux), `start <path>` (Windows).
3. Give a 1–3 sentence summary in chat: what's on screen, what to look at, and how to respond. Never re-explain the whole page in chat — that defeats the point.
4. Continue the conversation. If the user gives feedback that changes the visual, write a new file (don't overwrite the old one unless told to).

### 2.5 Close the loop

- For **option comparisons**: the user's pick becomes the implementation contract. Don't re-ask what they already chose.
- For **diagrams**: if the user wants changes, edit and regenerate. Don't offer to explain the diagram in chat instead — they asked to see it.
- If the user says the visual wasn't helpful, drop the approach — don't push another visual. Say so and answer in text.

---

## 3. Reference routing

Read only what the current output needs:

| Need | Read |
|---|---|
| Any Mermaid diagram, Excalidraw embed, or hand-built SVG diagram | [`references/diagrams.md`](references/diagrams.md) |
| Any chart from numerical data | [`references/charts.md`](references/charts.md) |
| Any page (all of them) | [`references/style.md`](references/style.md) |
| Theme toggle, motion, hover tooltips, step-through, option selection | [`references/interactivity.md`](references/interactivity.md) |
| Side-by-side option comparison | [`references/options.md`](references/options.md) |

Templates are always available; copy the closest one and adapt. The templates ship the toggle, animation, and interaction wiring pre-built — start from them rather than reimplementing.

---

## 4. Non-negotiable quality rules

These apply to every page. Details in the references.

1. **No AI-slop palette**: no violet/fuchsia/indigo defaults (`#8b5cf6`, `#7c3aed`, `#d946ef`), no cyan+magenta+purple neon, no gradient-mesh blobs, no pure `#000`/`#fff`
2. **No AI-slop typography**: no Inter, Roboto, Arial, or bare system-ui as the body font. Default pairing: Fraunces + IBM Plex Sans + JetBrains Mono (see [`references/style.md`](references/style.md))
3. **OKLCH custom properties** for all palette values (`--color-paper`, `--color-ink`, `--color-accent`, …). Hex equivalents only in SVG attributes, Mermaid `themeVariables`, Chart.js, and favicons
4. **Hairlines, not card borders or shadows**. Depth comes from weight, size, and color. Max radius 8px
5. **Accent discipline**: 1–2 focal elements in accent color per visual, ≤3% of any viewport. Everything else ink/muted
6. **Complexity budgets**: max ~9 nodes per diagram, max ~8 bars, max ~5 line series. Over budget → split into overview + detail
7. **No horizontal overflow** at desktop width; `min-width: 0` on grid/flex children; `overflow-x: clip` on html and body
8. **Interaction layer ships by default**: theme toggle (light/dark/auto, persisted), entrance animations under 500ms, hover affordances where they add signal. `prefers-reduced-motion` respected; no continuous animations; animate only `transform`/`opacity`. Patterns in [`references/interactivity.md`](references/interactivity.md)
9. **Pages remain complete without JS** — static markup carries the full meaning; toggle, tooltips, and animations are enhancement
10. **Mermaid**: `theme: 'base'` with `themeVariables` matching the page palette (hex); re-render on theme change; never bare `<pre class="mermaid">` without proper theming
11. **Every font weight used must be loaded** — no faux-bold; `font-display: swap` on all web fonts

---

## 5. Final checklist

Before delivering:

- [ ] Gate honestly passed (seeing beats reading)
- [ ] Complete HTML document, self-contained, data-URI favicon
- [ ] Written to `~/.visual-explainer/` (or temp dir with path told to user)
- [ ] Opened in browser (or open command given)
- [ ] Chat summary is 1–3 sentences, not a re-explanation
- [ ] No Inter/Roboto/Arial/system-ui body font; Fraunces + IBM Plex Sans + JetBrains Mono loaded
- [ ] OKLCH tokens in CSS; hex only in SVG/Mermaid/Chart.js/favicon contexts
- [ ] No violet/fuchsia/neon palette; no pure black/white
- [ ] Accent used on ≤2 focal elements
- [ ] Hairlines, not shadows; no card-in-card
- [ ] Within complexity budgets
- [ ] No horizontal overflow, no console errors; `overflow-x: clip` on html/body
- [ ] Theme toggle present, persisted, and Mermaid re-renders on change
- [ ] Reduced motion: animations collapse to instant; content fully visible
- [ ] No-JS contract: static markup carries the complete meaning
- [ ] Prose sparse — visuals carry the meaning

---
name: visual-explainer
description: "Generate self-contained, minimal HTML pages with diagrams (Mermaid via Pele, or Excalidraw), charts, and side-by-side visual comparisons to aid explanations. Use when an explanation would be clearer seen than read — comparing UI options or design directions, architecture or flow diagrams (technical or non-technical), spatial relationships, or numerical data the user is actively exploring or comparing. Do not use for files that merely exist, plain text answers, simple choices describable in words, or content a table or paragraph covers fine."
license: MIT
metadata:
  version: "1.1.0"
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
| Graph-shaped: flows, pipelines, sequences, ER, state machines, class, mindmap | **Mermaid**, rendered with **Pele** | [`references/diagrams.md`](references/diagrams.md) |
| Spatial, hand-drawn feel, whiteboard-style, non-technical audience, user will want to edit | **Excalidraw** (embedded canvas or `.excalidraw` file) | [`references/diagrams.md`](references/diagrams.md) |
| Editorial visuals Mermaid can't express: before/after states, mass/depth diagrams, layered cross-sections | **Hand-built SVG/CSS** | [`references/style.md`](references/style.md) |
| Numerical data being explored: trends, comparisons, distributions, parts of a whole | **Chart** (hand-built SVG for simple, Chart.js for complex) | [`references/charts.md`](references/charts.md) |
| 2–4 genuinely different options: UI mockups, architectures, approaches | **Side-by-side comparison** | [`references/options.md`](references/options.md) |
| 15+ element architecture or mixed content | **Hybrid**: small Mermaid overview + detail panels | [`references/diagrams.md`](references/diagrams.md) |

Mix representations on one page when it serves the explanation. A Mermaid diagram next to a hand-built before/after SVG beats two Mermaid diagrams.

**Mermaid diagrams render with [Pele](https://github.com/obsidianmd/pele), not Mermaid.js.** Pele is small, has no dependencies, and colours the SVG with CSS variables, so diagrams take the page palette and follow the theme toggle without a re-render. Setup and the syntax check are in [`references/diagrams.md`](references/diagrams.md).

**Technical vs non-technical:**

- **Technical audience**: Mermaid, precise terminology, denser information
- **Non-technical audience**: Excalidraw or simplified visuals, plain-language labels, fewer nodes, human metaphors, no jargon. A hand-drawn style reads friendlier than a graph-rendered flowchart
- When unsure, match the vocabulary the user has been using in the conversation

### 2.2 Style: one quiet system

Every page uses the same minimal system, so there is no style to pick. It follows the anti-slop house rules of [taste-skill](https://github.com/leonxlnx/taste-skill): **IBM Plex Mono headings, IBM Plex Sans text**, a neutral stone ground, full-ink text, one blue accent on the focal element only, panels separated by a step in tone rather than lines or shadows, and no ornaments (no eyebrows, tracked caps, pills, index numbers, gradients). Light and dark ship together. Full system in [`references/style.md`](references/style.md); read it first, every time.

**Every page also ships a small interaction layer** (theme toggle, one restrained entrance, hover affordances where they add signal). See [`references/interactivity.md`](references/interactivity.md); the templates already include it.

For a non-technical audience, keep the same page and lean on simpler visuals: fewer nodes, plain-language labels, or an Excalidraw sketch. UI option previews carry their own style inside the preview; the page around them stays plain.

### 2.3 Write the HTML

Copy the matching template from [`templates/`](templates/):

- [`templates/base.html`](templates/base.html) — minimal scaffold, fill in the visual
- [`templates/diagram.html`](templates/diagram.html) — Mermaid and/or Excalidraw centerpiece
- [`templates/chart.html`](templates/chart.html) — data chart centerpiece
- [`templates/options.html`](templates/options.html) — side-by-side comparison

**Every page must be a complete, self-contained HTML document**: embedded CSS, data-URI favicon, Google Fonts, and CDN scripts only for Pele, Excalidraw or Chart.js, pinned to exact versions. Pages must render meaningfully even if a CDN fails: the Mermaid source stays in the page as text until Pele replaces it.

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
| Any Mermaid diagram (Pele), Excalidraw embed, or hand-built SVG diagram | [`references/diagrams.md`](references/diagrams.md) |
| Any chart from numerical data | [`references/charts.md`](references/charts.md) |
| Any page (all of them) | [`references/style.md`](references/style.md) |
| Theme toggle, motion, hover tooltips, step-through, option selection | [`references/interactivity.md`](references/interactivity.md) |
| Side-by-side option comparison | [`references/options.md`](references/options.md) |

Templates are always available; copy the closest one and adapt. The templates ship the toggle, animation, and interaction wiring pre-built — start from them rather than reimplementing.

---

## 4. Non-negotiable quality rules

These apply to every page. Details in the references.

1. **Type**: IBM Plex Mono for headings, figures and code; IBM Plex Sans for everything else, labels and axis ticks included. Four sizes. Sentence case. Load every weight used, `display=swap`
2. **Palette**: the hex tokens in [`references/style.md`](references/style.md), shared by CSS, SVG, Pele and Chart.js. No cream with terracotta, no violet/indigo/fuchsia, no neon, no gradients
3. **Accent discipline**: the accent marks 1–2 focal elements per visual. Everything else ink, muted or `--bar`
4. **No ornaments**: no eyebrows above titles, no tiny tracked uppercase labels, no pill badges, no 01/02/03 numbering, no hairline section dividers, no shadows on things at rest, no icons in tinted circles, no emoji
5. **Surfaces by tone**: panels are `--surface` on `--bg`, no borders around them, one 6px radius, no card in card
6. **Complexity budgets**: ~9 nodes per diagram, 8 bars, 3 line series. Over budget → split into overview + detail
7. **No horizontal overflow** at any width; `min-width: 0` on grid/flex children; `overflow-x: clip` on html and body; equal side margins
8. **Interaction layer ships by default**: theme toggle (icon button; system by default, then light and dark; persisted), one entrance under 500ms, hover where it adds signal. `transform`/`opacity` only; `prefers-reduced-motion` makes everything instant
9. **Pages remain complete without JS**: static markup carries the full meaning
10. **Mermaid renders with Pele**, pinned version, themed through `--pele-*` variables mapped to the page tokens. Never hard-code colours in the Mermaid source (`style`, `classDef fill:`); mark the focal node with `class X focal`

## 5. Final checklist

Before delivering:

- [ ] Gate honestly passed (seeing beats reading)
- [ ] Complete HTML document, self-contained, data-URI favicon
- [ ] Written to `~/.visual-explainer/` (or temp dir with path told to user)
- [ ] Opened in browser (or open command given)
- [ ] Chat summary is 1–3 sentences, not a re-explanation
- [ ] Mono headings, sans text; nothing above the `h1`
- [ ] Page tokens only; no hard-coded colours in CSS, SVG or Mermaid source
- [ ] Accent on ≤2 focal elements
- [ ] No eyebrows, tracked caps, pills, shadows, gradients or section rules
- [ ] Within complexity budgets
- [ ] Every Mermaid diagram passed the Pele syntax check
- [ ] No horizontal overflow at 390px, no console errors
- [ ] Theme toggle works in both directions; diagrams and charts follow it
- [ ] Reduced motion: everything instant; content fully visible
- [ ] No-JS: static markup carries the complete meaning
- [ ] Prose sparse: visuals carry the meaning

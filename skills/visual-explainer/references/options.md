# Options — side-by-side visual comparison

When the user needs to choose between 2–4 approaches and the difference is **visual** (UI mockups, layouts, architecture shapes, design directions), render them side by side. When the options are describable in words, don't — answer in chat.

## The sameness trap

**The #1 failure: options that differ only in color, wording, or variable names.**

The test: could a stakeholder with strong opinions pick one and reject the others for substantive reasons? If all options lead to roughly the same implementation, they're not distinct options — they're one option with noise.

| Bad (variants of one idea) | Good (genuinely different directions) |
|---|---|
| Three microservices diagrams with slightly different boundaries | Monolith vs microservices vs serverless |
| Three card layouts with different accent colors | Editorial vs terminal vs brutalist UI directions |
| REST endpoint naming variations | REST vs GraphQL vs RPC |
| Same flow with different arrow styles | Sync vs async vs event-sourced |

**Vary the structural approach, not the presentation of it.**

## How many options

- **2–4 per comparison.** More than 4 overwhelms
- If the space has 5+ viable approaches, pick the 3 most representative and say what else was considered
- 1 option isn't a comparison — it's a mockup. Render it alone

## Structure

Copy [`templates/options.html`](../templates/options.html):

1. **Header** — title naming the decision ("Which sidebar layout?"), one-sentence context framing what the user is choosing
2. **Options grid** — 2 columns for 2 options, 3 columns for 3, 2×2 for 4. Wide content (architecture diagrams) gets full-width stacked rows instead
3. Each option card contains:
   - **Label** (A, B, C) + name
   - **Preview** — the visual itself: HTML mockup, Mermaid diagram, SVG, or code block
   - **Tradeoff line** — one sentence, honest about what this option gives up. No option is all-win
4. **Recommendation** (optional) — a subtle badge or border accent on one option, with one sentence why. Only when the model actually has a defensible position
5. **Response prompt** — one line: "Which direction feels right? Tell me and I'll build it out."

## Option preview content

### UI mockups (HTML)

Self-contained HTML snippets inside each card. Realistic enough to compare, not pixel-perfect:

- Real layout, real type hierarchy, real spacing — not wireframe placeholders
- Use the project's actual content when available ("Dashboard", "Orders", real nav items)
- Each option must read as a complete direction, not a fragment
- Same viewport size for all options — comparison fairness
- **No fake browser chrome** (URL bars, traffic-light dots) — the user's browser supplies real chrome

### Architecture diagrams (Mermaid)

One diagram per option, same zoom level, same level of abstraction. Vary:

- Structural paradigm (monolith/microservices/serverless, sync/async/event-driven)
- Tradeoff priority (simplicity vs scale vs flexibility)
- Boundary placement (where the seams are)

### Code patterns

Show enough code to reveal the philosophy — the call site, the types, the error handling where approaches diverge. Not the whole file.

### Distinctness rules for visual options

- **Palettes with character** — commit to a direction per option (editorial, terminal, warm noir, brutalist) rather than three blue variants
- **Typography creates hierarchy** — headlines 3–4x body size, dramatic weight contrast (800 vs 300)
- **Layout differs** — asymmetric vs grid, dense vs airy, single-column vs split

## Interactivity — click-to-select

Option cards are `<button>` elements (keyboard accessible). Clicking selects — exactly one at a time:

- `.selected` gets the accent border and a ✓ check marker in the header
- The recommended option (if any) ships pre-selected
- **Selection is visual only** — nothing is persisted, recorded, or sent anywhere. The page says so: *"Click a card to mark a favourite — the selection is visual only. Tell me your pick in chat."*
- The user's chat answer remains the implementation contract, not the click

Full pattern in [`interactivity.md`](interactivity.md) §5 and shipped in [`templates/options.html`](../templates/options.html).

## After the user picks

- The pick becomes the implementation contract. Don't re-ask or second-guess
- If the user wants to merge aspects of two options ("B's layout with A's palette"), that's a new option — render it before building
- If the user rejects all options, ask what direction was missing before rendering more

## When NOT to use options

- Text-based choices (sync vs async explained in one sentence each) — chat
- Tradeoff lists, pros/cons tables — chat or a small table
- "Which name do you like?" — chat
- Requirements gathering, scope questions — chat

Options pages are for when **seeing the difference** is the point.

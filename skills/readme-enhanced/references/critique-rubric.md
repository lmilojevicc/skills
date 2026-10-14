# README Quality Rubric & Case Studies

Use this 10-point rubric to audit, grade, and refine any repository README.

---

## 1. The 10-Point Quality Rubric

| # | Check | Target Standard | Failure Mode |
|---|---|---|---|
| **1** | **The 5-Second Test** | A reader knows what the project does and who it's for within 5 seconds. | Jargon soup ("Next-gen paradigm-shifting developer abstraction layer"). |
| **2** | **Time-to-First-Value (TTFV)** | Quickstart is visible above the fold or right below the hero. User can run a command in under 60 seconds. | Burying install instructions below 5 screens of architecture essays (SuperPlane failure). |
| **3** | **Visual Evidence** | Hero screenshot, GIF demo, or terminal output shows proof of life. | Wall of dry prose with zero visual proof. |
| **4** | **Layout & Alignment Discipline** | Consistent visual alignment. Centered hero lockups stay strictly centered; content sections stay left-aligned. | Inconsistent alignment mixing centered and left-aligned elements haphazardly (Recordly failure). |
| **5** | **Badge Curation** | 3–6 modern badges from [shieldcn.dev](https://shieldcn.dev). Linked to actual targets. Dark/light adaptive where needed. | 20 unaligned, unclickable badges from obsolete services. |
| **6** | **Copy-Pasteable Quickstart** | Every code snippet is syntactically valid and runnable without unstated hidden prerequisites. | Snippets with missing imports, uninstalled dependencies, or placeholder syntax that fails. |
| **7** | **Common Recipes / Cheat Sheet** | Shows 4–8 common real-world operations or code patterns for quick reference. | Forcing the user to search external documentation just to find basic daily commands. |
| **8** | **Scope Discipline** | README is a **landing page**, not a doc dump. In-depth configuration tables, API references, and architecture specs belong in `/docs`. | 2,000-line README containing exhaustive flag dictionaries and change history. |
| **9** | **Responsive & Cross-Theme Assets** | Logos and diagrams render properly in both GitHub dark and light modes via `<picture>`. Images have width bounds. | Black-on-transparent logos that vanish in dark mode; giant 4K images that break horizontal scrolling. |
| **10** | **Orientation & Next Steps** | Clear, curated links to `/docs`, website, issue tracker, changelog, or community channels. | Dead ends with no guidance on where to go next. |

---

## 2. Case Studies: The Good, The Mediocre, and The Flawed

### Case Study A: `jdx/mise` (Grade: A+)
- **Why It Excels**:
  - **Centered Hero Lockup**: Clean `<picture>` adaptive logo, title, and shieldcn-style badges.
  - **Single-Sentence Value Pitch**: *"Dev tools, env vars, and tasks in one CLI"*.
  - **Visual Demo**: High-quality GIF demonstration with a link to a full command transcript.
  - **Progressive Quickstart**:
    1. Install binary.
    2. Try a tool immediately with `mise exec node@24 -- node -v` without shell configuration.
    3. Set up a project directory.
    4. Optional shell activation.
  - **Strict Scope Discipline**: Advanced documentation lives on `mise.jdx.dev`.

### Case Study B: `charmbracelet/huh` (Grade: A+)
- **Why It Excels**:
  - **Immediate Visual Impact**: A terminal tape GIF showing the interactive burger order form.
  - **15-Line Hello World**: A concise, copy-pasteable Go example that any developer can run instantly.
  - **Modular Explanations**: Breaks down core concepts (`Form`, `Group`, `Field`) with micro-snippets.
  - **Accessible Mode**: Highlights accessibility features upfront.

### Case Study C: `vorssaint/vorssaint-utils` (Grade: A)
- **Why It Excels**:
  - **High-Value Pitch**: *"One menu bar icon doing the job of a dozen paid Mac apps. Install only what you use."*
  - **Side-by-Side UI Gallery**: Shows 4 compact panel screenshots side-by-side (`width="196"`), giving an immediate visual overview of the entire suite.
  - **Privacy First**: Explicitly addresses data privacy and telemetry above the fold.
  - **Platform Clarity**: Clear badge indicating macOS 14+ and Apple Silicon requirement.

### Case Study D: `mikefarah/yq` (Grade: A)
- **Why It Excels**:
  - **Cheat-Sheet First**: Features a "Quick Usage Guide" showing immediate CLI invocations for read, pipe, update in-place, merge, and format conversions.
  - **Binary Download Prominence**: Direct links to precompiled releases for zero-dependency usage.

### Case Study E: `webadderallorg/Recordly` (Grade: C+)
- **What Went Wrong (Alignment & Visual Hierarchy)**:
  - Header mixes centered logo and badges with left-aligned headings and uncentered links.
  - An unconstrained full-width image is followed by random horizontal rules (`---`) and an uncentered sponsor logo.
  - Inconsistent heading sizes (`###` before `##` before `#`).
  - **The Fix**: Standardize the hero into a centered block, bound image dimensions, and maintain consistent heading hierarchy.

### Case Study F: `superplanehq/superplane` (Grade: B-)
- **What Went Wrong (Missing TTFV)**:
  - Gorgeous top banner, but immediately dives into high-level conceptual tables ("How the factory works", "Built around your stack").
  - Lacks a quickstart or "Try it in 60 seconds" section near the top. Readers leave without knowing how to run or test the software.
  - **The Fix**: Add an immediate "Try SuperPlane in 60 Seconds" section with a 1-line Docker command or sandbox link directly under the value pitch.

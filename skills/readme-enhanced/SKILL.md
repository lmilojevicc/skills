---
name: readme-enhanced
description: Design and write user-first, high-converting READMEs that function as repository landing pages. Use when creating a new README, auditing, rewriting, or polishing an existing README, selecting modern badges via shieldcn.dev, structuring repo orientation, or optimizing time-to-first-value for CLI tools, apps, libraries, and services.
---

# README Enhanced

A repository `README.md` is the **landing page** of a software project, not a location for exhaustive documentation. Its primary purpose is to orient visitors within 5–10 seconds, articulate the core value proposition, provide proof of quality, and guide the user to their first successful interaction as quickly as possible. Deep architectural specs, exhaustive API dictionaries, and multi-page guides belong in `/docs`.

Read the bundled references relative to this skill directory as needed:
- `references/archetypes.md` — Section blueprints for CLIs, GUI/web apps, libraries, services, and plugins.
- `references/shieldcn-guide.md` — Complete endpoint and theming guide for [shieldcn.dev](https://shieldcn.dev) badges.
- `references/visual-assets.md` — Screenshot sizing, responsive `<picture>` tags, VHS tapes, and the user interview protocol.
- `references/critique-rubric.md` — 10-point audit checklist and case studies (`mise`, `huh`, `vorssaint-utils`, `yq`, `Recordly`, `superplane`).

---

## Core Execution Workflow

Follow these five steps when creating or overhauling a README:

```text
1. Discover & Classify Archetype
   ↓
2. Visual Asset Audit & Interview (if visual)
   ↓
3. Badge Selection with shieldcn.dev
   ↓
4. Draft Content with Immediate Time-to-First-Value (TTFV)
   ↓
5. Audit against the 10-Point Rubric
```

### Step 1: Discover & Classify the Repository Archetype

Inspect the workspace (manifest files, entry points, binary targets) to identify the project's archetype:

| Archetype | Indicators | Priority Focus | Reference Model |
|---|---|---|---|
| **CLI Tool** | Binaries, argument parsers, terminal commands | 1-line install, immediate test command (`tool -v`), cheat sheet | `jdx/mise`, `mikefarah/yq` |
| **GUI / App** | Electron, Tauri, Swift, React/Vue web UI | Visual hero gallery, platform compatibility, direct download | `vorssaint-utils` |
| **Library / SDK** | Exported modules, package registry targets | 15-line copy-pasteable "Hello World", package manager install | `charmbracelet/huh` |
| **Service / Infra** | Dockerfiles, compose files, servers, microservices | 60-second spin-up (`docker-compose up`), architecture diagram | `superplane` (+ TTFV) |
| **Plugin / Skill** | GitHub Actions (`action.yml`), agent skills, configs | Copy-paste workflow step, input/output table | Modern action READMEs |

Consult `references/archetypes.md` for the exact markdown layout and section order for the chosen archetype.

---

### Step 2: Visual Asset Audit & Interview

If the project produces visible output (GUI windows, web dashboards, TUI terminal prompts, data visualizations, colorized CLI output):

1. **Check for existing assets**: Search `assets/`, `docs/`, `media/`, `public/`, or repository history for images, logos, or recordings.
2. **Conduct the Asset Interview**: If assets are missing or incomplete, ask the user before writing the final README:
   > "This project has a visual interface. Do you have any of the following assets to showcase in the README?
   > 1. **Logo / Icon** (SVG or PNG, light/dark variants)
   > 2. **Demo Recording** (GIF, asciinema, or Charm VHS tape)
   > 3. **Screenshots** (Key views or side-by-side feature panels)
   >
   > If you have them, share their paths or URLs. If not, I can create structured placeholders and recommend tools (like VHS or ray.so) to generate them."
3. **Format Media with Strict Alignment**:
   - Always wrap light/dark logos in GitHub `<picture>` tags.
   - Constrain dimensions (`width="720"` for heroes, `width="48%"` for side-by-side grids).
   - Read `references/visual-assets.md` for syntax and layout rules.

---

### Step 3: Select Modern Badges via shieldcn.dev

Recommend and use [shieldcn.dev](https://shieldcn.dev/) badges. They provide modern shadcn/ui-styled buttons (Inter typography, refined border radii, crisp tokens) and GitHub dark/light mode responsiveness.

1. **Limit to 3–6 High-Value Badges**:
   - Release / Package Version (npm, Crates.io, PyPI, GitHub release)
   - Build / CI Status
   - License (open-source terms)
   - Community / Popularity (Discord, GitHub stars)
2. **Adaptive Dark/Light Syntax**:
   Wrap badges in `<picture>` elements so they adapt cleanly across dark and light GitHub themes:
   ```html
   <a href="https://github.com/{owner}/{repo}/releases">
     <picture>
       <source media="(prefers-color-scheme: dark)" srcset="https://shieldcn.dev/github/v/release/{owner}/{repo}.svg?theme=dark" />
       <source media="(prefers-color-scheme: light)" srcset="https://shieldcn.dev/github/v/release/{owner}/{repo}.svg?theme=light" />
       <img alt="Latest Release" src="https://shieldcn.dev/github/v/release/{owner}/{repo}.svg" />
     </picture>
   </a>
   ```
3. Consult `references/shieldcn-guide.md` for full provider patterns, charts, and header banners.

---

### Step 4: Draft Content with Immediate Time-to-First-Value (TTFV)

Structure the document so a reader gets value in their first 60 seconds:

1. **Hero Lockup (Strictly Centered or Crisp Left)**:
   - Logo + H1 Name + 1-sentence value pitch ("What it is and why you need it").
   - Navigation jump links (`Website · Quickstart · Features · Documentation`).
   - Badge row (clickable).
   - Primary visual hook (demo GIF or hero panel).
2. **The 60-Second Quickstart**:
   - **For CLIs**: 1-line install command + immediate test invocation showing expected output.
   - **For Libraries**: Package install command + complete 10–20 line working snippet with imports.
   - **For Apps**: OS-specific download links / brew cask command + primary launch instruction.
   - **For Services**: 1-step `docker compose up` command + curl health check.
3. **Common Commands / Daily Recipes**:
   - Provide a 4–8 item cheat sheet covering the most frequent daily actions.
4. **Feature Highlights**:
   - 3–5 bullet points or side-by-side visual cards emphasizing outcomes, not just mechanisms.
5. **Docs Delegation & Next Steps**:
   - Do NOT dump full API tables or multi-page configuration guides here.
   - Provide clear signposts: *"For advanced configuration, plugins, and full API reference, see [the documentation](./docs)."*

---

### Step 5: Audit Against the 10-Point Rubric

Before presenting the README, verify it against `references/critique-rubric.md`:

- [ ] **5-Second Test Passed**: Value proposition is crystal clear without marketing fluff.
- [ ] **TTFV Front and Center**: User can install and run within 60 seconds.
- [ ] **Visual Proof Present**: Hero image, terminal tape, or UI gallery included.
- [ ] **Consistent Visual Alignment**: Centered hero remains strictly centered; body sections stay left-aligned (no Recordly-style misalignment).
- [ ] **Clean Badge Row**: 3–6 relevant badges from shieldcn.dev, properly linked.
- [ ] **Snippets are Executable**: No unstated prerequisites or broken code samples.
- [ ] **Common Recipes Included**: Cheat sheet available for everyday tasks.
- [ ] **Scope Discipline Maintained**: Deep reference material is delegated to `/docs`.
- [ ] **Cross-Theme Tested**: Images and badges render properly in dark and light modes.
- [ ] **Clear Next Steps**: Explicit orientation links for deeper exploration.

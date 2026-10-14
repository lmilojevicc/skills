# Repository Archetypes & Layout Templates

Every repository belongs to an archetype with distinct user expectations. Match the README structure to the archetype to minimize friction and deliver immediate value.

---

## 1. CLI Tool Archetype
*(Inspired by `jdx/mise` and `mikefarah/yq`)*

CLI users care about **speed, dependencies, and immediate usability**. They want to know:
- Does it require a runtime (Node/Python/Ruby) or is it a standalone binary?
- How do I install it in one line?
- What does the output look like right now?

### Section Blueprint
1. **Hero**: Title, 1-sentence value pitch, badges ([shieldcn.dev](https://shieldcn.dev)), and navigation bar.
2. **Demo**: Terminal GIF (VHS tape) or rendered CLI output block.
3. **Quickstart (Time-to-First-Value)**:
   - Step 1: 1-line install command (`curl`, `brew`, `cargo`, `npm`)
   - Step 2: Immediate executable test command with expected output comment
   - Step 3: Minimal real-world usage example
4. **Common Commands / Cheat Sheet**: 4–8 most frequent recipes formatted with clear comments.
5. **Key Features**: Bullet list of standout capabilities.
6. **Installation Matrix**: Collapsible or clean table covering package managers (Homebrew, Cargo, npm, apt, winget, Docker).
7. **Orientation & Docs**: Clear pointer to `/docs` for advanced flags and configuration.

---

## 2. GUI / Desktop / Web App Archetype
*(Inspired by `vorssaint/vorssaint-utils`)*

Visual app users scan with their eyes before reading a single paragraph. They want to see:
- What does the app look like?
- Does it run on my OS (macOS, Windows, Linux, Web)?
- Where is the download link?
- Is it private, bloated, or subscription-locked?

### Section Blueprint
1. **Hero (Centered Lockup)**:
   - Adaptive logo (`<picture>` with dark/light mode)
   - H1 Title
   - Tagline highlighting key benefit (e.g. "One menu bar icon doing the job of a dozen paid apps")
   - Navigation links (`Website · Download · Features · Privacy · Docs`)
   - Platform & release badges from [shieldcn.dev](https://shieldcn.dev)
2. **Immediate Visual Hook**: Side-by-side screenshot gallery (e.g. 2–4 panels at `width="48%"`) or video hero.
3. **Value Proposition**: 2–3 sentences on the core philosophy (e.g., zero telemetry, native performance, modular).
4. **Download & Installation**:
   - Direct download links (`.dmg`, `.exe`, `.AppImage`)
   - Package manager one-liners (`brew install --cask ...`, `winget install ...`)
5. **Feature Highlights (Visual-Backed)**:
   - 3–5 key capabilities, each paired with a focused screenshot or mini-GIF.
6. **Privacy & Permissions**: Clear disclosure of required system permissions and data handling.
7. **Docs & Community**: Links to `/docs` and Discord/Discussions.

---

## 3. Library / SDK / Framework Archetype
*(Inspired by `charmbracelet/huh`)*

Developers consuming a library want **code, types, and developer ergonomics**. They want:
- How do I import it?
- Show me a working "Hello World" in 15 lines of code.
- What are the core primitives?
- Where are the API reference and docs?

### Section Blueprint
1. **Hero**: Package name, tagline, badges (Package version, docs status, CI build, license).
2. **Visual Demo**: GIF or syntax-highlighted screenshot showing the library in action.
3. **Installation**: One-line package manager command (`npm install`, `cargo add`, `go get`, `pip install`).
4. **Hello World (Copy-Pasteable)**:
   - A 10–20 line complete, working, runnable example.
   - Self-contained with imports and minimal comments.
5. **Core Concepts / Primitives**:
   - 3–4 foundational abstractions (e.g. Form, Group, Field).
   - Brief code snippets showing composition.
6. **Feature Matrix / Comparison** (optional): When to choose this library vs alternatives.
7. **Next Steps**: Link to full API reference (TypeDoc, docs.rs, pkg.go.dev) and repository `/docs`.

---

## 4. Service / Backend / Infrastructure Archetype
*(Inspired by `superplane` + fixing TTFV)*

DevOps and backend engineers need **trust, architecture, and fast spinup**. They want:
- What system components are involved (DB, queues, workers)?
- Can I spin it up in Docker Compose in 30 seconds to test?
- What third-party services does it integrate with?

### Section Blueprint
1. **Hero**: System name, punchy tagline, badges, and quick links.
2. **Value Summary**: Who is this for and what workflow does it automate?
3. **Try It in 60 Seconds (TTFV)**:
   - `docker-compose up` snippet or 1-line curl script or hosted sandbox link.
   - Verified default port and test command (`curl localhost:8080/health`).
4. **Architecture / Flow Diagram**:
   - Clean Mermaid diagram or standalone SVG showing how data flows through the system.
5. **Integration Matrix**: Table of supported databases, cloud providers, and auth systems.
6. **Configuration Overview**: Essential environment variables (with link to `/docs/configuration.md` for the exhaustive list).
7. **Deployment & Production**: Brief overview with links to `/docs/deploy`.

---

## 5. Plugin / GitHub Action / Agent Skill Archetype

Integration users want **instant copy-paste configuration**. They want:
- How do I drop this into my workflow or agent?
- What are the required inputs and what outputs are returned?
- Real-world configuration examples.

### Section Blueprint
1. **Hero**: Tool name, tagline, compatibility badge.
2. **Quickstart**:
   - Complete GitHub Action YAML step or Agent Skill installation command (`pi install ...` / `npx skills add ...`).
3. **Inputs & Configuration Table**:
   - Clean markdown table: `Input`, `Required`, `Default`, `Description`.
4. **Outputs Table**:
   - `Output`, `Type`, `Description`.
5. **Real-World Recipes**:
   - 2–3 practical workflow snippets (e.g., PR comments, slack notifications, caching).
6. **Security & Permissions**: Required tokens or secret scopes.
7. **Full Documentation**: Link to `/docs`.

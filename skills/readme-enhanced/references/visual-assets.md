# Visual Assets & Media Guide

Visual assets transform a repository README from a wall of dry text into an engaging, high-converting product landing page. In developer tooling, seeing is believing: a 5-second GIF or a pair of screenshots conveys interface quality, polish, and UX faster than hundreds of words.

---

## 1. When is a Repo "Visual"?

A repository requires visual assets if it produces visible user output:
- **GUI & Desktop Apps** (Electron, Tauri, native macOS/Windows/Linux apps, menu bar apps)
- **Web Applications & Dashboards** (Next.js, Vite, Vue, Svelte, administrative panels)
- **TUI & Rich CLIs** (terminal tools using spinners, interactive prompts, colorized tables, huh/bubbletea, ink, ratatui)
- **Data Visualization & Charting Libraries** (plotting libraries, graph generators, diagram tools)
- **Design Systems & Component Libraries** (shadcn blocks, Tailwind kits, UI component packs)
- **Browser Extensions & Developer Plugins**

---

## 2. The Visual Asset Interview Protocol

When you detect that a repository has a visual component, check the workspace for existing assets (e.g., `assets/`, `docs/`, `media/`, `public/`, `screenshots/`, `demo.gif`, `logo.svg`).

If assets are missing or incomplete, **prompt the user** before drafting the README:

> "I see this project has a visual interface (CLI/TUI/GUI/Web). Do you have any of the following assets we can include to make the README pop?
> 1. **Logo / Icon**: An SVG or PNG mark (ideally with dark and light variants)
> 2. **Demo Recording**: A GIF, asciinema, or Charm VHS tape demonstrating core usage
> 3. **Screenshots**: High-resolution captures of the key UI views or terminal output
>
> If you have them, let me know where they are stored. If not, I can create placeholders and recommend quick ways to capture them."

### Recommended Asset Capture Tools for Users
- **Terminal TUIs & CLIs**: [Charm VHS](https://github.com/charmbracelet/vhs) (declarative tape to GIF), [asciinema](https://asciinema.org)
- **Code Snippets**: [ray.so](https://ray.so) or [carbon.now.sh](https://carbon.now.sh)
- **Desktop / Web Screenshots**: CleanShot X, Shottr, or browser responsive screenshot tools
- **GIF Optimization**: `ffmpeg` or `gifsicle` to keep GIF size under 3MB for fast loading

---

## 3. Formatting & Alignment Rules

A major reason why some READMEs look amateurish (e.g. Recordly) is **misalignment**—mixing centered elements with left-aligned elements arbitrarily, using inconsistent margins, or letting giant images break page flow.

### Rule 1: Maintain Centered Hero Discipline
If you choose a centered header block, **everything in the hero must be centered**:
- Logo image
- Repository title (`<h1>`)
- Short tagline (`<p>`)
- Navigation jump links (`<p>`)
- Badges container (`<p>`)
- Primary hero visual / demo GIF (`<p>`)

Once the hero concludes (typically after a `<hr />` or clear spacing), transition cleanly to **left-aligned** standard markdown headings (`## What is X?`, `## Quickstart`).

```html
<!-- CORRECT: Clean centered hero lockup -->
<div align="center">

  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/logo-dark.svg">
    <img src="assets/logo-light.svg" alt="Project Logo" width="160">
  </picture>

  <h1>Project Name</h1>

  <p><b>A blazing-fast schema migration tool for SQLite and Postgres</b></p>

  <p>
    <a href="https://example.com">Website</a> ·
    <a href="#quickstart">Quickstart</a> ·
    <a href="#features">Features</a> ·
    <a href="./docs">Documentation</a>
  </p>

  <p>
    <a href="https://github.com/org/repo/releases"><img src="https://shieldcn.dev/github/v/release/org/repo.svg" alt="Release"></a>
    <a href="https://github.com/org/repo/actions"><img src="https://shieldcn.dev/github/actions/org/repo/ci.svg" alt="Build"></a>
    <a href="LICENSE"><img src="https://shieldcn.dev/github/license/org/repo.svg" alt="License"></a>
  </p>

  <p>
    <img src="assets/demo.gif" alt="Demo of Project in action" width="720">
  </p>

  <hr />

</div>

## What is Project Name?
```

### Rule 2: Responsive Dark/Light Logos via `<picture>`
Always provide a fallback and use GitHub's native `prefers-color-scheme` matching:
```html
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/logo-dark.svg" />
  <img src="assets/logo-light.svg" alt="Logo" width="200" />
</picture>
```

### Rule 3: Side-by-Side Feature Grids
For GUI apps with multiple panels (like `vorssaint-utils`), avoid stacking 6 full-screen images vertically. Present them side-by-side in responsive blocks:
```html
<p align="center">
  <img src="assets/panel-a.png" width="48%" alt="Feature A UI" />
  <img src="assets/panel-b.png" width="48%" alt="Feature B UI" />
</p>
```

### Rule 4: Constrain Dimensions
Never use raw full-resolution images without a width constraint:
- Banner / Hero GIFs: `width="720"` or `width="800"` (or `width="100%"` for banners)
- Single UI screenshots: `width="640"` to `width="800"`
- Icons / Logos: `width="120"` to `width="240"`
- Side-by-side cards: `width="48%"` or `width="32%"`

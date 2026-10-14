<div align="center">

  <h1>README Enhanced</h1>

  <p><b>Agent skill for creating user-first, high-converting repository READMEs that act as landing pages</b></p>

  <p>
    <a href="#quickstart">Quickstart</a> ·
    <a href="#core-philosophy">Core Philosophy</a> ·
    <a href="#archetypes">Archetypes</a> ·
    <a href="#badge-design">Badges</a> ·
    <a href="./SKILL.md">Skill Instructions</a>
  </p>

  <p>
    <a href="https://github.com/jal-co/shieldcn">
      <picture>
        <source media="(prefers-color-scheme: dark)" srcset="https://shieldcn.dev/badge/badges-shieldcn.dev-black.svg?theme=dark" />
        <source media="(prefers-color-scheme: light)" srcset="https://shieldcn.dev/badge/badges-shieldcn.dev-black.svg?theme=light" />
        <img alt="Badges powered by shieldcn.dev" src="https://shieldcn.dev/badge/badges-shieldcn.dev-black.svg" />
      </picture>
    </a>
    <a href="LICENSE">
      <picture>
        <source media="(prefers-color-scheme: dark)" srcset="https://shieldcn.dev/badge/license-MIT-blue.svg?theme=dark" />
        <source media="(prefers-color-scheme: light)" srcset="https://shieldcn.dev/badge/license-MIT-blue.svg?theme=light" />
        <img alt="License MIT" src="https://shieldcn.dev/badge/license-MIT-blue.svg" />
      </picture>
    </a>
  </p>

  <hr />

</div>

## What is readme-enhanced?

`readme-enhanced` is a specialized coding agent skill designed to turn GitHub repository READMEs into **high-converting landing pages**.

Most open-source READMEs fail in one of two ways: they are either a dry, 2,000-line "doc dump" that buries the installation instructions, or an unformatted wall of text with broken visual hierarchy and missing examples. `readme-enhanced` provides structured blueprints, modern badge patterns via [shieldcn.dev](https://shieldcn.dev), and rapid **Time-to-First-Value (TTFV)** workflows.

---

## Quickstart

### 1. Install the Skill Package in Pi

Install locally or point Pi to this package directory:

```bash
pi install ./skills/readme-enhanced
```

Or install directly into your personal agent skills directory:

```bash
cp -r ./skills/readme-enhanced ~/.pi/agent/skills/
```

### 2. Invoke the Skill

Ask your agent to audit or author a README:

```text
"Create a user-first README for this CLI tool following readme-enhanced guidelines."
```

Or force direct execution:

```text
/skill:readme-enhanced audit this repository's README
```

---

## Core Philosophy

1. **The README is a Landing Page**: Its job is orientation, motivation, and conversion—not exhaustive reference.
2. **5-Second Value Pitch**: Visitors must understand what problem the repo solves before scrolling.
3. **Immediate Time-to-First-Value (TTFV)**: Put executable quickstarts and common commands within reach in under 60 seconds.
4. **Docs Delegation**: In-depth architecture specs, multi-page configuration tables, and API references belong in `/docs`.
5. **Modern Badges**: Use [shieldcn.dev](https://shieldcn.dev/) for clean, shadcn-styled buttons with native GitHub dark/light `<picture>` theming.

---

## Supported Repo Archetypes

| Archetype | Focus | Reference Case Study |
|---|---|---|
| **CLI Tools** | 1-line install, instant test command, common recipes cheat sheet | `jdx/mise`, `mikefarah/yq` |
| **GUI & Desktop Apps** | Adaptive logo, side-by-side screenshot gallery, platform clarity | `vorssaint/vorssaint-utils` |
| **Libraries & SDKs** | 15-line copy-pasteable "Hello World", package manager install | `charmbracelet/huh` |
| **Services & Infra** | 60-second spin-up (`docker compose up`), architecture flow diagram | `superplane` (+ TTFV) |
| **Plugins & Skills** | Copy-paste workflow YAML step, input/output summary table | Modern GitHub Actions |

---

## What's Included

```text
readme-enhanced/
├── package.json                   # Standalone Pi package manifest
├── README.md                      # Orientation & quickstart
├── SKILL.md                       # Agent execution workflow & rules
└── references/
    ├── archetypes.md              # Section blueprints & layout templates
    ├── shieldcn-guide.md          # shieldcn.dev badge, banner & chart guide
    ├── visual-assets.md           # Screenshot grids, VHS tapes & interview protocol
    └── critique-rubric.md         # 10-point audit rubric & case study critiques
```

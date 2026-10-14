# shieldcn Badge & Banner Guide

[shieldcn.dev](https://shieldcn.dev) is a modern badge image service designed as an aesthetic alternative to legacy badge generators. Badges render with shadcn/ui button aesthetics (Inter font, modern border radii, clean borders, consistent padding, and deliberate color tokens).

## Why shieldcn Over Legacy Badges?

1. **Modern Aesthetic**: Matches the clean design standards of contemporary developer tooling (shadcn/ui, Tailwind, Radix).
2. **Unified Typography & Padding**: Avoids the pixelated or uneven fonts common in legacy badges.
3. **Adaptive Dark/Light Theming**: Supports GitHub's `prefers-color-scheme` via `<picture>` elements.
4. **First-Class Charts & Banners**: Provides dynamic star history, download trends, and header banners from the same service.
5. **Fast & Free**: Edge-cached, zero config, open source.

---

## 1. Core Badge URL Patterns

shieldcn uses intuitive provider endpoints: `https://shieldcn.dev/{provider}/{target}.svg`

### Common Endpoints

| Provider | Purpose | URL Pattern |
|---|---|---|
| **GitHub Stars** | Show repo popularity | `https://shieldcn.dev/github/stars/{owner}/{repo}.svg` |
| **GitHub Release** | Latest release tag | `https://shieldcn.dev/github/v/release/{owner}/{repo}.svg` |
| **GitHub Workflow** | CI / test status | `https://shieldcn.dev/github/actions/{owner}/{repo}/{workflow}.svg` |
| **GitHub License** | Project license | `https://shieldcn.dev/github/license/{owner}/{repo}.svg` |
| **npm Version** | Latest npm package version | `https://shieldcn.dev/npm/{package}.svg` |
| **npm Downloads** | Weekly / monthly downloads | `https://shieldcn.dev/npm/dw/{package}.svg` |
| **Crates.io** | Rust crate version | `https://shieldcn.dev/crates/v/{crate}.svg` |
| **PyPI** | Python package version | `https://shieldcn.dev/pypi/v/{package}.svg` |
| **Docker Hub** | Pulls or image size | `https://shieldcn.dev/docker/pulls/{user}/{repo}.svg` |
| **Discord** | Online member count | `https://shieldcn.dev/discord/{guild_id}.svg` |
| **Static Badge** | Arbitrary label + value | `https://shieldcn.dev/badge/{label}-{value}-{color}.svg` |

---

## 2. GitHub Theme Adaptation (Dark & Light Mode)

GitHub supports native theme detection via the HTML `<picture>` tag. Use this pattern so badges look crisp on both dark and light reader themes:

```html
<p align="center">
  <a href="https://github.com/{owner}/{repo}/releases">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://shieldcn.dev/github/v/release/{owner}/{repo}.svg?theme=dark" />
      <source media="(prefers-color-scheme: light)" srcset="https://shieldcn.dev/github/v/release/{owner}/{repo}.svg?theme=light" />
      <img alt="Latest Release" src="https://shieldcn.dev/github/v/release/{owner}/{repo}.svg" />
    </picture>
  </a>
  <a href="https://github.com/{owner}/{repo}/actions">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://shieldcn.dev/github/actions/{owner}/{repo}/ci.svg?theme=dark" />
      <source media="(prefers-color-scheme: light)" srcset="https://shieldcn.dev/github/actions/{owner}/{repo}/ci.svg?theme=light" />
      <img alt="CI Status" src="https://shieldcn.dev/github/actions/{owner}/{repo}/ci.svg" />
    </picture>
  </a>
  <a href="LICENSE">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://shieldcn.dev/github/license/{owner}/{repo}.svg?theme=dark" />
      <source media="(prefers-color-scheme: light)" srcset="https://shieldcn.dev/github/license/{owner}/{repo}.svg?theme=light" />
      <img alt="License" src="https://shieldcn.dev/github/license/{owner}/{repo}.svg" />
    </picture>
  </a>
</p>
```

---

## 3. Customizing Badge Appearance

shieldcn badges accept URL query parameters:

- **`variant`**: `default` | `outline` | `secondary` | `ghost` | `destructive`
- **`theme`**: `dark` | `light` | `zinc` | `slate` | `neutral`
- **`logo`**: icon name from Simple Icons or Lucide (e.g. `?logo=github`, `?logo=rust`, `?logo=typescript`)
- **`label`**: override default label text

### Example Variants:
```markdown
<!-- Outline badge -->
![stars](https://shieldcn.dev/github/stars/{owner}/{repo}.svg?variant=outline)

<!-- Secondary badge -->
![version](https://shieldcn.dev/npm/{package}.svg?variant=secondary)
```

---

## 4. Charts and Header Banners

shieldcn can render visual charts and header banners directly in markdown:

### Star History Chart
```markdown
<p align="center">
  <img src="https://shieldcn.dev/chart/github/stars/{owner}/{repo}.svg" alt="GitHub Star History" width="700" />
</p>
```

### Repository Header Banner
```markdown
<p align="center">
  <img src="https://shieldcn.dev/header/minimal.svg?title=MyProject&tagline=The+high-performance+data+engine" alt="Project Banner" width="100%" />
</p>
```

---

## 5. Curation Rules for Badges

1. **Cap at 3–6 badges**: A wall of 15 badges creates visual noise and causes readers to scroll past without absorbing information.
2. **Focus on high-signal metrics**:
   - Package version (Release / npm / Crates.io)
   - Build / CI status (reassurance that code works)
   - License (open-source terms)
   - Community (Discord / Stars / Downloads)
3. **Always wrap badges in links**: Clicking a badge should navigate directly to its destination (releases page, npm package, workflow run, or license file). Never leave an unclickable badge image.
4. **Group on a single line**: Keep badges together in one centered or left-aligned container.

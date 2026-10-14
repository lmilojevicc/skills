# Charts — visualizing numerical data

Charts are for data the user is **actively exploring**. Never generate a chart just because a data file exists.

## Pre-flight: does this data deserve a chart?

| Situation | Answer |
|---|---|
| User asks about trends, comparisons, distributions, or "the shape of the data" | Chart |
| User asks "what's the biggest/smallest/fastest" | Chart (bar or summary) |
| User is comparing categories or time periods | Chart |
| User asked a yes/no or single-number question | No chart — answer in text |
| Data has fewer than 4–5 comparable values | No chart — a sentence or small table |
| Data just exists in a file, user hasn't engaged with it | No chart |

## Chart type selection

| You want to show… | Use | Rules |
|---|---|---|
| Discrete categories compared (sales by month, features by adoption) | **Bar / column** | 4–8 bars. More → group or split. Horizontal bars when labels are long |
| Trends over time (growth, latency over releases) | **Line** | 4–12 points. Max 5 series. Only the focal series gets vertex dots |
| Parts of a whole (market share, budget split) | **Pie / donut** | 2–6 slices. Never 3D. Never for comparison (bar is better) |
| Two-variable relationship or distribution | **Scatter** | Max ~30 points. Mark outliers |
| Multiple entities scored on criteria (skill matrices, benchmarks) | **Radar** | Max 5 axes, max 5 series, 1 focal |
| Hierarchy with quantities (conversion funnel, org size) | **Pyramid / funnel** | Max 6 layers |
| Single value that matters | **Big number** (stat card) | One number, styled prominently. More honest than a chart for 1 data point |

## Honesty rules — non-negotiable

1. **Y-axis starts at zero** for bar charts. A truncated axis distorts magnitude comparison
2. **No fabricated data.** Only chart numbers that actually exist in the conversation, file, or codebase. If the user didn't supply a number, don't invent one
3. **Polyline, not spline** — smoothed curves lie about sampled data
4. **Label the axes** or make units obvious. A chart without units is decoration
5. **No 3D** — ever. No shadows, no extrusions, no depth effects
6. **Accent ≤ 1 bar/series/slice** — the focal point. Everything else muted
7. **Don't connect discontinuous data** across gaps

## Rendering choice

### HTML bars (default — hoverable, animated, zero dependencies)

Copy the pattern from [`templates/chart.html`](../templates/chart.html). Bars are flex children styled with CSS custom properties, which gives hover dimming, tooltips, and grow-in animation for free — no JS, no CDN.

- Bar heights are percentages of the tallest bar (`style="height: 62%"`)
- The focal bar gets class `focal` — accent fill, accent value label
- Each bar column carries a `.bar-tip` tooltip (pure CSS, shows on hover/focus) and `tabindex="0"` for keyboard access
- Bars grow in on load via `.ve-bar`; reduced-motion users see them static
- Hovering a column dims siblings (`.chart:hover .bar-col:not(:hover) .bar { opacity: 0.25; }`)

This is the right choice for explainer-scale charts (≤ 8 bars) because every interactive affordance works without JavaScript or CDN dependencies.

### Hand-built SVG (when you need axes, gridlines, or exact coordinates)

Full layout control for line charts, scatter, radar — anything the HTML-bar pattern can't express. SVG patterns below stay available. Add the draw-in animation class `ve-draw` with `pathLength="1"` to lines (see [`interactivity.md`](interactivity.md)).

Bar chart pattern:

```svg
<svg viewBox="0 0 1000 500" role="img" aria-labelledby="chart-title chart-desc">
  <title id="chart-title">Monthly active users</title>
  <desc id="chart-desc">Bar chart showing monthly active users from January to June</desc>

  <!-- Gridlines (4-6 horizontal) -->
  <line x1="80" y1="100" x2="960" y2="100" stroke="rgba(45,49,66,0.08)" stroke-width="0.8"/>
  <!-- ... -->

  <!-- Y-axis labels: right-aligned mono, muted -->
  <text x="72" y="104" text-anchor="end" font-size="12" font-family="var(--font-mono)" fill="var(--text-dim)">1000</text>
  <!-- ... -->

  <!-- Bars: pitch ~110px, bar ~72px -->
  <rect x="140" y="280" width="72" height="140" fill="rgba(79,93,117,0.15)" stroke="var(--text-dim)" stroke-width="1"/>
  <!-- Focal bar: accent fill/stroke -->
  <rect x="250" y="180" width="72" height="240" fill="rgba(214,122,72,0.12)" stroke="var(--accent)" stroke-width="1"/>

  <!-- Value labels above bars -->
  <text x="176" y="272" text-anchor="middle" font-size="12" font-family="var(--font-mono)" fill="var(--text-dim)">420</text>
  <!-- ... -->
</svg>
```

Plot area margins: left 80px, bottom 60px, top 40px, right 40px.

Line chart pattern:

```svg
<!-- Focal series -->
<polyline points="140,320 300,280 460,240 620,200 780,160"
          fill="none" stroke="var(--accent)" stroke-width="1.8" stroke-linejoin="round"/>
<circle cx="140" cy="320" r="4" fill="var(--accent)"/>
<!-- ... dots only on focal series ... -->

<!-- Non-focal series: thinner, no dots -->
<polyline points="140,400 300,380 460,360 620,340 780,320"
          fill="none" stroke="var(--series-2)" stroke-width="1.2" stroke-linejoin="round"/>
```

### Chart.js (for interactive dashboards, many data points, or zoomable charts)

Use when the chart is complex — many series, tooltips matter, or the user will hover for values:

```html
<script src="https://cdn.jsdelivr.net/npm/chart.js@4/dist/chart.umd.min.js"></script>
<canvas id="chart" width="600" height="300"></canvas>
<script>
  new Chart(document.getElementById('chart'), {
    type: 'bar',
    data: { /* real data */ },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { labels: { color: textColor } } },
      scales: {
        x: { ticks: { color: textColor }, grid: { color: gridColor } },
        y: { ticks: { color: textColor }, grid: { color: gridColor }, beginAtZero: true }
      }
    }
  });
</script>
```

Pull colors from the page's CSS custom properties at runtime. Wrap the canvas in a styled container with border and padding. On theme change, destroy and recreate the chart with the new palette — see [`interactivity.md`](interactivity.md).

## Complexity budgets

| Chart type | Max |
|---|---|
| Bars | 8 (group into periods or split beyond) |
| Line series | 5 |
| Line points | 12 (aggregate beyond) |
| Pie slices | 6 |
| Scatter points | 30 |
| Radar axes | 5 |
| Pyramid layers | 6 |

Over budget → split into two charts or switch to a table.

## Chart page structure

Copy [`templates/chart.html`](../templates/chart.html):

1. **Header** — title naming what the chart shows and the period/scope
2. **KPI row (optional)** — 2–4 big-number stat cards for the headline numbers
3. **Chart container** — the centerpiece, card-framed
4. **Takeaways** — 2–3 bullets naming what the user should notice ("March spike corresponds to the launch")
5. **Source note** — tiny mono line naming where the data came from (file, query, conversation)

## Anti-patterns

- Charting data the user never asked about ("I noticed a CSV, here's a dashboard")
- More than 8 bars ungrouped
- Accent on multiple bars/series ("everything is important")
- 3D anything
- Truncated y-axis on bar charts
- Smoothed curves on sampled data
- Unlabeled axes
- Dots on every series in a multi-series line chart
- Inventing data to fill a gap in the story

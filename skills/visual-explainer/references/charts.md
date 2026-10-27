# Charts — visualizing numerical data

Charts are for data the user is **actively exploring**. Never draw a chart just because a data file exists.

## Pre-flight: does this data deserve a chart?

| Situation | Answer |
|---|---|
| User asks about trends, comparisons, distributions, or "the shape of the data" | Chart |
| User asks "what's the biggest/smallest/fastest" | Chart (bar or headline number) |
| User is comparing categories or time periods | Chart |
| User asked a yes/no or single-number question | No chart: answer in text |
| Data has fewer than 4–5 comparable values | No chart: a sentence or small table |
| Data just exists in a file, user hasn't engaged with it | No chart |

## Chart type selection

| Question | Use | Rules |
|---|---|---|
| How much per category or period? | **Columns** | 4–8 bars. Horizontal bars when labels are long, sorted by value |
| Is it moving over time? | **Line** | 4–12 points, straight segments. One series is normal, three is the most |
| What share of a whole? | **100% stacked bar** or thin ring | 2–5 parts. Never 3D, never labels on slices |
| Do two variables relate? | **Scatter** | Up to ~30 points. Label the outliers |
| How far to a target? | **Progress bar** | Both ends labelled, fill is the true ratio |
| One value that matters | **Headline number** | A KPI cell, no chart. More honest than a chart of one point |

## Honesty rules (non-negotiable)

1. **Bars start at zero.** A truncated axis distorts magnitude
2. **No invented data.** Only numbers from the conversation, a file or the codebase. Totals and deltas are computed from the values shown, so they add up
3. **Straight segments, not splines.** A smoothed curve invents values between samples
4. **Units are always clear**: on the axis, in the title, or in the value labels
5. **No 3D**, no shadows, no gradients on marks
6. **Accent on one mark**: the focal bar, series or slice. Everything else `--bar`, `--muted` or ink
7. **Don't connect across gaps** in discontinuous data
8. **Every relative figure names its baseline**: "+44% on January", not "+44%"

## Look

- **One hue per chart.** The accent goes on the main data element; the rest are neutral (`--bar`). Never a hue per bar
- **Bars** have square corners. Gap between bars about a quarter of the bar width
- **Baseline**: one 1px line in `--ink`. No y-axis line, no box around the plot
- **Gridlines**: none when value labels sit on the marks; otherwise 3–5 horizontal lines, 1px, `--line`. Never vertical gridlines
- **Ticks**: 13px sans in `--muted`, round even steps (0 / 150 / 300 / 450 / 600), top tick above the maximum. X labels flat, never rotated
- **Lines**: 2px, no point markers except an 8px dot on the hovered or last point. No area fill, or a flat 12% tint at most
- **Legend**: none for a single series (the title names it). Otherwise small swatches under the chart, each the mark it explains, scaled down
- **Annotate the event that matters**: a spike or step gets a short label naming its cause ("Launch")

## Rendering choice

### HTML bars (default: hoverable, animated, no dependencies)

Copy the pattern from [`templates/chart.html`](../templates/chart.html). Bars are flex children, which gives hover dimming, tooltips and grow-in with no JS and no CDN:

- Bar heights are percentages of the tallest bar (`style="height: 62%"`)
- The focal column gets class `focal`: accent fill and accent value label
- Each column has a `.bar-tip` tooltip and `tabindex="0"`
- Bars grow in via `.ve-bar`; reduced-motion users see them static
- Value labels above the bars replace the y-axis

Right for explainer-scale charts (≤ 8 bars).

### Hand-built SVG (lines, scatter, axes)

Full control for anything the HTML bars can't express. Use the tokens in attributes so the theme toggle works without a re-render:

```svg
<svg viewBox="0 0 800 320" role="img" aria-labelledby="chart-title chart-desc" style="width: 100%; height: auto;">
  <title id="chart-title">p95 latency by release</title>
  <desc id="chart-desc">Line chart of p95 latency across six releases; it drops from 420 to 180 ms at v2.3</desc>

  <!-- 3–5 horizontal gridlines -->
  <g stroke="var(--line)" stroke-width="1">
    <line x1="56" y1="40"  x2="780" y2="40"/>
    <line x1="56" y1="140" x2="780" y2="140"/>
  </g>
  <!-- Baseline -->
  <line x1="56" y1="280" x2="780" y2="280" stroke="var(--ink)" stroke-width="1"/>

  <!-- Y ticks: right-aligned, sans, muted -->
  <g font-family="var(--font-sans)" font-size="13" fill="var(--muted)" text-anchor="end">
    <text x="48" y="44">600</text>
    <text x="48" y="144">300</text>
    <text x="48" y="284">0</text>
  </g>

  <!-- Focal series: accent, 2px, straight segments, draws in -->
  <polyline class="ve-draw" pathLength="1" points="80,140 220,150 360,160 500,220 640,226 760,230"
            fill="none" stroke="var(--accent)" stroke-width="2" stroke-linejoin="round"/>
  <circle cx="760" cy="230" r="4" fill="var(--accent)"/>

  <!-- Comparison series, if any: neutral, no dots -->
  <polyline points="80,180 220,182 360,186 500,190 640,192 760,196"
            fill="none" stroke="var(--bar)" stroke-width="2" stroke-linejoin="round"/>

  <!-- Annotation -->
  <line x1="500" y1="40" x2="500" y2="280" stroke="var(--muted)" stroke-width="1" stroke-dasharray="3 3"/>
  <text x="506" y="54" font-family="var(--font-sans)" font-size="13" fill="var(--muted)">v2.3 cache</text>
</svg>
```

Plot margins: left 56px, bottom 40px, top 32px, right 24px.

### Chart.js (many points, several series, zoom)

Only when the chart is genuinely complex. Read colours from the tokens, and redraw on `themechange`:

```html
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.7/dist/chart.umd.min.js"></script>
<script>
  let chart;
  const token = name => getComputedStyle(document.documentElement).getPropertyValue(name).trim();
  function draw() {
    if (chart) chart.destroy();
    Chart.defaults.font.family = token('--font-sans');
    Chart.defaults.color = token('--muted');
    chart = new Chart(document.getElementById('data-chart'), {
      type: 'bar',
      data: { labels: [/* real labels */], datasets: [{ data: [/* real data */], backgroundColor: token('--bar'), borderRadius: 0 }] },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          x: { grid: { display: false }, border: { color: token('--ink') } },
          y: { beginAtZero: true, grid: { color: token('--line') }, border: { display: false }, ticks: { maxTicksLimit: 5 } }
        }
      }
    });
  }
  document.fonts.ready.then(draw);
  document.documentElement.addEventListener('themechange', draw);
</script>
```

Put the canvas in a `.panel` with a fixed height. If the CDN fails, the takeaways and source note still tell the story.

## Complexity budgets

| Chart | Max |
|---|---|
| Bars | 8 (group into periods or split beyond) |
| Line series | 3 (switch metrics with a control instead of overlaying more) |
| Line points | 12 (aggregate beyond) |
| Parts of a whole | 5 |
| Scatter points | 30 |

Over budget → split into two charts or use a table.

## Chart page structure

Copy [`templates/chart.html`](../templates/chart.html):

1. **Header**: a title naming what is measured and over what period, then one sentence
2. **KPIs (optional)**: 2–4 headline numbers on one surface split by 1px gaps. Label over value; values in mono, 28px, ink, never accent
3. **Chart panel**: the centerpiece
4. **Source note**: one small muted line naming where the data came from (file, query, conversation)
5. **What to notice**: 2–3 takeaways ("March spike is the launch")

## Anti-patterns

- Charting data the user never asked about ("I noticed a CSV, here's a dashboard")
- A hue per bar, rainbow palettes, the accent on several marks
- Sparklines on KPIs, icons in tinted circles, deltas as green pills
- Truncated y-axis on bars, smoothed curves, rotated labels
- Unlabelled units, or a legend for a single series
- 3D, shadows, gradient fills
- Inventing data to fill a gap in the story

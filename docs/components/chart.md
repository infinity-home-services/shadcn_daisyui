# Chart

Simple bar and line charts drawn with the theme colors.

## Specs

| Part | Description |
| --- | --- |
| Container | A card framing the chart with a title and caption. |
| Bars | Themed .chart-bar columns whose height encodes the value. |
| Line / area | An SVG polyline with a translucent area fill. |
| Axis labels | Muted text labels along the category axis. |

| Property | Value |
| --- | --- |
| Bar radius | var(--radius-sm) on the top corners |
| Plot height | h-40 (10rem) |
| Bar hover | opacity 0.8, 0.15s transition |
| Label font | 0.75rem muted |

Tokens used: `chart-1`, `chart-2`, `chart-3`, `chart-4`, `chart-5`, `muted-foreground`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | No interactive targets by default; add focusable points only if the chart is interactive |

Role / ARIA: A presentational drawing (bars / SVG). Give the chart container role=img with an aria-label summarizing the data, or pair it with an accessible data table.

Focus: Static charts take no focus; if you add tooltips or selectable points, make those controls keyboard-focusable.

Screen reader: Provide a text alternative (aria-label or an adjacent table) - the bars and SVG convey no values to assistive tech on their own.

Touch target: Static by default; any interactive points or legend toggles must meet the 44pt touch minimum.

Reduced motion: Only a 0.15s hover opacity transition on bars; nothing moves, so reduced-motion is effectively unaffected.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
Chart(data) { point in
    BarMark(x: .value("Month", point.month), y: .value("Revenue", point.revenue))
        .foregroundStyle(by: .value("Series", point.series))
}
.chartForegroundStyleScale(range: [.chart1, .chart2, .chart3, .chart4, .chart5])
```

Swift Charts is the native equivalent (BarMark / LineMark / AreaMark) and gets VoiceOver audio-graph support for free via .accessibilityChartDescriptor.

## Bar & line

```html
<div class="grid w-full gap-6 lg:grid-cols-2">
  <div class="card">
    <div class="card-body">
      <p class="text-sm font-medium">Revenue</p>
      <p class="mb-3 text-sm text-muted-foreground">Last 6 months</p>
      <div class="flex h-40 items-end gap-3">
        <div class="chart-bar w-full" style="height: 40%"></div>
        <div class="chart-bar w-full" style="height: 65%"></div>
        <div class="chart-bar w-full" style="height: 52%"></div>
        <div class="chart-bar w-full" style="height: 80%"></div>
        <div class="chart-bar w-full" style="height: 60%"></div>
        <div class="chart-bar w-full" style="height: 95%"></div>
      </div>
      <div class="mt-2 flex gap-3 text-center text-xs text-muted-foreground">
        <span class="w-full">Jan</span><span class="w-full">Feb</span><span class="w-full">Mar</span>
        <span class="w-full">Apr</span><span class="w-full">May</span><span class="w-full">Jun</span>
      </div>
    </div>
  </div>
  <div class="card">
    <div class="card-body">
      <p class="text-sm font-medium">Visitors</p>
      <p class="mb-3 text-sm text-muted-foreground">Trend</p>
      <svg viewBox="0 0 300 130" class="h-40 w-full" preserveAspectRatio="none">
        <polygon fill="var(--primary)" opacity="0.08" points="0,120 0,80 50,90 100,55 150,70 200,35 250,50 300,20 300,120" />
        <polyline fill="none" stroke="var(--primary)" stroke-width="2" stroke-linejoin="round" stroke-linecap="round" points="0,80 50,90 100,55 150,70 200,35 250,50 300,20" />
      </svg>
    </div>
  </div>
</div>
```

# Stat

Compact blocks for key metrics.

## Specs

| Part | Description |
| --- | --- |
| Stats container | Card surface holding one or more stat cells side by side. |
| Title | Metric label, 0.875rem, muted-foreground. |
| Value | The large headline figure, font-weight 600. |
| Description | Trend/context line in muted-foreground. |

| Property | Value |
| --- | --- |
| Radius | var(--radius-xl) on the stats card |
| Border | 1px border-color around the card; 1px divider between cells |
| Shadow | var(--shadow-sm) |
| Title / desc font | 0.875rem, muted-foreground |
| Value weight | 600 |

Tokens used: `card`, `card-foreground`, `muted-foreground`, `border-color`

## Accessibility

Role / ARIA: Presentational layout - a styled set of divs; the value reads as plain text.

Focus: Not focusable; no interactive elements within a stat cell.

Screen reader: Title, value, and description read in document order as adjacent text.

Touch target: Not interactive; no hit-target requirement.

Reduced motion: Static; no animation to suppress.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
GroupBox {
    VStack(alignment: .leading, spacing: 4) {
        Text("Total Revenue").font(.caption).foregroundStyle(.secondary)
        Text("$45,231").font(.title2.weight(.semibold))
        Text("+20.1% from last month").font(.caption).foregroundStyle(.secondary)
    }
}
```

Compose a labeled VStack (or GroupBox per metric); lay multiple out in a Grid/HStack.

## Default

```html
<div class="stats w-full">
  <div class="stat">
    <div class="stat-title">Total Revenue</div>
    <div class="stat-value">$45,231</div>
    <div class="stat-desc">+20.1% from last month</div>
  </div>
  <div class="stat">
    <div class="stat-title">Subscriptions</div>
    <div class="stat-value">+2,350</div>
    <div class="stat-desc">+180.1% from last month</div>
  </div>
  <div class="stat">
    <div class="stat-title">Active Now</div>
    <div class="stat-value">+573</div>
    <div class="stat-desc">+201 since last hour</div>
  </div>
</div>
```

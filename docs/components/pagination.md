# Pagination

Navigation for moving between pages of content.

## Specs

| Part | Description |
| --- | --- |
| Nav | nav landmark labeled Pagination wrapping the controls. |
| Prev / Next | Ghost buttons with chevron icons; disabled at the ends. |
| Page buttons | Square buttons; the current page is outlined and marked aria-current. |

| Property | Value |
| --- | --- |
| Button size | btn-sm (h-8 / 2rem) square |
| Gap | 0.25rem (gap-1) |
| Current page | btn-outline + aria-current=page |
| Gap marker | ellipsis in muted-foreground |

Tokens used: `accent`, `accent-foreground`, `muted-foreground`, `border-color`, `foreground`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Move between page links/buttons |
| Enter / Space | Activate the focused page control |

Role / ARIA: nav element with aria-label=Pagination. Pages render as links (path mode) or buttons (event mode); the current page carries aria-current=page and end controls set aria-disabled / disabled.

Focus: Each control shows its focus ring; disabled prev/next are skipped/marked aria-disabled.

Screen reader: The nav label names the region and aria-current identifies the active page. Icon-only prev/next buttons include visible Previous / Next text.

Touch target: btn-sm controls are 32px; bump spacing or size for touch-primary layouts toward 44pt.

Reduced motion: No motion.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
HStack {
    Button("Previous") { page -= 1 }.disabled(page <= 1)
    ForEach(1...totalPages, id: \.self) { p in
        Button("\(p)") { page = p }
            .buttonStyle(p == page ? .borderedProminent : .bordered)
    }
    Button("Next") { page += 1 }.disabled(page >= totalPages)
}
```

No native pager control (iOS uses .page TabView dots or infinite lists); compose buttons when explicit numbered pagination is required.

## Default

HEEx:

```heex
<.pagination page={@page} total_pages={@total_pages} path={fn p -> ~p"/items?page=#{p}" end} />
<.pagination page={@page} total_pages={@total_pages} event="paginate" />
```

```html
<nav class="flex items-center gap-1">
  <button class="btn btn-ghost btn-sm gap-1 px-2.5">
    <span class="hero-chevron-left size-4" aria-hidden="true"></span> Previous
  </button>
  <button class="btn btn-ghost btn-sm btn-square">1</button>
  <button class="btn btn-outline btn-sm btn-square">2</button>
  <button class="btn btn-ghost btn-sm btn-square">3</button>
  <span class="px-1.5 text-sm text-muted-foreground">…</span>
  <button class="btn btn-ghost btn-sm btn-square">8</button>
  <button class="btn btn-ghost btn-sm gap-1 px-2.5">
    Next <span class="hero-chevron-right size-4" aria-hidden="true"></span>
  </button>
</nav>
```

# Footer

A multi-column page footer layout.

## Specs

| Part | Description |
| --- | --- |
| Footer | Multi-column <footer> grid of link groups. |
| Column | A <nav> with a footer-title and stacked links. |
| Footer title | Section heading in muted-foreground. |

| Property | Value |
| --- | --- |
| Font | 0.875rem |
| Title color | muted-foreground |
| Surface | bg-base-100, 1px border-base-300, rounded-xl, p-6 in the demo |
| Links | link link-hover anchors |

Tokens used: `background`, `color-base-300`, `muted-foreground`, `foreground`

## Accessibility

Role / ARIA: contentinfo landmark when it is the page footer; columns are <nav> regions of links.

Focus: Links are individually focusable with native focus rings.

Screen reader: Read as a footer/contentinfo region; titles head their link groups.

Touch target: Footer links should offer comfortable tap areas on touch.

Reduced motion: Color/underline transitions only on links.

## Native (SwiftUI)

Parity: guidance only - no native component yet.

```swift
VStack(alignment: .leading, spacing: 16) {
    ForEach(columns) { col in
        Text(col.title).font(.caption).foregroundStyle(.secondary)
        ForEach(col.links) { Link($0.title, destination: $0.url) }
    }
}
```

No footer primitive; lay out link columns in a VStack/Grid at the bottom of the view.

## Default

```html
<footer class="footer w-full rounded-xl border border-base-300 bg-base-100 p-6">
  <nav>
    <h6 class="footer-title">Product</h6>
    <a class="link link-hover">Features</a>
    <a class="link link-hover">Pricing</a>
  </nav>
  <nav>
    <h6 class="footer-title">Company</h6>
    <a class="link link-hover">About</a>
    <a class="link link-hover">Contact</a>
  </nav>
  <nav>
    <h6 class="footer-title">Legal</h6>
    <a class="link link-hover">Terms</a>
    <a class="link link-hover">Privacy</a>
  </nav>
</footer>
```

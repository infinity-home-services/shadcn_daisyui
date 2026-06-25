# List

Vertical rows of items with avatars and actions.

## Specs

| Part | Description |
| --- | --- |
| List | Rounded, bordered <ul class=list> container. |
| List row | list-row with avatar, primary/secondary text, and a trailing action. |
| Row divider | 1px border-color between rows. |

| Property | Value |
| --- | --- |
| Radius | rounded-xl container in the example |
| Border | 1px border-color outer, 1px divider between rows |
| Font | 0.875rem base; secondary text text-xs muted-foreground |
| Padding | p-3 per row, gap-3 between row elements |

Tokens used: `card`, `border-color`, `muted-foreground`, `foreground`

## Accessibility

Role / ARIA: Semantic <ul>/<li>; the per-row action buttons carry their own aria-labels.

Focus: Only the in-row controls (e.g. the more-options button) are focusable.

Screen reader: Rows read as list items; trailing icon buttons announce via aria-label.

Touch target: Row action buttons should meet the 44pt touch target on touch surfaces.

Reduced motion: Static; no animation to suppress.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
List(people) { person in
    HStack {
        avatar(person)
        VStack(alignment: .leading) {
            Text(person.name)
            Text(person.email).font(.caption).foregroundStyle(.secondary)
        }
        Spacer()
        Menu { ... } label: { Image(systemName: "ellipsis") }
    }
}
```

Native List with custom rows is the direct equivalent.

## Default

```html
<ul class="list w-full max-w-md rounded-xl border border-base-300">
  <li class="list-row flex items-center gap-3 p-3">
    <div class="avatar avatar-placeholder">
      <div class="w-8 rounded-full"><span class="text-xs">AB</span></div>
    </div>
    <div class="flex-1">
      <div class="font-medium">Alex Brown</div>
      <div class="text-xs text-muted-foreground">alex@example.com</div>
    </div>
    <button class="btn btn-ghost btn-sm btn-square" aria-label="More options"><span class="hero-ellipsis-horizontal size-4" aria-hidden="true"></span></button>
  </li>
  <li class="list-row flex items-center gap-3 p-3">
    <div class="avatar avatar-placeholder">
      <div class="w-8 rounded-full"><span class="text-xs">CD</span></div>
    </div>
    <div class="flex-1">
      <div class="font-medium">Casey Day</div>
      <div class="text-xs text-muted-foreground">casey@example.com</div>
    </div>
    <button class="btn btn-ghost btn-sm btn-square" aria-label="More options"><span class="hero-ellipsis-horizontal size-4" aria-hidden="true"></span></button>
  </li>
</ul>
```

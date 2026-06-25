# Rating

A star rating input.

## Specs

| Part | Description |
| --- | --- |
| Rating group | Container holding the radio-input stars. |
| Star input | <input type=radio> masked to mask-star-2 and filled bg-warning. |

| Property | Value |
| --- | --- |
| Star fill | color-warning (bg-warning) |
| Shape | mask-star-2 clip |
| Selection | Single radio per name group; checked star sets the value |
| Size | Sized via utility classes on the inputs |

Tokens used: `color-warning`, `muted`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Move focus into / out of the rating group |
| Arrow keys | Move selection between stars |
| Space | Select the focused star |

Role / ARIA: Radio group: each star is a labeled radio input (aria-label is the star number).

Focus: Native radio focus ring on the active star.

Screen reader: Announced as a radio group; each option reads its numeric aria-label and checked state.

Touch target: Stars should present a 44pt effective tap area on touch surfaces.

Reduced motion: Color-only fill change; nothing animates.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
HStack(spacing: 4) {
    ForEach(1...5, id: \.self) { i in
        Image(systemName: i <= rating ? "star.fill" : "star")
            .foregroundStyle(.yellow)
            .onTapGesture { rating = i }
    }
}
```

Tappable star HStack; bind selection to the rating value.

## Default

```html
<div class="rating">
  <input type="radio" name="rating-demo" class="mask mask-star-2 bg-warning" aria-label="1" />
  <input type="radio" name="rating-demo" class="mask mask-star-2 bg-warning" aria-label="2" checked />
  <input type="radio" name="rating-demo" class="mask mask-star-2 bg-warning" aria-label="3" />
  <input type="radio" name="rating-demo" class="mask mask-star-2 bg-warning" aria-label="4" />
  <input type="radio" name="rating-demo" class="mask mask-star-2 bg-warning" aria-label="5" />
</div>
```

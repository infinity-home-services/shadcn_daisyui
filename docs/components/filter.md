# Filter

A radio-button filter group with a reset.

## Specs

| Part | Description |
| --- | --- |
| Filter form | <form class=filter> grouping the options and reset. |
| Reset | type=reset button (×) that clears the selected radio. |
| Options | Button-styled radio inputs sharing one name; one active at a time. |

| Property | Value |
| --- | --- |
| Options | btn btn-outline radios, single-select per name group |
| Reset | btn-square outline clear control |
| Selection | Active option styled by the radio :checked state |

Tokens used: `primary`, `primary-foreground`, `border-color`, `foreground`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Move focus into / out of the filter group |
| Arrow keys | Move selection between options |
| Space | Select the focused option / activate reset |

Role / ARIA: A radio group of options plus a reset button; each radio has an aria-label.

Focus: Native radio/button focus rings on each control.

Screen reader: Announced as a radio group; selecting an option and the reset are exposed natively.

Touch target: Each option button should meet the 44pt touch target.

Reduced motion: Color-only state change; nothing animates position.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
Picker("Framework", selection: $framework) {
    Text("Svelte").tag("svelte")
    Text("Vue").tag("vue")
    Text("React").tag("react")
}
.pickerStyle(.segmented)
```

A segmented Picker covers single-select filters; add a Clear button for the reset.

## Default

```html
<form class="filter">
  <input class="btn btn-square btn-outline" type="reset" value="×" aria-label="Clear filters" />
  <input class="btn btn-outline" type="radio" name="frameworks" aria-label="Svelte" />
  <input class="btn btn-outline" type="radio" name="frameworks" aria-label="Vue" />
  <input class="btn btn-outline" type="radio" name="frameworks" aria-label="React" />
</form>
```

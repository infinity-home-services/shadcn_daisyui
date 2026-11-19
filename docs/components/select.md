# Select

Displays a list of options for the user to pick from, triggered by a button.

> Requires a JS hook: initialize with `initShadcnDaisyui()` (dead views) or the corresponding `Shadcn*` LiveView hook from `shadcn-daisyui.js`.

Form-bind with field={@form[:x]} (or name + value): a hidden input the hook keeps in sync dispatches input + change, so phx-change fires. multiple turns rows into checkboxes and posts a list - see Multi Select. The open list and the value survive LiveView patches.

## Specs

| Part | Description |
| --- | --- |
| Trigger | Outline button showing the current value and a chevron-down icon. |
| Panel | Popover listbox of option buttons positioned below the trigger. |
| Option | Each row (combo-item) with a check icon revealed on selection. |

| Property | Value |
| --- | --- |
| Trigger height | 2.25rem / 36px (btn h-9) |
| Trigger radius | var(--radius-md) |
| Panel radius | var(--radius-md) |
| Panel elevation | ring-1 ring-foreground/10, shadow-md |
| Option padding | 0.375rem block, 0.5rem inline |
| Option radius | var(--radius-sm) |

Tokens used: `popover`, `popover-foreground`, `border-color`, `accent`, `accent-foreground`, `muted-foreground`

## Accessibility

| Keys | Action |
| --- | --- |
| Enter / Space / Up / Down | Open the listbox from the trigger |
| Up / Down, Home / End | Move the active option |
| Enter / Space | Select the active option and close (multiple: toggle, stay open) |
| Esc | Close the listbox without changing the value |

Role / ARIA: The trigger is role=combobox (aria-haspopup=listbox, aria-expanded, aria-activedescendant) over a role=listbox of role=option rows with aria-selected, driven by the ShadcnSelect hook. Requires a unique id. Name it with a <label for> on the trigger (field binding uses the field id), aria-label or aria-labelledby.

Focus: Trigger shows the ring on focus; the active option is highlighted with the accent background.

Screen reader: For a fully announced native experience prefer native-select; this custom control trades native semantics for shadcn visuals.

Touch target: Trigger is 36px tall (desktop-fine); option rows grow to 44px on touch. Pass full_width for a 44px trigger in sheets and compact forms.

Reduced motion: Panel toggles visibility without a color fade under the theme.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
Picker("Fruit", selection: $fruit) {
    ForEach(fruits, id: \.self) { Text($0).tag($0) }
}
.pickerStyle(.menu)
```

A .menu Picker gives the same trigger-then-list behavior natively, with system-managed selection semantics.

## Props

| Name | Type | Default |
| --- | --- | --- |
| id | string (required) | - |
| field | Phoenix.HTML.FormField | nil |
| name / value | string / any (list when multiple) | nil |
| multiple | boolean | false |
| placeholder | string | "Select…" |
| full_width | boolean | false |
| disabled | boolean | false |
| :option value count | slot | - |

## Default

HEEx:

```heex
<.select id="fruit" placeholder="Select a fruit">
  <:option value="Apple">Apple</:option>
  <:option value="Banana">Banana</:option>
  <:option value="Blueberry">Blueberry</:option>
  <:option value="Grapes">Grapes</:option>
  <:option value="Pineapple">Pineapple</:option>
</.select>
```

```html
<div data-select class="relative w-60">
  <button type="button" data-select-trigger class="btn btn-outline w-full justify-between font-normal">
    <span data-select-label class="text-muted-foreground">Select a fruit</span>
    <span class="hero-chevron-down size-4 opacity-50" aria-hidden="true"></span>
  </button>
  <div data-select-panel class="popover-panel absolute z-50 mt-1 hidden w-full p-1">
    <button type="button" class="combo-item" data-select-item data-value="Apple"><span class="hero-check size-4 opacity-0" aria-hidden="true"></span> Apple</button>
    <button type="button" class="combo-item" data-select-item data-value="Banana"><span class="hero-check size-4 opacity-0" aria-hidden="true"></span> Banana</button>
    <button type="button" class="combo-item" data-select-item data-value="Blueberry"><span class="hero-check size-4 opacity-0" aria-hidden="true"></span> Blueberry</button>
    <button type="button" class="combo-item" data-select-item data-value="Grapes"><span class="hero-check size-4 opacity-0" aria-hidden="true"></span> Grapes</button>
    <button type="button" class="combo-item" data-select-item data-value="Pineapple"><span class="hero-check size-4 opacity-0" aria-hidden="true"></span> Pineapple</button>
  </div>
</div>
```

## Multiple

HEEx:

```heex
<.select id="fruits" multiple placeholder="Select fruits" aria-label="Fruits">
  <:option value="Apple">Apple</:option>
  <:option value="Banana">Banana</:option>
  <:option value="Blueberry">Blueberry</:option>
  <:option value="Grapes">Grapes</:option>
</.select>
```

```html
<div id="fruits" data-select data-multiple data-placeholder="Select fruits" class="relative w-60">
  <button type="button" role="combobox" aria-haspopup="listbox" aria-expanded="false" aria-label="Fruits" class="btn btn-outline w-full justify-between font-normal" data-select-trigger>
    <span class="flex min-w-0 items-center gap-1 text-muted-foreground" data-select-label>Select fruits</span>
    <span class="hero-chevron-down size-4 shrink-0 opacity-50" aria-hidden="true"></span>
  </button>
  <div class="popover-panel absolute z-50 mt-1 hidden w-full p-1" data-select-panel>
    <div role="listbox" aria-multiselectable="true" class="max-h-72 overflow-auto" data-select-list>
      <button type="button" tabindex="-1" role="option" aria-selected="false" class="combo-item" data-select-item data-value="Apple"><span class="facet-check" aria-hidden="true"><span class="hero-check size-3.5"></span></span><span data-label class="truncate">Apple</span></button>
      <button type="button" tabindex="-1" role="option" aria-selected="false" class="combo-item" data-select-item data-value="Banana"><span class="facet-check" aria-hidden="true"><span class="hero-check size-3.5"></span></span><span data-label class="truncate">Banana</span></button>
      <button type="button" tabindex="-1" role="option" aria-selected="false" class="combo-item" data-select-item data-value="Blueberry"><span class="facet-check" aria-hidden="true"><span class="hero-check size-3.5"></span></span><span data-label class="truncate">Blueberry</span></button>
      <button type="button" tabindex="-1" role="option" aria-selected="false" class="combo-item" data-select-item data-value="Grapes"><span class="facet-check" aria-hidden="true"><span class="hero-check size-3.5"></span></span><span data-label class="truncate">Grapes</span></button>
    </div>
    <div class="-mx-1 mt-1 hidden border-t border-border px-1 pt-1" data-select-clear>
      <button type="button" class="combo-item justify-center" data-select-clear-btn>Clear</button>
    </div>
  </div>
</div>
```

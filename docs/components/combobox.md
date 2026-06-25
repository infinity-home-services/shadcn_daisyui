# Combobox

An input with a searchable, filterable list of options.

> Requires a JS hook: initialize with `initShadcnDaisyui()` (dead views) or the corresponding `Shadcn*` LiveView hook from `shadcn-daisyui.js`.

## Usage guidance

Use when:

- Choosing one option from a long list (> ~10: users, tags, locations)
- Lists where typing-to-filter beats scrolling

Don't use for:

- Short lists - native select or radio-group is faster and more accessible
- Free text that merely suggests - use an input with a datalist pattern

Sizing: Trigger matches input metrics (h-9, text-sm); listbox is rounded-lg with shadow-sm.

Responsive: On compact, the option list should be generous (full-width, comfortable rows ≥ 44px).

iOS: A searchable list pushed or presented as a sheet - not a tiny inline dropdown.

## Specs

| Part | Description |
| --- | --- |
| Trigger | A button (aria-haspopup=listbox) showing the current value or placeholder; toggles the popover. |
| Search input | role=combobox with aria-autocomplete=list; filters the options as you type. |
| Listbox | role=listbox panel of role=option rows; the active row is highlighted with accent. |
| Empty state | Shown when the filter matches nothing. |

| Property | Value |
| --- | --- |
| Popover radius | var(--radius-md) |
| Option radius | var(--radius-sm) |
| Option padding | 0.375rem 0.5rem |
| Option font | 0.875rem |
| Border | 1px var(--border-color) |

Tokens used: `popover`, `popover-foreground`, `accent`, `accent-foreground`, `muted-foreground`, `border-color`, `ring`

## Accessibility

| Keys | Action |
| --- | --- |
| Arrow Down | Move the active option down (wraps to the top) |
| Arrow Up | Move the active option up (wraps to the bottom) |
| Enter | Select the active option and close the listbox |
| Esc | Close the listbox and return focus to the trigger |
| Type | Filter the options by substring |

Role / ARIA: Trigger is a button with aria-haspopup=listbox / aria-expanded / aria-controls. The search field is role=combobox; the list is role=listbox with role=option children carrying aria-selected.

Focus: Opening the popover moves focus into the search input and sets the active option; selecting or Esc returns focus to the trigger.

Screen reader: aria-activedescendant points at the highlighted option id so its label is announced without moving DOM focus; aria-selected marks the chosen value.

Touch target: Trigger is a full-height field; option rows are tappable but slightly under 44pt - pad rows for touch-first use.

Reduced motion: Popover toggles via a hidden class with no movement, so reduced-motion has nothing to suppress.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
Picker("Framework", selection: $value) {
    ForEach(options, id: \.self) { Text($0).tag($0) }
}
.pickerStyle(.menu)   // searchable menu → wrap a List in .searchable for the type-to-filter behavior
```

A plain Picker(.menu) covers selection; to match the type-to-filter combobox, present a searchable List in a popover/sheet instead.

## Default

HEEx:

```heex
<.combobox id="framework" placeholder="Select framework…">
  <:option value="Next.js">Next.js</:option>
  <:option value="SvelteKit">SvelteKit</:option>
  <:option value="Nuxt.js">Nuxt.js</:option>
  <:option value="Remix">Remix</:option>
  <:option value="Astro">Astro</:option>
  <:option value="Phoenix">Phoenix</:option>
</.combobox>
```

```html
<div data-combobox class="relative w-60">
  <button type="button" data-combobox-trigger class="btn btn-outline w-full justify-between font-normal">
    <span data-combobox-label class="text-muted-foreground">Select framework…</span>
    <span class="hero-chevron-up-down size-4 opacity-50" aria-hidden="true"></span>
  </button>
  <div data-combobox-panel class="popover-panel absolute z-30 mt-1 hidden w-full p-1">
    <input data-combobox-search class="input mb-1 w-full" placeholder="Search framework…" />
    <ul data-combobox-list class="max-h-52 overflow-auto">
      <li><button type="button" class="combo-item" data-value="Next.js"><span class="hero-check size-4 opacity-0" aria-hidden="true"></span> Next.js</button></li>
      <li><button type="button" class="combo-item" data-value="SvelteKit"><span class="hero-check size-4 opacity-0" aria-hidden="true"></span> SvelteKit</button></li>
      <li><button type="button" class="combo-item" data-value="Nuxt.js"><span class="hero-check size-4 opacity-0" aria-hidden="true"></span> Nuxt.js</button></li>
      <li><button type="button" class="combo-item" data-value="Remix"><span class="hero-check size-4 opacity-0" aria-hidden="true"></span> Remix</button></li>
      <li><button type="button" class="combo-item" data-value="Astro"><span class="hero-check size-4 opacity-0" aria-hidden="true"></span> Astro</button></li>
      <li><button type="button" class="combo-item" data-value="Phoenix"><span class="hero-check size-4 opacity-0" aria-hidden="true"></span> Phoenix</button></li>
    </ul>
    <p data-combobox-empty class="hidden p-2 text-center text-sm text-muted-foreground">No framework found.</p>
  </div>
</div>
```

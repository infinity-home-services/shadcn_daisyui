# Reveal

Slides a row open and closed in place: grid-template-rows 0fr to 1fr plus opacity, 180ms ease-out.

This is the one sanctioned layout animation (styles-motion.md): the accordion / collapse already animates grid-template-rows the same way. The server owns open (flip an assign); for client-side toggles give it an id and point a <button data-reveal-toggle="id"> at it (shadcn-daisyui.js sets data-open and aria-expanded), and pass client so LiveView patches keep the toggled state. When open turns false in the same patch that empties the row, the row still collapses around its old content: keep the content rendered (a chip row with no :if) and let open drive it - the chip row holds its removed chips for the 180ms collapse through phx-remove. Content removed with :if vanishes at once and the row snaps shut; give such content phx-remove={JS.transition({"transition-opacity duration-150 ease-out", "opacity-100", "opacity-0"}, time: 180)} to keep it while the row closes. Plain HTML: <div class="reveal" data-open><div class="reveal-track"><div>…</div></div></div>.

## Usage guidance

Use when:

- A row that appears and disappears inside the page flow: active filter chips, an inline alert, a bulk-action bar
- Optional fields revealed by a toggle ("More options")

Don't use for:

- Floating content (menus, popovers) - those fade and scale, they don't push the page
- Page content on load - content appears immediately
- Large regions or whole sections - navigate, use an accordion, or a sheet

Sizing: No metrics of its own. Put spacing inside (class="pt-3") rather than on the parent: space-y-* or gap-* keeps the gap while the row is closed.

Responsive: Same at every size class. Keep revealed rows short; tall content belongs in a sheet on compact.

iOS: Insert or remove the row with withAnimation(.easeOut(duration: 0.18)) and .transition(.opacity.combined(with: .move(edge: .top))); the system honors Reduce Motion.

## Specs

| Part | Description |
| --- | --- |
| Reveal | .reveal grid with one row: 0fr closed, 1fr open (data-open). |
| Track | .reveal-track: min-height 0, clips the content while it grows. |
| Content | Your row; the class attr lands here, so padding is safe. |

| Property | Value |
| --- | --- |
| Duration | 180ms (small-surface tier) |
| Easing | ease-out |
| Properties | grid-template-rows 0fr ↔ 1fr, opacity 0 ↔ 1, visibility |
| Reduced motion | transition: none (instant) |

Tokens used: 

## Accessibility

| Keys | Action |
| --- | --- |
| Enter / Space | On a data-reveal-toggle button: open or close the row |

Role / ARIA: No role of its own. A client toggle is a disclosure: the button carries aria-expanded and aria-controls (set by the package JS). Server-driven rows that announce something (an inline alert) keep their own role=alert / role=status.

Focus: Closed content is visibility:hidden once collapsed, so it leaves the tab order. If focus is inside when it closes, move it to the toggle (the toggle usually still has it).

Screen reader: Closed content is hidden from assistive tech; opening it does not announce by itself, so rows that matter (errors) should be role=alert or role=status.

Touch target: The toggle is a normal button: 44px on touch per the interaction rules.

Reduced motion: prefers-reduced-motion: reduce removes the transition; the row appears and disappears instantly.

## Native (SwiftUI)

Parity: native parity with the web component.

```swift
VStack(alignment: .leading, spacing: 0) {
    Button(showFilters ? "Hide filters" : "Filters") {
        withAnimation(.easeOut(duration: 0.18)) { showFilters.toggle() }
    }
    if showFilters {
        FilterChips(filters: $filters)
            .padding(.top, 12)
            .transition(.opacity.combined(with: .move(edge: .top)))
    }
    ResultsList()
}
.clipped()
```

Insertion with a transition is the SwiftUI equivalent; the Motion.surface preset (0.18s ease-out) matches the web timing. Respect accessibilityReduceMotion by dropping the move and keeping (or skipping) the fade.

## Props

| Name | Type | Default |
| --- | --- | --- |
| open | boolean | false |
| id | string | nil |
| client | boolean | false |
| class | classes for the content | nil |

## Filter row

HEEx:

```heex
<button type="button" class="btn btn-outline btn-sm" phx-click="toggle_filters">
  <.icon name="hero-funnel" class="size-4" /> Filters
</button>
<%!-- keep the row rendered (no :if); `open` slides it in and out --%>
<.reveal open={@filters != []} class="pt-3">
  <.chip_row id="active-filters" aria-label="Active filters">…</.chip_row>
</.reveal>
<div class="card mt-3">…results…</div>
```

```html
<div class="w-full">
  <button type="button" class="btn btn-outline btn-sm" data-reveal-toggle="filter-row" aria-expanded="false">
    <span class="hero-funnel size-4" aria-hidden="true"></span> Filters
  </button>
  <div id="filter-row" class="reveal">
    <div class="reveal-track">
      <div class="pt-3">
      <div id="reveal-filters" data-chip-row role="group" aria-label="Active filters" class="chip-row">
        <ul class="chip-row-chips" data-chip-row-chips>
          <li class="badge chip badge-secondary" data-index="0" data-value="status:todo" data-chip><span id="reveal-filters-chip-0-label" class="chip-label">Status: Todo</span><button type="button" id="reveal-filters-chip-0-remove" class="chip-remove" aria-label="Remove" aria-labelledby="reveal-filters-chip-0-remove reveal-filters-chip-0-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
          <li class="badge chip badge-secondary" data-index="1" data-value="status:in-progress" data-chip><span id="reveal-filters-chip-1-label" class="chip-label">Status: In progress</span><button type="button" id="reveal-filters-chip-1-remove" class="chip-remove" aria-label="Remove" aria-labelledby="reveal-filters-chip-1-remove reveal-filters-chip-1-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
          <li class="badge chip badge-secondary" data-index="2" data-value="priority:high" data-chip><span id="reveal-filters-chip-2-label" class="chip-label">Priority: High</span><button type="button" id="reveal-filters-chip-2-remove" class="chip-remove" aria-label="Remove" aria-labelledby="reveal-filters-chip-2-remove reveal-filters-chip-2-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
          <li class="badge chip badge-secondary" data-index="3" data-value="label:bug" data-chip><span id="reveal-filters-chip-3-label" class="chip-label">Label: Bug</span><button type="button" id="reveal-filters-chip-3-remove" class="chip-remove" aria-label="Remove" aria-labelledby="reveal-filters-chip-3-remove reveal-filters-chip-3-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
        </ul>
        <div class="chip-row-more" data-chip-row-more hidden>
          <button type="button" class="badge badge-outline chip chip-more" aria-expanded="false" aria-controls="reveal-filters-overflow" data-chip-row-trigger data-more-label="Show {count} more"></button>
          <div id="reveal-filters-overflow" class="popover-panel chip-row-panel" data-chip-row-panel hidden>
            <ul class="flex flex-wrap gap-2" aria-label="Active filters">
              <li class="badge chip badge-secondary" data-index="0" data-value="status:todo" hidden data-chip-copy><span id="reveal-filters-copy-0-label" class="chip-label">Status: Todo</span><button type="button" id="reveal-filters-copy-0-remove" class="chip-remove" aria-label="Remove" aria-labelledby="reveal-filters-copy-0-remove reveal-filters-copy-0-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
              <li class="badge chip badge-secondary" data-index="1" data-value="status:in-progress" hidden data-chip-copy><span id="reveal-filters-copy-1-label" class="chip-label">Status: In progress</span><button type="button" id="reveal-filters-copy-1-remove" class="chip-remove" aria-label="Remove" aria-labelledby="reveal-filters-copy-1-remove reveal-filters-copy-1-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
              <li class="badge chip badge-secondary" data-index="2" data-value="priority:high" hidden data-chip-copy><span id="reveal-filters-copy-2-label" class="chip-label">Priority: High</span><button type="button" id="reveal-filters-copy-2-remove" class="chip-remove" aria-label="Remove" aria-labelledby="reveal-filters-copy-2-remove reveal-filters-copy-2-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
              <li class="badge chip badge-secondary" data-index="3" data-value="label:bug" hidden data-chip-copy><span id="reveal-filters-copy-3-label" class="chip-label">Label: Bug</span><button type="button" id="reveal-filters-copy-3-remove" class="chip-remove" aria-label="Remove" aria-labelledby="reveal-filters-copy-3-remove reveal-filters-copy-3-label" data-chip-remove><span class="hero-x-mark size-3" aria-hidden="true"></span></button></li>
            </ul>
          </div>
        </div>
        <div class="chip-row-actions" data-chip-row-actions>
          <button type="button" class="btn btn-ghost btn-sm" data-reveal-toggle="filter-row" aria-expanded="false">Clear all</button>
        </div>
      </div>
      </div>
    </div>
  </div>
  <div class="card mt-3 w-full">
    <div class="card-body gap-1 text-sm">
      <p class="font-medium">128 issues</p>
      <p class="text-muted-foreground">The results move down while the filter row slides open.</p>
    </div>
  </div>
</div>
```

## Inline alert

HEEx:

```heex
<.reveal open={@saved?} class="pb-3">
  <.alert><:title>Changes saved</:title>Your profile has been updated.</.alert>
</.reveal>
```

```html
<div class="w-full max-w-md">
  <div id="saved-alert" class="reveal">
    <div class="reveal-track">
      <div class="pb-3">
        <div class="alert" role="status">
          <span class="hero-check-circle size-4" aria-hidden="true"></span>
          <div>
            <h3 class="text-sm font-medium">Changes saved</h3>
            <p class="text-sm text-muted-foreground">Your profile has been updated.</p>
          </div>
        </div>
      </div>
    </div>
  </div>
  <button type="button" class="btn btn-outline" data-reveal-toggle="saved-alert" aria-expanded="false">Toggle alert</button>
</div>
```

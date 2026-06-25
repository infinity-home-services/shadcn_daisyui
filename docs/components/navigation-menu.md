# Navigation Menu

A horizontal menu with rich dropdown panels.

## Specs

| Part | Description |
| --- | --- |
| Bar | A horizontal `<nav>` of trigger buttons and direct links. |
| Trigger | A `.btn-ghost` button (`dropdown-hover`) with a chevron that opens a panel. |
| Panel | A `.dropdown-content` popover surface of grouped link rows. |

| Property | Value |
| --- | --- |
| Trigger height | 2rem (btn-sm) |
| Panel surface | var(--popover) on var(--border-color), var(--radius-md), shadow-sm |
| Panel offset | mt-1.5 below the trigger |
| Row hover | var(--accent) background, var(--radius-md) on each link row |

Tokens used: `background`, `foreground`, `popover`, `popover-foreground`, `accent`, `accent-foreground`, `muted-foreground`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Move across triggers, links, then into an open panel |
| Enter / Space | Activate a focused link or focusable trigger |
| Esc | Move focus out, closing a hover/focus-opened panel |

Role / ARIA: A navigation landmark (<nav>); triggers are buttons and the panel items are links.

Focus: Triggers and links take the standard ring-shadow focus outline.

Screen reader: The nav landmark and link text are announced; this hover-driven menu does not expose full menu semantics.

Touch target: btn-sm triggers are compact; ensure 2.75rem effective area where the bar is used on touch.

Reduced motion: Panels appear without animated transitions under the instant-theme rule.

## Native (SwiftUI)

Parity: partial - some web features are not yet native.

```swift
NavigationStack {
  List {
    NavigationLink("Getting started") { GettingStartedView() }
    NavigationLink("Components") { ComponentsView() }
  }
}
```

Hover-driven mega menus are pointer-only; on iOS use a NavigationStack/List or a Menu for the grouped destinations.

## Default

```html
<nav class="flex flex-wrap items-center gap-1">
  <div class="dropdown dropdown-hover">
    <div tabindex="0" role="button" class="btn btn-ghost btn-sm gap-1">
      Getting started <span class="hero-chevron-down size-4" aria-hidden="true"></span>
    </div>
    <div tabindex="0" class="dropdown-content z-20 mt-1.5 w-80 p-2">
      <a class="block rounded-md p-3 hover:bg-accent">
        <div class="text-sm font-medium">Introduction</div>
        <p class="mt-0.5 text-sm text-muted-foreground">Components styled to match shadcn/ui.</p>
      </a>
      <a class="block rounded-md p-3 hover:bg-accent">
        <div class="text-sm font-medium">Installation</div>
        <p class="mt-0.5 text-sm text-muted-foreground">Add the theme to your project.</p>
      </a>
    </div>
  </div>
  <div class="dropdown dropdown-hover">
    <div tabindex="0" role="button" class="btn btn-ghost btn-sm gap-1">
      Components <span class="hero-chevron-down size-4" aria-hidden="true"></span>
    </div>
    <div tabindex="0" class="dropdown-content z-20 mt-1.5 grid w-[26rem] grid-cols-2 gap-1 p-2">
      <a class="rounded-md p-2 hover:bg-accent">
        <div class="text-sm font-medium">Alert Dialog</div>
        <p class="text-xs text-muted-foreground">Modal confirmation.</p>
      </a>
      <a class="rounded-md p-2 hover:bg-accent">
        <div class="text-sm font-medium">Hover Card</div>
        <p class="text-xs text-muted-foreground">Preview on hover.</p>
      </a>
      <a class="rounded-md p-2 hover:bg-accent">
        <div class="text-sm font-medium">Progress</div>
        <p class="text-xs text-muted-foreground">Loading indicator.</p>
      </a>
      <a class="rounded-md p-2 hover:bg-accent">
        <div class="text-sm font-medium">Tabs</div>
        <p class="text-xs text-muted-foreground">Layered sections.</p>
      </a>
    </div>
  </div>
  <a class="btn btn-ghost btn-sm">Documentation</a>
</nav>
```

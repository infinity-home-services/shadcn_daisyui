# Section Nav

Where an edit form's sections are: a list beside the cards on wide screens, a dropdown in the page header on narrow ones, marking the section in view.

> Requires a JS hook: initialize with `initShadcnDaisyui()` (dead views) or the corresponding `Shadcn*` LiveView hook from `shadcn-daisyui.js`.

Each section is an element (a card) with that id. Both variants mark the section in view (aria-current / aria-selected), measured against the bottom of the pinned page header (data-sticky-top); at the bottom of the page it is the last one. Choosing one scrolls there (smoothly, or at once under reduced motion), keeps it marked until the scroll settles, moves focus to it and closes the select. The side list's filter matches section and group names. Consecutive sections with the same group share a heading; the select names the current one "Group, Section". Needs the ShadcnSectionNav hook. In these previews a bordered box stands in for the window (the side list is capped to the box's height); the record page on the dev server (`/lab/data-table/:id`) shows both variants in a real page.

## Usage guidance

Use when:

- A long edit form split into cards (Customer, Addresses, Items, Billing…)
- Records people come back to for one detail: the list finds it the same way every time
- Over 10 sections: the side list adds a filter

Don't use for:

- Three or four short sections - one scrolling page is enough
- Separate parts of a record with their own data - use <.record_tabs>
- A step-by-step flow - use steps and one page per step

Sizing: Side: a 12rem column beside the cards (24px gap), text-sm items with 6px / 8px padding, rounded-md, accent on the section in view, text-xs muted group labels. Select: a full-width outline trigger, a floating list with options at least 44px tall and a tick on the current one.

Responsive: From lg (64rem) the side list shows, pinned just under the page's pinned header and level with the first card, scrolling on its own when taller than the window. Below lg it hides and variant="select" (in the page header's :below slot) shows instead - render both.

iOS: A Form with a Section per card in a ScrollViewReader, and a toolbar Menu of sections that scrolls to one.

## Specs

| Part | Description |
| --- | --- |
| Layout | Side, with cards: a grid of the list and the cards (24px apart). |
| Filter | Over 10 sections: a "Filter sections" search input. |
| Group label | text-xs muted, over consecutive sections of a group. |
| Item | A link to #id; accent and 500 on the section in view. |
| Select trigger | Full-width outline button naming the current section. |
| Select list | A listbox of 44px options grouped by heading, with a tick. |

| Property | Value |
| --- | --- |
| Side column | 12rem, from 64rem; sticky under the header + 16px |
| Item | 0.375rem 0.5rem padding, text-sm, var(--radius-md) |
| Group label | 0.75rem, weight 500, var(--muted-foreground) |
| Select options | min 2.75rem / 44px, 16px tick |
| Select list | max min(24rem, 60dvh), scrolls |

Tokens used: `accent`, `accent-foreground`, `muted-foreground`, `foreground`, `input`, `popover`, `border-color`, `ring`

## Accessibility

| Keys | Action |
| --- | --- |
| Tab | Side: the filter, then each link |
| Enter | Go to the section; focus moves to it |
| Down / Up on the trigger | Open the list on the first / last option |
| Up / Down, Home / End | Move between options |
| Esc | Close the list; focus back on the trigger |

Role / ARIA: Side: a nav named "Sections" of links (href=#id) with aria-current=true on the section in view. Select: a button (aria-haspopup=listbox, aria-expanded, aria-controls) and a listbox of role=option buttons with aria-selected, grouped by role=group headings.

Focus: Choosing a section moves focus to its card (tabindex=-1, no ring around the whole card) so keyboard and screen reader users continue from there.

Screen reader: The current link reads as current; the trigger reads "Sections" and the section in view; options announce selected.

Touch target: Select options are at least 44px tall; side items are a desktop control (from lg).

Reduced motion: Choosing a section jumps there instead of scrolling smoothly.

## Native (SwiftUI)

Parity: guidance only - no native component yet.

```swift
ScrollViewReader { proxy in
    Form {
        ForEach(sections) { section in
            Section(section.label) { fields(for: section) }.id(section.id)
        }
    }
    .toolbar {
        Menu("Sections", systemImage: "list.bullet") {
            ForEach(sections) { section in
                Button(section.label) { withAnimation { proxy.scrollTo(section.id, anchor: .top) } }
            }
        }
    }
}
```

iOS has no scroll-spy list; a toolbar Menu of sections that scrolls with ScrollViewReader covers finding a section. On iPad a NavigationSplitView sidebar of sections is the wide-screen equivalent.

## Props

| Name | Type | Default |
| --- | --- | --- |
| id | string (required) | - |
| sections | [{id, label}] or [{id, label, group}] | - |
| variant | side \| select | side |
| aria_label | string | "Sections" |
| class | any | nil |
| inner_block | slot (side: the cards, laid out beside the list) | - |

## Side list

HEEx:

```heex
<.section_nav
  id="order-sections"
  sections={[
    {"customer", "Name", "Customer"},
    {"contact", "Contact", "Customer"},
    {"billing-address", "Billing address", "Addresses"},
    {"shipping-address", "Shipping address", "Addresses"},
    {"items", "Items", "Order"},
    …
    {"notes", "Notes", "Other"}
  ]}
>
  <.card id="customer">…</.card>
  <.card id="contact">…</.card>
  …
  <.card id="notes">…</.card>
</.section_nav>
```

```html
<div class="h-96 w-full overflow-y-auto rounded-xl border border-border p-4">
  <!-- The box stands in for the window: the list is capped to its height. -->
  <p class="mb-4 text-sm text-muted-foreground lg:hidden">
    The list shows from 1024px wide: widen the window to see it.
  </p>
  <div class="section-nav-layout">
    <nav id="side-sections" data-section-nav data-variant="side" aria-label="Sections" class="section-nav section-nav-side" style="max-height: 20rem">
      <label class="input section-nav-filter">
        <span class="hero-magnifying-glass size-4 shrink-0 opacity-50" aria-hidden="true"></span>
        <input type="search" placeholder="Filter sections" aria-label="Filter sections" autocomplete="off" data-section-filter>
      </label>
      <div class="section-nav-group" data-group-label="Customer">
        <div class="section-nav-group-label">Customer</div>
        <a href="#side-customer" class="section-nav-item" aria-current="true" data-section="side-customer" data-label="Name">
          Name
        </a>
        <a href="#side-contact" class="section-nav-item" data-section="side-contact" data-label="Contact">
          Contact
        </a>
      </div>
      <div class="section-nav-group" data-group-label="Addresses">
        <div class="section-nav-group-label">Addresses</div>
        <a href="#side-billing-address" class="section-nav-item" data-section="side-billing-address" data-label="Billing address">
          Billing address
        </a>
        <a href="#side-shipping-address" class="section-nav-item" data-section="side-shipping-address" data-label="Shipping address">
          Shipping address
        </a>
      </div>
      <div class="section-nav-group" data-group-label="Order">
        <div class="section-nav-group-label">Order</div>
        <a href="#side-items" class="section-nav-item" data-section="side-items" data-label="Items">
          Items
        </a>
        <a href="#side-discounts" class="section-nav-item" data-section="side-discounts" data-label="Discounts">
          Discounts
        </a>
        <a href="#side-taxes" class="section-nav-item" data-section="side-taxes" data-label="Taxes">
          Taxes
        </a>
      </div>
      <div class="section-nav-group" data-group-label="Delivery">
        <div class="section-nav-group-label">Delivery</div>
        <a href="#side-delivery-window" class="section-nav-item" data-section="side-delivery-window" data-label="Delivery window">
          Delivery window
        </a>
        <a href="#side-instructions" class="section-nav-item" data-section="side-instructions" data-label="Instructions">
          Instructions
        </a>
      </div>
      <div class="section-nav-group" data-group-label="Billing">
        <div class="section-nav-group-label">Billing</div>
        <a href="#side-payment" class="section-nav-item" data-section="side-payment" data-label="Payment">
          Payment
        </a>
        <a href="#side-invoice" class="section-nav-item" data-section="side-invoice" data-label="Invoice">
          Invoice
        </a>
      </div>
      <div class="section-nav-group" data-group-label="Other">
        <div class="section-nav-group-label">Other</div>
        <a href="#side-notes" class="section-nav-item" data-section="side-notes" data-label="Notes">
          Notes
        </a>
      </div>
      <p class="section-nav-none" data-section-none hidden>No sections match.</p>
    </nav>
    <div class="section-nav-content">
      <div class="card" id="side-customer">
        <div class="card-body">
          <h3 class="card-title">Name</h3>
          <p class="text-sm text-muted-foreground">Who the order is for.</p>
        </div>
      </div>
      <div class="card" id="side-contact">
        <div class="card-body">
          <h3 class="card-title">Contact</h3>
          <p class="text-sm text-muted-foreground">Email and phone for questions about the order.</p>
        </div>
      </div>
      <div class="card" id="side-billing-address">
        <div class="card-body">
          <h3 class="card-title">Billing address</h3>
          <p class="text-sm text-muted-foreground">Where the invoice goes.</p>
        </div>
      </div>
      <div class="card" id="side-shipping-address">
        <div class="card-body">
          <h3 class="card-title">Shipping address</h3>
          <p class="text-sm text-muted-foreground">Leave empty to ship to the billing address.</p>
        </div>
      </div>
      <div class="card" id="side-items">
        <div class="card-body">
          <h3 class="card-title">Items</h3>
          <p class="text-sm text-muted-foreground">What&#39;s on the order.</p>
        </div>
      </div>
      <div class="card" id="side-discounts">
        <div class="card-body">
          <h3 class="card-title">Discounts</h3>
          <p class="text-sm text-muted-foreground">Codes and manual discounts.</p>
        </div>
      </div>
      <div class="card" id="side-taxes">
        <div class="card-body">
          <h3 class="card-title">Taxes</h3>
          <p class="text-sm text-muted-foreground">Tax rates and exemptions.</p>
        </div>
      </div>
      <div class="card" id="side-delivery-window">
        <div class="card-body">
          <h3 class="card-title">Delivery window</h3>
          <p class="text-sm text-muted-foreground">When someone is there to take the delivery.</p>
        </div>
      </div>
      <div class="card" id="side-instructions">
        <div class="card-body">
          <h3 class="card-title">Instructions</h3>
          <p class="text-sm text-muted-foreground">Gate codes, loading dock, who to ask for.</p>
        </div>
      </div>
      <div class="card" id="side-payment">
        <div class="card-body">
          <h3 class="card-title">Payment</h3>
          <p class="text-sm text-muted-foreground">How the customer pays.</p>
        </div>
      </div>
      <div class="card" id="side-invoice">
        <div class="card-body">
          <h3 class="card-title">Invoice</h3>
          <p class="text-sm text-muted-foreground">Payment terms and the invoice number.</p>
        </div>
      </div>
      <div class="card" id="side-notes">
        <div class="card-body">
          <h3 class="card-title">Notes</h3>
          <p class="text-sm text-muted-foreground">Anything the team should know.</p>
        </div>
      </div>
    </div>
  </div>
</div>
```

## Select (narrow screens)

HEEx:

```heex
<.page_header>
  Edit order
  <:below>
    <.section_nav id="order-sections-select" sections={@sections} variant="select" />
  </:below>
</.page_header>
```

```html
<div class="h-[32rem] w-full overflow-y-auto rounded-xl border border-border p-4">
  <!-- The box stands in for the window; the pinned div stands in for the page header. -->
  <div data-sticky-top class="sticky -top-4 z-10 -mx-4 -mt-4 mb-4 space-y-3 border-b border-border bg-base-100 p-4">
    <p class="text-base font-semibold">Edit order</p>
    <p class="hidden text-sm text-muted-foreground lg:block">
      The select shows below 1024px wide: narrow the window to see it.
    </p>
    <div id="pick-sections" data-section-nav data-variant="select" class="section-nav section-nav-select">
      <button type="button" id="pick-sections-trigger" class="btn btn-outline section-nav-trigger" aria-haspopup="listbox" aria-expanded="false" aria-controls="pick-sections-list" aria-label="Sections" data-section-trigger>
        <span class="section-nav-current" data-section-current>Customer, Name</span>
        <span class="hero-chevron-down size-4 shrink-0 opacity-50" aria-hidden="true"></span>
      </button>
      <div id="pick-sections-list" role="listbox" aria-label="Sections" class="popover-panel section-nav-panel" data-section-panel hidden>
        <div role="group" aria-labelledby="pick-sections-group-0">
          <div id="pick-sections-group-0" class="command-group-label">Customer</div>
          <button type="button" role="option" tabindex="-1" id="pick-sections-option-pick-customer" class="section-nav-option" aria-selected="true" data-section="pick-customer" data-label="Customer, Name">
            <span class="section-nav-option-label">Name</span>
            <span class="hero-check section-nav-tick size-4" aria-hidden="true"></span>
          </button>
          <button type="button" role="option" tabindex="-1" id="pick-sections-option-pick-contact" class="section-nav-option" aria-selected="false" data-section="pick-contact" data-label="Customer, Contact">
            <span class="section-nav-option-label">Contact</span>
            <span class="hero-check section-nav-tick size-4" aria-hidden="true"></span>
          </button>
        </div>
        <div role="group" aria-labelledby="pick-sections-group-1" class="section-nav-panel-group">
          <div id="pick-sections-group-1" class="command-group-label">Addresses</div>
          <button type="button" role="option" tabindex="-1" id="pick-sections-option-pick-billing-address" class="section-nav-option" aria-selected="false" data-section="pick-billing-address" data-label="Addresses, Billing address">
            <span class="section-nav-option-label">Billing address</span>
            <span class="hero-check section-nav-tick size-4" aria-hidden="true"></span>
          </button>
          <button type="button" role="option" tabindex="-1" id="pick-sections-option-pick-shipping-address" class="section-nav-option" aria-selected="false" data-section="pick-shipping-address" data-label="Addresses, Shipping address">
            <span class="section-nav-option-label">Shipping address</span>
            <span class="hero-check section-nav-tick size-4" aria-hidden="true"></span>
          </button>
        </div>
        <div role="group" aria-labelledby="pick-sections-group-2" class="section-nav-panel-group">
          <div id="pick-sections-group-2" class="command-group-label">Order</div>
          <button type="button" role="option" tabindex="-1" id="pick-sections-option-pick-items" class="section-nav-option" aria-selected="false" data-section="pick-items" data-label="Order, Items">
            <span class="section-nav-option-label">Items</span>
            <span class="hero-check section-nav-tick size-4" aria-hidden="true"></span>
          </button>
          <button type="button" role="option" tabindex="-1" id="pick-sections-option-pick-discounts" class="section-nav-option" aria-selected="false" data-section="pick-discounts" data-label="Order, Discounts">
            <span class="section-nav-option-label">Discounts</span>
            <span class="hero-check section-nav-tick size-4" aria-hidden="true"></span>
          </button>
          <button type="button" role="option" tabindex="-1" id="pick-sections-option-pick-taxes" class="section-nav-option" aria-selected="false" data-section="pick-taxes" data-label="Order, Taxes">
            <span class="section-nav-option-label">Taxes</span>
            <span class="hero-check section-nav-tick size-4" aria-hidden="true"></span>
          </button>
        </div>
        <div role="group" aria-labelledby="pick-sections-group-3" class="section-nav-panel-group">
          <div id="pick-sections-group-3" class="command-group-label">Delivery</div>
          <button type="button" role="option" tabindex="-1" id="pick-sections-option-pick-delivery-window" class="section-nav-option" aria-selected="false" data-section="pick-delivery-window" data-label="Delivery, Delivery window">
            <span class="section-nav-option-label">Delivery window</span>
            <span class="hero-check section-nav-tick size-4" aria-hidden="true"></span>
          </button>
          <button type="button" role="option" tabindex="-1" id="pick-sections-option-pick-instructions" class="section-nav-option" aria-selected="false" data-section="pick-instructions" data-label="Delivery, Instructions">
            <span class="section-nav-option-label">Instructions</span>
            <span class="hero-check section-nav-tick size-4" aria-hidden="true"></span>
          </button>
        </div>
        <div role="group" aria-labelledby="pick-sections-group-4" class="section-nav-panel-group">
          <div id="pick-sections-group-4" class="command-group-label">Billing</div>
          <button type="button" role="option" tabindex="-1" id="pick-sections-option-pick-payment" class="section-nav-option" aria-selected="false" data-section="pick-payment" data-label="Billing, Payment">
            <span class="section-nav-option-label">Payment</span>
            <span class="hero-check section-nav-tick size-4" aria-hidden="true"></span>
          </button>
          <button type="button" role="option" tabindex="-1" id="pick-sections-option-pick-invoice" class="section-nav-option" aria-selected="false" data-section="pick-invoice" data-label="Billing, Invoice">
            <span class="section-nav-option-label">Invoice</span>
            <span class="hero-check section-nav-tick size-4" aria-hidden="true"></span>
          </button>
        </div>
        <div role="group" aria-labelledby="pick-sections-group-5" class="section-nav-panel-group">
          <div id="pick-sections-group-5" class="command-group-label">Other</div>
          <button type="button" role="option" tabindex="-1" id="pick-sections-option-pick-notes" class="section-nav-option" aria-selected="false" data-section="pick-notes" data-label="Other, Notes">
            <span class="section-nav-option-label">Notes</span>
            <span class="hero-check section-nav-tick size-4" aria-hidden="true"></span>
          </button>
        </div>
      </div>
    </div>
  </div>
  <div class="flex flex-col gap-6">
    <div class="card" id="pick-customer">
      <div class="card-body">
        <h3 class="card-title">Name</h3>
        <p class="text-sm text-muted-foreground">Who the order is for.</p>
      </div>
    </div>
    <div class="card" id="pick-contact">
      <div class="card-body">
        <h3 class="card-title">Contact</h3>
        <p class="text-sm text-muted-foreground">Email and phone for questions about the order.</p>
      </div>
    </div>
    <div class="card" id="pick-billing-address">
      <div class="card-body">
        <h3 class="card-title">Billing address</h3>
        <p class="text-sm text-muted-foreground">Where the invoice goes.</p>
      </div>
    </div>
    <div class="card" id="pick-shipping-address">
      <div class="card-body">
        <h3 class="card-title">Shipping address</h3>
        <p class="text-sm text-muted-foreground">Leave empty to ship to the billing address.</p>
      </div>
    </div>
    <div class="card" id="pick-items">
      <div class="card-body">
        <h3 class="card-title">Items</h3>
        <p class="text-sm text-muted-foreground">What&#39;s on the order.</p>
      </div>
    </div>
    <div class="card" id="pick-discounts">
      <div class="card-body">
        <h3 class="card-title">Discounts</h3>
        <p class="text-sm text-muted-foreground">Codes and manual discounts.</p>
      </div>
    </div>
    <div class="card" id="pick-taxes">
      <div class="card-body">
        <h3 class="card-title">Taxes</h3>
        <p class="text-sm text-muted-foreground">Tax rates and exemptions.</p>
      </div>
    </div>
    <div class="card" id="pick-delivery-window">
      <div class="card-body">
        <h3 class="card-title">Delivery window</h3>
        <p class="text-sm text-muted-foreground">When someone is there to take the delivery.</p>
      </div>
    </div>
    <div class="card" id="pick-instructions">
      <div class="card-body">
        <h3 class="card-title">Instructions</h3>
        <p class="text-sm text-muted-foreground">Gate codes, loading dock, who to ask for.</p>
      </div>
    </div>
    <div class="card" id="pick-payment">
      <div class="card-body">
        <h3 class="card-title">Payment</h3>
        <p class="text-sm text-muted-foreground">How the customer pays.</p>
      </div>
    </div>
    <div class="card" id="pick-invoice">
      <div class="card-body">
        <h3 class="card-title">Invoice</h3>
        <p class="text-sm text-muted-foreground">Payment terms and the invoice number.</p>
      </div>
    </div>
    <div class="card" id="pick-notes">
      <div class="card-body">
        <h3 class="card-title">Notes</h3>
        <p class="text-sm text-muted-foreground">Anything the team should know.</p>
      </div>
    </div>
  </div>
</div>
```

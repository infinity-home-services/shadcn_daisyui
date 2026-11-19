# Command Menu

A searchable dropdown for long grouped lists: a search box over grouped, nested rows, anchored to its trigger, a drawer on phones.

> Requires a JS hook: initialize with `initShadcnDaisyui()` (dead views) or the corresponding `Shadcn*` LiveView hook from `shadcn-daisyui.js`.

Needs the ShadcnCommandMenu hook (in Hooks; dead views: initShadcnDaisyui()). Build the rows in Elixir, each child right after its parent, and render them with one :for (a slot entry can't sit inside a for block). parent nests a row under another (up to four levels). Typing filters every level: a row shows when every word typed starts a word of its own text (label, description, keywords) or its parents', so a location's name shows it under its brand (muted, for context) and a brand's name shows it with all its locations; accents and case don't matter, the first match is active, and the count is announced. current marks the chosen row (a check, aria-selected) and is active when the menu opens. Choosing a row closes the menu (a row with confirm, once it's accepted). Esc closes and returns focus to the trigger; a press outside or Tab closes it. One command menu is open at a time.

## Usage guidance

Use when:

- Choosing one of many (dozens to a few hundred) places, scopes or records from a trigger: a brand and location switcher, a team picker
- The list has groups and levels (brands and their locations) and people find a row by typing part of its name
- Each row does something: goes somewhere, submits a form or runs an event

Don't use for:

- Setting a form field - use <.combobox> or <.select> (they post a value)
- A handful of actions - use <.dropdown_menu>
- Searching the whole app, or a list only the server can search - use <.command> (on_search)

Sizing: Panel w-72 (18rem) by default, at least the trigger's width; the list scrolls past 300px, and the panel never outgrows the room beside its trigger. Rows are 32px (44px in the drawer); each level of nesting steps in 1.5rem, so a child's icon sits under its parent's label.

Responsive: From 48rem a dropdown in the top layer: below its trigger (side="right": beside it), flipped above or to the left when there's more room there, kept inside the window, following the trigger as the page scrolls. Below 48rem a bottom drawer, up to 85% of the screen, with a 16px search box that isn't focused on open, so the keyboard doesn't cover the list.

iOS: A sheet with .searchable and a List of Sections; DisclosureGroup or indented rows for children, a checkmark on the current row, .presentationDetents([.medium, .large]).

## Specs

| Part | Description |
| --- | --- |
| Trigger | The menu's own button (:trigger), or trigger_id. |
| Panel | Popover surface in the top layer (popover=manual): search row, list, empty text. |
| Search | A combobox input, 36px row with a search icon. |
| List | A listbox of groups (heading + options); scrolls past 300px. |
| Row | Icon, label, optional description, a check on the current row; indented by level. |

| Property | Value |
| --- | --- |
| Panel | w-72, ≥ trigger width, var(--radius-md), popover ring + shadow-md, 4px gap |
| Search row | 36px (44px in the drawer), 1px bottom border |
| Row | 32px, 14px text, 8px gaps; drawer 44px |
| Nesting | 1.5rem per level (up to 4) |
| Motion | dropdown fades and zooms from 95% in 150ms; drawer slides up in 300ms; none with reduced motion |

## Accessibility

| Keys | Action |
| --- | --- |
| Enter / Space / ↓ / ↑ | On the trigger: open (↑ starts at the last row) |
| ↓ / ↑ | Move through the rows (wraps, skips disabled ones) |
| Page Down / Page Up | Move ten rows |
| Enter | Choose the active row |
| Esc | Close, focus back on the trigger |
| Tab | Close and move on |

Role / ARIA: The trigger has aria-haspopup="dialog", aria-expanded and aria-controls (the panel). The panel is role="dialog" named by label; its search box is role="combobox" (aria-controls the list, aria-activedescendant the active row) over a role="listbox" of role="group"s, each labelled by its heading. Rows are role="option", the current one aria-selected="true"; disabled rows aria-disabled.

Focus: Opening focuses the search box (the drawer focuses itself instead; typing goes to the search). Focus stays in the search box while the arrow keys move the active row, which scrolls into view. Closing with Esc or a choice returns focus to the trigger.

Screen reader: The active row is read through aria-activedescendant; after typing, the number of results (or the empty text) is announced in a polite status region. Nested rows are indented visually only: put what a row belongs to in its description when it matters.

Touch target: Drawer rows are 44px, its search box 44px with 16px text.

Reduced motion: No fade, zoom or slide: the menu and the drawer appear at once.

## Props

| Name | Type | Default |
| --- | --- | --- |
| id | string (required) | - |
| label | string (required, the accessible name) | - |
| placeholder | string | "Search…" |
| trigger_id | string (an element elsewhere that opens it) | nil (the :trigger slot) |
| trigger_class | any | "btn btn-outline w-64 …" |
| side | bottom \| right | bottom |
| align | start \| end | start |
| class | any (the panel's width) | "w-72" |
| phx-target | any (rows' phx-click) | nil |
| :trigger | slot (inside the trigger button) | - |
| :item | slot: id group parent icon description keywords current, phx-click values \| navigate \| patch \| href method \| form name value, confirm disabled | - |
| :empty | slot | "No results found." |

## Switch location

The company, divisions with their regions, and brands with their locations. Type a city: the location shows under its brand.

HEEx:

```heex
<.command_menu id="scope" label="Switch location" placeholder="Search brands and locations">
  <:trigger>
    <span class="truncate">{@scope.label}</span>
    <span class="hero-chevron-up-down size-4 opacity-50" aria-hidden="true"></span>
  </:trigger>
  <:item
    :for={row <- @rows}
    id={row.id}
    group={row.group}
    parent={row[:parent]}
    icon={row.icon}
    description={row[:description]}
    current={row.id == @scope.id}
    patch={~p"/?scope=#{row.id}"}
  >
    {row.label}
  </:item>
  <:empty>No brand or location matches.</:empty>
</.command_menu>
```

```html
<div id="scope" class="command-menu" data-command-menu data-side="bottom" data-align="start">
  <button type="button" id="scope-trigger" class="btn btn-outline w-64 justify-between font-normal" data-command-menu-trigger aria-haspopup="dialog" aria-expanded="false" aria-controls="scope-panel">
    <span class="truncate">Birch Home Boston</span>
    <span class="hero-chevron-up-down size-4 opacity-50" aria-hidden="true"></span>
  </button>
  <div id="scope-panel" popover="manual" role="dialog" aria-label="Switch location" tabindex="-1" class="command-menu-panel w-72" data-command-menu-panel>
    <div class="command-menu-handle" aria-hidden="true"></div>
    <div class="command-menu-search">
      <span class="hero-magnifying-glass size-4 shrink-0 opacity-50" aria-hidden="true"></span>
      <input id="scope-search" type="text" data-command-menu-search role="combobox" aria-expanded="true" aria-controls="scope-list" aria-autocomplete="list" aria-label="Search brands and locations" autocomplete="off" autocapitalize="off" spellcheck="false" placeholder="Search brands and locations">
    </div>
    <div id="scope-list" role="listbox" aria-label="Switch location" class="command-menu-list">
      <div role="group" aria-labelledby="scope-group-0" data-command-menu-group>
        <div id="scope-group-0" class="command-group-label">Company</div>
        <a href="#scope=acme" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=acme" id="acme" role="option" class="command-item command-menu-item" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-building-office-2 size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              All of Acme
            </span>
          </span>
        </a>
      </div>
      <div role="group" aria-labelledby="scope-group-1" data-command-menu-group>
        <div id="scope-group-1" class="command-group-label">Divisions</div>
        <a href="#scope=div-east" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=div-east" id="div-east" role="option" class="command-item command-menu-item" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-squares-2x2 size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              East division
            </span>
          </span>
        </a>
        <a href="#scope=reg-northeast" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=reg-northeast" id="reg-northeast" role="option" class="command-item command-menu-item" data-parent="div-east" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Northeast
            </span>
          </span>
        </a>
        <a href="#scope=reg-mid-atlantic" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=reg-mid-atlantic" id="reg-mid-atlantic" role="option" class="command-item command-menu-item" data-parent="div-east" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Mid-Atlantic
            </span>
          </span>
        </a>
        <a href="#scope=reg-southeast" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=reg-southeast" id="reg-southeast" role="option" class="command-item command-menu-item" data-parent="div-east" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Southeast
            </span>
          </span>
        </a>
        <a href="#scope=div-west" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=div-west" id="div-west" role="option" class="command-item command-menu-item" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-squares-2x2 size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              West division
            </span>
          </span>
        </a>
        <a href="#scope=reg-mountain" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=reg-mountain" id="reg-mountain" role="option" class="command-item command-menu-item" data-parent="div-west" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Mountain
            </span>
          </span>
        </a>
        <a href="#scope=reg-pacific" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=reg-pacific" id="reg-pacific" role="option" class="command-item command-menu-item" data-parent="div-west" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Pacific
            </span>
          </span>
        </a>
        <a href="#scope=reg-southwest" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=reg-southwest" id="reg-southwest" role="option" class="command-item command-menu-item" data-parent="div-west" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Southwest
            </span>
          </span>
        </a>
      </div>
      <div role="group" aria-labelledby="scope-group-2" data-command-menu-group>
        <div id="scope-group-2" class="command-group-label">Brands</div>
        <a href="#scope=brand-1" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=brand-1" id="brand-1" role="option" class="command-item command-menu-item" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-tag size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Alder Home
            </span>
            <span class="command-item-description">3 locations</span>
          </span>
        </a>
        <a href="#scope=loc-1-1" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-1-1" id="loc-1-1" role="option" class="command-item command-menu-item" data-parent="brand-1" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Alder Home Raleigh
            </span>
            <span class="command-item-description">Store 101</span>
          </span>
        </a>
        <a href="#scope=loc-1-2" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-1-2" id="loc-1-2" role="option" class="command-item command-menu-item" data-parent="brand-1" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Alder Home Tampa
            </span>
            <span class="command-item-description">Store 102</span>
          </span>
        </a>
        <a href="#scope=loc-1-3" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-1-3" id="loc-1-3" role="option" class="command-item command-menu-item" data-parent="brand-1" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Alder Home Albany
            </span>
            <span class="command-item-description">Store 103</span>
          </span>
        </a>
        <a href="#scope=brand-2" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=brand-2" id="brand-2" role="option" class="command-item command-menu-item" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-tag size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Birch Home
            </span>
            <span class="command-item-description">3 locations</span>
          </span>
        </a>
        <a href="#scope=loc-2-1" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-2-1" id="loc-2-1" role="option" class="command-item command-menu-item" data-current data-parent="brand-2" data-depth="1" aria-selected="true" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Birch Home Boston
            </span>
            <span class="command-item-description">Store 201</span>
          </span>
          <span class="hero-check command-menu-check" aria-hidden="true"></span>
        </a>
        <a href="#scope=loc-2-2" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-2-2" id="loc-2-2" role="option" class="command-item command-menu-item" data-parent="brand-2" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Birch Home Fresno
            </span>
            <span class="command-item-description">Store 202</span>
          </span>
        </a>
        <a href="#scope=loc-2-3" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-2-3" id="loc-2-3" role="option" class="command-item command-menu-item" data-parent="brand-2" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Birch Home Omaha
            </span>
            <span class="command-item-description">Store 203</span>
          </span>
        </a>
        <a href="#scope=brand-3" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=brand-3" id="brand-3" role="option" class="command-item command-menu-item" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-tag size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Cedar Home
            </span>
            <span class="command-item-description">3 locations</span>
          </span>
        </a>
        <a href="#scope=loc-3-1" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-3-1" id="loc-3-1" role="option" class="command-item command-menu-item" data-parent="brand-3" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Cedar Home Portland
            </span>
            <span class="command-item-description">Store 301</span>
          </span>
        </a>
        <a href="#scope=loc-3-2" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-3-2" id="loc-3-2" role="option" class="command-item command-menu-item" data-parent="brand-3" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Cedar Home Richmond
            </span>
            <span class="command-item-description">Store 302</span>
          </span>
        </a>
        <a href="#scope=loc-3-3" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-3-3" id="loc-3-3" role="option" class="command-item command-menu-item" data-parent="brand-3" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Cedar Home Tucson
            </span>
            <span class="command-item-description">Store 303</span>
          </span>
        </a>
        <a href="#scope=brand-4" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=brand-4" id="brand-4" role="option" class="command-item command-menu-item" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-tag size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Dogwood Home
            </span>
            <span class="command-item-description">3 locations</span>
          </span>
        </a>
        <a href="#scope=loc-4-1" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-4-1" id="loc-4-1" role="option" class="command-item command-menu-item" data-parent="brand-4" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Dogwood Home Tulsa
            </span>
            <span class="command-item-description">Store 401</span>
          </span>
        </a>
        <a href="#scope=loc-4-2" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-4-2" id="loc-4-2" role="option" class="command-item command-menu-item" data-parent="brand-4" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Dogwood Home Charlotte
            </span>
            <span class="command-item-description">Store 402</span>
          </span>
        </a>
        <a href="#scope=loc-4-3" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-4-3" id="loc-4-3" role="option" class="command-item command-menu-item" data-parent="brand-4" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Dogwood Home Hartford
            </span>
            <span class="command-item-description">Store 403</span>
          </span>
        </a>
        <a href="#scope=brand-5" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=brand-5" id="brand-5" role="option" class="command-item command-menu-item" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-tag size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Elm Home
            </span>
            <span class="command-item-description">3 locations</span>
          </span>
        </a>
        <a href="#scope=loc-5-1" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-5-1" id="loc-5-1" role="option" class="command-item command-menu-item" data-parent="brand-5" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Elm Home Mesa
            </span>
            <span class="command-item-description">Store 501</span>
          </span>
        </a>
        <a href="#scope=loc-5-2" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-5-2" id="loc-5-2" role="option" class="command-item command-menu-item" data-parent="brand-5" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Elm Home Reno
            </span>
            <span class="command-item-description">Store 502</span>
          </span>
        </a>
        <a href="#scope=loc-5-3" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-5-3" id="loc-5-3" role="option" class="command-item command-menu-item" data-parent="brand-5" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Elm Home Sacramento
            </span>
            <span class="command-item-description">Store 503</span>
          </span>
        </a>
        <a href="#scope=brand-6" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=brand-6" id="brand-6" role="option" class="command-item command-menu-item" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-tag size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Fir Home
            </span>
            <span class="command-item-description">3 locations</span>
          </span>
        </a>
        <a href="#scope=loc-6-1" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-6-1" id="loc-6-1" role="option" class="command-item command-menu-item" data-parent="brand-6" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Fir Home Tampa
            </span>
            <span class="command-item-description">Store 601</span>
          </span>
        </a>
        <a href="#scope=loc-6-2" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-6-2" id="loc-6-2" role="option" class="command-item command-menu-item" data-parent="brand-6" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Fir Home Albany
            </span>
            <span class="command-item-description">Store 602</span>
          </span>
        </a>
        <a href="#scope=loc-6-3" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-6-3" id="loc-6-3" role="option" class="command-item command-menu-item" data-parent="brand-6" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Fir Home Denver
            </span>
            <span class="command-item-description">Store 603</span>
          </span>
        </a>
      </div>
    </div>
    <p data-command-menu-empty hidden class="command-menu-empty">
      No brand or location matches.
    </p>
    <div id="scope-status" role="status" class="sr-only" data-command-menu-status phx-update="ignore">
    </div>
  </div>
</div>
```

## From the sidebar header

trigger_id points the menu at the app shell's heading, rendered as a button; side="right" opens it beside the sidebar, as shadcn's team switcher does.

HEEx:

```heex
<:header>
  <.app_shell_heading id="scope-trigger" as="button" icon="hero-building-office-2"
    title={@scope.label} subtitle="Location" tip={@scope.label} chevron />
</:header>
…
<.command_menu id="scope" trigger_id="scope-trigger" side="right" label="Switch location">
  <:item :for={row <- @rows} id={row.id} group={row.group} parent={row[:parent]}
    icon={row.icon} current={row.id == @scope.id} patch={~p"/?scope=#{row.id}"}>
    {row.label}
  </:item>
</.command_menu>
```

```html
<div class="w-64 rounded-lg border border-border bg-base-200 p-2">
  <button type="button" class="app-shell-heading" id="scope-heading">
    <span class="app-shell-tile"><span class="hero-building-office-2 size-4" aria-hidden="true"></span></span>
    <span class="app-shell-label app-shell-heading-text">
      <span class="app-shell-heading-title">All of Acme</span>
      <span class="app-shell-heading-subtitle">Location</span>
    </span>
    <span class="hero-chevron-up-down size-4 shrink-0 app-shell-label app-shell-muted" aria-hidden="true">
    </span>
  </button>
</div>
<div id="scope-side" class="command-menu" data-command-menu data-trigger="scope-heading" data-side="right" data-align="start">
  <div id="scope-side-panel" popover="manual" role="dialog" aria-label="Switch location" tabindex="-1" class="command-menu-panel w-72" data-command-menu-panel>
    <div class="command-menu-handle" aria-hidden="true"></div>
    <div class="command-menu-search">
      <span class="hero-magnifying-glass size-4 shrink-0 opacity-50" aria-hidden="true"></span>
      <input id="scope-side-search" type="text" data-command-menu-search role="combobox" aria-expanded="true" aria-controls="scope-side-list" aria-autocomplete="list" aria-label="Search brands and locations" autocomplete="off" autocapitalize="off" spellcheck="false" placeholder="Search brands and locations">
    </div>
    <div id="scope-side-list" role="listbox" aria-label="Switch location" class="command-menu-list">
      <div role="group" aria-labelledby="scope-side-group-0" data-command-menu-group>
        <div id="scope-side-group-0" class="command-group-label">Company</div>
        <a href="#scope=acme" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=acme" id="side-acme" role="option" class="command-item command-menu-item" data-current aria-selected="true" data-command-menu-item tabindex="-1">
          <span class="hero-building-office-2 size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              All of Acme
            </span>
          </span>
          <span class="hero-check command-menu-check" aria-hidden="true"></span>
        </a>
      </div>
      <div role="group" aria-labelledby="scope-side-group-1" data-command-menu-group>
        <div id="scope-side-group-1" class="command-group-label">Divisions</div>
        <a href="#scope=div-east" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=div-east" id="side-div-east" role="option" class="command-item command-menu-item" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-squares-2x2 size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              East division
            </span>
          </span>
        </a>
        <a href="#scope=reg-northeast" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=reg-northeast" id="side-reg-northeast" role="option" class="command-item command-menu-item" data-parent="side-div-east" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Northeast
            </span>
          </span>
        </a>
        <a href="#scope=reg-mid-atlantic" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=reg-mid-atlantic" id="side-reg-mid-atlantic" role="option" class="command-item command-menu-item" data-parent="side-div-east" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Mid-Atlantic
            </span>
          </span>
        </a>
        <a href="#scope=reg-southeast" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=reg-southeast" id="side-reg-southeast" role="option" class="command-item command-menu-item" data-parent="side-div-east" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Southeast
            </span>
          </span>
        </a>
        <a href="#scope=div-west" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=div-west" id="side-div-west" role="option" class="command-item command-menu-item" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-squares-2x2 size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              West division
            </span>
          </span>
        </a>
        <a href="#scope=reg-mountain" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=reg-mountain" id="side-reg-mountain" role="option" class="command-item command-menu-item" data-parent="side-div-west" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Mountain
            </span>
          </span>
        </a>
        <a href="#scope=reg-pacific" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=reg-pacific" id="side-reg-pacific" role="option" class="command-item command-menu-item" data-parent="side-div-west" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Pacific
            </span>
          </span>
        </a>
        <a href="#scope=reg-southwest" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=reg-southwest" id="side-reg-southwest" role="option" class="command-item command-menu-item" data-parent="side-div-west" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Southwest
            </span>
          </span>
        </a>
      </div>
      <div role="group" aria-labelledby="scope-side-group-2" data-command-menu-group>
        <div id="scope-side-group-2" class="command-group-label">Brands</div>
        <a href="#scope=brand-1" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=brand-1" id="side-brand-1" role="option" class="command-item command-menu-item" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-tag size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Alder Home
            </span>
          </span>
        </a>
        <a href="#scope=loc-1-1" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-1-1" id="side-loc-1-1" role="option" class="command-item command-menu-item" data-parent="side-brand-1" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Alder Home Raleigh
            </span>
          </span>
        </a>
        <a href="#scope=loc-1-2" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-1-2" id="side-loc-1-2" role="option" class="command-item command-menu-item" data-parent="side-brand-1" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Alder Home Tampa
            </span>
          </span>
        </a>
        <a href="#scope=loc-1-3" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-1-3" id="side-loc-1-3" role="option" class="command-item command-menu-item" data-parent="side-brand-1" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Alder Home Albany
            </span>
          </span>
        </a>
        <a href="#scope=brand-2" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=brand-2" id="side-brand-2" role="option" class="command-item command-menu-item" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-tag size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Birch Home
            </span>
          </span>
        </a>
        <a href="#scope=loc-2-1" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-2-1" id="side-loc-2-1" role="option" class="command-item command-menu-item" data-parent="side-brand-2" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Birch Home Boston
            </span>
          </span>
        </a>
        <a href="#scope=loc-2-2" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-2-2" id="side-loc-2-2" role="option" class="command-item command-menu-item" data-parent="side-brand-2" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Birch Home Fresno
            </span>
          </span>
        </a>
        <a href="#scope=loc-2-3" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-2-3" id="side-loc-2-3" role="option" class="command-item command-menu-item" data-parent="side-brand-2" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Birch Home Omaha
            </span>
          </span>
        </a>
        <a href="#scope=brand-3" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=brand-3" id="side-brand-3" role="option" class="command-item command-menu-item" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-tag size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Cedar Home
            </span>
          </span>
        </a>
        <a href="#scope=loc-3-1" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-3-1" id="side-loc-3-1" role="option" class="command-item command-menu-item" data-parent="side-brand-3" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Cedar Home Portland
            </span>
          </span>
        </a>
        <a href="#scope=loc-3-2" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-3-2" id="side-loc-3-2" role="option" class="command-item command-menu-item" data-parent="side-brand-3" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Cedar Home Richmond
            </span>
          </span>
        </a>
        <a href="#scope=loc-3-3" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-3-3" id="side-loc-3-3" role="option" class="command-item command-menu-item" data-parent="side-brand-3" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Cedar Home Tucson
            </span>
          </span>
        </a>
        <a href="#scope=brand-4" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=brand-4" id="side-brand-4" role="option" class="command-item command-menu-item" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-tag size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Dogwood Home
            </span>
          </span>
        </a>
        <a href="#scope=loc-4-1" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-4-1" id="side-loc-4-1" role="option" class="command-item command-menu-item" data-parent="side-brand-4" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Dogwood Home Tulsa
            </span>
          </span>
        </a>
        <a href="#scope=loc-4-2" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-4-2" id="side-loc-4-2" role="option" class="command-item command-menu-item" data-parent="side-brand-4" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Dogwood Home Charlotte
            </span>
          </span>
        </a>
        <a href="#scope=loc-4-3" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-4-3" id="side-loc-4-3" role="option" class="command-item command-menu-item" data-parent="side-brand-4" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Dogwood Home Hartford
            </span>
          </span>
        </a>
        <a href="#scope=brand-5" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=brand-5" id="side-brand-5" role="option" class="command-item command-menu-item" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-tag size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Elm Home
            </span>
          </span>
        </a>
        <a href="#scope=loc-5-1" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-5-1" id="side-loc-5-1" role="option" class="command-item command-menu-item" data-parent="side-brand-5" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Elm Home Mesa
            </span>
          </span>
        </a>
        <a href="#scope=loc-5-2" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-5-2" id="side-loc-5-2" role="option" class="command-item command-menu-item" data-parent="side-brand-5" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Elm Home Reno
            </span>
          </span>
        </a>
        <a href="#scope=loc-5-3" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-5-3" id="side-loc-5-3" role="option" class="command-item command-menu-item" data-parent="side-brand-5" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Elm Home Sacramento
            </span>
          </span>
        </a>
        <a href="#scope=brand-6" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=brand-6" id="side-brand-6" role="option" class="command-item command-menu-item" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-tag size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Fir Home
            </span>
          </span>
        </a>
        <a href="#scope=loc-6-1" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-6-1" id="side-loc-6-1" role="option" class="command-item command-menu-item" data-parent="side-brand-6" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Fir Home Tampa
            </span>
          </span>
        </a>
        <a href="#scope=loc-6-2" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-6-2" id="side-loc-6-2" role="option" class="command-item command-menu-item" data-parent="side-brand-6" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Fir Home Albany
            </span>
          </span>
        </a>
        <a href="#scope=loc-6-3" data-csrf="LGkqNxtjRCYtVER1Hj4xdRMsWRB2GBEc_DaCaQ0EEb12szG7as3f4QEF" data-to="#scope=loc-6-3" id="side-loc-6-3" role="option" class="command-item command-menu-item" data-parent="side-brand-6" data-depth="1" aria-selected="false" data-command-menu-item tabindex="-1">
          <span class="hero-map-pin size-4 shrink-0" aria-hidden="true"></span>
          <span class="command-item-text">
            <span class="command-item-title">
              Fir Home Denver
            </span>
          </span>
        </a>
      </div>
    </div>
    <p data-command-menu-empty hidden class="command-menu-empty">
      No results found.
    </p>
    <div id="scope-side-status" role="status" class="sr-only" data-command-menu-status phx-update="ignore">
    </div>
  </div>
</div>
```

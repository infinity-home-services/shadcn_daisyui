defmodule ShadcnDaisyuiDemoWeb.Catalog.Enrichment.Interactive do
  @moduledoc "Specs / Accessibility / Native enrichment for the Interactive component group."

  @doc "Map of slug => enrichment fields."
  def specs do
    %{
      "combobox" => %{
        specs: %{
          anatomy: [
            %{
              part: "Trigger",
              description:
                "A button (aria-haspopup=listbox) showing the current value or placeholder; toggles the popover."
            },
            %{
              part: "Search input",
              description:
                "role=combobox with aria-autocomplete=list; filters the options as you type."
            },
            %{
              part: "Listbox",
              description:
                "role=listbox panel of role=option rows; the active row is highlighted with accent."
            },
            %{
              part: "Empty state",
              description: "Shown when the filter matches nothing."
            }
          ],
          measurements: [
            %{property: "Popover radius", value: "var(--radius-md)"},
            %{property: "Option radius", value: "var(--radius-sm)"},
            %{property: "Option padding", value: "0.375rem 0.5rem"},
            %{property: "Option font", value: "0.875rem"},
            %{property: "Border", value: "1px var(--border-color)"}
          ],
          tokens: [
            "popover",
            "popover-foreground",
            "accent",
            "accent-foreground",
            "muted-foreground",
            "border-color",
            "ring"
          ]
        },
        accessibility: %{
          roles:
            "Trigger is a button with aria-haspopup=listbox / aria-expanded / aria-controls. The search field is role=combobox; the list is role=listbox with role=option children carrying aria-selected.",
          keyboard: [
            %{keys: "Arrow Down", action: "Move the active option down (wraps to the top)"},
            %{keys: "Arrow Up", action: "Move the active option up (wraps to the bottom)"},
            %{keys: "Enter", action: "Select the active option and close the listbox"},
            %{keys: "Esc", action: "Close the listbox and return focus to the trigger"},
            %{keys: "Type", action: "Filter the options by substring"}
          ],
          focus:
            "Opening the popover moves focus into the search input and sets the active option; selecting or Esc returns focus to the trigger.",
          screen_reader:
            "aria-activedescendant points at the highlighted option id so its label is announced without moving DOM focus; aria-selected marks the chosen value.",
          touch_target:
            "Trigger is a full-height field; option rows are tappable but slightly under 44pt - pad rows for touch-first use.",
          reduced_motion:
            "Popover toggles via a hidden class with no movement, so reduced-motion has nothing to suppress."
        },
        swiftui: %{
          code: ~S"""
          Picker("Framework", selection: $value) {
              ForEach(options, id: \.self) { Text($0).tag($0) }
          }
          .pickerStyle(.menu)   // searchable menu → wrap a List in .searchable for the type-to-filter behavior
          """,
          notes:
            "A plain Picker(.menu) covers selection; to match the type-to-filter combobox, present a searchable List in a popover/sheet instead."
        },
        ios_status: :partial
      },
      "command" => %{
        specs: %{
          anatomy: [
            %{
              part: "Search input",
              description:
                "role=combobox at the top of the modal; filters every command by text content."
            },
            %{
              part: "Groups",
              description:
                "Labelled sections (data-group) that hide themselves when none of their items match."
            },
            %{
              part: "Item",
              description:
                "role=option row (data-command-item) with optional icon and a trailing shortcut hint."
            },
            %{
              part: "Empty state",
              description: "Shown when the query matches no command."
            }
          ],
          measurements: [
            %{property: "Dialog radius", value: "var(--radius-lg)"},
            %{property: "Item radius", value: "var(--radius-sm)"},
            %{property: "Group label font", value: "0.75rem / weight 500"},
            %{property: "Surface", value: "var(--popover) over a modal backdrop"}
          ],
          tokens: [
            "popover",
            "popover-foreground",
            "accent",
            "accent-foreground",
            "muted-foreground",
            "border-color"
          ]
        },
        accessibility: %{
          roles:
            "A native <dialog> modal. The search is role=combobox over a role=listbox; each command is role=option with aria-selected tracking the active row.",
          keyboard: [
            %{keys: "Cmd/Ctrl + K", action: "Open the command palette from anywhere"},
            %{keys: "Arrow Down", action: "Move to the next visible command (wraps)"},
            %{keys: "Arrow Up", action: "Move to the previous visible command (wraps)"},
            %{keys: "Enter", action: "Run the active command and close the palette"},
            %{keys: "Esc", action: "Close the dialog (native <dialog> behavior)"},
            %{keys: "Type", action: "Filter commands; empty groups collapse"}
          ],
          focus:
            "Opening focuses the search field (a MutationObserver resets the query on open); the native <dialog> traps focus and restores it to the opener on close.",
          screen_reader:
            "aria-activedescendant names the highlighted command; the modal dialog role scopes the listbox to the palette.",
          touch_target:
            "Command rows are comfortable to tap; the palette is keyboard-first but works as a tap list on touch.",
          reduced_motion:
            "The dialog open/close is excluded from the instant-theme transition reset, but it only fades/scales briefly and respects prefers-reduced-motion."
        },
        swiftui: %{
          code: ~S"""
          List(filtered) { cmd in
              Button { run(cmd) } label: { Label(cmd.title, systemImage: cmd.icon) }
          }
          .searchable(text: $query, placement: .toolbar)
          """,
          notes:
            "No system command palette exists; the closest match is a searchable List presented in a sheet. Bind Cmd-K with a .keyboardShortcut on macOS / Catalyst."
        },
        ios_status: :partial
      },
      "context-menu" => %{
        specs: %{
          anatomy: [
            %{
              part: "Trigger area",
              description:
                "The element that opens the menu on right-click / long-press (data-context-menu-trigger)."
            },
            %{
              part: "Menu",
              description: "A fixed-positioned role=menu panel clamped inside the viewport."
            },
            %{
              part: "Menu items",
              description: "role=menuitem buttons; the first item is focused on open."
            }
          ],
          measurements: [
            %{property: "Menu radius", value: "var(--radius-md)"},
            %{property: "Item radius", value: "var(--radius-sm)"},
            %{property: "Min width", value: "12rem"},
            %{property: "Padding", value: "0.25rem (menu), 0.375rem 0.5rem (item)"}
          ],
          tokens: ["popover", "popover-foreground", "accent", "accent-foreground", "border-color"]
        },
        accessibility: %{
          roles:
            "The panel is role=menu and its buttons are role=menuitem; it is positioned at the pointer and kept inside the viewport edges.",
          keyboard: [
            %{keys: "Arrow Down", action: "Focus the next item (wraps to the first)"},
            %{keys: "Arrow Up", action: "Focus the previous item (wraps to the last)"},
            %{keys: "Esc", action: "Close the menu and return focus to the trigger"},
            %{keys: "Enter / Space", action: "Activate the focused item (native button)"}
          ],
          focus:
            "Opening focuses the first menuitem; Esc, an outside click, scroll, or window blur closes the menu and focus returns to the trigger.",
          screen_reader:
            "Announced as a menu with menuitem children; activation runs the item's native button handler.",
          touch_target:
            "Opened by long-press on touch; menu items are full-width rows that meet tap-size when padded for touch.",
          reduced_motion:
            "The menu toggles via a hidden class with no transition, so reduced-motion is unaffected."
        },
        swiftui: %{
          code: ~S"""
          rowView
              .contextMenu {
                  Button("Edit") { edit() }
                  Button("Duplicate") { duplicate() }
                  Divider()
                  Button("Delete", role: .destructive) { delete() }
              }
          """,
          notes:
            ".contextMenu is the exact native analog - long-press on touch, right-click on macOS - so behavior maps one-to-one."
        },
        ios_status: :parity
      },
      "data-table" => %{
        specs: %{
          anatomy: [
            %{
              part: "Toolbar",
              description: "Text filter, faceted status filter, and a reset button."
            },
            %{
              part: "Header row",
              description:
                "Sortable th cells (data-dt-sort) exposing aria-sort and a direction caret."
            },
            %{
              part: "Body",
              description: "Rows rendered from the demo dataset, paged client-side."
            },
            %{
              part: "Pagination",
              description: "Prev / Next buttons with a row + page count readout."
            }
          ],
          measurements: [
            %{property: "Page size", value: "5 rows"},
            %{property: "Sort caret", value: "size-3.5 hero icon"},
            %{property: "Cell font", value: "0.875rem (table default)"},
            %{property: "Surface", value: "var(--card) inside a rounded card"}
          ],
          tokens: [
            "card",
            "card-foreground",
            "muted-foreground",
            "accent",
            "secondary",
            "border-color"
          ]
        },
        accessibility: %{
          roles:
            "A semantic <table>. Sortable headers are tabbable (tabindex=0) and carry aria-sort=none|ascending|descending; the sort-direction icon is aria-hidden.",
          keyboard: [
            %{
              keys: "Tab",
              action: "Move between the filter, sortable headers, and pagination controls"
            },
            %{keys: "Enter / Space", action: "Toggle sort on the focused header (asc → desc)"},
            %{keys: "Type", action: "Filter rows by email in the toolbar input"}
          ],
          focus:
            "Headers receive a visible focus style; the filter and pagination buttons are native focusable controls.",
          screen_reader:
            "aria-sort announces the current sort column and direction; the row/page count text reports result size.",
          touch_target:
            "Header hit areas and pagination buttons are tappable; this is a desktop-oriented showcase, so size up controls for touch.",
          reduced_motion: "Sorting and paging re-render rows instantly with no animation."
        },
        swiftui: %{
          code: ~S"""
          Table(rows, sortOrder: $sortOrder) {
              TableColumn("Status", value: \.status) { Text($0.status) }
              TableColumn("Email", value: \.email)
              TableColumn("Amount") { Text($0.amount, format: .currency(code: "USD")) }
          }
          .searchable(text: $query)
          """,
          notes:
            "SwiftUI Table covers sorting and columns on macOS/iPadOS; on compact iPhone fall back to a List of rows, since Table degrades to single-column."
        },
        ios_status: :partial
      },
      "calendar" => %{
        specs: %{
          anatomy: [
            %{part: "Caption", description: "Centered month + year heading."},
            %{
              part: "Month nav",
              description: "Ghost prev/next buttons that step the visible month."
            },
            %{
              part: "Weekday header",
              description: "role=columnheader cells (Su-Sa) with full-day aria-labels."
            },
            %{
              part: "Day grid",
              description:
                "role=grid of role=gridcell day buttons; today is outlined, the selection filled with primary."
            }
          ],
          measurements: [
            %{property: "Day cell", value: "2rem x 2rem"},
            %{property: "Day radius", value: "var(--radius-md)"},
            %{property: "Grid", value: "7 columns, 0.25rem row gap"},
            %{property: "Caption font", value: "0.875rem / weight 500"}
          ],
          tokens: [
            "primary",
            "primary-foreground",
            "accent",
            "accent-foreground",
            "muted-foreground",
            "border-color"
          ]
        },
        accessibility: %{
          roles:
            "The month is role=grid with role=columnheader weekdays and role=gridcell day buttons; each day has a full localized aria-label and aria-selected reflects the selection.",
          keyboard: [
            %{keys: "Tab", action: "Move between the nav buttons and day cells"},
            %{
              keys: "Enter / Space",
              action: "Activate the focused nav button or pick the focused day (native button)"
            }
          ],
          focus:
            "Day cells and the prev/next buttons are native buttons; the nav stops click propagation so a wrapping popover stays open across a re-render.",
          screen_reader:
            "Each day reads its weekday, month, day, and year; aria-selected announces the chosen date and the grid label names the month.",
          touch_target:
            "32px day cells are below the 44pt touch minimum - size the calendar up or add padding for touch-first use.",
          reduced_motion: "Month changes re-render the grid in place with no transition."
        },
        swiftui: %{
          code: ~S"""
          DatePicker("Date", selection: $date, displayedComponents: .date)
              .datePickerStyle(.graphical)
          """,
          notes:
            "The .graphical DatePicker is the native month-grid calendar. Use a range selection / two-month layout via custom views if range mode is required."
        },
        ios_status: :parity
      },
      "date-picker" => %{
        specs: %{
          anatomy: [
            %{
              part: "Trigger",
              description:
                "An outline button (aria-haspopup=dialog) showing the formatted date or placeholder."
            },
            %{part: "Popover", description: "Panel containing the calendar grid."},
            %{
              part: "Calendar",
              description:
                "The same role=grid day picker; choosing a day fills the label and closes the popover."
            }
          ],
          measurements: [
            %{property: "Popover radius", value: "var(--radius-md)"},
            %{property: "Day cell", value: "2rem x 2rem"},
            %{property: "Trigger", value: "field height, var(--radius-md)"},
            %{property: "Border", value: "1px var(--border-color)"}
          ],
          tokens: [
            "popover",
            "popover-foreground",
            "primary",
            "primary-foreground",
            "accent",
            "muted-foreground",
            "border-color"
          ]
        },
        accessibility: %{
          roles:
            "Trigger is a button with aria-haspopup=dialog and aria-expanded; the popover holds the calendar role=grid described under Calendar.",
          keyboard: [
            %{keys: "Tab", action: "Move into the popover and across the calendar controls"},
            %{
              keys: "Enter / Space",
              action:
                "Pick the focused day (closes the popover) or step months via the nav buttons"
            },
            %{keys: "Esc", action: "Dismiss via outside-click; clicking away closes the popover"}
          ],
          focus:
            "Opening reveals the calendar; selecting a day or an outside click closes the popover. aria-expanded on the trigger stays in sync.",
          screen_reader:
            "Trigger announces the current date; inside, day cells read their full localized date label.",
          touch_target:
            "The trigger is a full field; the 32px day cells need extra padding to meet the touch minimum.",
          reduced_motion: "The popover toggles a hidden class with no movement."
        },
        swiftui: %{
          code: ~S"""
          DatePicker("Pick a date", selection: $date, displayedComponents: .date)
              .datePickerStyle(.compact)   // .graphical for an inline calendar
          """,
          notes:
            "A compact DatePicker is the native trigger-plus-popover equivalent; switch to .graphical when you want the calendar always visible."
        },
        ios_status: :parity
      },
      "carousel" => %{
        specs: %{
          anatomy: [
            %{
              part: "Viewport",
              description:
                "A horizontally scroll-snapping track (role=group, aria-roledescription=carousel)."
            },
            %{part: "Slides", description: "Each child snaps to the viewport width."},
            %{
              part: "Prev / Next",
              description:
                "Buttons that scroll one viewport-width left/right with smooth behavior."
            }
          ],
          measurements: [
            %{property: "Slide step", value: "carousel.clientWidth per click"},
            %{property: "Scroll", value: "smooth behavior, CSS scroll-snap"},
            %{property: "Controls", value: "btn-circle ghost arrows"}
          ],
          tokens: ["background", "foreground", "border-color", "muted", "accent"]
        },
        accessibility: %{
          roles:
            "The track is role=group with aria-roledescription=carousel and an aria-label; the arrow buttons get aria-label Next/Previous slide if unset.",
          keyboard: [
            %{keys: "Tab", action: "Reach the Prev and Next buttons"},
            %{
              keys: "Enter / Space",
              action: "Activate Prev/Next to scroll one slide (native buttons)"
            },
            %{
              keys: "Arrow / Page keys",
              action:
                "Scroll the focused viewport horizontally (native scroll-container behavior)"
            }
          ],
          focus:
            "Prev/Next are native buttons; the scroll viewport itself is keyboard-scrollable when focused.",
          screen_reader:
            "Announced as a carousel group; arrows are labelled Next slide / Previous slide.",
          touch_target:
            "Swipe to advance on touch; the circular arrow buttons are comfortably tappable.",
          reduced_motion:
            "Scrolls use behavior:smooth - honor prefers-reduced-motion by treating the jump as instant for sensitive users."
        },
        swiftui: %{
          code: ~S"""
          TabView {
              ForEach(slides) { slide in SlideView(slide) }
          }
          .tabViewStyle(.page(indexDisplayMode: .automatic))
          """,
          notes:
            "A paged TabView gives native swipe + page dots; explicit prev/next arrows are not idiomatic on iOS, so they are usually dropped on touch."
        },
        ios_status: :partial
      },
      "drawer" => %{
        specs: %{
          anatomy: [
            %{part: "Trigger", description: "A button that opens the drawer via showModal()."},
            %{
              part: "Panel",
              description:
                "A native <dialog> sliding up from the bottom (.drawer-bottom) with a grab handle."
            },
            %{
              part: "Content",
              description: "Centered, max-w-md body with a full-width primary action."
            }
          ],
          measurements: [
            %{property: "Grab handle", value: "1.5px tall x 12 wide, rounded-full bg-base-300"},
            %{property: "Content width", value: "max-w-md, centered"},
            %{property: "Surface", value: "var(--popover) over the modal backdrop"}
          ],
          tokens: [
            "popover",
            "popover-foreground",
            "color-base-300",
            "muted-foreground",
            "primary",
            "primary-foreground"
          ]
        },
        accessibility: %{
          roles:
            "A native <dialog> opened with showModal(), so it is a modal dialog with built-in focus trapping and backdrop.",
          keyboard: [
            %{keys: "Esc", action: "Close the drawer (native <dialog> dismiss)"},
            %{keys: "Tab / Shift+Tab", action: "Cycle focus within the trapped dialog"},
            %{
              keys: "Enter / Space",
              action: "Activate the focused control (e.g. the primary action)"
            }
          ],
          focus:
            "showModal traps focus inside the panel and restores it to the trigger on close; an outside click on the backdrop dismisses it.",
          screen_reader:
            "Announced as a modal dialog; give the panel a heading and aria-label/labelledby so its purpose is read on open.",
          touch_target:
            "Touch-first surface: the primary action is a full-width btn meeting the 44pt minimum; the grab handle hints at swipe-to-dismiss.",
          reduced_motion:
            "The drawer slide is excluded from the instant-theme transition reset so it animates; gate the slide on prefers-reduced-motion for sensitive users."
        },
        swiftui: %{
          code: ~S"""
          .sheet(isPresented: $showing) {
              DrawerContent()
                  .presentationDetents([.medium, .large])
                  .presentationDragIndicator(.visible)
          }
          """,
          notes:
            "This IS the native iOS sheet with detents and a drag indicator - use the system presentation rather than a custom bottom panel."
        },
        ios_status: :partial
      },
      "input-otp" => %{
        specs: %{
          anatomy: [
            %{
              part: "Group",
              description:
                "A role=group wrapper (aria-label One-time code) holding the digit slots."
            },
            %{
              part: "Slots",
              description:
                "Single-character inputs (.otp-slot) each labelled Digit N of M; non-digits are stripped."
            },
            %{part: "Separator (optional)", description: "A visual divider between slot groups."}
          ],
          measurements: [
            %{property: "Slot radius", value: "var(--radius-md)"},
            %{property: "Slot focus", value: "var(--ring) focus ring"},
            %{property: "Input filter", value: "one digit per slot, auto-advance"}
          ],
          tokens: [
            "background",
            "foreground",
            "input",
            "border-color",
            "ring",
            "muted-foreground"
          ]
        },
        accessibility: %{
          roles:
            "The wrapper is role=group with aria-label One-time code; each slot is a text input labelled with its position (Digit N of M).",
          keyboard: [
            %{keys: "Type a digit", action: "Fills the slot and auto-advances focus to the next"},
            %{
              keys: "Backspace",
              action: "On an empty slot, moves focus back to the previous slot"
            },
            %{
              keys: "Paste",
              action:
                "Distributes the pasted digits across all slots and focuses the first empty one"
            },
            %{keys: "Tab", action: "Move between slots manually"}
          ],
          focus:
            "Focus auto-advances on entry and steps back on backspace; pasting jumps focus to the first unfilled slot.",
          screen_reader:
            "Each slot announces its index out of the total, so the user knows which digit they are entering.",
          touch_target:
            "Slots are sized boxes; ensure each is at least 44pt on touch and that the numeric keyboard appears (inputmode=numeric).",
          reduced_motion: "Focus moves between slots without any animation."
        },
        swiftui: %{
          code: ~S"""
          HStack(spacing: 8) {
              ForEach(0..<6, id: \.self) { i in
                  TextField("", text: $digits[i])
                      .keyboardType(.numberPad)
                      .textContentType(.oneTimeCode)
                      .frame(width: 44, height: 44)
                      .multilineTextAlignment(.center)
              }
          }
          """,
          notes:
            "No native OTP control exists; build it from per-digit TextFields. .textContentType(.oneTimeCode) enables system autofill from SMS."
        },
        ios_status: :guidance_only
      },
      "resizable" => %{
        specs: %{
          anatomy: [
            %{
              part: "Panels",
              description: "Two or more .resizable-panel regions; the first stores its width."
            },
            %{
              part: "Handle",
              description:
                "A draggable divider (role=separator, aria-orientation=vertical, tabindex=0) with a grip."
            }
          ],
          measurements: [
            %{
              property: "Handle width",
              value: "thin visible line with a wider invisible hit area (::after)"
            },
            %{property: "Handle focus", value: "var(--ring) focus ring"},
            %{property: "Container radius", value: "var(--radius-lg)"},
            %{property: "Border", value: "1px var(--border-color)"}
          ],
          tokens: ["background", "foreground", "border-color", "muted", "ring"]
        },
        accessibility: %{
          roles:
            "The handle is role=separator with aria-orientation=vertical and tabindex=0 so it is focusable as a resize control.",
          keyboard: [
            %{keys: "Tab", action: "Focus the resize handle (shows a focus ring)"}
          ],
          focus:
            "The handle is focusable and shows a ring on :focus-visible; dragging uses pointer capture and disables text selection during the drag.",
          screen_reader:
            "Announced as a separator; add an aria-label and aria-valuenow if you wire up keyboard resizing for full WAI-ARIA window-splitter support.",
          touch_target:
            "The visible handle is thin but a wider invisible ::after hit area makes it draggable by pointer and touch.",
          reduced_motion: "Resizing tracks the pointer directly with no animation."
        },
        swiftui: %{
          code: ~S"""
          NavigationSplitView {
              SidebarView()
          } detail: {
              DetailView()
          }
          // macOS: HSplitView { PaneA(); PaneB() } gives a user-draggable divider
          """,
          notes:
            "NavigationSplitView manages the split on iPadOS but the divider is not freely user-draggable; macOS HSplitView is the closer match for a drag-to-resize handle."
        },
        ios_status: :partial
      },
      "menubar" => %{
        specs: %{
          anatomy: [
            %{
              part: "Bar",
              description: "A horizontal row of ghost menu triggers in a bordered container."
            },
            %{
              part: "Menu trigger",
              description: "A role=button label (File / Edit / View) that opens its dropdown."
            },
            %{
              part: "Dropdown",
              description:
                "A .menu list of items, each optionally showing a keyboard shortcut hint."
            }
          ],
          measurements: [
            %{property: "Bar radius", value: "var(--radius-md)"},
            %{property: "Menu item radius", value: "var(--radius-sm)"},
            %{property: "Trigger", value: "btn-ghost btn-sm"},
            %{property: "Surface", value: "var(--popover) dropdown over var(--background) bar"}
          ],
          tokens: [
            "background",
            "foreground",
            "popover",
            "popover-foreground",
            "accent",
            "muted-foreground",
            "border-color"
          ]
        },
        accessibility: %{
          roles:
            "Built on daisyUI dropdowns: each trigger is role=button with a tabindex=0 menu (.menu) of links. For full menubar semantics add role=menubar / menuitem and roving focus.",
          keyboard: [
            %{keys: "Tab", action: "Move focus across the menu triggers"},
            %{
              keys: "Enter / Space",
              action: "Open the focused trigger's menu (tabindex=0 dropdown)"
            },
            %{keys: "Esc", action: "Close the open menu (blur the focused dropdown)"}
          ],
          focus:
            "daisyUI dropdowns open on focus/click of the tabindex=0 trigger and close on blur; there is no built-in roving arrow-key traversal across the bar.",
          screen_reader:
            "Each trigger reads as a button and its items as links; promote to role=menubar/menuitem if you need true menu semantics announced.",
          touch_target:
            "btn-sm triggers and menu rows are tappable; size up the bar for touch since this pattern is desktop-oriented.",
          reduced_motion:
            "Menus appear without movement, so reduced-motion has nothing to suppress."
        },
        swiftui: %{
          code: ~S"""
          .toolbar {
              ToolbarItem(placement: .navigation) {
                  Menu("File") {
                      Button("New Tab") { newTab() }
                      Button("New Window") { newWindow() }
                  }
              }
          }
          // macOS: declare top-level menus with the CommandMenu / .commands modifier
          """,
          notes:
            "On macOS use the .commands / CommandMenu API for a real menu bar; on iOS/iPadOS this becomes toolbar Menus, since there is no global menubar."
        },
        ios_status: :partial
      },
      "chart" => %{
        specs: %{
          anatomy: [
            %{
              part: "Container",
              description: "A card framing the chart with a title and caption."
            },
            %{
              part: "Bars",
              description: "Themed .chart-bar columns whose height encodes the value."
            },
            %{part: "Line / area", description: "An SVG polyline with a translucent area fill."},
            %{part: "Axis labels", description: "Muted text labels along the category axis."}
          ],
          measurements: [
            %{property: "Bar radius", value: "var(--radius-sm) on the top corners"},
            %{property: "Plot height", value: "h-40 (10rem)"},
            %{property: "Bar hover", value: "opacity 0.8, 0.15s transition"},
            %{property: "Label font", value: "0.75rem muted"}
          ],
          tokens: ["chart-1", "chart-2", "chart-3", "chart-4", "chart-5", "muted-foreground"]
        },
        accessibility: %{
          roles:
            "A presentational drawing (bars / SVG). Give the chart container role=img with an aria-label summarizing the data, or pair it with an accessible data table.",
          keyboard: [
            %{
              keys: "Tab",
              action:
                "No interactive targets by default; add focusable points only if the chart is interactive"
            }
          ],
          focus:
            "Static charts take no focus; if you add tooltips or selectable points, make those controls keyboard-focusable.",
          screen_reader:
            "Provide a text alternative (aria-label or an adjacent table) - the bars and SVG convey no values to assistive tech on their own.",
          touch_target:
            "Static by default; any interactive points or legend toggles must meet the 44pt touch minimum.",
          reduced_motion:
            "Only a 0.15s hover opacity transition on bars; nothing moves, so reduced-motion is effectively unaffected."
        },
        swiftui: %{
          code: ~S"""
          Chart(data) { point in
              BarMark(x: .value("Month", point.month), y: .value("Revenue", point.revenue))
                  .foregroundStyle(by: .value("Series", point.series))
          }
          .chartForegroundStyleScale(range: [.chart1, .chart2, .chart3, .chart4, .chart5])
          """,
          notes:
            "Swift Charts is the native equivalent (BarMark / LineMark / AreaMark) and gets VoiceOver audio-graph support for free via .accessibilityChartDescriptor."
        },
        ios_status: :parity
      }
    }
  end
end

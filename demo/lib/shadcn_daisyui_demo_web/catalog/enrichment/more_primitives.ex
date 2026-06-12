defmodule ShadcnDaisyuiDemoWeb.Catalog.Enrichment.MorePrimitives do
  @moduledoc "Specs / Accessibility / Native enrichment for the More primitives component group."

  @doc "Map of slug => enrichment fields."
  def specs do
    %{
      "button-group" => %{
        specs: %{
          anatomy: [
            %{
              part: "Group",
              description: "A `.join` container that fuses children into one segmented control."
            },
            %{
              part: "Item",
              description: "Each `.join-item .btn` button; only the outer corners round."
            }
          ],
          measurements: [
            %{
              property: "Group corners",
              value: "var(--radius-md) on the first/last item only (join-ss/se/es/ee vars)"
            },
            %{
              property: "Item height",
              value: "2.25rem (btn default), btn-sm/btn-lg scale together"
            },
            %{
              property: "Internal seams",
              value:
                "border-inline-start-width: 0 on every item after the first (shared 1px border)"
            },
            %{
              property: "Item shadow",
              value: "none (`.join .btn` clears box-shadow so seams stay flat)"
            }
          ],
          tokens: ["background", "foreground", "border-color", "accent", "accent-foreground"]
        },
        accessibility: %{
          roles:
            "A row of native buttons; add role=group with an aria-label when the buttons form one logical control.",
          keyboard: [
            %{keys: "Tab", action: "Move focus to and between the buttons"},
            %{keys: "Enter / Space", action: "Activate the focused button"}
          ],
          focus:
            "Each button shows the standard ring-shadow focus outline; seams do not clip the ring.",
          screen_reader:
            "Buttons are announced individually by their label; a group label gives shared context.",
          touch_target:
            "Default 2.25rem buttons read as desktop-sized; use btn-lg for primary actions on touch.",
          reduced_motion: "No motion; hover/press are instant color changes only."
        },
        swiftui: %{
          code: ~S"""
          Picker("View", selection: $range) {
            Text("Years").tag(Range.years)
            Text("Months").tag(Range.months)
            Text("Days").tag(Range.days)
          }
          .pickerStyle(.segmented)
          """,
          notes:
            "A non-exclusive button group maps to an HStack of bordered Buttons; an exclusive one maps to a segmented Picker."
        },
        ios_status: :partial
      },
      "toggle" => %{
        specs: %{
          anatomy: [
            %{
              part: "Control",
              description:
                "A bordered `.btn` (often `.btn-square`) wrapping a hidden checkbox input."
            },
            %{
              part: "Label",
              description: "Icon and/or text inside the button that conveys the toggled state."
            }
          ],
          measurements: [
            %{property: "Height", value: "2.25rem (btn default)"},
            %{property: "Corner radius", value: "var(--radius-md)"},
            %{property: "Border", value: "1px var(--border-color) (btn-outline)"},
            %{
              property: "Pressed fill",
              value: "var(--accent) background with var(--accent-foreground) text when checked"
            }
          ],
          tokens: ["background", "foreground", "border-color", "accent", "accent-foreground"]
        },
        accessibility: %{
          roles:
            "A two-state button; the hidden checkbox carries the on/off state and aria-label.",
          keyboard: [
            %{keys: "Tab", action: "Move focus to the toggle"},
            %{keys: "Space / Enter", action: "Flip the on/off state"}
          ],
          focus: "Focus shows the ring-shadow outline on the button.",
          screen_reader: "Announced via the input's aria-label plus its checked/unchecked state.",
          touch_target: "2.25rem square; pad to 2.75rem effective area on touch surfaces.",
          reduced_motion: "State change is an instant color swap; no transition to suppress."
        },
        swiftui: %{
          code: ~S"""
          Toggle(isOn: $isBold) {
            Image(systemName: "bold")
          }
          .toggleStyle(.button)
          """,
          notes:
            "A single pressed-state button maps to a .button-style Toggle; a daisyUI switch maps to the default Toggle."
        },
        ios_status: :parity
      },
      "toggle-group" => %{
        specs: %{
          anatomy: [
            %{
              part: "Group",
              description: "A `.join` container holding the toggle buttons as one control."
            },
            %{
              part: "Item",
              description:
                "Each `.join-item .btn` label wrapping a hidden checkbox with `has-[:checked]` styling."
            }
          ],
          measurements: [
            %{property: "Group corners", value: "var(--radius-md) on the outer corners only"},
            %{property: "Item height", value: "2.25rem (btn default)"},
            %{
              property: "Internal seams",
              value: "shared 1px border (border-inline-start-width: 0 after the first item)"
            },
            %{
              property: "Pressed fill",
              value: "var(--accent) / var(--accent-foreground) on checked items"
            }
          ],
          tokens: ["background", "foreground", "border-color", "accent", "accent-foreground"]
        },
        accessibility: %{
          roles:
            "A grouped set of two-state buttons; for single-select use radio inputs, for multi-select use checkboxes.",
          keyboard: [
            %{keys: "Tab", action: "Move focus into and across the items"},
            %{keys: "Space / Enter", action: "Toggle the focused item"}
          ],
          focus: "Each item shows the ring-shadow outline when focused.",
          screen_reader: "Each item is announced by its aria-label and pressed/checked state.",
          touch_target: "2.25rem items; size up to 2.75rem effective area on touch.",
          reduced_motion: "Pressed state is an instant color change; no animation."
        },
        swiftui: %{
          code: ~S"""
          Picker("Format", selection: $alignment) {
            Image(systemName: "bold").tag(Format.bold)
            Image(systemName: "italic").tag(Format.italic)
            Image(systemName: "underline").tag(Format.underline)
          }
          .pickerStyle(.segmented)
          """,
          notes:
            "Single-select toggle groups map to a segmented Picker; multi-select needs an HStack of .button-style Toggles."
        },
        ios_status: :partial
      },
      "input-group" => %{
        specs: %{
          anatomy: [
            %{
              part: "Group",
              description: "A `.join` container fusing addons and the input into one field."
            },
            %{
              part: "Addon",
              description:
                "A leading/trailing `.join-item .btn` used as a prefix label or action."
            },
            %{
              part: "Input",
              description: "The `.join-item .input` field, shadow cleared so it sits flush."
            }
          ],
          measurements: [
            %{property: "Height", value: "2.25rem across addons and input"},
            %{property: "Corner radius", value: "var(--radius-md) on the outer corners only"},
            %{property: "Input padding", value: "padding-inline 0.75rem"},
            %{
              property: "Border",
              value: "shared 1px var(--input); seams collapse to a single line"
            }
          ],
          tokens: [
            "background",
            "foreground",
            "input",
            "border-color",
            "primary",
            "primary-foreground"
          ]
        },
        accessibility: %{
          roles:
            "A text input with attached addons; the input keeps its own label or aria-label.",
          keyboard: [
            %{keys: "Tab", action: "Move between the input and any interactive addons"},
            %{keys: "Enter", action: "Submit or trigger a trailing action button"}
          ],
          focus: "Focusing the input swaps its border to var(--ring) and shows the ring-shadow.",
          screen_reader:
            "Static prefixes are read as text; the input is labeled independently of the addons.",
          touch_target:
            "2.25rem field height; action buttons should reach 2.75rem effective area on touch.",
          reduced_motion: "Focus styling is an instant color change with no transition."
        },
        swiftui: %{
          code: ~S"""
          HStack(spacing: 0) {
            Text("https://").foregroundStyle(.secondary).padding(.horizontal, 8)
            TextField("example.com", text: $url)
            Button("Copy") { copy() }
          }
          .overlay(RoundedRectangle(cornerRadius: 8).stroke(.separator))
          """,
          notes:
            "No direct primitive; compose an HStack with a shared rounded border, or use a TextField with a trailing label/button."
        },
        ios_status: :partial
      },
      "navigation-menu" => %{
        specs: %{
          anatomy: [
            %{
              part: "Bar",
              description: "A horizontal `<nav>` of trigger buttons and direct links."
            },
            %{
              part: "Trigger",
              description:
                "A `.btn-ghost` button (`dropdown-hover`) with a chevron that opens a panel."
            },
            %{
              part: "Panel",
              description: "A `.dropdown-content` popover surface of grouped link rows."
            }
          ],
          measurements: [
            %{property: "Trigger height", value: "2rem (btn-sm)"},
            %{
              property: "Panel surface",
              value: "var(--popover) on var(--border-color), var(--radius-md), shadow-sm"
            },
            %{property: "Panel offset", value: "mt-1.5 below the trigger"},
            %{
              property: "Row hover",
              value: "var(--accent) background, var(--radius-md) on each link row"
            }
          ],
          tokens: [
            "background",
            "foreground",
            "popover",
            "popover-foreground",
            "accent",
            "accent-foreground",
            "muted-foreground"
          ]
        },
        accessibility: %{
          roles:
            "A navigation landmark (<nav>); triggers are buttons and the panel items are links.",
          keyboard: [
            %{keys: "Tab", action: "Move across triggers, links, then into an open panel"},
            %{keys: "Enter / Space", action: "Activate a focused link or focusable trigger"},
            %{keys: "Esc", action: "Move focus out, closing a hover/focus-opened panel"}
          ],
          focus: "Triggers and links take the standard ring-shadow focus outline.",
          screen_reader:
            "The nav landmark and link text are announced; this hover-driven menu does not expose full menu semantics.",
          touch_target:
            "btn-sm triggers are compact; ensure 2.75rem effective area where the bar is used on touch.",
          reduced_motion:
            "Panels appear without animated transitions under the instant-theme rule."
        },
        swiftui: %{
          code: ~S"""
          NavigationStack {
            List {
              NavigationLink("Getting started") { GettingStartedView() }
              NavigationLink("Components") { ComponentsView() }
            }
          }
          """,
          notes:
            "Hover-driven mega menus are pointer-only; on iOS use a NavigationStack/List or a Menu for the grouped destinations."
        },
        ios_status: :partial
      },
      "hover-card" => %{
        specs: %{
          anatomy: [
            %{
              part: "Trigger",
              description: "An inline link/element that reveals the card on hover or focus."
            },
            %{
              part: "Card",
              description: "A `.dropdown-content` popover surface holding preview content."
            }
          ],
          measurements: [
            %{
              property: "Surface",
              value: "var(--popover) on var(--border-color), var(--radius-md), shadow-sm"
            },
            %{property: "Padding", value: "p-4 inside the card"},
            %{property: "Width", value: "w-72 (preview content width)"},
            %{property: "Offset", value: "mt-2 below the trigger"}
          ],
          tokens: [
            "popover",
            "popover-foreground",
            "border-color",
            "foreground",
            "muted-foreground"
          ]
        },
        accessibility: %{
          roles:
            "A trigger that reveals supplementary preview content; purely informational, not a menu.",
          keyboard: [
            %{keys: "Tab", action: "Focus the trigger, which also reveals the card"},
            %{keys: "Esc", action: "Move focus away to dismiss the card"}
          ],
          focus:
            "The trigger shows the ring-shadow outline and the card opens on focus as well as hover.",
          screen_reader:
            "Preview content is read when focus enters it; treat it as non-essential supplementary detail.",
          touch_target:
            "Hover has no touch equivalent; provide a tap path to the same information on touch surfaces.",
          reduced_motion: "The card appears without animated transitions."
        },
        swiftui: %{
          code: ~S"""
          Text("@shadcn")
            .popover(isPresented: $showCard) {
              ProfilePreview().padding()
            }
          """,
          notes:
            "There is no hover on touch; bind a .popover to a tap or long-press instead of pointer hover."
        },
        ios_status: :guidance_only
      },
      "sheet" => %{
        specs: %{
          anatomy: [
            %{part: "Trigger", description: "An element that calls showModal() on the dialog."},
            %{
              part: "Panel",
              description: "A native `<dialog class=\"sheet\">` pinned to the inline-end edge."
            },
            %{
              part: "Header",
              description:
                "Title (text-lg semibold), description (muted), and a top-right close button."
            }
          ],
          measurements: [
            %{property: "Width", value: "20rem, capped at max-width 90vw"},
            %{property: "Height", value: "100dvh, anchored to the inline-end edge"},
            %{
              property: "Padding",
              value: "1.5rem; leading border-inline-start 1px var(--border-color)"
            },
            %{
              property: "Surface",
              value: "var(--popover) on var(--popover-foreground), shadow-sm"
            },
            %{
              property: "Enter/exit",
              value: "translate 0.3s ease slide-in plus a 50% black backdrop"
            }
          ],
          tokens: [
            "popover",
            "popover-foreground",
            "border-color",
            "foreground",
            "muted-foreground"
          ]
        },
        accessibility: %{
          roles:
            "A native modal <dialog>; the browser provides the dialog role, focus trap, and inert background.",
          keyboard: [
            %{keys: "Esc", action: "Close the sheet (native dialog behavior)"},
            %{keys: "Tab / Shift+Tab", action: "Cycle focus within the trapped dialog"},
            %{keys: "Enter / Space", action: "Activate the focused control"}
          ],
          focus:
            "Opening moves focus into the dialog and traps it; closing returns focus to the trigger.",
          screen_reader:
            "Announced as a dialog; give it an accessible name via the title for context.",
          touch_target:
            "The close button is btn-sm square; pad to 2.75rem effective area on touch.",
          reduced_motion:
            "The 0.3s slide is exempt from the instant-theme rule; honor prefers-reduced-motion to drop it."
        },
        swiftui: %{
          code: ~S"""
          .sheet(isPresented: $isEditing) {
            EditProfileView()
              .presentationDetents([.medium, .large])
          }
          """,
          notes:
            "An edge sheet maps to a .sheet with detents; iOS sheets rise from the bottom rather than the side, and swipe-down dismisses."
        },
        ios_status: :partial
      },
      "sidebar" => %{
        specs: %{
          anatomy: [
            %{
              part: "Layout",
              description:
                "A flex container with an `<aside>` rail and a `<main>` content region."
            },
            %{
              part: "Group",
              description: "A titled `.menu` list (`.menu-title` heading) of navigation rows."
            },
            %{
              part: "Item",
              description: "A link row; the active row gets `.menu-active` (subtle accent fill)."
            }
          ],
          measurements: [
            %{property: "Rail width", value: "~15rem (240px) in app usage"},
            %{property: "Rail border", value: "border-r 1px var(--border-color), bg-base-100"},
            %{property: "Item text", value: "0.875rem (text-sm), var(--radius-sm) rows"},
            %{property: "Active fill", value: "var(--accent) / var(--accent-foreground)"}
          ],
          tokens: [
            "background",
            "foreground",
            "border-color",
            "color-base-200",
            "accent",
            "accent-foreground",
            "muted-foreground"
          ]
        },
        accessibility: %{
          roles:
            "An <aside> complementary landmark wrapping a nav menu; <main> is the content landmark.",
          keyboard: [
            %{keys: "Tab", action: "Move focus through the navigation links"},
            %{keys: "Enter", action: "Follow the focused link"}
          ],
          focus:
            "Each link row shows the ring-shadow outline; the active row also carries the accent fill.",
          screen_reader:
            "The complementary landmark and menu-title group the destinations; the active link conveys current location.",
          touch_target:
            "Rows are text-sm; hidden below lg, so pair with a dock that meets 2.75rem touch targets on compact.",
          reduced_motion: "No motion; active/hover are instant color changes."
        },
        swiftui: %{
          code: ~S"""
          NavigationSplitView {
            List(selection: $selection) {
              Section("Platform") {
                NavigationLink("Dashboard", value: Route.dashboard)
                NavigationLink("Projects", value: Route.projects)
              }
            }
          } detail: {
            DetailView()
          }
          """,
          notes:
            "Maps cleanly to a NavigationSplitView sidebar that collapses to a stack on compact width."
        },
        ios_status: :parity
      },
      "field" => %{
        specs: %{
          anatomy: [
            %{part: "Label", description: "The control's label, wired to it via the form field."},
            %{part: "Control", description: "The wrapped input/select/checkbox group."},
            %{part: "Description", description: "Optional muted helper text under the control."},
            %{part: "Error", description: "Field errors rendered below, gated on used_input?."}
          ],
          measurements: [
            %{
              property: "Internal stacking",
              value: "label, control, description stack with ~6-8px (space-y-1.5) gaps"
            },
            %{property: "Field spacing", value: "field blocks 16px apart"},
            %{property: "Description text", value: "text-xs var(--muted-foreground)"},
            %{
              property: "Fieldset border",
              value: "1px var(--border-color), var(--radius-lg) when grouped as a fieldset"
            }
          ],
          tokens: ["foreground", "muted-foreground", "border-color", "input", "destructive"]
        },
        accessibility: %{
          roles:
            "A label/control/description grouping; a multi-control variant uses fieldset/legend.",
          keyboard: [
            %{keys: "Tab", action: "Move focus to the control(s)"},
            %{keys: "Space / Enter", action: "Operate the focused control"}
          ],
          focus:
            "The control shows its own ring-shadow focus styling; the label is click-associated.",
          screen_reader:
            "The label, description, and errors are associated with the control so they are read together.",
          touch_target:
            "Wrap checkbox/radio rows in a tappable label so the whole row reaches 2.75rem.",
          reduced_motion: "Static layout; no motion."
        },
        swiftui: %{
          code: ~S"""
          Section {
            TextField("Email", text: $email)
          } footer: {
            Text("We never share it.")
          }
          """,
          notes:
            "Maps to a Form Section with footer description text; validation errors render below the row in a destructive style."
        },
        ios_status: :parity
      },
      "aspect-ratio" => %{
        specs: %{
          anatomy: [
            %{
              part: "Container",
              description: "A box constrained to a fixed width/height ratio (e.g. aspect-video)."
            },
            %{
              part: "Content",
              description: "The media or placeholder filling the constrained box."
            }
          ],
          measurements: [
            %{property: "Ratio", value: "16/9 via aspect-video (any aspect-* utility works)"},
            %{property: "Corner radius", value: "var(--radius-lg) (rounded-lg) in the example"},
            %{property: "Placeholder fill", value: "var(--muted) / var(--muted-foreground)"},
            %{property: "Width", value: "fills its container (max-w-sm in the demo)"}
          ],
          tokens: ["muted", "muted-foreground", "border-color"]
        },
        accessibility: %{
          roles:
            "A purely structural layout wrapper with no role; semantics come from the content it holds.",
          focus: "Not focusable itself; any interactive child manages its own focus.",
          screen_reader:
            "Transparent to assistive tech; describe the contained media (alt text) instead.",
          touch_target:
            "No interaction; any actionable child is responsible for its own hit area.",
          reduced_motion: "No motion."
        },
        swiftui: %{
          code: ~S"""
          Image("cover")
            .resizable()
            .aspectRatio(16 / 9, contentMode: .fit)
          """,
          notes: "Maps directly to the .aspectRatio modifier on the contained view."
        },
        ios_status: :parity
      },
      "scroll-area" => %{
        specs: %{
          anatomy: [
            %{
              part: "Viewport",
              description:
                "A fixed-height box with overflow-y-auto that clips and scrolls its content."
            },
            %{part: "Content", description: "The scrolling rows/items inside the viewport."}
          ],
          measurements: [
            %{property: "Height", value: "fixed (h-32 in the demo) to force scrolling"},
            %{property: "Border", value: "1px var(--border-color), var(--radius-lg)"},
            %{property: "Padding", value: "p-4 inside the viewport"},
            %{property: "Row dividers", value: "border-b var(--color-base-200) between rows"}
          ],
          tokens: ["background", "foreground", "border-color", "color-base-200"]
        },
        accessibility: %{
          roles:
            "A structural scroll container; add role=region with an aria-label when the region needs a name.",
          keyboard: [
            %{keys: "Arrow / Page / Home / End", action: "Scroll when the region is focused"},
            %{keys: "Tab", action: "Reach focusable items inside the region"}
          ],
          focus:
            "Make the viewport focusable (tabindex) if keyboard scrolling without interactive children is needed.",
          screen_reader:
            "Content is read in order; a named region helps users understand the scrollable boundary.",
          touch_target:
            "Scrolls with native touch panning; any rows that are tappable need 2.75rem hit areas.",
          reduced_motion: "Native scrolling; honor reduced-motion for any smooth-scroll behavior."
        },
        swiftui: %{
          code: ~S"""
          ScrollView {
            LazyVStack(alignment: .leading) {
              ForEach(items) { item in
                Text(item.title)
              }
            }
          }
          .frame(height: 128)
          """,
          notes:
            "Maps to a height-constrained ScrollView; iOS provides native scroll indicators and rubber-banding."
        },
        ios_status: :parity
      },
      "empty" => %{
        specs: %{
          anatomy: [
            %{
              part: "Container",
              description: "A centered, dashed-border box for the empty state."
            },
            %{
              part: "Icon",
              description: "A muted hero icon signaling the empty/missing content."
            },
            %{
              part: "Copy",
              description:
                "A title plus muted description, optionally followed by an action button."
            }
          ],
          measurements: [
            %{property: "Border", value: "1px dashed var(--border-color), var(--radius-lg)"},
            %{property: "Padding", value: "p-8, centered, gap-2 between elements"},
            %{property: "Icon size", value: "size-7 in var(--muted-foreground)"},
            %{property: "Text", value: "text-sm title, text-sm muted description"}
          ],
          tokens: ["foreground", "muted-foreground", "border-color", "background"]
        },
        accessibility: %{
          roles:
            "A structural placeholder block; the icon is aria-hidden and the text carries the meaning.",
          focus: "Not focusable itself; any recovery action button manages its own focus.",
          screen_reader:
            "The title and description are read as text; consider aria-live if the empty state appears after a filter.",
          touch_target: "Any action button should reach 2.75rem effective area on touch.",
          reduced_motion: "No motion."
        },
        swiftui: %{
          code: ~S"""
          ContentUnavailableView {
            Label("No results found", systemImage: "tray")
          } description: {
            Text("Try adjusting your search.")
          } actions: {
            Button("Clear filters") { clearFilters() }
          }
          """,
          notes: "Maps directly to ContentUnavailableView, including the optional action button."
        },
        ios_status: :parity
      },
      "typography" => %{
        specs: %{
          anatomy: [
            %{
              part: "Headings",
              description:
                "h1 text-3xl bold, h2 text-xl semibold (often border-b), tracking-tight."
            },
            %{
              part: "Prose",
              description: "leading-7 paragraphs, links via link-primary, muted secondary text."
            },
            %{
              part: "Blocks",
              description:
                "Blockquotes (border-l-2), lists (list-disc), inline code on var(--muted)."
            }
          ],
          measurements: [
            %{property: "h1", value: "text-3xl (1.875rem) font-bold tracking-tight"},
            %{
              property: "h2",
              value:
                "text-xl (1.25rem) font-semibold, optional border-b 1px var(--border-color) pb-2"
            },
            %{property: "Body", value: "leading-7 prose, text-sm for UI copy"},
            %{
              property: "Inline code",
              value: "var(--muted) bg, var(--radius-sm), px-1.5 py-0.5 font-mono text-sm"
            }
          ],
          tokens: ["foreground", "muted", "muted-foreground", "border-color", "primary"]
        },
        accessibility: %{
          roles:
            "Native semantic elements (h1/h2, p, blockquote, ul, code, a) supply structure and roles directly.",
          focus: "Only links are focusable; they take the standard ring-shadow outline.",
          screen_reader:
            "Heading levels build the document outline; keep them sequential and meaningful.",
          touch_target:
            "Inline links are below 44pt; rely on platform link affordances rather than enlarging text runs.",
          reduced_motion: "Static text; no motion."
        },
        swiftui: %{
          code: ~S"""
          VStack(alignment: .leading, spacing: 16) {
            Text("The Joke Tax Chronicles").font(.largeTitle.bold())
            Text("Once upon a time...").foregroundStyle(.secondary)
            Text("The King's Plan").font(.title2.weight(.semibold))
          }
          """,
          notes:
            "A guidance topic rather than a component: map the type ramp to Text styles (.largeTitle, .title2, .body) and Dynamic Type."
        },
        ios_status: :guidance_only
      },
      "alert-dialog" => %{
        specs: %{
          anatomy: [
            %{part: "Trigger", description: "An element that calls showModal() on the dialog."},
            %{
              part: "Box",
              description: "A `.modal-box` surface with title and muted description."
            },
            %{
              part: "Actions",
              description:
                "A `.modal-action` row: a cancel and a confirm (often btn-error) button."
            }
          ],
          measurements: [
            %{
              property: "Box surface",
              value: "var(--popover) on var(--border-color), var(--radius-lg), shadow-sm"
            },
            %{property: "Title", value: "text-lg font-semibold"},
            %{property: "Description", value: "text-sm var(--muted-foreground)"},
            %{property: "Backdrop", value: "modal-backdrop dims the page behind the dialog"}
          ],
          tokens: [
            "popover",
            "popover-foreground",
            "border-color",
            "muted-foreground",
            "destructive",
            "destructive-foreground"
          ]
        },
        accessibility: %{
          roles:
            "A native modal <dialog>; treat it as an alertdialog by keeping focus on the confirm/cancel choice.",
          keyboard: [
            %{
              keys: "Tab / Shift+Tab",
              action: "Cycle focus between cancel and confirm within the trap"
            },
            %{keys: "Enter / Space", action: "Activate the focused action"},
            %{keys: "Esc", action: "Dismiss via the native dialog (treated as cancel)"}
          ],
          focus: "Opening traps focus inside the dialog; closing returns focus to the trigger.",
          screen_reader:
            "Announced as a dialog; the title and description give the consequence of the action.",
          touch_target: "Action buttons are 2.25rem; size up to 2.75rem effective area on touch.",
          reduced_motion: "Honor prefers-reduced-motion for the modal's enter/exit fade."
        },
        swiftui: %{
          code: ~S"""
          .alert("Are you absolutely sure?", isPresented: $showAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete account", role: .destructive) { delete() }
          } message: {
            Text("This action cannot be undone.")
          }
          """,
          notes: "Maps directly to an .alert with a .destructive confirm and a .cancel button."
        },
        ios_status: :parity
      },
      "collapsible" => %{
        specs: %{
          anatomy: [
            %{
              part: "Section",
              description: "A `.collapse` block (collapse-arrow) holding a checkbox toggle."
            },
            %{
              part: "Trigger",
              description: "The `.collapse-title` row that expands/collapses the section."
            },
            %{part: "Content", description: "The `.collapse-content` region revealed when open."}
          ],
          measurements: [
            %{
              property: "Trigger padding",
              value: "1rem block, padding-inline-end 2.5rem for the arrow"
            },
            %{property: "Trigger text", value: "text-sm (0.875rem) font-medium"},
            %{property: "Content text", value: "text-sm var(--muted-foreground)"},
            %{
              property: "Divider",
              value: "border-bottom 1px var(--border-color) between sections"
            }
          ],
          tokens: ["foreground", "muted-foreground", "border-color", "color-base-300"]
        },
        accessibility: %{
          roles:
            "A disclosure: a toggle (checkbox) controls the visibility of an associated content region.",
          keyboard: [
            %{keys: "Tab", action: "Move focus to the toggle"},
            %{keys: "Space / Enter", action: "Expand or collapse the section"}
          ],
          focus: "The toggle shows the ring-shadow focus outline.",
          screen_reader:
            "Expose expanded/collapsed state (e.g. aria-expanded) so the open/closed status is announced.",
          touch_target:
            "The full trigger row is tappable; ensure it reaches 2.75rem height on touch.",
          reduced_motion: "Honor prefers-reduced-motion for the open/close height animation."
        },
        swiftui: %{
          code: ~S"""
          DisclosureGroup("@shadcn starred 3 repositories") {
            Text("@radix-ui/primitives")
            Text("@radix-ui/colors")
          }
          """,
          notes:
            "Maps directly to DisclosureGroup, which manages its own expanded state and chevron."
        },
        ios_status: :parity
      }
    }
  end
end

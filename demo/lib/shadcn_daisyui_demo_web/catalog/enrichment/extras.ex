defmodule ShadcnDaisyuiDemoWeb.Catalog.Enrichment.Extras do
  @moduledoc "Specs / Accessibility / Native enrichment for the daisyUI extras component group."

  @doc "Map of slug => enrichment fields."
  def specs do
    %{
      "stat" => %{
        specs: %{
          anatomy: [
            %{
              part: "Stats container",
              description: "Card surface holding one or more stat cells side by side."
            },
            %{part: "Title", description: "Metric label, 0.875rem, muted-foreground."},
            %{part: "Value", description: "The large headline figure, font-weight 600."},
            %{part: "Description", description: "Trend/context line in muted-foreground."}
          ],
          measurements: [
            %{property: "Radius", value: "var(--radius-xl) on the stats card"},
            %{
              property: "Border",
              value: "1px border-color around the card; 1px divider between cells"
            },
            %{property: "Shadow", value: "var(--shadow-sm)"},
            %{property: "Title / desc font", value: "0.875rem, muted-foreground"},
            %{property: "Value weight", value: "600"}
          ],
          tokens: ["card", "card-foreground", "muted-foreground", "border-color"]
        },
        accessibility: %{
          roles: "Presentational layout - a styled set of divs; the value reads as plain text.",
          focus: "Not focusable; no interactive elements within a stat cell.",
          screen_reader: "Title, value, and description read in document order as adjacent text.",
          touch_target: "Not interactive; no hit-target requirement.",
          reduced_motion: "Static; no animation to suppress."
        },
        swiftui: %{
          code: ~S"""
          GroupBox {
              VStack(alignment: .leading, spacing: 4) {
                  Text("Total Revenue").font(.caption).foregroundStyle(.secondary)
                  Text("$45,231").font(.title2.weight(.semibold))
                  Text("+20.1% from last month").font(.caption).foregroundStyle(.secondary)
              }
          }
          """,
          notes:
            "Compose a labeled VStack (or GroupBox per metric); lay multiple out in a Grid/HStack."
        },
        ios_status: :partial
      },
      "steps" => %{
        specs: %{
          anatomy: [
            %{part: "Steps list", description: "Horizontal <ul> of step items."},
            %{
              part: "Step",
              description:
                "An <li> with a numbered node above its label; completed steps get step-primary."
            }
          ],
          measurements: [
            %{property: "Label font", value: "0.875rem"},
            %{property: "Default node", value: "--step-bg muted, --step-fg muted-foreground"},
            %{property: "Active node", value: "--step-bg primary, --step-fg primary-foreground"},
            %{property: "Connector", value: "Track line between nodes follows the node color"}
          ],
          tokens: ["muted", "muted-foreground", "primary", "primary-foreground"]
        },
        accessibility: %{
          roles:
            "Presentational <ul>/<li>; current/complete state is conveyed only visually by color.",
          focus: "Not focusable; add ARIA (aria-current) yourself if steps must be announced.",
          screen_reader:
            "Step labels read as a plain list; progress is not exposed without extra ARIA.",
          touch_target: "Not interactive; no hit-target requirement.",
          reduced_motion: "Static; no animation to suppress."
        },
        swiftui: %{
          code: ~S"""
          HStack(spacing: 0) {
              ForEach(steps) { step in
                  Circle().fill(step.done ? Color.accentColor : Color(.systemGray4))
                      .frame(width: 24, height: 24)
                  if step != steps.last { Rectangle().frame(height: 2) }
              }
          }
          """,
          notes:
            "No stock stepper; build from nodes + connectors, or use a segmented ProgressView."
        },
        ios_status: :partial
      },
      "timeline" => %{
        specs: %{
          anatomy: [
            %{
              part: "Timeline list",
              description: "<ul class=timeline> of vertically stacked events."
            },
            %{
              part: "Middle marker",
              description: "Centered icon node (check/clock) on the spine."
            },
            %{part: "Box", description: "timeline-box card holding the event label."},
            %{part: "Connector", description: "<hr> spine segments tinted with border-color."}
          ],
          measurements: [
            %{property: "Box radius", value: "var(--radius-md)"},
            %{property: "Box border", value: "1px border-color"},
            %{property: "Box shadow", value: "var(--shadow-xs)"},
            %{property: "Box font", value: "0.875rem"},
            %{property: "Spine", value: "<hr> tinted border-color"}
          ],
          tokens: ["card", "border-color", "primary", "muted-foreground"]
        },
        accessibility: %{
          roles: "Presentational <ul>/<li>; marker icons are aria-hidden decoration.",
          focus: "Not focusable; no interactive elements.",
          screen_reader:
            "Event labels read in order as a list; icons are hidden from the accessibility tree.",
          touch_target: "Not interactive; no hit-target requirement.",
          reduced_motion: "Static; no animation to suppress."
        },
        swiftui: %{
          code: ~S"""
          List(events) { event in
              Label(event.title, systemImage: event.done ? "checkmark.circle" : "clock")
          }
          .listStyle(.plain)
          """,
          notes: "A plain List with leading status icons approximates the vertical spine."
        },
        ios_status: :partial
      },
      "chat" => %{
        specs: %{
          anatomy: [
            %{
              part: "Chat row",
              description: "Wrapper aligned with chat-start (left) or chat-end (right)."
            },
            %{
              part: "Bubble",
              description:
                "chat-bubble surface; chat-bubble-primary for the sender's own messages."
            }
          ],
          measurements: [
            %{property: "Bubble radius", value: "var(--radius-lg)"},
            %{property: "Incoming bubble", value: "muted background, foreground text"},
            %{property: "Primary bubble", value: "primary background, primary-foreground text"},
            %{property: "Alignment", value: "chat-start left, chat-end right"}
          ],
          tokens: ["muted", "foreground", "primary", "primary-foreground"]
        },
        accessibility: %{
          roles: "Presentational message rows; add a log/list role if used as a live transcript.",
          focus: "Bubbles are not focusable on their own.",
          screen_reader:
            "Bubble text reads in source order; sender is conveyed only by side/color.",
          touch_target: "Not interactive; no hit-target requirement.",
          reduced_motion: "Static; no animation to suppress."
        },
        swiftui: %{
          code: ~S"""
          HStack {
              if message.isMine { Spacer() }
              Text(message.text)
                  .padding(10)
                  .background(message.isMine ? Color.accentColor : Color(.secondarySystemBackground))
                  .foregroundStyle(message.isMine ? .white : .primary)
                  .clipShape(RoundedRectangle(cornerRadius: 16))
              if !message.isMine { Spacer() }
          }
          """,
          notes: "Build message bubbles with aligned HStacks; no stock chat control exists."
        },
        ios_status: :partial
      },
      "rating" => %{
        specs: %{
          anatomy: [
            %{part: "Rating group", description: "Container holding the radio-input stars."},
            %{
              part: "Star input",
              description: "<input type=radio> masked to mask-star-2 and filled bg-warning."
            }
          ],
          measurements: [
            %{property: "Star fill", value: "color-warning (bg-warning)"},
            %{property: "Shape", value: "mask-star-2 clip"},
            %{
              property: "Selection",
              value: "Single radio per name group; checked star sets the value"
            },
            %{property: "Size", value: "Sized via utility classes on the inputs"}
          ],
          tokens: ["color-warning", "muted"]
        },
        accessibility: %{
          roles:
            "Radio group: each star is a labeled radio input (aria-label is the star number).",
          keyboard: [
            %{keys: "Tab", action: "Move focus into / out of the rating group"},
            %{keys: "Arrow keys", action: "Move selection between stars"},
            %{keys: "Space", action: "Select the focused star"}
          ],
          focus: "Native radio focus ring on the active star.",
          screen_reader:
            "Announced as a radio group; each option reads its numeric aria-label and checked state.",
          touch_target: "Stars should present a 44pt effective tap area on touch surfaces.",
          reduced_motion: "Color-only fill change; nothing animates."
        },
        swiftui: %{
          code: ~S"""
          HStack(spacing: 4) {
              ForEach(1...5, id: \.self) { i in
                  Image(systemName: i <= rating ? "star.fill" : "star")
                      .foregroundStyle(.yellow)
                      .onTapGesture { rating = i }
              }
          }
          """,
          notes: "Tappable star HStack; bind selection to the rating value."
        },
        ios_status: :parity
      },
      "radial-progress" => %{
        specs: %{
          anatomy: [
            %{
              part: "Ring",
              description: "Circular track driven by the --value custom property (0-100)."
            },
            %{part: "Center label", description: "Percentage text centered inside the ring."}
          ],
          measurements: [
            %{property: "Value", value: "--value:0-100 sets the swept arc"},
            %{property: "Color", value: "primary by default; recolor with text-* utilities"},
            %{property: "Label font", value: "text-sm in the examples"},
            %{property: "ARIA", value: "role=progressbar with aria-valuenow/min/max"}
          ],
          tokens: ["primary", "muted", "foreground"]
        },
        accessibility: %{
          roles:
            "role=progressbar with aria-valuenow, aria-valuemin, aria-valuemax and an aria-label.",
          focus: "Not focusable; it is a status readout, not a control.",
          screen_reader: "Announced as a progress bar reporting the current percentage.",
          touch_target: "Not interactive; no hit-target requirement.",
          reduced_motion: "Static at render; the arc does not animate unless you animate --value."
        },
        swiftui: %{
          code: ~S"""
          Gauge(value: 0.7) { Text("70%") }
              .gaugeStyle(.accessoryCircularCapacity)
              .tint(.accentColor)
          """,
          notes:
            "A circular Gauge maps cleanly; ProgressView(value:).progressViewStyle(.circular) also works."
        },
        ios_status: :parity
      },
      "indicator" => %{
        specs: %{
          anatomy: [
            %{
              part: "Indicator wrapper",
              description: "Positioning context for the overlaid item."
            },
            %{
              part: "Indicator item",
              description:
                "A badge pinned to a corner (here badge-error) over the anchor element."
            },
            %{part: "Anchor", description: "The element the badge sits on, e.g. a button."}
          ],
          measurements: [
            %{property: "Placement", value: "Absolutely positioned to a corner of the wrapper"},
            %{property: "Badge", value: "Inherits daisyUI badge sizing/colors"},
            %{property: "Color", value: "badge-error uses destructive for the count dot"}
          ],
          tokens: ["destructive", "destructive-foreground", "primary"]
        },
        accessibility: %{
          roles:
            "Presentational overlay; the badge is decorative unless its count carries meaning via the anchor's label.",
          focus: "The badge itself is not focusable; focus belongs to the anchor control.",
          screen_reader:
            "Surface the count in the anchor's accessible name; the badge is not announced on its own.",
          touch_target: "Not interactive; no hit-target requirement.",
          reduced_motion: "Static; no animation to suppress."
        },
        swiftui: %{
          code: ~S"""
          Image(systemName: "bell")
              .overlay(alignment: .topTrailing) {
                  Text("9").font(.caption2).padding(4)
                      .background(.red, in: Circle()).foregroundStyle(.white)
              }
          // or, in a TabView / List: .badge(9)
          """,
          notes:
            "Native .badge(_:) covers tab/list counts; .overlay places a custom corner badge anywhere."
        },
        ios_status: :parity
      },
      "status" => %{
        specs: %{
          anatomy: [
            %{part: "Status dot", description: "A tiny inline circle colored by state."},
            %{
              part: "Label",
              description: "Adjacent text describing the state (Online / Offline)."
            }
          ],
          measurements: [
            %{property: "Shape", value: "Small circular dot"},
            %{property: "Online", value: "status-success → color-success"},
            %{property: "Offline", value: "status-error → destructive"},
            %{property: "Label font", value: "text-sm"}
          ],
          tokens: ["color-success", "destructive", "muted-foreground"]
        },
        accessibility: %{
          roles: "Presentational dot; meaning lives in the adjacent text label.",
          focus: "Not focusable.",
          screen_reader: "The dot is decorative; only the text label conveys state.",
          touch_target: "Not interactive; no hit-target requirement.",
          reduced_motion: "Static; no animation to suppress."
        },
        swiftui: %{
          code: ~S"""
          HStack(spacing: 6) {
              Circle().fill(isOnline ? .green : .red).frame(width: 8, height: 8)
              Text(isOnline ? "Online" : "Offline")
          }
          """,
          notes:
            "A small colored Circle plus a Text label; pair the color with words for accessibility."
        },
        ios_status: :partial
      },
      "countdown" => %{
        specs: %{
          anatomy: [
            %{
              part: "Countdown span",
              description: "Monospace wrapper for the animated digit(s)."
            },
            %{
              part: "Value span",
              description:
                "Inner span whose --value drives the odometer roll; aria-live=polite for updates."
            }
          ],
          measurements: [
            %{
              property: "Value",
              value: "--value sets the displayed number (odometer transition)"
            },
            %{property: "Font", value: "font-mono, text-2xl in the example"},
            %{property: "Motion", value: "Vertical digit roll on change"}
          ],
          tokens: ["foreground", "muted-foreground"]
        },
        accessibility: %{
          roles: "Presentational numeric display; updates are announced via aria-live=polite.",
          focus: "Not focusable.",
          screen_reader:
            "The polite live region announces each new value as the countdown ticks.",
          touch_target: "Not interactive; no hit-target requirement.",
          reduced_motion:
            "The digit roll is excluded from the global transition reset; honor prefers-reduced-motion if you drive it yourself."
        },
        swiftui: %{
          code: ~S"""
          Text(timerInterval: Date.now...endDate, countsDown: true)
              .font(.system(.title, design: .monospaced))
          """,
          notes: "Text(timerInterval:countsDown:) gives a self-updating monospaced countdown."
        },
        ios_status: :parity
      },
      "mockup" => %{
        specs: %{
          anatomy: [
            %{
              part: "Frame",
              description: "mockup-browser or mockup-window chrome around content."
            },
            %{part: "Toolbar", description: "mockup-browser-toolbar with a faux URL input."},
            %{
              part: "Code block",
              description: "mockup-code listing with data-prefix gutters per line."
            }
          ],
          measurements: [
            %{property: "Radius", value: "var(--radius-lg)"},
            %{property: "Surface", value: "muted background, 1px border-color"},
            %{property: "URL field", value: "background-colored faux input in the toolbar"}
          ],
          tokens: ["muted", "background", "border-color", "color-success"]
        },
        accessibility: %{
          roles:
            "Presentational decorative frame; the contained content carries its own semantics.",
          focus: "The frame is not focusable; only real controls inside it are.",
          screen_reader:
            "The chrome is decorative; ensure inner content is meaningful on its own.",
          touch_target: "Not interactive; no hit-target requirement.",
          reduced_motion: "Static; no animation to suppress."
        },
        swiftui: %{
          code: ~S"""
          VStack(spacing: 0) {
              HStack { Circle(); Circle(); Circle() }.foregroundStyle(.secondary).padding(8)
              content
          }
          .background(Color(.secondarySystemBackground))
          .clipShape(RoundedRectangle(cornerRadius: 12))
          """,
          notes: "No native window-chrome control; build a decorative frame around your content."
        },
        ios_status: :guidance_only
      },
      "link" => %{
        specs: %{
          anatomy: [
            %{part: "Anchor", description: "Styled <a> with link styling."},
            %{
              part: "Variant",
              description: "link-primary tints it; link-hover defers the underline to hover."
            }
          ],
          measurements: [
            %{
              property: "Underline",
              value: "Underlined by default; link-hover underlines on hover only"
            },
            %{property: "Color", value: "Inherits text; link-primary uses primary"},
            %{property: "Font", value: "text-sm in the example"}
          ],
          tokens: ["primary", "foreground", "ring"]
        },
        accessibility: %{
          roles: "Native <a>; give it an href so it is a real, focusable link.",
          keyboard: [
            %{keys: "Tab", action: "Move focus to / from the link"},
            %{keys: "Enter", action: "Follow the link"}
          ],
          focus: "Native focus ring (var(--ring)) on :focus-visible.",
          screen_reader:
            "Announced as a link with its text; ensure the text is descriptive on its own.",
          touch_target: "Inline links should still offer a comfortable tap area on touch.",
          reduced_motion: "Color/underline transitions only; nothing moves."
        },
        swiftui: %{
          code: ~S"""
          Link("Primary link", destination: URL(string: "https://example.com")!)
              .tint(.accentColor)
          """,
          notes: "SwiftUI Link maps directly; tint controls the accent color."
        },
        ios_status: :parity
      },
      "list" => %{
        specs: %{
          anatomy: [
            %{part: "List", description: "Rounded, bordered <ul class=list> container."},
            %{
              part: "List row",
              description: "list-row with avatar, primary/secondary text, and a trailing action."
            },
            %{part: "Row divider", description: "1px border-color between rows."}
          ],
          measurements: [
            %{property: "Radius", value: "rounded-xl container in the example"},
            %{property: "Border", value: "1px border-color outer, 1px divider between rows"},
            %{property: "Font", value: "0.875rem base; secondary text text-xs muted-foreground"},
            %{property: "Padding", value: "p-3 per row, gap-3 between row elements"}
          ],
          tokens: ["card", "border-color", "muted-foreground", "foreground"]
        },
        accessibility: %{
          roles: "Semantic <ul>/<li>; the per-row action buttons carry their own aria-labels.",
          focus: "Only the in-row controls (e.g. the more-options button) are focusable.",
          screen_reader:
            "Rows read as list items; trailing icon buttons announce via aria-label.",
          touch_target: "Row action buttons should meet the 44pt touch target on touch surfaces.",
          reduced_motion: "Static; no animation to suppress."
        },
        swiftui: %{
          code: ~S"""
          List(people) { person in
              HStack {
                  avatar(person)
                  VStack(alignment: .leading) {
                      Text(person.name)
                      Text(person.email).font(.caption).foregroundStyle(.secondary)
                  }
                  Spacer()
                  Menu { ... } label: { Image(systemName: "ellipsis") }
              }
          }
          """,
          notes: "Native List with custom rows is the direct equivalent."
        },
        ios_status: :parity
      },
      "swap" => %{
        specs: %{
          anatomy: [
            %{
              part: "Swap label",
              description: "A <label> wrapper (often styled as a button) toggling two states."
            },
            %{part: "Checkbox", description: "Hidden <input type=checkbox> that drives on/off."},
            %{
              part: "Swap faces",
              description:
                "swap-on / swap-off children shown for each state (swap-rotate animates between them)."
            }
          ],
          measurements: [
            %{property: "States", value: "Two faces: swap-on (checked) and swap-off (unchecked)"},
            %{property: "Animation", value: "swap-rotate rotates between the two faces"},
            %{property: "Icon size", value: "size-5 in the example"}
          ],
          tokens: ["foreground", "primary", "border-color"]
        },
        accessibility: %{
          roles: "Wraps a checkbox; give the input an aria-label describing the toggle action.",
          keyboard: [
            %{keys: "Tab", action: "Move focus to / from the swap"},
            %{keys: "Space", action: "Toggle between the two states"}
          ],
          focus: "Native checkbox focus; ensure the label exposes a visible focus indicator.",
          screen_reader:
            "Announced as a checkbox with its aria-label; checked state conveys which face is shown.",
          touch_target: "Style the label to a 44pt effective tap area on touch.",
          reduced_motion:
            "The rotate animation should be suppressed under prefers-reduced-motion."
        },
        swiftui: %{
          code: ~S"""
          Toggle(isOn: $isDark) {
              Image(systemName: isDark ? "moon.fill" : "sun.max.fill")
                  .contentTransition(.symbolEffect(.replace))
          }
          .toggleStyle(.button)
          """,
          notes: "A button-style Toggle with a symbol replace transition mirrors the icon swap."
        },
        ios_status: :guidance_only
      },
      "stack" => %{
        specs: %{
          anatomy: [
            %{part: "Stack container", description: "stack wrapper that overlaps its children."},
            %{
              part: "Stacked items",
              description: "Cards layered front-to-back with a slight offset (here three cards)."
            }
          ],
          measurements: [
            %{property: "Layout", value: "Children overlap in the same box with a small offset"},
            %{property: "Size", value: "Sized via utilities (size-20 in the example)"},
            %{property: "Surfaces", value: "Cards use primary / secondary / base-100 fills"}
          ],
          tokens: [
            "primary",
            "primary-foreground",
            "secondary",
            "secondary-foreground",
            "color-base-200"
          ]
        },
        accessibility: %{
          roles:
            "Presentational overlap layout; only the top item is typically visible/meaningful.",
          focus:
            "Not focusable as a unit; any controls inside stacked items keep their own focus.",
          screen_reader:
            "All stacked children remain in the DOM and read in order - hide non-top items if that is confusing.",
          touch_target: "Not interactive; no hit-target requirement.",
          reduced_motion: "Static; no animation to suppress."
        },
        swiftui: %{
          code: ~S"""
          ZStack {
              CardC(); CardB().offset(y: -4); CardA().offset(y: -8)
          }
          """,
          notes: "A ZStack with small offsets reproduces the overlapped-card look."
        },
        ios_status: :guidance_only
      },
      "mask" => %{
        specs: %{
          anatomy: [
            %{
              part: "Masked element",
              description: "An element clipped to a shape via a mask-* utility."
            }
          ],
          measurements: [
            %{property: "Shapes", value: "mask-squircle, mask-hexagon, mask-star-2, etc."},
            %{property: "Size", value: "Sized via utilities (size-14 in the example)"},
            %{property: "Fill", value: "Background color shows through the clipped shape"}
          ],
          tokens: ["primary", "secondary", "color-warning"]
        },
        accessibility: %{
          roles: "Presentational clipping; the shape is purely decorative.",
          focus: "Not focusable.",
          screen_reader: "Decorative; provide alt text if a masked image carries meaning.",
          touch_target: "Not interactive; no hit-target requirement.",
          reduced_motion: "Static; no animation to suppress."
        },
        swiftui: %{
          code: ~S"""
          Color.accentColor
              .frame(width: 56, height: 56)
              .clipShape(.rect(cornerRadius: 16, style: .continuous)) // or a custom Shape
          """,
          notes: ".mask(_:) or .clipShape(_:) with a custom Shape gives the same effect."
        },
        ios_status: :guidance_only
      },
      "navbar" => %{
        specs: %{
          anatomy: [
            %{part: "Navbar bar", description: "Top bar container, min-height 3.5rem."},
            %{part: "Brand / start", description: "flex-1 region holding the brand link."},
            %{
              part: "Menu / end",
              description: "flex-none region with a horizontal menu and primary action."
            }
          ],
          measurements: [
            %{property: "Min height", value: "3.5rem (h-14)"},
            %{property: "Border", value: "1px border-base-300 (rounded-xl in the demo card)"},
            %{property: "Surface", value: "bg-base-100"},
            %{property: "Font", value: "text-sm contents"}
          ],
          tokens: ["background", "color-base-300", "primary", "primary-foreground", "foreground"]
        },
        accessibility: %{
          roles: "Navigation landmark - wrap links in <nav>; menu items are real <a> links.",
          keyboard: [
            %{keys: "Tab", action: "Move through brand, links, and actions"},
            %{keys: "Enter", action: "Follow the focused link / activate the button"}
          ],
          focus: "Each link/button shows a native focus ring; nothing hides focus.",
          screen_reader: "Announced as a navigation region; links read by their text.",
          touch_target: "Bar controls should meet 44pt effective hit areas on touch.",
          reduced_motion: "No motion beyond color transitions."
        },
        swiftui: %{
          code: ~S"""
          NavigationStack {
              content
                  .toolbar {
                      ToolbarItem(placement: .principal) { Text("Acme Inc").font(.headline) }
                      ToolbarItem(placement: .topBarTrailing) { Button("Sign in") { } }
                  }
          }
          """,
          notes: "Use the system navigation bar / .toolbar; never hand-build the bar on iOS."
        },
        ios_status: :guidance_only
      },
      "footer" => %{
        specs: %{
          anatomy: [
            %{part: "Footer", description: "Multi-column <footer> grid of link groups."},
            %{part: "Column", description: "A <nav> with a footer-title and stacked links."},
            %{part: "Footer title", description: "Section heading in muted-foreground."}
          ],
          measurements: [
            %{property: "Font", value: "0.875rem"},
            %{property: "Title color", value: "muted-foreground"},
            %{
              property: "Surface",
              value: "bg-base-100, 1px border-base-300, rounded-xl, p-6 in the demo"
            },
            %{property: "Links", value: "link link-hover anchors"}
          ],
          tokens: ["background", "color-base-300", "muted-foreground", "foreground"]
        },
        accessibility: %{
          roles:
            "contentinfo landmark when it is the page footer; columns are <nav> regions of links.",
          focus: "Links are individually focusable with native focus rings.",
          screen_reader: "Read as a footer/contentinfo region; titles head their link groups.",
          touch_target: "Footer links should offer comfortable tap areas on touch.",
          reduced_motion: "Color/underline transitions only on links."
        },
        swiftui: %{
          code: ~S"""
          VStack(alignment: .leading, spacing: 16) {
              ForEach(columns) { col in
                  Text(col.title).font(.caption).foregroundStyle(.secondary)
                  ForEach(col.links) { Link($0.title, destination: $0.url) }
              }
          }
          """,
          notes:
            "No footer primitive; lay out link columns in a VStack/Grid at the bottom of the view."
        },
        ios_status: :guidance_only
      },
      "hero" => %{
        specs: %{
          anatomy: [
            %{part: "Hero section", description: "Full-width banner container."},
            %{
              part: "Hero content",
              description: "Centered block with heading, supporting text, and a CTA button."
            }
          ],
          measurements: [
            %{
              property: "Surface",
              value: "bg-muted, 1px border-base-300, rounded-xl in the demo"
            },
            %{property: "Padding", value: "py-12 vertical band"},
            %{property: "Heading", value: "text-2xl font-bold tracking-tight"},
            %{property: "Body", value: "text-sm muted-foreground; content max-w-md"}
          ],
          tokens: ["muted", "muted-foreground", "color-base-300", "primary", "foreground"]
        },
        accessibility: %{
          roles: "Presentational layout band; the heading and CTA carry their own semantics.",
          focus: "Only the CTA button (and any links) inside are focusable.",
          screen_reader: "Heading reads as a heading; the CTA reads as a button.",
          touch_target: "The CTA should meet the 44pt touch target on touch surfaces.",
          reduced_motion: "Static; no animation to suppress."
        },
        swiftui: %{
          code: ~S"""
          ZStack {
              Color(.secondarySystemBackground)
              VStack(spacing: 12) {
                  Text("Build faster").font(.title.bold())
                  Text("shadcn looks, daisyUI ergonomics").font(.subheadline).foregroundStyle(.secondary)
                  Button("Get started") { }.buttonStyle(.borderedProminent)
              }
          }
          """,
          notes: "Compose a ZStack header band; there is no stock hero control."
        },
        ios_status: :guidance_only
      },
      "dock" => %{
        specs: %{
          anatomy: [
            %{
              part: "Dock bar",
              description: "Bottom navigation bar pinned to the foot of the view."
            },
            %{
              part: "Dock item",
              description: "Icon + dock-label button; dock-active marks the current destination."
            }
          ],
          measurements: [
            %{property: "Variant", value: "dock-sm compact size in the example"},
            %{property: "Position", value: "Anchored to the bottom edge"},
            %{property: "Item", value: "Stacked icon (size-5) over a dock-label"},
            %{property: "Active", value: "dock-active highlights the current item"}
          ],
          tokens: ["background", "primary", "muted-foreground", "border-color"]
        },
        accessibility: %{
          roles:
            "Navigation landmark of tab-like destinations; mark the active item with aria-current.",
          keyboard: [
            %{keys: "Tab", action: "Move focus across dock destinations"},
            %{keys: "Enter / Space", action: "Activate the focused destination"}
          ],
          focus: "Each destination button shows a native focus ring.",
          screen_reader: "Announced as navigation; each item reads its label and current state.",
          touch_target: "Dock destinations must meet the 44pt minimum tap area.",
          reduced_motion: "No motion beyond color transitions."
        },
        swiftui: %{
          code: ~S"""
          TabView {
              HomeView().tabItem { Label("Home", systemImage: "house") }
              SearchView().tabItem { Label("Search", systemImage: "magnifyingglass") }
              ProfileView().tabItem { Label("Profile", systemImage: "person") }
          }
          """,
          notes: "The native tab bar is the platform equivalent of a bottom dock."
        },
        ios_status: :guidance_only
      },
      "filter" => %{
        specs: %{
          anatomy: [
            %{
              part: "Filter form",
              description: "<form class=filter> grouping the options and reset."
            },
            %{
              part: "Reset",
              description: "type=reset button (×) that clears the selected radio."
            },
            %{
              part: "Options",
              description: "Button-styled radio inputs sharing one name; one active at a time."
            }
          ],
          measurements: [
            %{property: "Options", value: "btn btn-outline radios, single-select per name group"},
            %{property: "Reset", value: "btn-square outline clear control"},
            %{property: "Selection", value: "Active option styled by the radio :checked state"}
          ],
          tokens: ["primary", "primary-foreground", "border-color", "foreground"]
        },
        accessibility: %{
          roles: "A radio group of options plus a reset button; each radio has an aria-label.",
          keyboard: [
            %{keys: "Tab", action: "Move focus into / out of the filter group"},
            %{keys: "Arrow keys", action: "Move selection between options"},
            %{keys: "Space", action: "Select the focused option / activate reset"}
          ],
          focus: "Native radio/button focus rings on each control.",
          screen_reader:
            "Announced as a radio group; selecting an option and the reset are exposed natively.",
          touch_target: "Each option button should meet the 44pt touch target.",
          reduced_motion: "Color-only state change; nothing animates position."
        },
        swiftui: %{
          code: ~S"""
          Picker("Framework", selection: $framework) {
              Text("Svelte").tag("svelte")
              Text("Vue").tag("vue")
              Text("React").tag("react")
          }
          .pickerStyle(.segmented)
          """,
          notes:
            "A segmented Picker covers single-select filters; add a Clear button for the reset."
        },
        ios_status: :partial
      },
      "validator" => %{
        specs: %{
          anatomy: [
            %{
              part: "Validated input",
              description:
                "An <input class=\"input validator\"> styled by its HTML validity state."
            },
            %{
              part: "Hint",
              description: "validator-hint message shown when the input is invalid."
            }
          ],
          measurements: [
            %{property: "Valid state", value: "Neutral/success styling when constraints pass"},
            %{property: "Invalid state", value: "Destructive border/ring when validity fails"},
            %{property: "Hint", value: "validator-hint message tied to the field"},
            %{
              property: "Constraints",
              value: "Driven by native attributes (required, type, pattern)"
            }
          ],
          tokens: ["input", "ring", "destructive", "destructive-foreground", "border-color"]
        },
        accessibility: %{
          roles:
            "Native form input; validity styling supplements (does not replace) real error messaging.",
          keyboard: [
            %{keys: "Tab", action: "Move focus to / from the field"},
            %{keys: "Typing", action: "Edit the value; validity updates live"}
          ],
          focus: "Native input focus ring (var(--ring)); invalid state adds a destructive ring.",
          screen_reader:
            "Wire the hint via aria-describedby and set aria-invalid so the error is announced - color alone is not enough.",
          touch_target: "Input meets the standard field height; comfortable on touch.",
          reduced_motion: "Color/ring transitions only; nothing moves."
        },
        swiftui: %{
          code: ~S"""
          TextField("you@example.com", text: $email)
              .textFieldStyle(.roundedBorder)
              .foregroundStyle(isValid ? .primary : .red)
          if !isValid { Text("Enter a valid email address").font(.caption).foregroundStyle(.red) }
          """,
          notes:
            "No native validator; tint the field and show a caption error based on your own validation."
        },
        ios_status: :partial
      }
    }
  end
end

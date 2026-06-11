defmodule ShadcnDaisyuiDemoWeb.Catalog do
  @moduledoc """
  The component catalog that drives the docs site.

  Every entry is a component page: a `slug`, `title`, one-line `description`, an
  optional `notes` string (usage/props hints), and a list of `examples`. Each
  example carries a single raw HTML string that is rendered both as a live
  preview and as an escaped code block (see `DocsComponents.preview_code/1`).

  Heroicons are written as `<span class="hero-name ...">` — that is exactly what
  the `<.icon>` helper expands to, so the code shown is real, copy-pasteable
  markup that works with nothing but the theme + heroicons plugin.
  """

  @groups [
    %{
      title: "Core",
      slugs: ~w(button badge card input textarea select checkbox radio-group switch
                label alert tabs table separator accordion avatar breadcrumb
                dropdown-menu dialog tooltip progress skeleton kbd slider spinner
                pagination popover toast)
    },
    %{
      title: "More primitives",
      slugs: ~w(button-group toggle toggle-group input-group navigation-menu hover-card
                sheet sidebar field aspect-ratio scroll-area empty typography
                alert-dialog collapsible)
    },
    %{
      title: "Interactive",
      slugs: ~w(combobox command context-menu data-table calendar date-picker carousel
                drawer input-otp resizable menubar chart)
    },
    %{
      title: "daisyUI extras",
      slugs: ~w(stat steps timeline chat rating radial-progress indicator status
                countdown mockup link list swap stack mask navbar footer hero dock
                filter validator)
    }
  ]

  @doc "Ordered sidebar groups, each with its resolved component structs (slug + title only needed)."
  def groups do
    Enum.map(@groups, fn g ->
      %{title: g.title, components: Enum.map(g.slugs, &component!/1)}
    end)
  end

  @doc "All component slugs, in sidebar order."
  def slugs, do: Enum.flat_map(@groups, & &1.slugs)

  @doc "The first component slug (landing target for /docs)."
  def first_slug, do: hd(slugs())

  @doc "Look up a component by slug, or nil."
  def component(slug), do: Map.get(components(), slug)

  defp component!(slug), do: Map.fetch!(components(), slug)

  @doc "Map of slug => component spec."
  def components do
    for c <- all(), into: %{}, do: {c.slug, c}
  end

  # ---------------------------------------------------------------------------
  # Component definitions
  # ---------------------------------------------------------------------------
  defp all do
    [
      # ===================== CORE =====================
      %{
        slug: "button",
        title: "Button",
        description: "Displays a button or a component that looks like a button.",
        props: [
          %{
            name: "variant",
            type: "default | secondary | outline | ghost | link | destructive",
            default: "default"
          },
          %{name: "size", type: "default | sm | lg | icon", default: "default"}
        ],
        examples: [
          %{
            title: "Variants",
            code: ~S"""
            <button class="btn btn-primary">Primary</button>
            <button class="btn btn-secondary">Secondary</button>
            <button class="btn btn-outline">Outline</button>
            <button class="btn btn-ghost">Ghost</button>
            <button class="btn btn-link">Link</button>
            <button class="btn btn-error">Destructive</button>
            """
          },
          %{
            title: "Sizes",
            code: ~S"""
            <button class="btn btn-primary btn-sm">Small</button>
            <button class="btn btn-primary">Default</button>
            <button class="btn btn-primary btn-lg">Large</button>
            <button class="btn btn-primary btn-square" aria-label="icon">
              <span class="hero-plus size-4"></span>
            </button>
            """
          },
          %{
            title: "States",
            code: ~S"""
            <button class="btn btn-primary" disabled>Disabled</button>
            <button class="btn btn-outline">
              <span class="hero-arrow-down-tray size-4"></span> With icon
            </button>
            <button class="btn btn-secondary">
              <span class="loading loading-spinner loading-xs"></span> Loading
            </button>
            """
          }
        ]
      },
      %{
        slug: "badge",
        title: "Badge",
        description: "Displays a badge or a component that looks like a badge.",
        props: [
          %{name: "variant", type: "default | secondary | outline | destructive", default: "default"}
        ],
        examples: [
          %{
            title: "Variants",
            code: ~S"""
            <span class="badge badge-primary">Primary</span>
            <span class="badge badge-secondary">Secondary</span>
            <span class="badge badge-outline">Outline</span>
            <span class="badge badge-error">Destructive</span>
            """
          }
        ]
      },
      %{
        slug: "card",
        title: "Card",
        description: "A container for grouping related content and actions.",
        examples: [
          %{
            title: "With form",
            code: ~S"""
            <div class="card w-full max-w-sm">
              <div class="card-body">
                <h3 class="card-title">Create project</h3>
                <p class="text-sm text-muted-foreground">Deploy your new project in one click.</p>
                <div class="mt-4 space-y-3">
                  <label class="block space-y-1.5">
                    <span class="text-sm font-medium">Name</span>
                    <input type="text" class="input w-full" placeholder="Name of your project" />
                  </label>
                  <label class="block space-y-1.5">
                    <span class="text-sm font-medium">Framework</span>
                    <select class="select w-full">
                      <option disabled selected>Select</option>
                      <option>Phoenix</option>
                      <option>Next.js</option>
                    </select>
                  </label>
                </div>
                <div class="card-actions mt-6 flex justify-between">
                  <button class="btn btn-outline">Cancel</button>
                  <button class="btn btn-primary">Deploy</button>
                </div>
              </div>
            </div>
            """
          },
          %{
            title: "With toggle",
            code: ~S"""
            <div class="card w-full max-w-sm">
              <div class="card-body">
                <h3 class="card-title">Notifications</h3>
                <p class="text-sm text-muted-foreground">You have 3 unread messages.</p>
                <div class="mt-4 flex items-center justify-between rounded-lg border border-base-300 p-4">
                  <div class="space-y-0.5">
                    <p class="text-sm font-medium">Push Notifications</p>
                    <p class="text-xs text-muted-foreground">Send to your device.</p>
                  </div>
                  <input type="checkbox" class="toggle" checked />
                </div>
                <div class="card-actions mt-6">
                  <button class="btn btn-primary w-full">
                    <span class="hero-check size-4"></span> Mark all as read
                  </button>
                </div>
              </div>
            </div>
            """
          }
        ]
      },
      %{
        slug: "input",
        title: "Input",
        description: "A form input field for collecting text from the user.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <label class="block w-full max-w-sm space-y-1.5">
              <span class="text-sm font-medium">Email</span>
              <input type="email" class="input w-full" placeholder="you@example.com" />
            </label>
            """
          }
        ]
      },
      %{
        slug: "textarea",
        title: "Textarea",
        description: "A multi-line text input field.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <label class="block w-full max-w-sm space-y-1.5">
              <span class="text-sm font-medium">Message</span>
              <textarea class="textarea w-full" rows="3" placeholder="Type your message..."></textarea>
            </label>
            """
          }
        ]
      },
      %{
        slug: "select",
        title: "Select",
        description: "A native select for choosing from a list of options.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <label class="block w-full max-w-sm space-y-1.5">
              <span class="text-sm font-medium">Role</span>
              <select class="select w-full">
                <option disabled selected>Select a role</option>
                <option>Admin</option>
                <option>Member</option>
                <option>Viewer</option>
              </select>
            </label>
            """
          }
        ]
      },
      %{
        slug: "checkbox",
        title: "Checkbox",
        description: "A control that toggles between checked and unchecked.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <div class="space-y-3">
              <label class="flex items-center gap-2 text-sm">
                <input type="checkbox" class="checkbox" checked /> Accept terms and conditions
              </label>
              <label class="flex items-center gap-2 text-sm">
                <input type="checkbox" class="checkbox" /> Subscribe to newsletter
              </label>
              <label class="flex items-center gap-2 text-sm text-muted-foreground">
                <input type="checkbox" class="checkbox" disabled /> Disabled option
              </label>
            </div>
            """
          }
        ]
      },
      %{
        slug: "radio-group",
        title: "Radio Group",
        description: "A set of checkable buttons where only one can be selected at a time.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <div class="space-y-3">
              <label class="flex items-center gap-2 text-sm">
                <input type="radio" name="plan" class="radio" checked /> Free
              </label>
              <label class="flex items-center gap-2 text-sm">
                <input type="radio" name="plan" class="radio" /> Pro
              </label>
              <label class="flex items-center gap-2 text-sm">
                <input type="radio" name="plan" class="radio" /> Enterprise
              </label>
            </div>
            """
          }
        ]
      },
      %{
        slug: "switch",
        title: "Switch",
        description: "A control that toggles between on and off states.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <div class="space-y-3">
              <label class="flex items-center gap-3 text-sm">
                <input type="checkbox" class="toggle" checked /> Airplane mode
              </label>
              <label class="flex items-center gap-3 text-sm">
                <input type="checkbox" class="toggle" /> Wi-Fi
              </label>
            </div>
            """
          }
        ]
      },
      %{
        slug: "label",
        title: "Label",
        description: "An accessible label associated with a form control.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <label class="flex items-center gap-2 text-sm font-medium">
              <input type="checkbox" class="checkbox" /> Accept terms and conditions
            </label>
            """
          }
        ]
      },
      %{
        slug: "alert",
        title: "Alert",
        description: "Displays a callout for user attention.",
        props: [
          %{name: "variant", type: "default | destructive", default: "default"}
        ],
        examples: [
          %{
            title: "Default & destructive",
            center: false,
            code: ~S"""
            <div class="w-full space-y-3">
              <div class="alert" role="alert">
                <span class="hero-information-circle size-4"></span>
                <div>
                  <h3 class="text-sm font-medium">Heads up!</h3>
                  <p class="text-sm text-muted-foreground">You can add components to your app using the CLI.</p>
                </div>
              </div>
              <div class="alert alert-error" role="alert">
                <span class="hero-exclamation-triangle size-4"></span>
                <div>
                  <h3 class="text-sm font-medium">Error</h3>
                  <p class="text-sm">Your session has expired. Please log in again.</p>
                </div>
              </div>
            </div>
            """
          }
        ]
      },
      %{
        slug: "tabs",
        title: "Tabs",
        description: "Layered sections of content shown one panel at a time.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <div role="tablist" class="tabs tabs-box w-fit">
              <input type="radio" name="demo_tabs" class="tab" aria-label="Account" checked />
              <input type="radio" name="demo_tabs" class="tab" aria-label="Password" />
              <input type="radio" name="demo_tabs" class="tab" aria-label="Notifications" />
            </div>
            """
          }
        ]
      },
      %{
        slug: "table",
        title: "Table",
        description: "A responsive table for displaying rows of data.",
        examples: [
          %{
            title: "Default",
            center: false,
            code: ~S"""
            <div class="card w-full overflow-hidden">
              <table class="table">
                <thead>
                  <tr>
                    <th>Invoice</th>
                    <th>Status</th>
                    <th>Method</th>
                    <th class="text-right">Amount</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td class="font-medium">INV001</td>
                    <td><span class="badge badge-secondary">Paid</span></td>
                    <td>Credit Card</td>
                    <td class="text-right">$250.00</td>
                  </tr>
                  <tr>
                    <td class="font-medium">INV002</td>
                    <td><span class="badge badge-outline">Pending</span></td>
                    <td>PayPal</td>
                    <td class="text-right">$150.00</td>
                  </tr>
                  <tr>
                    <td class="font-medium">INV003</td>
                    <td><span class="badge badge-error">Unpaid</span></td>
                    <td>Bank Transfer</td>
                    <td class="text-right">$350.00</td>
                  </tr>
                </tbody>
              </table>
            </div>
            """
          }
        ]
      },
      %{
        slug: "separator",
        title: "Separator",
        description: "Visually or semantically separates content.",
        props: [
          %{name: "orientation", type: "horizontal | vertical", default: "horizontal"}
        ],
        examples: [
          %{
            title: "Horizontal & vertical",
            center: false,
            code: ~S"""
            <div class="w-full max-w-sm">
              <div class="space-y-1">
                <p class="text-sm font-medium leading-none">Radix Primitives</p>
                <p class="text-sm text-muted-foreground">An open-source UI component library.</p>
              </div>
              <div class="divider my-3"></div>
              <div class="flex h-5 items-center gap-4 text-sm">
                <span>Blog</span>
                <div class="divider divider-horizontal"></div>
                <span>Docs</span>
                <div class="divider divider-horizontal"></div>
                <span>Source</span>
              </div>
            </div>
            """
          }
        ]
      },
      %{
        slug: "accordion",
        title: "Accordion",
        description: "Vertically stacked, expandable sections.",
        examples: [
          %{
            title: "Default",
            center: false,
            code: ~S"""
            <div class="card w-full">
              <div class="card-body py-1">
                <div class="collapse collapse-arrow">
                  <input type="checkbox" checked />
                  <div class="collapse-title">Is it accessible?</div>
                  <div class="collapse-content">Yes. It adheres to the WAI-ARIA design pattern.</div>
                </div>
                <div class="collapse collapse-arrow">
                  <input type="checkbox" />
                  <div class="collapse-title">Is it styled?</div>
                  <div class="collapse-content">Yes. It comes with shadcn-matched styles out of the box.</div>
                </div>
                <div class="collapse collapse-arrow">
                  <input type="checkbox" />
                  <div class="collapse-title">Is it animated?</div>
                  <div class="collapse-content">Yes. It uses a smooth height transition.</div>
                </div>
              </div>
            </div>
            """
          }
        ]
      },
      %{
        slug: "avatar",
        title: "Avatar",
        description: "An image element with a text fallback.",
        examples: [
          %{
            title: "Placeholders & group",
            code: ~S"""
            <div class="flex items-center gap-4">
              <div class="avatar avatar-placeholder">
                <div class="w-10 rounded-full"><span class="text-sm font-medium">JD</span></div>
              </div>
              <div class="avatar avatar-placeholder">
                <div class="w-10 rounded-lg"><span class="text-sm font-medium">UI</span></div>
              </div>
              <div class="avatar-group -space-x-3">
                <div class="avatar avatar-placeholder">
                  <div class="w-10 rounded-full"><span class="text-xs">AB</span></div>
                </div>
                <div class="avatar avatar-placeholder">
                  <div class="w-10 rounded-full"><span class="text-xs">CD</span></div>
                </div>
                <div class="avatar avatar-placeholder">
                  <div class="w-10 rounded-full"><span class="text-xs">+3</span></div>
                </div>
              </div>
            </div>
            """
          }
        ]
      },
      %{
        slug: "breadcrumb",
        title: "Breadcrumb",
        description: "Displays the path to the current resource.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <div class="breadcrumbs text-sm">
              <ul>
                <li><a>Home</a></li>
                <li><a>Components</a></li>
                <li>Breadcrumb</li>
              </ul>
            </div>
            """
          }
        ]
      },
      %{
        slug: "dropdown-menu",
        title: "Dropdown Menu",
        description: "A menu of actions or links triggered by a button.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <div class="dropdown">
              <div tabindex="0" role="button" class="btn btn-outline">
                Open menu <span class="hero-chevron-down size-4"></span>
              </div>
              <ul tabindex="0" class="dropdown-content menu z-10 mt-2 w-48">
                <li class="menu-title">My Account</li>
                <li><a>Profile</a></li>
                <li><a>Billing</a></li>
                <li><a>Settings</a></li>
                <li><a class="text-destructive">Log out</a></li>
              </ul>
            </div>
            """
          }
        ]
      },
      %{
        slug: "dialog",
        title: "Dialog",
        description: "A modal window overlaid on the page.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <button class="btn btn-primary" onclick="dialog_demo.showModal()">Open dialog</button>
            <dialog id="dialog_demo" class="modal">
              <div class="modal-box space-y-2">
                <h3 class="text-lg font-semibold">Are you absolutely sure?</h3>
                <p class="text-sm text-muted-foreground">
                  This action cannot be undone. This will permanently delete your account.
                </p>
                <div class="modal-action">
                  <form method="dialog" class="flex gap-3">
                    <button class="btn btn-outline">Cancel</button>
                    <button class="btn btn-error">Delete</button>
                  </form>
                </div>
              </div>
              <form method="dialog" class="modal-backdrop"><button>close</button></form>
            </dialog>
            """
          }
        ]
      },
      %{
        slug: "tooltip",
        title: "Tooltip",
        description: "A floating label shown on hover or focus.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <div class="tooltip" data-tip="Tooltip text">
              <button class="btn btn-secondary">Hover me</button>
            </div>
            """
          }
        ]
      },
      %{
        slug: "progress",
        title: "Progress",
        description: "Displays an indicator showing completion progress.",
        examples: [
          %{
            title: "Default",
            center: false,
            code: ~S"""
            <progress class="progress w-full" value="60" max="100"></progress>
            """
          }
        ]
      },
      %{
        slug: "skeleton",
        title: "Skeleton",
        description: "A placeholder preview while content is loading.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <div class="flex items-center gap-3">
              <div class="skeleton h-10 w-10 rounded-full"></div>
              <div class="space-y-2">
                <div class="skeleton h-3 w-40"></div>
                <div class="skeleton h-3 w-24"></div>
              </div>
            </div>
            """
          }
        ]
      },
      %{
        slug: "kbd",
        title: "Kbd",
        description: "Displays keyboard keys or shortcuts inline.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <p class="text-sm text-muted-foreground">
              Press <kbd class="kbd">⌘</kbd> <kbd class="kbd">K</kbd> to open the command menu.
            </p>
            """
          }
        ]
      },
      %{
        slug: "slider",
        title: "Slider",
        description: "An input for selecting a value from a range.",
        examples: [
          %{
            title: "Default",
            center: false,
            code: ~S"""
            <input type="range" min="0" max="100" value="50" class="range w-full" />
            """
          }
        ]
      },
      %{
        slug: "spinner",
        title: "Spinner",
        description: "An animated loading indicator.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <div class="flex items-center gap-4">
              <span class="loading loading-spinner"></span>
              <span class="loading loading-spinner loading-sm"></span>
              <button class="btn btn-primary">
                <span class="loading loading-spinner loading-xs"></span> Please wait
              </button>
            </div>
            """
          }
        ]
      },
      %{
        slug: "pagination",
        title: "Pagination",
        description: "Navigation for moving between pages of content.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <nav class="flex items-center gap-1">
              <button class="btn btn-ghost btn-sm gap-1 px-2.5">
                <span class="hero-chevron-left size-4"></span> Previous
              </button>
              <button class="btn btn-ghost btn-sm btn-square">1</button>
              <button class="btn btn-outline btn-sm btn-square">2</button>
              <button class="btn btn-ghost btn-sm btn-square">3</button>
              <span class="px-1.5 text-sm text-muted-foreground">…</span>
              <button class="btn btn-ghost btn-sm btn-square">8</button>
              <button class="btn btn-ghost btn-sm gap-1 px-2.5">
                Next <span class="hero-chevron-right size-4"></span>
              </button>
            </nav>
            """
          }
        ]
      },
      %{
        slug: "popover",
        title: "Popover",
        description: "Rich floating content triggered by a button.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <div class="dropdown">
              <div tabindex="0" role="button" class="btn btn-outline">Open popover</div>
              <div tabindex="0" class="dropdown-content z-10 mt-2 w-72 p-4">
                <div class="space-y-3">
                  <div class="space-y-1">
                    <h4 class="text-sm font-medium leading-none">Dimensions</h4>
                    <p class="text-sm text-muted-foreground">Set the dimensions for the layer.</p>
                  </div>
                  <div class="grid grid-cols-3 items-center gap-3 text-sm">
                    <label for="pop-w">Width</label>
                    <input id="pop-w" class="input col-span-2 h-8" value="100%" />
                    <label for="pop-h">Height</label>
                    <input id="pop-h" class="input col-span-2 h-8" value="25px" />
                  </div>
                </div>
              </div>
            </div>
            """
          }
        ]
      },
      %{
        slug: "toast",
        title: "Toast",
        description: "A brief, auto-dismissing notification.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <div class="flex flex-wrap items-center gap-3">
              <button class="btn btn-outline" onclick="window.showToast()">Show toast</button>
              <button class="btn btn-outline" onclick="window.showToast('success')">Show success</button>
            </div>
            <div id="toast-host" class="toast toast-end toast-bottom z-[60]"></div>
            """
          }
        ]
      },

      # ===================== MORE PRIMITIVES =====================
      %{
        slug: "button-group",
        title: "Button Group",
        description: "A set of buttons joined into a single segmented control.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <div class="join">
              <button class="join-item btn btn-outline">Years</button>
              <button class="join-item btn btn-outline">Months</button>
              <button class="join-item btn btn-outline">Days</button>
            </div>
            """
          }
        ]
      },
      %{
        slug: "toggle",
        title: "Toggle",
        description: "A two-state button that can be on or off.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <div class="flex flex-wrap items-center gap-3">
              <label class="btn btn-outline btn-square">
                <input type="checkbox" class="hidden" aria-label="Bold" /><span class="font-bold">B</span>
              </label>
              <label class="btn btn-outline gap-2">
                <input type="checkbox" class="hidden" aria-label="Bookmark" />
                <span class="hero-star size-4"></span> Bookmark
              </label>
            </div>
            """
          }
        ]
      },
      %{
        slug: "toggle-group",
        title: "Toggle Group",
        description: "A set of two-state buttons that can be toggled together.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <div class="join">
              <label class="join-item btn btn-outline btn-square has-[:checked]:bg-accent has-[:checked]:text-accent-foreground">
                <input type="checkbox" class="hidden" aria-label="Bold" />
                <span class="font-bold">B</span>
              </label>
              <label class="join-item btn btn-outline btn-square has-[:checked]:bg-accent has-[:checked]:text-accent-foreground">
                <input type="checkbox" class="hidden" aria-label="Italic" checked />
                <span class="italic">I</span>
              </label>
              <label class="join-item btn btn-outline btn-square has-[:checked]:bg-accent has-[:checked]:text-accent-foreground">
                <input type="checkbox" class="hidden" aria-label="Underline" />
                <span class="underline">U</span>
              </label>
            </div>
            """
          }
        ]
      },
      %{
        slug: "input-group",
        title: "Input Group",
        description: "An input with attached addons or actions.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <div class="join">
              <span class="join-item btn btn-outline pointer-events-none">https://</span>
              <input class="join-item input" placeholder="example.com" />
              <button class="join-item btn btn-primary">Copy</button>
            </div>
            """
          }
        ]
      },
      %{
        slug: "navigation-menu",
        title: "Navigation Menu",
        description: "A horizontal menu with rich dropdown panels.",
        examples: [
          %{
            title: "Default",
            center: false,
            code: ~S"""
            <nav class="flex flex-wrap items-center gap-1">
              <div class="dropdown dropdown-hover">
                <div tabindex="0" role="button" class="btn btn-ghost btn-sm gap-1">
                  Getting started <span class="hero-chevron-down size-4"></span>
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
                  Components <span class="hero-chevron-down size-4"></span>
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
            """
          }
        ]
      },
      %{
        slug: "hover-card",
        title: "Hover Card",
        description: "A card of preview content shown on hover.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <div class="dropdown dropdown-hover">
              <div tabindex="0" role="button" class="link link-primary">@shadcn</div>
              <div tabindex="0" class="dropdown-content z-10 mt-2 w-72 p-4">
                <div class="flex items-start gap-3">
                  <div class="avatar avatar-placeholder shrink-0">
                    <div class="size-12 rounded-full"><span>SC</span></div>
                  </div>
                  <div class="space-y-1">
                    <p class="text-sm font-semibold">@shadcn</p>
                    <p class="text-sm text-muted-foreground">The library you copy into your app. Joined December 2021.</p>
                  </div>
                </div>
              </div>
            </div>
            """
          }
        ]
      },
      %{
        slug: "sheet",
        title: "Sheet",
        description: "A panel that slides in from the edge of the screen.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <button class="btn btn-outline" onclick="document.getElementById('sheet_dialog').showModal()">
              Open sheet →
            </button>
            <dialog id="sheet_dialog" class="sheet" onclick="if(event.target===this)this.close()">
              <button
                class="btn btn-ghost btn-square btn-sm absolute right-3 top-3"
                aria-label="Close"
                onclick="this.closest('dialog').close()"
              >
                <span class="hero-x-mark size-4"></span>
              </button>
              <h3 class="text-lg font-semibold">Edit profile</h3>
              <p class="mt-1 text-sm text-muted-foreground">
                Make changes to your profile here. Click save when you're done.
              </p>
              <div class="mt-5 space-y-4">
                <label class="block space-y-1.5">
                  <span class="text-sm font-medium">Name</span>
                  <input class="input w-full" value="Jane Doe" />
                </label>
                <label class="block space-y-1.5">
                  <span class="text-sm font-medium">Username</span>
                  <input class="input w-full" value="@jane" />
                </label>
              </div>
              <div class="mt-6 flex justify-end gap-3">
                <button class="btn btn-outline" onclick="this.closest('dialog').close()">Cancel</button>
                <button class="btn btn-primary" onclick="this.closest('dialog').close()">Save changes</button>
              </div>
            </dialog>
            """
          }
        ]
      },
      %{
        slug: "sidebar",
        title: "Sidebar",
        description: "An app navigation sidebar layout.",
        examples: [
          %{
            title: "Default",
            center: false,
            code: ~S"""
            <div class="flex h-64 overflow-hidden rounded-xl border border-base-300">
              <aside class="w-56 border-r border-base-300 bg-base-100 p-2">
                <ul class="menu w-full">
                  <li class="menu-title">Platform</li>
                  <li><a class="menu-active">Dashboard</a></li>
                  <li><a>Projects</a></li>
                  <li><a>Team</a></li>
                  <li><a>Settings</a></li>
                </ul>
              </aside>
              <div class="flex-1 p-6 text-sm text-muted-foreground">Main content area</div>
            </div>
            """
          }
        ]
      },
      %{
        slug: "field",
        title: "Field",
        description: "A grouped set of related form controls.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <fieldset class="w-full max-w-sm space-y-1.5 rounded-lg border border-base-300 p-4">
              <legend class="px-1 text-sm font-medium">Notifications</legend>
              <label class="flex items-center gap-2 text-sm">
                <input type="checkbox" class="checkbox" checked /> Email
              </label>
              <label class="flex items-center gap-2 text-sm">
                <input type="checkbox" class="checkbox" /> SMS
              </label>
              <p class="text-xs text-muted-foreground">Choose how you want to be notified.</p>
            </fieldset>
            """
          }
        ]
      },
      %{
        slug: "aspect-ratio",
        title: "Aspect Ratio",
        description: "Constrains content to a fixed width/height ratio.",
        examples: [
          %{
            title: "16 / 9",
            code: ~S"""
            <div class="w-full max-w-sm space-y-1.5">
              <p class="text-sm font-medium">Aspect ratio (16:9)</p>
              <div class="flex aspect-video items-center justify-center rounded-lg bg-muted text-sm text-muted-foreground">
                16 / 9
              </div>
            </div>
            """
          }
        ]
      },
      %{
        slug: "scroll-area",
        title: "Scroll Area",
        description: "A scrollable region with a fixed height.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <div class="w-full max-w-sm space-y-1.5">
              <p class="text-sm font-medium">Scroll area</p>
              <div class="h-32 overflow-y-auto rounded-lg border border-base-300 p-4 text-sm">
                <p class="border-b border-base-200 py-1">Item 1</p>
                <p class="border-b border-base-200 py-1">Item 2</p>
                <p class="border-b border-base-200 py-1">Item 3</p>
                <p class="border-b border-base-200 py-1">Item 4</p>
                <p class="border-b border-base-200 py-1">Item 5</p>
                <p class="border-b border-base-200 py-1">Item 6</p>
                <p class="border-b border-base-200 py-1">Item 7</p>
                <p class="border-b border-base-200 py-1">Item 8</p>
                <p class="py-1">Item 9</p>
              </div>
            </div>
            """
          }
        ]
      },
      %{
        slug: "empty",
        title: "Empty",
        description: "A placeholder for when there is no content to show.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <div class="flex w-full max-w-sm flex-col items-center justify-center gap-2 rounded-lg border border-dashed border-base-300 p-8 text-center">
              <span class="hero-inbox size-7 text-muted-foreground"></span>
              <p class="text-sm font-medium">No results found</p>
              <p class="text-sm text-muted-foreground">Try adjusting your search.</p>
              <button class="btn btn-outline btn-sm mt-1">Clear filters</button>
            </div>
            """
          }
        ]
      },
      %{
        slug: "typography",
        title: "Typography",
        description: "Styles for headings, prose, lists, and inline code.",
        examples: [
          %{
            title: "Default",
            center: false,
            code: ~S"""
            <article class="space-y-4">
              <h1 class="text-3xl font-bold tracking-tight">The Joke Tax Chronicles</h1>
              <p class="leading-7 text-muted-foreground">
                Once upon a time, in a far-off land, there was a very lazy king who spent all day on his throne.
              </p>
              <h2 class="border-b border-base-300 pb-2 text-xl font-semibold tracking-tight">The King's Plan</h2>
              <p class="leading-7">
                The king thought long and hard, and finally came up with
                <a class="link link-primary">a brilliant plan</a>: he would tax the jokes in the kingdom.
              </p>
              <blockquote class="border-l-2 border-base-300 pl-4 italic text-muted-foreground">
                "After all," he said, "everyone enjoys a good joke, so it's only fair that they should pay for the privilege."
              </blockquote>
              <ul class="list-disc space-y-1 pl-6 text-sm">
                <li>1st level of puns: 5 gold coins</li>
                <li>2nd level of jokes: 10 gold coins</li>
                <li>3rd level of one-liners: 20 gold coins</li>
              </ul>
              <p class="text-sm">
                Install with <code class="rounded bg-muted px-1.5 py-0.5 font-mono text-sm">npm i shadcn-daisyui</code>.
              </p>
            </article>
            """
          }
        ]
      },
      %{
        slug: "alert-dialog",
        title: "Alert Dialog",
        description: "A modal that interrupts the user to confirm an action.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <button class="btn btn-outline" onclick="alert_dialog_demo.showModal()">Delete account</button>
            <dialog id="alert_dialog_demo" class="modal">
              <div class="modal-box space-y-2">
                <h3 class="text-lg font-semibold">Are you absolutely sure?</h3>
                <p class="text-sm text-muted-foreground">
                  This action cannot be undone. This will permanently delete your account and remove your data from our servers.
                </p>
                <div class="modal-action">
                  <form method="dialog" class="flex gap-3">
                    <button class="btn btn-outline">Cancel</button>
                    <button class="btn btn-error">Yes, delete account</button>
                  </form>
                </div>
              </div>
              <form method="dialog" class="modal-backdrop"><button>close</button></form>
            </dialog>
            """
          }
        ]
      },
      %{
        slug: "collapsible",
        title: "Collapsible",
        description: "A single expandable/collapsible section.",
        examples: [
          %{
            title: "Default",
            center: false,
            code: ~S"""
            <div class="card w-full">
              <div class="card-body py-1">
                <div class="collapse collapse-arrow">
                  <input type="checkbox" />
                  <div class="collapse-title font-medium">@shadcn starred 3 repositories</div>
                  <div class="collapse-content space-y-2 text-sm text-muted-foreground">
                    <div class="rounded-md border border-base-300 px-3 py-2">@radix-ui/primitives</div>
                    <div class="rounded-md border border-base-300 px-3 py-2">@radix-ui/colors</div>
                  </div>
                </div>
              </div>
            </div>
            """
          }
        ]
      },

      # ===================== INTERACTIVE =====================
      %{
        slug: "combobox",
        title: "Combobox",
        description: "An input with a searchable, filterable list of options.",
        hook: true,
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <div data-combobox class="relative w-60">
              <button type="button" data-combobox-trigger class="btn btn-outline w-full justify-between font-normal">
                <span data-combobox-label class="text-muted-foreground">Select framework…</span>
                <span class="hero-chevron-up-down size-4 opacity-50"></span>
              </button>
              <div data-combobox-panel class="popover-panel absolute z-30 mt-1 hidden w-full p-1">
                <input data-combobox-search class="input mb-1 w-full" placeholder="Search framework…" />
                <ul data-combobox-list class="max-h-52 overflow-auto">
                  <li><button type="button" class="combo-item" data-value="Next.js"><span class="hero-check size-4 opacity-0"></span> Next.js</button></li>
                  <li><button type="button" class="combo-item" data-value="SvelteKit"><span class="hero-check size-4 opacity-0"></span> SvelteKit</button></li>
                  <li><button type="button" class="combo-item" data-value="Nuxt.js"><span class="hero-check size-4 opacity-0"></span> Nuxt.js</button></li>
                  <li><button type="button" class="combo-item" data-value="Remix"><span class="hero-check size-4 opacity-0"></span> Remix</button></li>
                  <li><button type="button" class="combo-item" data-value="Astro"><span class="hero-check size-4 opacity-0"></span> Astro</button></li>
                  <li><button type="button" class="combo-item" data-value="Phoenix"><span class="hero-check size-4 opacity-0"></span> Phoenix</button></li>
                </ul>
                <p data-combobox-empty class="hidden p-2 text-center text-sm text-muted-foreground">No framework found.</p>
              </div>
            </div>
            """
          }
        ]
      },
      %{
        slug: "command",
        title: "Command",
        description: "A command palette for fast keyboard-driven actions.",
        hook: true,
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <button class="btn btn-outline w-64 justify-between" onclick="document.getElementById('command_dialog').showModal()">
              <span class="text-muted-foreground">Search commands…</span>
              <kbd class="kbd">⌘K</kbd>
            </button>
            <dialog id="command_dialog" data-command class="command-dialog">
              <div class="flex items-center gap-2 border-b border-base-300 px-3">
                <span class="hero-magnifying-glass size-4 opacity-50"></span>
                <input data-command-search class="h-11 w-full bg-transparent text-sm outline-none" placeholder="Type a command or search…" />
              </div>
              <ul data-command-list class="max-h-80 overflow-auto p-1">
                <li class="command-group-label" data-group>Suggestions</li>
                <li><button type="button" class="command-item" data-command-item><span class="hero-calendar size-4"></span> Calendar</button></li>
                <li><button type="button" class="command-item" data-command-item><span class="hero-face-smile size-4"></span> Search Emoji</button></li>
                <li><button type="button" class="command-item" data-command-item><span class="hero-calculator size-4"></span> Calculator</button></li>
                <li class="command-group-label" data-group>Settings</li>
                <li><button type="button" class="command-item" data-command-item><span class="hero-user size-4"></span> Profile <span class="ml-auto text-xs text-muted-foreground">⌘P</span></button></li>
                <li><button type="button" class="command-item" data-command-item><span class="hero-cog-6-tooth size-4"></span> Settings <span class="ml-auto text-xs text-muted-foreground">⌘S</span></button></li>
              </ul>
              <p data-command-empty class="hidden p-6 text-center text-sm text-muted-foreground">No results found.</p>
            </dialog>
            """
          }
        ]
      },
      %{
        slug: "context-menu",
        title: "Context Menu",
        description: "A menu shown on right-click.",
        hook: true,
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <div data-context-menu-trigger class="flex h-32 w-full max-w-sm items-center justify-center rounded-lg border border-dashed border-base-300 text-sm text-muted-foreground">
              Right-click here
            </div>
            <ul data-context-menu class="context-menu hidden">
              <li><button type="button">Back <span class="text-xs text-muted-foreground">⌘[</span></button></li>
              <li><button type="button">Forward <span class="text-xs text-muted-foreground">⌘]</span></button></li>
              <li><button type="button">Reload <span class="text-xs text-muted-foreground">⌘R</span></button></li>
              <li><button type="button" class="text-destructive">Delete</button></li>
            </ul>
            """
          }
        ]
      },
      %{
        slug: "data-table",
        title: "Data Table",
        description: "A table with filtering, faceted filters, sorting, and paging.",
        hook: true,
        examples: [
          %{
            title: "Default",
            center: false,
            code: ~S"""
            <div data-datatable class="w-full space-y-3">
              <div class="flex flex-wrap items-center gap-2">
                <input data-dt-filter class="input w-full sm:w-64" placeholder="Filter emails…" />
                <div data-dt-facet="status" class="relative">
                  <button type="button" data-dt-facet-trigger class="btn btn-outline btn-sm border-dashed font-normal">
                    <span class="hero-plus-circle size-4"></span>
                    Status
                    <span data-dt-facet-badges class="hidden"></span>
                  </button>
                  <div data-dt-facet-panel class="popover-panel absolute z-30 mt-1 hidden w-52 p-1">
                    <ul data-dt-facet-list></ul>
                    <div data-dt-facet-clear class="hidden">
                      <div class="my-1 border-t border-base-300"></div>
                      <button type="button" data-dt-facet-clear-btn class="combo-item justify-center text-center">
                        Clear filters
                      </button>
                    </div>
                  </div>
                </div>
                <button type="button" data-dt-reset class="btn btn-ghost btn-sm hidden">
                  Reset <span class="hero-x-mark size-4"></span>
                </button>
              </div>
              <div class="card overflow-hidden">
                <table class="table w-full table-fixed">
                  <thead>
                    <tr>
                      <th data-dt-sort="status" class="w-40">
                        <span class="inline-flex items-center gap-1">Status <span data-dt-sort-icon class="hero-chevron-up-down size-3.5 opacity-50"></span></span>
                      </th>
                      <th data-dt-sort="email">
                        <span class="inline-flex items-center gap-1">Email <span data-dt-sort-icon class="hero-chevron-up-down size-3.5 opacity-50"></span></span>
                      </th>
                      <th data-dt-sort="amount" class="w-32 text-right">
                        <span class="inline-flex items-center justify-end gap-1">Amount <span data-dt-sort-icon class="hero-chevron-up-down size-3.5 opacity-50"></span></span>
                      </th>
                    </tr>
                  </thead>
                  <tbody data-dt-body></tbody>
                </table>
              </div>
              <div class="flex items-center justify-between">
                <span data-dt-info class="text-sm text-muted-foreground"></span>
                <div class="flex gap-2">
                  <button type="button" data-dt-prev class="btn btn-outline btn-sm">Previous</button>
                  <button type="button" data-dt-next class="btn btn-outline btn-sm">Next</button>
                </div>
              </div>
            </div>
            """
          }
        ]
      },
      %{
        slug: "calendar",
        title: "Calendar",
        description: "A date-selection calendar.",
        hook: true,
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <div class="card w-fit">
              <div class="card-body"><div data-calendar></div></div>
            </div>
            """
          }
        ]
      },
      %{
        slug: "date-picker",
        title: "Date Picker",
        description: "A popover calendar for picking a single date or a range.",
        hook: true,
        examples: [
          %{
            title: "Single & range",
            code: ~S"""
            <div class="flex flex-col gap-4">
              <div class="space-y-2">
                <p class="text-sm text-muted-foreground">Date picker</p>
                <div data-datepicker class="relative w-64">
                  <button type="button" data-datepicker-trigger class="btn btn-outline w-full justify-start gap-2 font-normal">
                    <span class="hero-calendar size-4 opacity-70"></span>
                    <span data-datepicker-label class="text-muted-foreground">Pick a date</span>
                  </button>
                  <div data-datepicker-panel class="popover-panel absolute z-30 mt-1 hidden p-3">
                    <div data-calendar></div>
                  </div>
                </div>
              </div>
              <div class="space-y-2">
                <p class="text-sm text-muted-foreground">Date range picker</p>
                <div data-daterange class="relative w-64">
                  <button type="button" data-daterange-trigger class="btn btn-outline w-full justify-start gap-2 font-normal">
                    <span class="hero-calendar size-4 opacity-70"></span>
                    <span data-daterange-label class="text-muted-foreground">Pick a date range</span>
                  </button>
                  <div data-daterange-panel class="popover-panel absolute z-30 mt-1 hidden p-3">
                    <div data-calendar-range></div>
                  </div>
                </div>
              </div>
            </div>
            """
          }
        ]
      },
      %{
        slug: "carousel",
        title: "Carousel",
        description: "A slideshow of items with previous/next controls.",
        hook: true,
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <div class="relative w-full max-w-sm px-4">
              <div data-carousel class="carousel w-full rounded-lg">
                <div class="carousel-item w-full">
                  <div class="flex aspect-video w-full items-center justify-center rounded-lg border border-base-300 bg-muted text-3xl font-semibold">1</div>
                </div>
                <div class="carousel-item w-full">
                  <div class="flex aspect-video w-full items-center justify-center rounded-lg border border-base-300 bg-muted text-3xl font-semibold">2</div>
                </div>
                <div class="carousel-item w-full">
                  <div class="flex aspect-video w-full items-center justify-center rounded-lg border border-base-300 bg-muted text-3xl font-semibold">3</div>
                </div>
                <div class="carousel-item w-full">
                  <div class="flex aspect-video w-full items-center justify-center rounded-lg border border-base-300 bg-muted text-3xl font-semibold">4</div>
                </div>
                <div class="carousel-item w-full">
                  <div class="flex aspect-video w-full items-center justify-center rounded-lg border border-base-300 bg-muted text-3xl font-semibold">5</div>
                </div>
              </div>
              <button type="button" data-carousel-prev class="btn btn-outline btn-circle btn-sm absolute left-0 top-1/2 -translate-y-1/2">
                <span class="hero-chevron-left size-4"></span>
              </button>
              <button type="button" data-carousel-next class="btn btn-outline btn-circle btn-sm absolute right-0 top-1/2 -translate-y-1/2">
                <span class="hero-chevron-right size-4"></span>
              </button>
            </div>
            """
          }
        ]
      },
      %{
        slug: "drawer",
        title: "Drawer",
        description: "A panel that slides up from the bottom of the screen.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <button class="btn btn-outline" onclick="document.getElementById('drawer_bottom').showModal()">
              Open drawer
            </button>
            <dialog id="drawer_bottom" class="drawer-bottom" onclick="if(event.target===this)this.close()">
              <div class="mx-auto mb-4 h-1.5 w-12 rounded-full bg-base-300"></div>
              <div class="mx-auto w-full max-w-md text-center">
                <h3 class="text-lg font-semibold">Move goal</h3>
                <p class="mt-1 text-sm text-muted-foreground">Set your daily activity goal.</p>
                <div class="my-6 flex items-center justify-center gap-6">
                  <button class="btn btn-outline btn-circle">−</button>
                  <span class="text-4xl font-bold tabular-nums">350</span>
                  <button class="btn btn-outline btn-circle">+</button>
                </div>
                <button class="btn btn-primary w-full" onclick="this.closest('dialog').close()">Submit</button>
              </div>
            </dialog>
            """
          }
        ]
      },
      %{
        slug: "input-otp",
        title: "Input OTP",
        description: "A segmented input for one-time passcodes.",
        hook: true,
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <div data-otp class="flex items-center gap-2">
              <input class="otp-slot" maxlength="1" inputmode="numeric" autocomplete="one-time-code" />
              <input class="otp-slot" maxlength="1" inputmode="numeric" />
              <input class="otp-slot" maxlength="1" inputmode="numeric" />
              <span class="text-muted-foreground">-</span>
              <input class="otp-slot" maxlength="1" inputmode="numeric" />
              <input class="otp-slot" maxlength="1" inputmode="numeric" />
              <input class="otp-slot" maxlength="1" inputmode="numeric" />
            </div>
            """
          }
        ]
      },
      %{
        slug: "resizable",
        title: "Resizable",
        description: "Panels the user can resize by dragging a handle.",
        hook: true,
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <div
              id="resizable-demo"
              data-resizable
              class="flex h-44 w-80 max-w-full overflow-hidden rounded-lg border border-base-300 text-sm"
            >
              <div class="resizable-panel flex items-center justify-center" style="width: 50%">
                <span class="font-semibold">One</span>
              </div>
              <div class="resizable-handle" role="separator" aria-orientation="vertical" tabindex="0">
                <div class="resizable-grip"><span class="hero-ellipsis-vertical size-2.5"></span></div>
              </div>
              <div class="resizable-panel flex flex-1 flex-col">
                <div class="flex flex-1 items-center justify-center border-b border-base-300">
                  <span class="font-semibold">Two</span>
                </div>
                <div class="flex flex-1 items-center justify-center">
                  <span class="font-semibold">Three</span>
                </div>
              </div>
            </div>
            """
          }
        ]
      },
      %{
        slug: "menubar",
        title: "Menubar",
        description: "A horizontal bar of dropdown menus, like a desktop app.",
        examples: [
          %{
            title: "Default",
            center: false,
            code: ~S"""
            <div class="flex w-fit items-center gap-1 rounded-md border border-base-300 bg-base-100 p-1">
              <div class="dropdown">
                <div tabindex="0" role="button" class="btn btn-ghost btn-sm">File</div>
                <ul tabindex="0" class="dropdown-content menu mt-1 w-52">
                  <li><a class="flex justify-between">New Tab <span class="text-xs text-muted-foreground">⌘T</span></a></li>
                  <li><a class="flex justify-between">New Window <span class="text-xs text-muted-foreground">⌘N</span></a></li>
                  <li><a>Share</a></li>
                  <li><a class="flex justify-between">Print <span class="text-xs text-muted-foreground">⌘P</span></a></li>
                </ul>
              </div>
              <div class="dropdown">
                <div tabindex="0" role="button" class="btn btn-ghost btn-sm">Edit</div>
                <ul tabindex="0" class="dropdown-content menu mt-1 w-44">
                  <li><a class="flex justify-between">Undo <span class="text-xs text-muted-foreground">⌘Z</span></a></li>
                  <li><a class="flex justify-between">Redo <span class="text-xs text-muted-foreground">⇧⌘Z</span></a></li>
                  <li><a>Cut</a></li>
                  <li><a>Copy</a></li>
                </ul>
              </div>
              <div class="dropdown">
                <div tabindex="0" role="button" class="btn btn-ghost btn-sm">View</div>
                <ul tabindex="0" class="dropdown-content menu mt-1 w-48">
                  <li><a>Reload</a></li>
                  <li><a>Toggle Fullscreen</a></li>
                  <li><a>Hide Sidebar</a></li>
                </ul>
              </div>
            </div>
            """
          }
        ]
      },
      %{
        slug: "chart",
        title: "Chart",
        description: "Simple bar and line charts drawn with the theme colors.",
        examples: [
          %{
            title: "Bar & line",
            center: false,
            code: ~S"""
            <div class="grid w-full gap-6 lg:grid-cols-2">
              <div class="card">
                <div class="card-body">
                  <p class="text-sm font-medium">Revenue</p>
                  <p class="mb-3 text-sm text-muted-foreground">Last 6 months</p>
                  <div class="flex h-40 items-end gap-3">
                    <div class="chart-bar w-full" style="height: 40%"></div>
                    <div class="chart-bar w-full" style="height: 65%"></div>
                    <div class="chart-bar w-full" style="height: 52%"></div>
                    <div class="chart-bar w-full" style="height: 80%"></div>
                    <div class="chart-bar w-full" style="height: 60%"></div>
                    <div class="chart-bar w-full" style="height: 95%"></div>
                  </div>
                  <div class="mt-2 flex gap-3 text-center text-xs text-muted-foreground">
                    <span class="w-full">Jan</span><span class="w-full">Feb</span><span class="w-full">Mar</span>
                    <span class="w-full">Apr</span><span class="w-full">May</span><span class="w-full">Jun</span>
                  </div>
                </div>
              </div>
              <div class="card">
                <div class="card-body">
                  <p class="text-sm font-medium">Visitors</p>
                  <p class="mb-3 text-sm text-muted-foreground">Trend</p>
                  <svg viewBox="0 0 300 130" class="h-40 w-full" preserveAspectRatio="none">
                    <polygon fill="var(--primary)" opacity="0.08" points="0,120 0,80 50,90 100,55 150,70 200,35 250,50 300,20 300,120" />
                    <polyline fill="none" stroke="var(--primary)" stroke-width="2" stroke-linejoin="round" stroke-linecap="round" points="0,80 50,90 100,55 150,70 200,35 250,50 300,20" />
                  </svg>
                </div>
              </div>
            </div>
            """
          }
        ]
      },

      # ===================== DAISYUI EXTRAS =====================
      %{
        slug: "stat",
        title: "Stat",
        description: "Compact blocks for key metrics.",
        examples: [
          %{
            title: "Default",
            center: false,
            code: ~S"""
            <div class="stats w-full">
              <div class="stat">
                <div class="stat-title">Total Revenue</div>
                <div class="stat-value">$45,231</div>
                <div class="stat-desc">+20.1% from last month</div>
              </div>
              <div class="stat">
                <div class="stat-title">Subscriptions</div>
                <div class="stat-value">+2,350</div>
                <div class="stat-desc">+180.1% from last month</div>
              </div>
              <div class="stat">
                <div class="stat-title">Active Now</div>
                <div class="stat-value">+573</div>
                <div class="stat-desc">+201 since last hour</div>
              </div>
            </div>
            """
          }
        ]
      },
      %{
        slug: "steps",
        title: "Steps",
        description: "A horizontal stepper showing progress through a flow.",
        examples: [
          %{
            title: "Default",
            center: false,
            code: ~S"""
            <ul class="steps w-full">
              <li class="step step-primary">Cart</li>
              <li class="step step-primary">Shipping</li>
              <li class="step">Payment</li>
              <li class="step">Confirm</li>
            </ul>
            """
          }
        ]
      },
      %{
        slug: "timeline",
        title: "Timeline",
        description: "A vertical or horizontal sequence of events.",
        examples: [
          %{
            title: "Default",
            center: false,
            code: ~S"""
            <ul class="timeline">
              <li>
                <div class="timeline-middle"><span class="hero-check-circle size-4 text-primary"></span></div>
                <div class="timeline-end timeline-box">Project kickoff</div>
                <hr />
              </li>
              <li>
                <hr />
                <div class="timeline-middle"><span class="hero-check-circle size-4 text-primary"></span></div>
                <div class="timeline-end timeline-box">Design complete</div>
                <hr />
              </li>
              <li>
                <hr />
                <div class="timeline-middle"><span class="hero-clock size-4 text-muted-foreground"></span></div>
                <div class="timeline-end timeline-box">Launch</div>
              </li>
            </ul>
            """
          }
        ]
      },
      %{
        slug: "chat",
        title: "Chat",
        description: "Chat-bubble message rows aligned left or right.",
        examples: [
          %{
            title: "Default",
            center: false,
            code: ~S"""
            <div class="w-full">
              <div class="chat chat-start">
                <div class="chat-bubble">You underestimate my power!</div>
              </div>
              <div class="chat chat-end">
                <div class="chat-bubble chat-bubble-primary">Don't try it 😈</div>
              </div>
            </div>
            """
          }
        ]
      },
      %{
        slug: "rating",
        title: "Rating",
        description: "A star rating input.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <div class="rating">
              <input type="radio" name="rating-demo" class="mask mask-star-2 bg-warning" aria-label="1" />
              <input type="radio" name="rating-demo" class="mask mask-star-2 bg-warning" aria-label="2" checked />
              <input type="radio" name="rating-demo" class="mask mask-star-2 bg-warning" aria-label="3" />
              <input type="radio" name="rating-demo" class="mask mask-star-2 bg-warning" aria-label="4" />
              <input type="radio" name="rating-demo" class="mask mask-star-2 bg-warning" aria-label="5" />
            </div>
            """
          }
        ]
      },
      %{
        slug: "radial-progress",
        title: "Radial Progress",
        description: "A circular percentage progress ring.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <div class="flex items-center gap-6">
              <div class="radial-progress text-sm" style="--value:70;" role="progressbar">70%</div>
              <div class="radial-progress text-sm" style="--value:40;" role="progressbar">40%</div>
              <div class="radial-progress text-primary text-sm" style="--value:90;" role="progressbar">90%</div>
            </div>
            """
          }
        ]
      },
      %{
        slug: "indicator",
        title: "Indicator",
        description: "A corner badge overlaid on another element.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <div class="indicator">
              <span class="indicator-item badge badge-error">9</span>
              <button class="btn btn-outline">
                <span class="hero-bell size-4"></span> Inbox
              </button>
            </div>
            """
          }
        ]
      },
      %{
        slug: "status",
        title: "Status",
        description: "A tiny status dot for online/offline state.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <div class="flex items-center gap-6">
              <span class="inline-flex items-center gap-2 text-sm">
                <span class="status status-success"></span> Online
              </span>
              <span class="inline-flex items-center gap-2 text-sm">
                <span class="status status-error"></span> Offline
              </span>
            </div>
            """
          }
        ]
      },
      %{
        slug: "countdown",
        title: "Countdown",
        description: "An animated numeric odometer for countdowns.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <span class="countdown font-mono text-2xl">
              <span style="--value:42;" aria-live="polite">42</span>
            </span>
            """
          }
        ]
      },
      %{
        slug: "mockup",
        title: "Mockup",
        description: "Browser and code window mockup frames.",
        examples: [
          %{
            title: "Browser & code",
            center: false,
            code: ~S"""
            <div class="w-full space-y-6">
              <div class="mockup-browser border border-base-300">
                <div class="mockup-browser-toolbar">
                  <div class="input">https://shadcn-daisyui.dev</div>
                </div>
                <div class="flex justify-center px-4 py-6 text-sm text-muted-foreground">Hello, world!</div>
              </div>
              <div class="mockup-code">
                <pre data-prefix="$"><code>mix phx.server</code></pre>
                <pre data-prefix=">" class="text-success"><code>running on :4000</code></pre>
              </div>
            </div>
            """
          }
        ]
      },
      %{
        slug: "link",
        title: "Link",
        description: "A styled inline anchor.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <div class="flex flex-wrap gap-4 text-sm">
              <a class="link link-primary">Primary link</a>
              <a class="link">Default link</a>
              <a class="link link-hover">Hover link</a>
            </div>
            """
          }
        ]
      },
      %{
        slug: "list",
        title: "List",
        description: "Vertical rows of items with avatars and actions.",
        examples: [
          %{
            title: "Default",
            center: false,
            code: ~S"""
            <ul class="list w-full max-w-md rounded-xl border border-base-300">
              <li class="list-row flex items-center gap-3 p-3">
                <div class="avatar avatar-placeholder">
                  <div class="w-8 rounded-full"><span class="text-xs">AB</span></div>
                </div>
                <div class="flex-1">
                  <div class="font-medium">Alex Brown</div>
                  <div class="text-xs text-muted-foreground">alex@example.com</div>
                </div>
                <button class="btn btn-ghost btn-sm btn-square"><span class="hero-ellipsis-horizontal size-4"></span></button>
              </li>
              <li class="list-row flex items-center gap-3 p-3">
                <div class="avatar avatar-placeholder">
                  <div class="w-8 rounded-full"><span class="text-xs">CD</span></div>
                </div>
                <div class="flex-1">
                  <div class="font-medium">Casey Day</div>
                  <div class="text-xs text-muted-foreground">casey@example.com</div>
                </div>
                <button class="btn btn-ghost btn-sm btn-square"><span class="hero-ellipsis-horizontal size-4"></span></button>
              </li>
            </ul>
            """
          }
        ]
      },
      %{
        slug: "swap",
        title: "Swap",
        description: "An animated swap between two icons or states.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <label class="swap swap-rotate btn btn-outline btn-square">
              <input type="checkbox" />
              <span class="hero-sun swap-on size-5"></span>
              <span class="hero-moon swap-off size-5"></span>
            </label>
            """
          }
        ]
      },
      %{
        slug: "stack",
        title: "Stack",
        description: "Overlapping, stacked elements.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <div class="stack size-20">
              <div class="card bg-primary text-primary-foreground"><div class="card-body items-center justify-center p-0">A</div></div>
              <div class="card bg-secondary text-secondary-foreground"><div class="card-body items-center justify-center p-0">B</div></div>
              <div class="card border border-base-300 bg-base-100"><div class="card-body items-center justify-center p-0">C</div></div>
            </div>
            """
          }
        ]
      },
      %{
        slug: "mask",
        title: "Mask",
        description: "Clip an element to a shape.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <div class="flex items-center gap-4">
              <div class="mask mask-squircle size-14 bg-primary"></div>
              <div class="mask mask-hexagon size-14 bg-secondary"></div>
              <div class="mask mask-star-2 size-14 bg-warning"></div>
            </div>
            """
          }
        ]
      },
      %{
        slug: "navbar",
        title: "Navbar",
        description: "A top application bar.",
        examples: [
          %{
            title: "Default",
            center: false,
            code: ~S"""
            <div class="navbar w-full rounded-xl border border-base-300 bg-base-100">
              <div class="flex-1"><a class="btn btn-ghost text-base">Acme Inc</a></div>
              <div class="flex-none">
                <ul class="menu menu-horizontal gap-1">
                  <li><a>Docs</a></li>
                  <li><a>Pricing</a></li>
                  <li><a class="btn btn-primary btn-sm text-primary-content">Sign in</a></li>
                </ul>
              </div>
            </div>
            """
          }
        ]
      },
      %{
        slug: "footer",
        title: "Footer",
        description: "A multi-column page footer layout.",
        examples: [
          %{
            title: "Default",
            center: false,
            code: ~S"""
            <footer class="footer w-full rounded-xl border border-base-300 bg-base-100 p-6">
              <nav>
                <h6 class="footer-title">Product</h6>
                <a class="link link-hover">Features</a>
                <a class="link link-hover">Pricing</a>
              </nav>
              <nav>
                <h6 class="footer-title">Company</h6>
                <a class="link link-hover">About</a>
                <a class="link link-hover">Contact</a>
              </nav>
              <nav>
                <h6 class="footer-title">Legal</h6>
                <a class="link link-hover">Terms</a>
                <a class="link link-hover">Privacy</a>
              </nav>
            </footer>
            """
          }
        ]
      },
      %{
        slug: "hero",
        title: "Hero",
        description: "A full-width hero section layout.",
        examples: [
          %{
            title: "Default",
            center: false,
            code: ~S"""
            <div class="hero w-full rounded-xl border border-base-300 bg-muted py-12">
              <div class="hero-content text-center">
                <div class="max-w-md space-y-3">
                  <h1 class="text-2xl font-bold tracking-tight">Build faster</h1>
                  <p class="text-sm text-muted-foreground">shadcn looks, daisyUI ergonomics — one theme file.</p>
                  <button class="btn btn-primary">Get started</button>
                </div>
              </div>
            </div>
            """
          }
        ]
      },
      %{
        slug: "dock",
        title: "Dock",
        description: "A bottom navigation bar for mobile.",
        examples: [
          %{
            title: "Default",
            center: false,
            code: ~S"""
            <div class="relative h-24 w-full overflow-hidden rounded-xl border border-base-300">
              <div class="dock dock-sm" style="position:absolute">
                <button class="dock-active">
                  <span class="hero-home size-5"></span><span class="dock-label">Home</span>
                </button>
                <button>
                  <span class="hero-magnifying-glass size-5"></span><span class="dock-label">Search</span>
                </button>
                <button>
                  <span class="hero-user size-5"></span><span class="dock-label">Profile</span>
                </button>
              </div>
            </div>
            """
          }
        ]
      },
      %{
        slug: "filter",
        title: "Filter",
        description: "A radio-button filter group with a reset.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <form class="filter">
              <input class="btn btn-square btn-outline" type="reset" value="×" />
              <input class="btn btn-outline" type="radio" name="frameworks" aria-label="Svelte" />
              <input class="btn btn-outline" type="radio" name="frameworks" aria-label="Vue" />
              <input class="btn btn-outline" type="radio" name="frameworks" aria-label="React" />
            </form>
            """
          }
        ]
      },
      %{
        slug: "validator",
        title: "Validator",
        description: "Form-validation visual states with a hint.",
        examples: [
          %{
            title: "Default",
            code: ~S"""
            <div class="w-full max-w-sm space-y-1.5">
              <input type="email" class="input validator w-full" required placeholder="you@example.com" />
              <p class="validator-hint">Enter a valid email address</p>
            </div>
            """
          }
        ]
      }
    ]
  end
end

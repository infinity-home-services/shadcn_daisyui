defmodule ShadcnDaisyui.Components do
  @moduledoc """
  Phoenix function components styled by the shadcn-daisyui theme.

  Most components are thin wrappers over daisyUI classes (so the theme does the
  styling). The interactive ones render the markup the JS hooks expect and set
  `phx-hook="Shadcn…"` - add the hooks to your `LiveSocket` (see the README).

      use ShadcnDaisyui.Components
      # or: import ShadcnDaisyui.Components

  Anything not wrapped here is still available as plain daisyUI classes
  (`btn`, `card`, `tabs tabs-box`, …) - the theme styles them automatically.

  `use ShadcnDaisyui.Components` also imports `ShadcnDaisyui.FormComponents`
  (field-aware form controls). The generator-compatible `button`, `input`,
  `flash`, `table`, … live in `ShadcnDaisyui.CoreComponents` - apps normally get
  those through their own `CoreComponents` module.
  """
  use Phoenix.Component

  defmacro __using__(_opts) do
    quote do
      import(ShadcnDaisyui.Components)
      import(ShadcnDaisyui.Components.Overlay)
      import(ShadcnDaisyui.Components.Navigation)
      import(ShadcnDaisyui.Components.Display)
      import(ShadcnDaisyui.FormComponents)
    end
  end

  # ----------------------------------------------------------------------------
  # Badge
  # ----------------------------------------------------------------------------
  @badge_variants %{
    "default" => "badge-primary",
    "secondary" => "badge-secondary",
    "outline" => "badge-outline",
    "destructive" => "badge-error"
  }

  @doc "A badge. Variants: default, secondary, outline, destructive."
  attr(:variant, :string, default: "default", values: ~w(default secondary outline destructive))
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def badge(assigns) do
    assigns = assign(assigns, :vclass, @badge_variants[assigns.variant])

    ~H"""
    <span class={["badge", @vclass, @class]} {@rest}>{render_slot(@inner_block)}</span>
    """
  end

  # ----------------------------------------------------------------------------
  # Alert
  # ----------------------------------------------------------------------------
  @doc """
  An alert. Variant `default` or `destructive`.

      <.alert variant="destructive">
        <:title>Error</:title>
        Your session has expired.
      </.alert>
  """
  attr(:variant, :string, default: "default", values: ~w(default destructive))
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:title)
  slot(:inner_block, required: true)

  def alert(assigns) do
    ~H"""
    <div class={["alert", @variant == "destructive" && "alert-error", @class]} role="alert" {@rest}>
      <div>
        <h3 :if={@title != []} class="text-sm font-medium">{render_slot(@title)}</h3>
        <p class="text-sm text-muted-foreground">{render_slot(@inner_block)}</p>
      </div>
    </div>
    """
  end

  # ----------------------------------------------------------------------------
  # Card (+ subcomponents)
  # ----------------------------------------------------------------------------
  @doc "A card container. Compose with the card_* helpers or just put a `.card-body` inside."
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def card(assigns) do
    ~H"""
    <div class={["card", @class]} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def card_body(assigns) do
    ~H"""
    <div class={["card-body", @class]}>{render_slot(@inner_block)}</div>
    """
  end

  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def card_title(assigns) do
    ~H"""
    <h3 class={["card-title", @class]}>{render_slot(@inner_block)}</h3>
    """
  end

  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def card_description(assigns) do
    ~H"""
    <p class={["text-sm text-muted-foreground", @class]}>{render_slot(@inner_block)}</p>
    """
  end

  # ----------------------------------------------------------------------------
  # Separator
  # ----------------------------------------------------------------------------
  attr(:orientation, :string, default: "horizontal", values: ~w(horizontal vertical))
  attr(:class, :any, default: nil)

  def separator(assigns) do
    ~H"""
    <div class={["divider", @orientation == "vertical" && "divider-horizontal", @class]}></div>
    """
  end

  # ============================================================================
  # Interactive (paired with JS hooks). Each needs an `id`.
  # ============================================================================

  @doc "An inline month calendar (single-date)."
  attr(:id, :string, required: true)
  attr(:class, :any, default: nil)

  def calendar(assigns) do
    ~H"""
    <div id={@id} phx-hook="ShadcnCalendar" data-calendar class={@class}></div>
    """
  end

  @doc "A date picker button that opens a calendar popover."
  attr(:id, :string, required: true)
  attr(:placeholder, :string, default: "Pick a date")
  attr(:class, :any, default: "w-60")

  def date_picker(assigns) do
    ~H"""
    <div id={@id} phx-hook="ShadcnDatePicker" data-datepicker class={["relative", @class]}>
      <button type="button" data-datepicker-trigger class="btn btn-outline w-full justify-start gap-2 font-normal">
        <span class="size-4 opacity-70 hero-calendar" aria-hidden="true"></span>
        <span data-datepicker-label class="text-muted-foreground">{@placeholder}</span>
      </button>
      <div data-datepicker-panel class="popover-panel absolute z-30 mt-1 hidden p-3">
        <div data-calendar></div>
      </div>
    </div>
    """
  end

  @doc "A date range picker (two months, shadcn-style band)."
  attr(:id, :string, required: true)
  attr(:placeholder, :string, default: "Pick a date range")
  attr(:class, :any, default: "w-64")

  def date_range(assigns) do
    ~H"""
    <div id={@id} phx-hook="ShadcnDateRange" data-daterange class={["relative", @class]}>
      <button type="button" data-daterange-trigger class="btn btn-outline w-full justify-start gap-2 font-normal">
        <span class="size-4 opacity-70 hero-calendar" aria-hidden="true"></span>
        <span data-daterange-label class="text-muted-foreground">{@placeholder}</span>
      </button>
      <div data-daterange-panel class="popover-panel absolute z-30 mt-1 hidden p-3">
        <div data-calendar-range></div>
      </div>
    </div>
    """
  end

  @doc """
  A combobox (searchable select). Provide options as `:option` slots.
  For form binding, provide `name` and `value` attributes to emit a hidden input.

      <.combobox id="fw" placeholder="Select framework…">
        <:option value="Next.js">Next.js</:option>
        <:option value="Phoenix">Phoenix</:option>
      </.combobox>

      <!-- With form binding: -->
      <.combobox id="fw" name="framework" value={@selected_framework}>
        <:option value="Next.js">Next.js</:option>
        <:option value="Phoenix">Phoenix</:option>
      </.combobox>
  """
  attr(:id, :string, required: true)
  attr(:placeholder, :string, default: "Select…")
  attr(:class, :any, default: "w-60")
  attr(:name, :string, default: nil, doc: "form field name; if set, emits a hidden input")
  attr(:value, :string, default: nil, doc: "current selected value")

  slot :option, doc: "each option; set `value`" do
    attr(:value, :string, required: true)
  end

  def combobox(assigns) do
    ~H"""
    <div id={@id} phx-hook="ShadcnCombobox" data-combobox class={["relative", @class]}>
      <input :if={@name} type="hidden" name={@name} value={@value} />
      <button type="button" data-combobox-trigger class="btn btn-outline w-full justify-between font-normal">
        <span data-combobox-label class="text-muted-foreground">{@placeholder}</span>
        <span class="size-4 opacity-50 hero-chevron-up-down" aria-hidden="true"></span>
      </button>
      <div data-combobox-panel class="popover-panel absolute z-30 mt-1 hidden w-full p-1">
        <input data-combobox-search class="input mb-1 w-full" placeholder={@placeholder} />
        <ul data-combobox-list class="max-h-52 overflow-auto">
          <li :for={opt <- @option}>
            <button type="button" class="combo-item" data-value={opt.value}>
              <span class="size-4 opacity-0 hero-check" aria-hidden="true"></span>
              {render_slot(opt)}
            </button>
          </li>
        </ul>
        <p data-combobox-empty class="hidden p-2 text-center text-sm text-muted-foreground">No results.</p>
      </div>
    </div>
    """
  end

  @doc """
  A custom select (shadcn-style trigger + listbox popover). Provide options as
  `:option` slots. For form binding, provide `name` and `value` attributes to emit
  a hidden input.

      <.select id="fruit" placeholder="Select a fruit">
        <:option value="Apple">Apple</:option>
        <:option value="Banana">Banana</:option>
      </.select>

      <!-- With form binding: -->
      <.select id="fruit" name="fruit" value={@selected_fruit}>
        <:option value="Apple">Apple</:option>
        <:option value="Banana">Banana</:option>
      </.select>

  For the plain HTML control use `<select class="select">`.
  """
  attr(:id, :string, required: true)
  attr(:placeholder, :string, default: "Select…")
  attr(:class, :any, default: "w-60")
  attr(:name, :string, default: nil, doc: "form field name; if set, emits a hidden input")
  attr(:value, :string, default: nil, doc: "current selected value")

  slot :option, doc: "each option; set `value`" do
    attr(:value, :string, required: true)
  end

  def select(assigns) do
    ~H"""
    <div id={@id} phx-hook="ShadcnSelect" data-select class={["relative", @class]}>
      <input :if={@name} type="hidden" name={@name} value={@value} />
      <button type="button" data-select-trigger class="btn btn-outline w-full justify-between font-normal">
        <span data-select-label class="text-muted-foreground">{@placeholder}</span>
        <span class="size-4 opacity-50 hero-chevron-down" aria-hidden="true"></span>
      </button>
      <div data-select-panel class="popover-panel absolute z-30 mt-1 hidden w-full p-1">
        <button
          :for={opt <- @option}
          type="button"
          class="combo-item"
          data-select-item
          data-value={opt.value}
        >
          <span class="size-4 opacity-0 hero-check" aria-hidden="true"></span>
          {render_slot(opt)}
        </button>
      </div>
    </div>
    """
  end

  @doc "A segmented one-time-code input."
  attr(:id, :string, required: true)
  attr(:length, :integer, default: 6)
  attr(:group, :integer, default: 3, doc: "insert a separator every `group` slots (0 = none)")
  attr(:class, :any, default: nil)

  def input_otp(assigns) do
    ~H"""
    <div id={@id} phx-hook="ShadcnOtp" data-otp class={["flex items-center gap-2", @class]}>
      <%= for i <- 0..(@length - 1) do %>
        <span :if={@group > 0 and i > 0 and rem(i, @group) == 0} class="text-muted-foreground">-</span>
        <input class="otp-slot" maxlength="1" inputmode="numeric" />
      <% end %>
    </div>
    """
  end

  @doc """
  A carousel. Provide slides as `:slide` slots.

      <.carousel id="c"><:slide>1</:slide><:slide>2</:slide></.carousel>
  """
  attr(:id, :string, required: true)
  attr(:class, :any, default: "w-full max-w-sm")
  slot(:slide, required: true)

  def carousel(assigns) do
    ~H"""
    <div class={["relative px-4", @class]}>
      <div id={@id} phx-hook="ShadcnCarousel" data-carousel class="carousel w-full rounded-lg">
        <div :for={s <- @slide} class="carousel-item w-full">{render_slot(s)}</div>
      </div>
      <button type="button" data-carousel-prev class="btn btn-outline btn-circle btn-sm absolute left-0 top-1/2 -translate-y-1/2">
        <span class="size-4 hero-chevron-left" aria-hidden="true"></span>
      </button>
      <button type="button" data-carousel-next class="btn btn-outline btn-circle btn-sm absolute right-0 top-1/2 -translate-y-1/2">
        <span class="size-4 hero-chevron-right" aria-hidden="true"></span>
      </button>
    </div>
    """
  end

  @doc "A two-pane resizable group with a draggable grip."
  attr(:id, :string, required: true)
  attr(:class, :any, default: "h-44 w-full")
  slot(:start, required: true)
  slot(:end_pane, required: true)

  def resizable(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="ShadcnResizable"
      data-resizable
      class={["flex overflow-hidden rounded-lg border border-base-300 text-sm", @class]}
    >
      <div class="resizable-panel flex items-center justify-center" style="width: 50%">{render_slot(@start)}</div>
      <div class="resizable-handle" role="separator" aria-orientation="vertical" tabindex="0">
        <div class="resizable-grip"><span class="size-2.5 hero-ellipsis-vertical" aria-hidden="true"></span></div>
      </div>
      <div class="resizable-panel flex flex-1 items-center justify-center">{render_slot(@end_pane)}</div>
    </div>
    """
  end
end

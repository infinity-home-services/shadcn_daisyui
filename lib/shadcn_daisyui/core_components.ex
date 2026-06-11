defmodule ShadcnDaisyui.CoreComponents do
  @moduledoc """
  A drop-in replacement for the core components Phoenix 1.8 generates, styled by
  the shadcn-daisyui theme.

  Exposes the exact API `phx.gen.live` / `phx.gen.html` templates call —
  `input/1`, `button/1`, `error/1`, `header/1`, `table/1`, `list/1`, `icon/1`,
  `flash/1` — so generated code works unmodified.

  ## Replacing your app's CoreComponents

  Keep your module name (referenced from `my_app_web.ex` and the generators) and
  delegate to this one:

      defmodule MyAppWeb.CoreComponents do
        use ShadcnDaisyui.CoreComponents
      end

  Every component is `defoverridable` — redefine any function locally to customize:

      defmodule MyAppWeb.CoreComponents do
        use ShadcnDaisyui.CoreComponents

        def header(assigns), do: ~H"..."   # your version wins
      end

  `mix shadcn_daisyui.install` performs this rewrite for you (your previous file
  is backed up).

  ## Error translation

  Form errors are translated through the configured MFA (the installer writes this):

      config :shadcn_daisyui, :translate_error, {MyAppWeb.CoreComponents, :translate_error}

  Without config, `%{count}`-style bindings are interpolated without translation.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @wrapped [
    flash: 1,
    button: 1,
    input: 1,
    error: 1,
    header: 1,
    table: 1,
    list: 1,
    icon: 1
  ]

  defmacro __using__(_opts) do
    # Wrapper definitions (not imports) so the using module *exports* the
    # components — `import MyAppWeb.CoreComponents` elsewhere keeps working.
    # `flash_group/1` is deliberately not wrapped: Phoenix 1.8 defines it in
    # `Layouts`, and a wrapper here would conflict with that local definition.
    wrappers =
      for {name, 1} <- @wrapped do
        quote do
          def unquote(name)(assigns), do: ShadcnDaisyui.CoreComponents.unquote(name)(assigns)
        end
      end

    quote do
      use Phoenix.Component

      unquote(wrappers)

      def show(js \\ %Phoenix.LiveView.JS{}, selector),
        do: ShadcnDaisyui.CoreComponents.show(js, selector)

      def hide(js \\ %Phoenix.LiveView.JS{}, selector),
        do: ShadcnDaisyui.CoreComponents.hide(js, selector)

      def translate_error(error), do: ShadcnDaisyui.CoreComponents.translate_error(error)

      def translate_errors(errors, field),
        do: ShadcnDaisyui.CoreComponents.translate_errors(errors, field)

      defoverridable [
                       show: 1,
                       show: 2,
                       hide: 1,
                       hide: 2,
                       translate_error: 1,
                       translate_errors: 2
                     ] ++ unquote(@wrapped)
    end
  end

  @doc """
  Renders flash notices.

      <.flash kind={:info} flash={@flash} />
  """
  attr(:id, :string, doc: "the optional id of flash container")
  attr(:flash, :map, default: %{}, doc: "the map of flash messages to display")
  attr(:title, :string, default: nil)
  attr(:kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup")
  attr(:rest, :global, doc: "the arbitrary HTML attributes to add to the flash container")
  slot(:inner_block, doc: "the optional inner block that renders the flash message")

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class="toast toast-top toast-end z-50"
      {@rest}
    >
      <div class={[
        "alert w-80 sm:w-96 max-w-80 sm:max-w-96 text-wrap",
        @kind == :info && "alert-info",
        @kind == :error && "alert-error"
      ]}>
        <.icon :if={@kind == :info} name="hero-information-circle" class="size-5 shrink-0" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle" class="size-5 shrink-0" />
        <div>
          <p :if={@title} class="font-semibold">{@title}</p>
          <p>{msg}</p>
        </div>
        <div class="flex-1" />
        <button type="button" class="group self-start cursor-pointer" aria-label="close">
          <.icon name="hero-x-mark" class="size-5 opacity-40 group-hover:opacity-70" />
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  Phoenix 1.8 defines this in your `Layouts` module — keep that one if you have
  it; this is provided for apps that don't.
  """
  attr(:flash, :map, required: true, doc: "the map of flash messages")
  attr(:id, :string, default: "flash-group", doc: "the optional id of flash container")

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />
    </div>
    """
  end

  @button_variants %{
    "default" => "btn-primary",
    "primary" => "btn-primary",
    "secondary" => "btn-secondary",
    "outline" => "btn-outline",
    "ghost" => "btn-ghost",
    "link" => "btn-link",
    "destructive" => "btn-error"
  }
  @button_sizes %{"default" => "", "sm" => "btn-sm", "lg" => "btn-lg", "icon" => "btn-square"}

  @doc """
  Renders a button with navigation support and shadcn variants.

      <.button>Send!</.button>
      <.button variant="outline" size="sm" phx-click="go">Cancel</.button>
      <.button navigate={~p"/"}>Home</.button>

  `variant="primary"` (what the Phoenix generators emit) is an alias for the
  default primary style.
  """
  attr(:variant, :string,
    default: "default",
    values: ~w(default primary secondary outline ghost link destructive)
  )

  attr(:size, :string, default: "default", values: ~w(default sm lg icon))
  attr(:class, :any, default: nil)

  attr(:rest, :global,
    include: ~w(href navigate patch method download name value disabled form type)
  )

  slot(:inner_block, required: true)

  def button(%{rest: rest} = assigns) do
    assigns =
      assigns
      |> assign(:vclass, @button_variants[assigns.variant])
      |> assign(:sclass, @button_sizes[assigns.size])

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={["btn", @vclass, @sclass, @class]} {@rest}>
        {render_slot(@inner_block)}
      </.link>
      """
    else
      ~H"""
      <button class={["btn", @vclass, @sclass, @class]} {@rest}>
        {render_slot(@inner_block)}
      </button>
      """
    end
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument, which is used to
  retrieve the input name, id, and values. Otherwise all attributes may be
  passed explicitly.

  ## Types

  All HTML input types, plus `type="select"`, `type="textarea"`, and
  `type="checkbox"` (boolean). For live file uploads see
  `Phoenix.Component.live_file_input/1`. For radio groups, switches, and the
  shadcn field layout see `ShadcnDaisyui.FormComponents`.

  ## Examples

      <.input field={@form[:email]} type="email" label="Email" />
      <.input field={@form[:role]} type="select" label="Role" prompt="Pick one" options={["admin", "member"]} />
      <.input field={@form[:active]} type="checkbox" label="Active" />
  """
  attr(:id, :any, default: nil)
  attr(:name, :any)
  attr(:label, :string, default: nil)
  attr(:value, :any)

  attr(:type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               search select tel text textarea time url week hidden)
  )

  attr(:field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"
  )

  attr(:errors, :list, default: [])
  attr(:checked, :boolean, doc: "the checked flag for checkbox inputs")
  attr(:prompt, :string, default: nil, doc: "the prompt for select inputs")
  attr(:options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2")
  attr(:multiple, :boolean, default: false, doc: "the multiple flag for select inputs")
  attr(:class, :any, default: nil, doc: "the input class to use over defaults")
  attr(:error_class, :any, default: nil, doc: "the input error class to use over defaults")

  attr(:rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)
  )

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "hidden"} = assigns) do
    ~H"""
    <input type="hidden" id={@id} name={@name} value={@value} {@rest} />
    """
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class="fieldset mb-2">
      <label for={@id} class="flex items-center gap-2 text-sm font-medium">
        <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} form={@rest[:form]} />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class={@class || "checkbox checkbox-sm"}
          {@rest}
        />{@label}
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label for={@id}>
        <span :if={@label} class="label mb-1.5 text-sm font-medium">{@label}</span>
        <select
          id={@id}
          name={@name}
          class={[@class || "select w-full", @errors != [] && (@error_class || "select-error")]}
          multiple={@multiple}
          {@rest}
        >
          <option :if={@prompt} value="">{@prompt}</option>
          {Phoenix.HTML.Form.options_for_select(@options, @value)}
        </select>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label for={@id}>
        <span :if={@label} class="label mb-1.5 text-sm font-medium">{@label}</span>
        <textarea
          id={@id}
          name={@name}
          class={[@class || "textarea w-full", @errors != [] && (@error_class || "textarea-error")]}
          {@rest}
        >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # All other input types (text, email, password, datetime-local, …).
  def input(assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label for={@id}>
        <span :if={@label} class="label mb-1.5 text-sm font-medium">{@label}</span>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[@class || "input w-full", @errors != [] && (@error_class || "input-error")]}
          {@rest}
        />
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  @doc """
  Renders a form error message.
  """
  slot(:inner_block, required: true)

  def error(assigns) do
    ~H"""
    <p class="mt-1.5 flex items-center gap-1.5 text-sm text-error">
      <.icon name="hero-exclamation-circle" class="size-4 shrink-0" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a header with title, subtitle, and actions.
  """
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)
  slot(:subtitle)
  slot(:actions)

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", "pb-4", @class]}>
      <div>
        <h1 class="text-lg font-semibold leading-8 tracking-tight">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="text-sm text-muted-foreground">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc """
  Renders a table with generic styling. Works with lists and LiveView streams.

      <.table id="users" rows={@users}>
        <:col :let={user} label="id">{user.id}</:col>
        <:col :let={user} label="username">{user.username}</:col>
      </.table>
  """
  attr(:id, :string, required: true)
  attr(:rows, :list, required: true)
  attr(:row_id, :any, default: nil, doc: "the function for generating the row id")
  attr(:row_click, :any, default: nil, doc: "the function for handling phx-click on each row")

  attr(:row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"
  )

  slot :col, required: true do
    attr(:label, :string)
  end

  slot(:action, doc: "the slot for showing user actions in the last table column")

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-x-auto">
      <table class="table">
        <thead>
          <tr>
            <th :for={col <- @col}>{col[:label]}</th>
            <th :if={@action != []}>
              <span class="sr-only">Actions</span>
            </th>
          </tr>
        </thead>
        <tbody id={@id} phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}>
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)}>
            <td
              :for={col <- @col}
              phx-click={@row_click && @row_click.(row)}
              class={@row_click && "hover:cursor-pointer"}
            >
              {render_slot(col, @row_item.(row))}
            </td>
            <td :if={@action != []} class="w-0 font-medium">
              <div class="flex gap-4">
                <%= for action <- @action do %>
                  {render_slot(action, @row_item.(row))}
                <% end %>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a data list.

      <.list>
        <:item title="Title">{@post.title}</:item>
      </.list>
  """
  slot :item, required: true do
    attr(:title, :string, required: true)
  end

  def list(assigns) do
    ~H"""
    <ul class="list">
      <li :for={item <- @item} class="list-row">
        <div class="list-col-grow">
          <div class="text-sm font-medium">{item.title}</div>
          <div class="text-sm text-muted-foreground">{render_slot(item)}</div>
        </div>
      </li>
    </ul>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com). Outline by default; use the
  `-solid` / `-mini` / `-micro` suffixes for the other styles.

      <.icon name="hero-x-mark" />
      <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
  """
  attr(:name, :string, required: true)
  attr(:class, :any, default: "size-4")

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} aria-hidden="true" />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  @doc """
  Translates an error message through the configured translator
  (`config :shadcn_daisyui, :translate_error, {Mod, :fun}`).
  """
  def translate_error({_msg, _opts} = error), do: ShadcnDaisyui.Translate.translate_error(error)

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end

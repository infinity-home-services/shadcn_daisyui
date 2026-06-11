defmodule ShadcnDaisyui.FormComponents do
  @moduledoc """
  Form controls in the shadcn "Form" style, all `Phoenix.HTML.FormField`-aware.

  `ShadcnDaisyui.CoreComponents.input/1` (the polymorphic generator-compatible
  input) covers most cases. Reach for these when you want the dedicated control
  or the `<.field>` layout with description text:

      <.field field={@form[:email]} label="Email" description="We never share it.">
        <.input field={@form[:email]} type="email" />
      </.field>

      <.switch field={@form[:notifications]} label="Email notifications" />
      <.radio_group field={@form[:plan]} label="Plan">
        <:radio value="free">Free</:radio>
        <:radio value="pro">Pro</:radio>
      </.radio_group>

  Errors render only after the input was used (`Phoenix.Component.used_input?/1`)
  and are translated via the configured `:translate_error` MFA.

      use ShadcnDaisyui.FormComponents
      # or: import ShadcnDaisyui.FormComponents
  """
  use Phoenix.Component

  alias ShadcnDaisyui.CoreComponents

  defmacro __using__(_opts) do
    quote(do: import(ShadcnDaisyui.FormComponents))
  end

  @doc "A form label."
  attr(:for, :string, default: nil)
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def label(assigns) do
    ~H"""
    <label for={@for} class={["text-sm font-medium", @class]}>{render_slot(@inner_block)}</label>
    """
  end

  @doc """
  The shadcn field layout: label + control + description + errors, with
  `aria-describedby` / `aria-invalid` wiring.

  The control goes in the inner block. The slot receives the derived ids and
  errors when you need them (`:let={f}` → `f.id`, `f.describedby`, `f.errors`).

      <.field field={@form[:email]} label="Email" description="We never share it.">
        <.input field={@form[:email]} type="email" />
      </.field>
  """
  attr(:field, Phoenix.HTML.FormField, required: true)
  attr(:label, :string, default: nil)
  attr(:description, :string, default: nil)
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def field(%{field: field} = assigns) do
    errors = field_errors(field)
    description_id = "#{field.id}-description"
    error_id = "#{field.id}-error"

    describedby =
      [assigns.description && description_id, errors != [] && error_id]
      |> Enum.filter(& &1)
      |> Enum.join(" ")

    assigns =
      assigns
      |> assign(:errors, errors)
      |> assign(:description_id, description_id)
      |> assign(:error_id, error_id)
      |> assign(:describedby, describedby)

    ~H"""
    <div
      class={["grid gap-1.5", @class]}
      aria-invalid={@errors != [] && "true"}
      aria-describedby={@describedby != "" && @describedby}
    >
      <.label :if={@label} for={@field.id}>{@label}</.label>
      {render_slot(@inner_block, %{id: @field.id, describedby: @describedby, errors: @errors})}
      <p :if={@description} id={@description_id} class="text-sm text-muted-foreground">
        {@description}
      </p>
      <div :if={@errors != []} id={@error_id}>
        <CoreComponents.error :for={msg <- @errors}>{msg}</CoreComponents.error>
      </div>
    </div>
    """
  end

  @doc """
  A checkbox bound to a boolean field (renders the hidden `false` input).

      <.checkbox field={@form[:active]} label="Active" />
  """
  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:id, :any, default: nil)
  attr(:name, :any, default: nil)
  attr(:value, :any, default: nil)
  attr(:checked, :boolean, default: nil)
  attr(:label, :string, default: nil)
  attr(:description, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(disabled form required))

  def checkbox(assigns), do: boolean_control(assigns, "checkbox checkbox-sm")

  @doc """
  A switch (daisyUI toggle) bound to a boolean field.

      <.switch field={@form[:notifications]} label="Email notifications" />
  """
  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:id, :any, default: nil)
  attr(:name, :any, default: nil)
  attr(:value, :any, default: nil)
  attr(:checked, :boolean, default: nil)
  attr(:label, :string, default: nil)
  attr(:description, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(disabled form required))

  def switch(assigns), do: boolean_control(assigns, "toggle")

  defp boolean_control(assigns, control_class) do
    assigns = apply_field(assigns)

    assigns =
      assigns
      |> Map.update!(:checked, fn
        nil -> Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
        checked -> checked
      end)
      |> assign(:control_class, control_class)

    ~H"""
    <div class="grid gap-1.5">
      <label for={@id} class="flex items-center gap-2 text-sm font-medium">
        <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} form={@rest[:form]} />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class={[@control_class, @class]}
          {@rest}
        />{@label}
      </label>
      <p :if={@description} class="text-sm text-muted-foreground">{@description}</p>
      <CoreComponents.error :for={msg <- @errors}>{msg}</CoreComponents.error>
    </div>
    """
  end

  @doc """
  A radio group bound to a field.

      <.radio_group field={@form[:plan]} label="Plan">
        <:radio value="free">Free</:radio>
        <:radio value="pro">Pro</:radio>
      </.radio_group>
  """
  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:id, :any, default: nil)
  attr(:name, :any, default: nil)
  attr(:value, :any, default: nil)
  attr(:label, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(disabled form required))

  slot :radio, required: true do
    attr(:value, :string, required: true)
  end

  def radio_group(assigns) do
    assigns = apply_field(assigns)

    ~H"""
    <fieldset class={["grid gap-2", @class]}>
      <legend :if={@label} class="mb-1 text-sm font-medium">{@label}</legend>
      <label
        :for={{radio, i} <- Enum.with_index(@radio)}
        for={"#{@id}-#{i}"}
        class="flex items-center gap-2 text-sm"
      >
        <input
          type="radio"
          id={"#{@id}-#{i}"}
          name={@name}
          value={radio.value}
          checked={to_string(radio.value) == to_string(@value)}
          class="radio radio-sm"
          {@rest}
        />{render_slot(radio)}
      </label>
      <CoreComponents.error :for={msg <- @errors}>{msg}</CoreComponents.error>
    </fieldset>
    """
  end

  @doc """
  A native `<select class="select">` bound to a field.

      <.native_select field={@form[:role]} label="Role" prompt="Pick one" options={["admin", "member"]} />
  """
  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:id, :any, default: nil)
  attr(:name, :any, default: nil)
  attr(:value, :any, default: nil)
  attr(:label, :string, default: nil)
  attr(:prompt, :string, default: nil)
  attr(:options, :list, default: [])
  attr(:multiple, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(disabled form required size))

  def native_select(assigns) do
    assigns = apply_field(assigns)

    ~H"""
    <div class="grid gap-1.5">
      <.label :if={@label} for={@id}>{@label}</.label>
      <select
        id={@id}
        name={@name}
        multiple={@multiple}
        class={["select w-full", @errors != [] && "select-error", @class]}
        {@rest}
      >
        <option :if={@prompt} value="">{@prompt}</option>
        {Phoenix.HTML.Form.options_for_select(@options, @value)}
      </select>
      <CoreComponents.error :for={msg <- @errors}>{msg}</CoreComponents.error>
    </div>
    """
  end

  @doc """
  A textarea, optionally bound to a field.

      <.textarea field={@form[:bio]} label="Bio" rows="4" />
  """
  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:id, :any, default: nil)
  attr(:name, :any, default: nil)
  attr(:value, :any, default: nil)
  attr(:label, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(disabled form placeholder readonly required rows))

  def textarea(assigns) do
    assigns = apply_field(assigns)

    ~H"""
    <div class="grid gap-1.5">
      <.label :if={@label} for={@id}>{@label}</.label>
      <textarea
        id={@id}
        name={@name}
        class={["textarea w-full", @errors != [] && "textarea-error", @class]}
        {@rest}
      >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      <CoreComponents.error :for={msg <- @errors}>{msg}</CoreComponents.error>
    </div>
    """
  end

  # Derives id/name/value/errors from a FormField; passes explicit assigns through.
  defp apply_field(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    multiple = assigns[:multiple] || false

    assigns
    |> assign(:field, nil)
    |> assign(:errors, field_errors(field))
    |> Map.update!(:id, fn id -> id || field.id end)
    |> Map.update!(:name, fn
      nil -> if multiple, do: field.name <> "[]", else: field.name
      name -> name
    end)
    |> Map.update!(:value, fn
      nil -> field.value
      value -> value
    end)
  end

  defp apply_field(assigns), do: assign_new(assigns, :errors, fn -> [] end)

  defp field_errors(%Phoenix.HTML.FormField{} = field) do
    if Phoenix.Component.used_input?(field) do
      Enum.map(field.errors, &ShadcnDaisyui.Translate.translate_error/1)
    else
      []
    end
  end
end

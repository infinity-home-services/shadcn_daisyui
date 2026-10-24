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

  A file upload is `dropzone/1` (a LiveView upload, or a plain form's file
  input), with the picked files as attachment tiles under it.

      use ShadcnDaisyui.FormComponents
      # or: import ShadcnDaisyui.FormComponents
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  alias ShadcnDaisyui.Components.Display
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

    # assign/3, not Map.update!/3: only assign marks `checked` changed, so the
    # control follows the field's value when LiveView re-renders. An explicit
    # `checked` attr wins over the field.
    assigns =
      assigns
      |> assign(
        :checked,
        derive(assigns.checked, fn ->
          Phoenix.HTML.Form.normalize_value("checkbox", assigns.value)
        end)
      )
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
    <fieldset class={["radio-group grid gap-2", @class]}>
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

  @doc """
  A file picker people can also drop files on. For a LiveView upload, the zone
  is a `<label>` around the visually hidden `live_file_input/1`, so a click, a
  tap, Enter or Space opens the picker, and it is the upload's
  `phx-drop-target`. Picked files show under it as
  `ShadcnDaisyui.Components.Display.attachment/1` tiles.

      <.dropzone id="import-file" upload={@uploads.people_csv} on_cancel="import:cancel">
        <:title touch="Choose a CSV file">Drop a CSV file here, or choose one</:title>
        <:description>One .csv file, up to 1 MB.</:description>
      </.dropzone>

      def handle_event("import:cancel", %{"ref" => ref}, socket),
        do: {:noreply, cancel_upload(socket, :people_csv, ref)}

  Without the slots, the title is "Drop a file here, or choose one" ("Drop
  files here, or choose them" when `max_entries > 1`). On touch screens, where
  people can't drag, it reads "Choose a file". The description comes from the
  upload: its accepted types, size limit and how many files ("One .csv file,
  up to 1 MB."). `<:title touch="Choose a CSV file">` words your own title for
  touch screens.

  Each entry is a tile: uploading with its progress, done, or an error with
  the reason. `on_cancel` (an event or a `Phoenix.LiveView.JS`) adds a remove
  button that pushes `%{"ref" => entry.ref}` (`target` sends it to a
  LiveComponent). `<:entry :let={entry}>` renders your own instead. Errors
  for the whole upload (too many files) show under the zone, as do each
  file's errors with your own `<:entry>`. `error_text` (`fn error -> text
  end`; `nil` keeps the default) replaces the built-in English for
  `:too_large`, `:not_accepted`, `:too_many_files` and
  `:external_client_failure`.

  `size="compact"` is one `h-9` row shaped like an input ("Choose a file or
  drop it here"), for tight forms. `disabled` dims it and takes no picks or
  drops. The zone's title names the input; a field label outside it
  (`<.label for={@uploads.logo.ref}>Logo</.label>`) adds to the name.

  Outside LiveView (a plain multipart form), pass `name` instead of `upload`,
  with `accept` and `multiple`: a drop puts the files on the input (only the
  accepted ones) and the zone names the chosen files.

      <.dropzone id="logo" name="logo" accept=".png,.svg" size="compact" />

  Needs the `ShadcnDropzone` hook (or `initShadcnDaisyui()` in a dead view)
  for the drag highlight on every LiveView version and for plain-form drops.
  """
  attr(:id, :string, required: true)
  attr(:upload, Phoenix.LiveView.UploadConfig, default: nil, doc: "the upload: `@uploads.name`")
  attr(:name, :string, default: nil, doc: "a plain form's file input, instead of `upload`")

  attr(:accept, :any,
    default: nil,
    doc: "with `name`: the accepted types, a list or a comma-separated string"
  )

  attr(:multiple, :boolean, default: false, doc: "with `name`: take several files")
  attr(:size, :string, default: "default", values: ~w(default compact))
  attr(:disabled, :boolean, default: false)

  attr(:on_cancel, :any,
    default: nil,
    doc: "event (or JS) the remove button pushes with `%{\"ref\" => ref}`"
  )

  attr(:target, :any, default: nil, doc: "`phx-target` for `on_cancel`")
  attr(:error_text, :any, default: nil, doc: "`fn error -> text end`; `nil` keeps the default")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot :title do
    attr(:touch, :string, doc: "the title on touch screens, where people can't drag")
  end

  slot(:description)
  slot(:entry, doc: "renders each upload entry instead of the attachment tile (`:let={entry}`)")

  def dropzone(%{upload: nil, name: nil}) do
    raise ArgumentError, "<.dropzone> needs `upload` (a LiveView upload) or `name` (a plain form)"
  end

  def dropzone(assigns) do
    upload = assigns.upload
    multiple = if upload, do: upload.max_entries > 1, else: assigns.multiple
    entries = if upload, do: upload.entries, else: []
    {upload_messages, entry_errors} = dropzone_errors(upload, assigns.error_text)

    # With its own entries the app may not show their errors: list them here.
    zone_errors =
      upload_messages ++
        if assigns.entry == [],
          do: [],
          else:
            for(e <- entries, msg <- entry_errors[e.ref] || [], do: "#{e.client_name}: #{msg}")

    description =
      if assigns.description == [],
        do: dropzone_description(upload, assigns.accept, multiple)

    describedby =
      [
        (assigns.description != [] or description) && "#{assigns.id}-description",
        zone_errors != [] && "#{assigns.id}-errors"
        | if(assigns.entry == [],
            do: for(e <- entries, entry_errors[e.ref], do: "#{assigns.id}-#{e.ref}-error"),
            else: []
          )
      ]
      |> Enum.filter(& &1)
      |> Enum.join(" ")

    assigns =
      assigns
      |> assign(:multiple, multiple)
      |> assign(:entries, entries)
      |> assign(:entry_errors, entry_errors)
      |> assign(:zone_errors, zone_errors)
      |> assign(:invalid, zone_errors != [] or entry_errors != %{})
      |> assign(:derived_description, description)
      |> assign(:describedby, describedby)
      |> assign(:input_name, plain_input_name(assigns.name, multiple))
      |> assign(:accept_attr, accept_attr(assigns.accept))
      |> assign(:title_touch, Enum.find_value(assigns.title, & &1[:touch]))

    ~H"""
    <div
      id={@id}
      class={["dropzone", @class]}
      data-dropzone={if @upload, do: "upload", else: "plain"}
      data-size={@size}
      data-disabled={@disabled}
      data-invalid={@invalid}
      phx-hook="ShadcnDropzone"
      phx-mounted={!@upload && JS.ignore_attributes(["data-chosen"])}
      {@rest}
    >
      <label
        class="dropzone-area"
        data-dropzone-area
        phx-drop-target={@upload && !@disabled && @upload.ref}
        phx-mounted={JS.ignore_attributes(["data-dragging"])}
      >
        <.live_file_input
          :if={@upload}
          upload={@upload}
          class="dropzone-input"
          disabled={@disabled}
          aria-describedby={@describedby != "" && @describedby}
          aria-invalid={@invalid && "true"}
        />
        <input
          :if={!@upload}
          type="file"
          id={"#{@id}-input"}
          name={@input_name}
          accept={@accept_attr}
          multiple={@multiple}
          disabled={@disabled}
          class="dropzone-input"
          aria-describedby={@describedby != "" && @describedby}
        />
        <span class="dropzone-icon" aria-hidden="true"><span class="hero-arrow-up-tray"></span></span>
        <span id={"#{@id}-title"} class="dropzone-title">
          <%= if @title != [] do %>
            <span class={@title_touch && "dropzone-mouse"}>{render_slot(@title)}</span>
            <span :if={@title_touch} class="dropzone-touch">{@title_touch}</span>
          <% else %>
            <span class="dropzone-mouse">{dropzone_title(@size, @multiple)}</span>
            <span class="dropzone-touch">{if @multiple, do: "Choose files", else: "Choose a file"}</span>
          <% end %>
        </span>
        <span
          :if={@size == "default" and (@description != [] or @derived_description)}
          id={"#{@id}-description"}
          class="dropzone-description"
          aria-hidden="true"
        >
          {if @description != [], do: render_slot(@description), else: @derived_description}
        </span>
        <span
          :if={!@upload}
          id={"#{@id}-chosen"}
          class="dropzone-chosen"
          data-dropzone-chosen
          phx-update="ignore"
          hidden
        >
        </span>
      </label>
      <p
        :if={@size == "compact" and (@description != [] or @derived_description)}
        id={"#{@id}-description"}
        class="dropzone-description"
      >
        {if @description != [], do: render_slot(@description), else: @derived_description}
      </p>
      <div id={"#{@id}-errors"} class="dropzone-errors" aria-live="polite">
        <p :for={msg <- @zone_errors}>
          <span class="hero-exclamation-circle" aria-hidden="true"></span>{msg}
        </p>
      </div>
      <div :if={@entries != []} class="dropzone-entries" role="list" aria-label="Chosen files">
        <div :for={entry <- @entries} role="listitem">
          <%= if @entry != [] do %>
            {render_slot(@entry, entry)}
          <% else %>
            <.dropzone_entry
              id={@id}
              entry={entry}
              errors={@entry_errors[entry.ref]}
              on_cancel={@on_cancel}
              target={@target}
            />
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:entry, Phoenix.LiveView.UploadEntry, required: true)
  attr(:errors, :list, default: nil)
  attr(:on_cancel, :any, default: nil)
  attr(:target, :any, default: nil)

  defp dropzone_entry(assigns) do
    entry = assigns.entry

    state =
      cond do
        assigns.errors -> "error"
        entry.done? -> "done"
        entry.progress > 0 or entry.preflighted? -> "uploading"
        true -> "idle"
      end

    assigns =
      assigns
      |> assign(:state, state)
      |> assign(:image, String.starts_with?(entry.client_type || "", "image/"))
      |> assign(:file_size, format_size(entry.client_size))

    ~H"""
    <Display.attachment id={"#{@id}-#{@entry.ref}"} state={@state}>
      <:media variant={if @image and @state != "error", do: "image", else: "icon"}>
        <%= cond do %>
          <% @state == "error" -> %>
            <span class="hero-exclamation-triangle" aria-hidden="true"></span>
          <% @image -> %>
            <.live_img_preview entry={@entry} aria-hidden="true" />
          <% @state == "uploading" -> %>
            <span class="loading loading-spinner loading-sm" aria-hidden="true"></span>
          <% @state == "done" -> %>
            <span class="hero-check" aria-hidden="true"></span>
          <% true -> %>
            <span class="hero-document" aria-hidden="true"></span>
        <% end %>
      </:media>
      <:title>{@entry.client_name}</:title>
      <:description>
        <%= case @state do %>
          <% "error" -> %>
            <span id={"#{@id}-#{@entry.ref}-error"}>{Enum.join(@errors, " ")}</span>
          <% "uploading" -> %>
            Uploading · {@entry.progress}%
          <% "done" -> %>
            Uploaded{@file_size && " · #{@file_size}"}
          <% _ -> %>
            {@file_size}
        <% end %>
      </:description>
      <:actions :if={@on_cancel}>
        <Display.attachment_action
          label={"#{if @state == "uploading", do: "Cancel", else: "Remove"} #{@entry.client_name}"}
          phx-click={@on_cancel}
          phx-value-ref={@entry.ref}
          phx-target={@target}
        >
          <span class="hero-x-mark size-3.5" aria-hidden="true"></span>
        </Display.attachment_action>
      </:actions>
    </Display.attachment>
    """
  end

  # <.prompt_input>'s attached files: the dropzone's entry tiles, one list item
  # each (ShadcnDaisyui.Components.Conversation.prompt_input/1)
  @doc false
  attr(:id, :string, required: true)
  attr(:upload, Phoenix.LiveView.UploadConfig, required: true)
  attr(:on_cancel, :any, default: nil)
  attr(:target, :any, default: nil)
  attr(:error_text, :any, default: nil)

  def upload_tiles(assigns) do
    {_messages, entry_errors} = dropzone_errors(assigns.upload, assigns.error_text)
    assigns = assign(assigns, :entry_errors, entry_errors)

    ~H"""
    <div :for={entry <- @upload.entries} role="listitem">
      <.dropzone_entry
        id={@id}
        entry={entry}
        errors={@entry_errors[entry.ref]}
        on_cancel={@on_cancel}
        target={@target}
      />
    </div>
    """
  end

  # The upload's own errors (too many files) as text, for <.prompt_input>
  @doc false
  def upload_messages(upload, error_text \\ nil),
    do: upload |> dropzone_errors(error_text) |> elem(0)

  defp dropzone_title("compact", true), do: "Choose files or drop them here"
  defp dropzone_title("compact", false), do: "Choose a file or drop it here"
  defp dropzone_title(_, true), do: "Drop files here, or choose them"
  defp dropzone_title(_, false), do: "Drop a file here, or choose one"

  # "One .csv file, up to 1 MB." / "Up to 3 image files, 8 MB each."
  defp dropzone_description(%Phoenix.LiveView.UploadConfig{} = upload, _accept, _multiple) do
    noun = accept_noun(upload.accept)
    size = format_size(upload.max_file_size)

    if upload.max_entries == 1,
      do: "One #{noun}, up to #{size}.",
      else: "Up to #{upload.max_entries} #{noun}s, #{size} each."
  end

  # a plain form knows only its accept list (the server checks the size)
  defp dropzone_description(nil, accept, multiple) do
    if accept_labels(accept) != [] do
      if multiple, do: "One or more #{accept_noun(accept)}s.", else: "One #{accept_noun(accept)}."
    end
  end

  # {the upload's own messages, %{entry ref => its messages}}
  defp dropzone_errors(nil, _error_text), do: {[], %{}}

  defp dropzone_errors(%Phoenix.LiveView.UploadConfig{} = upload, error_text) do
    message = fn error ->
      (is_function(error_text, 1) && error_text.(error)) || default_upload_error(error, upload)
    end

    entry_errors =
      for entry <- upload.entries,
          errors = upload_errors(upload, entry),
          errors != [],
          into: %{},
          do: {entry.ref, Enum.map(errors, message)}

    {Enum.map(upload_errors(upload), message), entry_errors}
  end

  defp default_upload_error(:too_large, upload),
    do: "File is larger than #{format_size(upload.max_file_size)}."

  defp default_upload_error(:not_accepted, upload) do
    case accept_labels(upload.accept) do
      [] -> "This file type isn't accepted."
      labels -> "Only #{join_or(labels)} files are accepted."
    end
  end

  defp default_upload_error(:too_many_files, %{max_entries: 1}), do: "Too many files. Choose one."

  defp default_upload_error(:too_many_files, upload),
    do: "Too many files. Choose up to #{upload.max_entries}."

  defp default_upload_error(:external_client_failure, _), do: "The upload failed. Try again."
  defp default_upload_error(_, _), do: "The upload failed."

  defp accept_noun(accept) do
    case accept_labels(accept) do
      [] -> "file"
      labels -> "#{join_or(labels)} file"
    end
  end

  # ".csv" stays, "image/*" reads "image", "text/csv" ".csv", "image/svg+xml" ".svg"
  defp accept_labels(accept) when accept in [nil, :any, ""], do: []

  defp accept_labels(accept) when is_binary(accept),
    do: accept |> String.split(",") |> accept_labels()

  defp accept_labels(accept) when is_list(accept) do
    accept
    |> Enum.map(&(&1 |> to_string() |> String.trim() |> String.downcase()))
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(fn
      "." <> _ = ext ->
        ext

      type ->
        case String.split(type, "/") do
          [major, "*"] -> major
          [_, sub] -> sub |> String.split("+") |> hd() |> simple_ext(type)
          _ -> type
        end
    end)
    |> Enum.uniq()
  end

  defp simple_ext(sub, type), do: if(sub =~ ~r/^[a-z0-9]+$/, do: "." <> sub, else: type)

  defp join_or([one]), do: one
  defp join_or(list), do: Enum.join(Enum.drop(list, -1), ", ") <> " or " <> List.last(list)

  defp accept_attr(accept) when is_list(accept), do: Enum.join(accept, ",")
  defp accept_attr(accept), do: accept

  defp plain_input_name(nil, _), do: nil

  defp plain_input_name(name, true),
    do: if(String.ends_with?(name, "[]"), do: name, else: name <> "[]")

  defp plain_input_name(name, false), do: name

  # 1_000_000 and 1_048_576 both read "1 MB"
  defp format_size(nil), do: nil

  defp format_size(bytes) when bytes >= 1_000_000_000,
    do: scaled(bytes, 1_000_000_000, 1_073_741_824, "GB")

  defp format_size(bytes) when bytes >= 1_000_000, do: scaled(bytes, 1_000_000, 1_048_576, "MB")
  defp format_size(bytes) when bytes >= 1_000, do: scaled(bytes, 1_000, 1_024, "KB")
  defp format_size(bytes), do: "#{bytes} bytes"

  defp scaled(bytes, decimal, binary, unit) do
    cond do
      rem(bytes, binary) == 0 -> "#{div(bytes, binary)} #{unit}"
      rem(bytes, decimal) == 0 -> "#{div(bytes, decimal)} #{unit}"
      true -> "#{bytes |> Kernel./(decimal) |> Float.round(1) |> trim_zero()} #{unit}"
    end
  end

  defp trim_zero(float) when float == trunc(float), do: Integer.to_string(trunc(float))
  defp trim_zero(float), do: Float.to_string(float)

  # Derives id/name/value/errors from a FormField; explicit attrs win. Every
  # derived assign goes through assign/3 so LiveView's change tracking sees it:
  # Map.update!/3 would leave it unmarked and the control would keep its
  # first-render state on every re-render.
  defp apply_field(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    name = if assigns[:multiple], do: field.name <> "[]", else: field.name

    assigns
    |> assign(:field, nil)
    |> assign(:errors, field_errors(field))
    |> assign(:id, derive(assigns.id, fn -> field.id end))
    |> assign(:name, derive(assigns.name, fn -> name end))
    |> assign(:value, derive(assigns.value, fn -> field.value end))
  end

  defp apply_field(assigns), do: assign_new(assigns, :errors, fn -> [] end)

  defp derive(nil, fun), do: fun.()
  defp derive(given, _fun), do: given

  defp field_errors(%Phoenix.HTML.FormField{} = field) do
    if Phoenix.Component.used_input?(field) do
      Enum.map(field.errors, &ShadcnDaisyui.Translate.translate_error/1)
    else
      []
    end
  end
end

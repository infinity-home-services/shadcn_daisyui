defmodule ShadcnDaisyuiDemoWeb.Catalog.Spec do
  @moduledoc """
  The validated schema for a single component-catalog entry.

  Every component in `ShadcnDaisyuiDemoWeb.Catalog` is built through
  `Spec.new!/1`, which turns a plain data map into a `%Spec{}` and runs
  `validate!/1`. This is the "bulletproof editing" guarantee: a missing required
  field, an unknown/typo'd key, or a malformed `guidance`/`props`/`examples`
  shape raises loudly (named by slug) instead of silently rendering a broken
  page. The catalog test suite exercises `new!/1` for all 77 components, so any
  drift fails CI.

  ## Fields

  Required: `slug`, `title`, `description`, `examples`.

  Optional (current): `guidance`, `props`, `hook`, `notes`.

  Optional (Phase 2 — Accessibility + Specs + native parity, nil until
  backfilled): `specs`, `accessibility`, `swiftui`, `ios_status`. They are
  defined here now so the schema, templates, and markdown export have a stable
  shape to grow into; `validate!/1` only checks them when present.

  A `%Spec{}` is a struct (hence a map), so existing call sites that read it with
  `Map.get/2,3` or dot-access (the page template and `Markdown`) keep working
  unchanged.
  """

  @enforce_keys [:slug, :title, :description, :examples]
  defstruct slug: nil,
            title: nil,
            description: nil,
            examples: [],
            guidance: nil,
            props: [],
            hook: false,
            notes: nil,
            # Phase 2 — populated during the depth backfill.
            specs: nil,
            accessibility: nil,
            swiftui: nil,
            ios_status: nil,
            # Phase 3 — visual polish (optional, curated set).
            do_dont: nil

  @type t :: %__MODULE__{}

  @guidance_keys [:use_when, :avoid_when, :sizing, :responsive, :ios]
  @ios_statuses [:parity, :partial, :guidance_only]

  @doc """
  Build a validated `%Spec{}` from a plain data map (or pass an existing struct
  through validation).

  Raises `ArgumentError` with the offending slug if a key is unknown or a
  required key is missing, then runs `validate!/1`.
  """
  def new!(%__MODULE__{} = spec), do: validate!(spec)

  def new!(attrs) when is_map(attrs) do
    spec =
      try do
        struct!(__MODULE__, attrs)
      rescue
        e in [KeyError, ArgumentError] ->
          reraise ArgumentError,
                  "invalid component spec #{inspect(Map.get(attrs, :slug))}: #{Exception.message(e)}",
                  __STACKTRACE__
      end

    validate!(spec)
  end

  @doc """
  Validate a `%Spec{}`, returning it unchanged on success or raising
  `ArgumentError` describing the first problem (prefixed with the slug).
  """
  def validate!(%__MODULE__{} = spec) do
    ctx = "component #{inspect(spec.slug)}"

    check!(present_string?(spec.slug), "#{ctx}: slug must be a non-empty string")
    check!(present_string?(spec.title), "#{ctx}: title must be a non-empty string")
    check!(present_string?(spec.description), "#{ctx}: description must be a non-empty string")
    check!(is_list(spec.examples) and spec.examples != [], "#{ctx}: needs at least one example")

    Enum.each(spec.examples, &validate_example!(&1, ctx))
    validate_guidance!(spec.guidance, ctx)
    validate_props!(spec.props, ctx)
    check!(is_boolean(spec.hook), "#{ctx}: hook must be a boolean")
    validate_specs!(spec.specs, ctx)
    validate_accessibility!(spec.accessibility, ctx)
    validate_swiftui!(spec.swiftui, ctx)
    validate_ios_status!(spec.ios_status, ctx)
    validate_do_dont!(spec.do_dont, ctx)

    spec
  end

  # --- examples ---------------------------------------------------------------

  defp validate_example!(example, ctx) when is_map(example) do
    title = Map.get(example, :title)
    check!(present_string?(title), "#{ctx}: every example needs a non-empty :title")

    code = Map.get(example, :code)
    check!(present_string?(code), "#{ctx}: example #{inspect(title)} needs non-empty :code")

    case Map.get(example, :heex) do
      nil -> :ok
      heex -> check!(is_binary(heex), "#{ctx}: example #{inspect(title)} :heex must be a string")
    end

    case Map.get(example, :center) do
      nil -> :ok
      c -> check!(is_boolean(c), "#{ctx}: example #{inspect(title)} :center must be a boolean")
    end
  end

  defp validate_example!(_other, ctx), do: check!(false, "#{ctx}: each example must be a map")

  # --- guidance ---------------------------------------------------------------

  defp validate_guidance!(nil, _ctx), do: :ok

  defp validate_guidance!(guidance, ctx) when is_map(guidance) do
    unknown = Map.keys(guidance) -- @guidance_keys

    check!(
      unknown == [],
      "#{ctx}: unknown guidance key(s) #{inspect(unknown)}; allowed: #{inspect(@guidance_keys)}"
    )

    for key <- [:use_when, :avoid_when], items = guidance[key], not is_nil(items) do
      check!(
        is_list(items) and Enum.all?(items, &is_binary/1),
        "#{ctx}: guidance.#{key} must be a list of strings"
      )
    end

    for key <- [:sizing, :responsive, :ios], val = guidance[key], not is_nil(val) do
      check!(is_binary(val), "#{ctx}: guidance.#{key} must be a string")
    end

    :ok
  end

  defp validate_guidance!(_other, ctx),
    do: check!(false, "#{ctx}: guidance must be a map")

  # --- props ------------------------------------------------------------------

  defp validate_props!(props, ctx) when is_list(props) do
    Enum.each(props, fn prop ->
      check!(is_map(prop), "#{ctx}: each prop must be a map")
      check!(present_string?(Map.get(prop, :name)), "#{ctx}: every prop needs a :name")

      check!(
        present_string?(Map.get(prop, :type)),
        "#{ctx}: prop #{Map.get(prop, :name)} needs a :type"
      )
    end)
  end

  defp validate_props!(nil, _ctx), do: :ok
  defp validate_props!(_other, ctx), do: check!(false, "#{ctx}: props must be a list")

  # --- specs (anatomy + measurements + tokens) --------------------------------

  @spec_keys [:anatomy, :measurements, :tokens, :anatomy_svg]

  defp validate_specs!(nil, _ctx), do: :ok

  defp validate_specs!(specs, ctx) when is_map(specs) do
    reject_unknown_keys!(specs, @spec_keys, "specs", ctx)

    if anatomy = specs[:anatomy] do
      validate_map_list!(anatomy, [:part, :description], "specs.anatomy", ctx)
    end

    if measurements = specs[:measurements] do
      validate_map_list!(measurements, [:property, :value], "specs.measurements", ctx)
    end

    if tokens = specs[:tokens] do
      check!(
        is_list(tokens) and Enum.all?(tokens, &is_binary/1),
        "#{ctx}: specs.tokens must be a list of token-name strings"
      )
    end

    if svg = specs[:anatomy_svg] do
      check!(is_binary(svg), "#{ctx}: specs.anatomy_svg must be an SVG string")
    end

    :ok
  end

  defp validate_specs!(_other, ctx), do: check!(false, "#{ctx}: specs must be a map")

  # --- accessibility ----------------------------------------------------------

  @accessibility_keys [:roles, :keyboard, :focus, :screen_reader, :touch_target, :reduced_motion]

  defp validate_accessibility!(nil, _ctx), do: :ok

  defp validate_accessibility!(a11y, ctx) when is_map(a11y) do
    reject_unknown_keys!(a11y, @accessibility_keys, "accessibility", ctx)

    if keyboard = a11y[:keyboard] do
      validate_map_list!(keyboard, [:keys, :action], "accessibility.keyboard", ctx)
    end

    for key <- [:roles, :focus, :screen_reader, :touch_target, :reduced_motion],
        val = a11y[key],
        not is_nil(val) do
      check!(is_binary(val), "#{ctx}: accessibility.#{key} must be a string")
    end

    :ok
  end

  defp validate_accessibility!(_other, ctx),
    do: check!(false, "#{ctx}: accessibility must be a map")

  # --- native parity ----------------------------------------------------------

  @swiftui_keys [:code, :notes]

  defp validate_swiftui!(nil, _ctx), do: :ok

  defp validate_swiftui!(swiftui, ctx) when is_map(swiftui) do
    reject_unknown_keys!(swiftui, @swiftui_keys, "swiftui", ctx)
    check!(present_string?(swiftui[:code]), "#{ctx}: swiftui.code must be a non-empty string")

    if notes = swiftui[:notes] do
      check!(is_binary(notes), "#{ctx}: swiftui.notes must be a string")
    end

    :ok
  end

  defp validate_swiftui!(_other, ctx), do: check!(false, "#{ctx}: swiftui must be a map")

  # --- do / don't visual pairs ------------------------------------------------

  @do_dont_keys [:do, :dont]

  defp validate_do_dont!(nil, _ctx), do: :ok

  defp validate_do_dont!(do_dont, ctx) when is_map(do_dont) do
    reject_unknown_keys!(do_dont, @do_dont_keys, "do_dont", ctx)
    check!(is_map(do_dont[:do]), "#{ctx}: do_dont.do must be a map with :label and :code")
    check!(is_map(do_dont[:dont]), "#{ctx}: do_dont.dont must be a map with :label and :code")

    for side <- [:do, :dont], entry = do_dont[side] do
      check!(present_string?(entry[:label]), "#{ctx}: do_dont.#{side} needs a :label")
      check!(present_string?(entry[:code]), "#{ctx}: do_dont.#{side} needs :code")
    end

    :ok
  end

  defp validate_do_dont!(_other, ctx), do: check!(false, "#{ctx}: do_dont must be a map")

  defp validate_ios_status!(nil, _ctx), do: :ok

  defp validate_ios_status!(status, ctx) do
    check!(
      status in @ios_statuses,
      "#{ctx}: ios_status must be one of #{inspect(@ios_statuses)}, got #{inspect(status)}"
    )
  end

  # --- helpers ----------------------------------------------------------------

  defp present_string?(value), do: is_binary(value) and String.trim(value) != ""

  defp reject_unknown_keys!(map, allowed, label, ctx) do
    unknown = Map.keys(map) -- allowed

    check!(
      unknown == [],
      "#{ctx}: unknown #{label} key(s) #{inspect(unknown)}; allowed: #{inspect(allowed)}"
    )
  end

  # Validate a list of maps where each map must carry the given non-empty string keys.
  defp validate_map_list!(list, required_keys, label, ctx) do
    check!(is_list(list), "#{ctx}: #{label} must be a list")

    Enum.each(list, fn entry ->
      check!(is_map(entry), "#{ctx}: each #{label} entry must be a map")

      Enum.each(required_keys, fn key ->
        check!(
          present_string?(Map.get(entry, key)),
          "#{ctx}: every #{label} entry needs a non-empty :#{key}"
        )
      end)
    end)
  end

  defp check!(true, _message), do: :ok
  defp check!(false, message), do: raise(ArgumentError, message)
end

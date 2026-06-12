defmodule ShadcnDaisyuiDemoWeb.TokensTest do
  @moduledoc """
  Agreement test for the token single-source-of-truth: `priv/tokens.json` must
  match the values declared in `priv/static/shadcn-daisyui.css`. If a color token
  is changed in the CSS without updating the JSON (or vice versa), this fails -
  so the Tokens reference page, per-component Specs, and the Swift sync can all
  trust the JSON.
  """
  use ExUnit.Case, async: true

  # priv/ lives at the package root, one level above the demo app (cwd in tests).
  @package_root Path.expand("..", File.cwd!())
  @tokens_json Path.join(@package_root, "priv/tokens.json")
  @theme_css Path.join(@package_root, "priv/static/shadcn-daisyui.css")

  setup_all do
    tokens = @tokens_json |> File.read!() |> Jason.decode!() |> Map.fetch!("tokens")
    css = File.read!(@theme_css)

    %{
      tokens: tokens,
      light: css_vars(css, ~s([data-theme="shadcn"])),
      dark: css_vars(css, ~s([data-theme="shadcn-dark"]))
    }
  end

  test "tokens.json is non-empty and well-formed", %{tokens: tokens} do
    assert length(tokens) > 0

    for t <- tokens do
      for key <- ["name", "label", "group", "light", "dark"] do
        assert is_binary(t[key]) and t[key] != "", "token #{inspect(t["name"])} missing #{key}"
      end
    end
  end

  test "token names are unique", %{tokens: tokens} do
    names = Enum.map(tokens, & &1["name"])
    assert names == Enum.uniq(names)
  end

  test "grouped/0 buckets every token (none dropped by an unlisted group)", %{tokens: tokens} do
    grouped = ShadcnDaisyuiDemoWeb.Catalog.Tokens.grouped()
    grouped_names = grouped |> Enum.flat_map(& &1.tokens) |> Enum.map(& &1["name"]) |> Enum.sort()
    assert grouped_names == tokens |> Enum.map(& &1["name"]) |> Enum.sort()
  end

  test "every specs.tokens reference in the catalog is a real token", %{tokens: tokens} do
    known = MapSet.new(tokens, & &1["name"])

    for {slug, spec} <- ShadcnDaisyuiDemoWeb.Catalog.components(),
        specs = spec.specs,
        is_map(specs),
        token <- specs[:tokens] || [] do
      assert MapSet.member?(known, token),
             "#{slug} specs.tokens lists #{inspect(token)}, which is not a token in tokens.json"
    end
  end

  test "every JSON token matches the CSS light value", %{tokens: tokens, light: light} do
    for t <- tokens do
      assert Map.has_key?(light, t["name"]),
             "tokens.json lists --#{t["name"]} but the CSS light theme does not declare it"

      assert light[t["name"]] == t["light"],
             "--#{t["name"]} light: CSS has #{inspect(light[t["name"]])}, tokens.json has #{inspect(t["light"])}"
    end
  end

  test "every JSON token matches the CSS dark value", %{tokens: tokens, dark: dark} do
    for t <- tokens do
      assert Map.has_key?(dark, t["name"]),
             "tokens.json lists --#{t["name"]} but the CSS dark theme does not declare it"

      assert dark[t["name"]] == t["dark"],
             "--#{t["name"]} dark: CSS has #{inspect(dark[t["name"]])}, tokens.json has #{inspect(t["dark"])}"
    end
  end

  # Pull the `--name: value;` declarations from the first CSS rule block whose
  # selector list contains `selector`. The light/dark token blocks have no nested
  # braces, so splitting on "}" isolates each rule cleanly. `shadcn` matches the
  # light block first (it appears before `shadcn-dark` in source order).
  defp css_vars(css, selector) do
    css
    |> String.split("}")
    |> Enum.find(&String.contains?(&1, selector))
    |> case do
      nil ->
        flunk("no CSS block found for selector #{selector}")

      block ->
        ~r/--([a-z0-9-]+):\s*([^;]+);/
        |> Regex.scan(block)
        |> Map.new(fn [_, name, value] -> {name, String.trim(value)} end)
    end
  end
end

defmodule ShadcnDaisyuiDemoWeb.Catalog.Tokens do
  @moduledoc """
  Reads `priv/tokens.json` from the package - the color-token single source of
  truth - for the docs Tokens reference page. The JSON is kept in agreement with
  the theme CSS by `tokens_test.exs`.
  """

  # Display order + human labels for the token groups in tokens.json.
  @groups [
    {"surface", "Surfaces"},
    {"content", "Content / foreground"},
    {"brand", "Brand"},
    {"muted", "Muted"},
    {"status", "Status"},
    {"line", "Borders & rings"},
    {"chart", "Charts"}
  ]

  @doc "The raw token list from tokens.json."
  def all do
    path()
    |> File.read!()
    |> Jason.decode!()
    |> Map.fetch!("tokens")
  end

  @doc "Tokens bucketed into display groups: a list of %{key, label, tokens}."
  def grouped do
    by_group = Enum.group_by(all(), & &1["group"])

    for {key, label} <- @groups, tokens = by_group[key], is_list(tokens) do
      %{key: key, label: label, tokens: tokens}
    end
  end

  defp path do
    Path.join(:code.priv_dir(:shadcn_daisyui), "tokens.json")
  end
end

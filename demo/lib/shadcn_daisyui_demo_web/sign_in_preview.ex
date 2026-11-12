defmodule ShadcnDaisyuiDemoWeb.SignInPreview do
  @moduledoc """
  The pretend app's sign-in page in every state, shown in the iframes on
  /docs/sign-in: one static page per state, so the static export can serve
  every one.
  """
  use ShadcnDaisyuiDemoWeb, :verified_routes

  @app %{
    app_name: "Atlas",
    org: "Acme Inc.",
    tagline: "Sales and service reporting for every Acme store.",
    image: "/images/sign-in-background.svg"
  }

  # {slug, title, what the page gets}
  @states [
    {"signed-out", "Signed out", %{}},
    {"just-signed-out", "Just signed out", %{notice: "signed_out"}},
    {"not-set-up", "Microsoft sign-in isn't set up", %{configured: false}},
    {"unavailable", "Microsoft can't be reached", %{notice: "unavailable"}},
    {"no-access", "No access", %{notice: "no_access"}},
    {"ended", "Access ended", %{notice: "ended"}},
    {"canceled", "Microsoft didn't complete it", %{notice: "canceled"}},
    {"failed", "The sign-in didn't complete", %{notice: "failed"}},
    {"development", "Development sign-in", %{development: true}}
  ]

  @doc "The pretend app's name, organisation, tagline and picture."
  def app, do: @app

  @doc "Every state, in order: `%{slug, title, notice, configured, development}`."
  def states do
    for {slug, title, opts} <- @states do
      Map.merge(
        %{slug: slug, title: title, notice: nil, configured: true, development: false},
        Map.put(opts, :slug, slug) |> Map.put(:title, title)
      )
    end
  end

  @doc "The state with this slug, or nil."
  def state(slug), do: Enum.find(states(), &(&1.slug == slug))

  @doc "Every preview page's slug, for the static export."
  def pages, do: Enum.map(states(), & &1.slug)

  @doc "The preview page's address."
  def path(slug), do: ~p"/docs/sign-in/preview/#{slug}"

  @doc "The development sign-in's role buttons, by group."
  def development_roles do
    [
      {"Company", ["Admin", "Finance"]},
      {"Brand", ["Brand admin", "Sales manager", "Advisor", "Installer"]}
    ]
  end

  @doc "The people the development sign-in can sign in as."
  def development_people do
    [{"Pat Lee · Admin", "1"}, {"Sam Rivera · Advisor", "2"}, {"Alex Chen · Sales manager", "3"}]
  end
end

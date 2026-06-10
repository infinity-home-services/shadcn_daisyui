defmodule ShadcnDaisyui.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/N00nDay/shadcn_daisyui"

  def project do
    [
      app: :shadcn_daisyui,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description:
        "A daisyUI v5 theme plus Phoenix components and JS hooks that make daisyUI look and " <>
          "behave like shadcn/ui (neutral palette, light + dark).",
      package: package(),
      docs: docs(),
      name: "ShadcnDaisyui",
      source_url: @source_url
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:phoenix_live_view, ">= 0.20.0"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Craig Howell"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      # ship the components (lib) and the css/js assets (priv/static)
      files: ~w(lib priv .formatter.exs mix.exs README.md LICENSE)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_url: @source_url,
      source_ref: "v#{@version}"
    ]
  end
end

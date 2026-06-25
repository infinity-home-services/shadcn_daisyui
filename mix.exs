defmodule ShadcnDaisyui.MixProject do
  use Mix.Project

  @version "0.3.0"
  @source_url "https://github.com/infinity-home-services/shadcn_daisyui"

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
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_html, "~> 4.1"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Craig Howell"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      # ship the components (lib), the css/js assets (priv/static), the npm entry
      # point (package.json) and the AI usage rules
      files: ~w(lib priv .formatter.exs mix.exs package.json README.md LICENSE CHANGELOG.md
           usage-rules.md usage-rules)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md",
        "CHANGELOG.md",
        "usage-rules.md",
        "usage-rules/forms.md",
        "usage-rules/theming.md",
        "usage-rules/foundations-platforms.md",
        "usage-rules/foundations-accessibility.md",
        "usage-rules/foundations-layout.md",
        "usage-rules/foundations-spacing.md",
        "usage-rules/foundations-navigation.md",
        "usage-rules/foundations-interaction.md",
        "usage-rules/styles-color.md",
        "usage-rules/styles-typography.md",
        "usage-rules/styles-shape-elevation.md",
        "usage-rules/styles-motion.md"
      ],
      groups_for_extras: [
        Guides: ["usage-rules.md", "usage-rules/forms.md", "usage-rules/theming.md"],
        Foundations: ~r"usage-rules/foundations-.*",
        Styles: ~r"usage-rules/styles-.*"
      ],
      source_url: @source_url,
      source_ref: "v#{@version}"
    ]
  end
end

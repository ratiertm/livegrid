defmodule LiveviewGrid.MixProject do
  use Mix.Project

  @version "0.7.0"

  def project do
    [
      app: :liveview_grid,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),

      # Docs
      name: "LiveView Grid",
      source_url: "https://github.com/liveview-grid/liveview_grid",
      docs: docs()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {LiveviewGrid.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7.12"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.20.2"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:bandit, "~> 1.2"},
      {:elixlsx, "~> 0.6"},
      # DBMS Integration (v0.3)
      {:ecto_sql, "~> 3.11"},
      {:ecto_sqlite3, "~> 0.17"},
      # REST API Integration (v0.5)
      {:req, "~> 0.5"},
      # Documentation
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "getting-started",
      extras: [
        "README.md",
        "guides/getting-started.md",
        "guides/formatters.md",
        "guides/data-sources.md",
        "guides/advanced-features.md",
        "guides/getting-started-en.md",
        "guides/formatters-en.md",
        "guides/data-sources-en.md",
        "guides/advanced-features-en.md"
      ],
      groups_for_extras: [
        "Guides (한국어)": [
          "guides/getting-started.md",
          "guides/formatters.md",
          "guides/data-sources.md",
          "guides/advanced-features.md"
        ],
        "Guides (English)": [
          "guides/getting-started-en.md",
          "guides/formatters-en.md",
          "guides/data-sources-en.md",
          "guides/advanced-features-en.md"
        ]
      ],
      groups_for_modules: [
        "Core": [
          LiveViewGrid,
          LiveViewGrid.Grid,
          LiveViewGrid.Formatter,
          LiveViewGrid.Renderers,
          LiveViewGrid.Export
        ],
        "Operations": [
          LiveViewGrid.Filter,
          LiveViewGrid.Sorting,
          LiveViewGrid.Pagination,
          LiveViewGrid.Grouping,
          LiveViewGrid.Tree,
          LiveViewGrid.Pivot
        ],
        "Data Sources": [
          LiveViewGrid.DataSource,
          LiveViewGrid.DataSource.InMemory,
          LiveViewGrid.DataSource.Ecto,
          LiveViewGrid.DataSource.Ecto.QueryBuilder,
          LiveViewGrid.DataSource.REST
        ],
        "Web Components": [
          LiveviewGridWeb.GridComponent
        ],
        "API & Auth": [
          LiveviewGrid.ApiKey,
          LiveviewGrid.ApiKeys
        ]
      ]
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "assets.setup", "assets.build"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind liveview_grid", "esbuild liveview_grid"],
      "assets.deploy": [
        "tailwind liveview_grid --minify",
        "esbuild liveview_grid --minify",
        "phx.digest"
      ]
    ]
  end
end

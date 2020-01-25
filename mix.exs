defmodule Validatex.MixProject do
  use Mix.Project

  @version "0.3.0"

  def project do
    [
      app: :validatex,
      dialyzer: dialyzer_base(),
      version: @version,
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      description: "An Elixir validation library for live view forms.",
      deps: deps(),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      source_url: "https://github.com/iodevs/validatex",
      name: "Validatex",
      docs: docs(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:result, "~> 1.5"},
      {:ex_maybe, "~> 1.1"},
      {:ex_doc, "~> 0.21", only: :dev},
      {:credo, "~> 1.1", only: [:dev, :test]},
      {:excoveralls, "~> 0.12.2", only: :test},
      {:dialyxir, "~> 0.5", only: [:dev, :test], runtime: false},
      {:propcheck, "~> 1.2", only: :test}
    ]
  end

  defp package do
    [
      maintainers: [
        "Jindrich K. Smitka <smitka.j@gmail.com>",
        "Ondrej Tucek <ondrej.tucek@gmail.com>"
      ],
      licenses: ["BSD-4-Clause"],
      links: %{
        "GitHub" => "https://github.com/iodevs/validatex"
      }
    ]
  end

  defp aliases() do
    [
      docs: ["docs", &copy_assets/1]
    ]
  end

  defp dialyzer_base() do
    [
      plt_add_apps: [:mix],
      plt_add_deps: :transitive,
      ignore_warnings: "dialyzer.ignore-warnings",
      flags: [
        :unmatched_returns,
        :error_handling,
        :race_conditions,
        :no_opaque
      ]
    ]
  end

  defp docs() do
    [
      source_ref: "v#{@version}",
      canonical: "https://hexdocs.pm/validatex",
      main: "readme",
      extras: ["README.md"],
      groups_for_extras: [
        Introduction: ~r/README.md/
      ]
    ]
  end

  defp copy_assets(_) do
    File.mkdir_p!("doc/docs")
    File.cp_r!("docs", "doc/docs")
  end
end

defmodule Validatex.MixProject do
  use Mix.Project

  def project do
    [
      app: :validatex,
      dialyzer: [
        plt_add_apps: [:mix],
        plt_add_deps: :transitive,
        ignore_warnings: "dialyzer.ignore-warnings",
        flags: [
          :unmatched_returns,
          :error_handling,
          :race_conditions,
          :no_opaque
        ]
      ],
      version: "0.1.0",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
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
      # {:ex_doc, "~> 0.21", only: :dev},
      {:credo, "~> 1.1", only: [:dev, :test]},
      {:excoveralls, "~> 0.11", only: :test},
      {:dialyxir, "~> 0.5", only: [:dev, :test], runtime: false}
    ]
  end

end

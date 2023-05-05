defmodule BlackjackCli.MixProject do
  use Mix.Project

  def project do
    [
      app: :blackjack_cli,
      version: "0.1.0",
      elixir: "~> 1.14.4",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {BlackjackCli.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_machina, "~> 2.7.0", only: :test},
      {:mox, "~> 1.0", only: :test},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      # {:gun, git: "https://github.com/ninenines/gun", ref: "f917599"},
      {:gun, "~> 2.0.0"},
      # {:cowlib, git: "https://github.com/ninenines/cowlib", ref: "2.11.0"},
      {:cowlib, "~> 2.12.0"},
      {:dotenvy, "~> 0.3.0"},
      {:jose, "~> 1.11.2"},
      {:jason, "~> 1.3"},
      {:ratatouille, "~> 0.5.1"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end

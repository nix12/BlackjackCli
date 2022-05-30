defmodule BlackjackCli.MixProject do
  use Mix.Project

  def project do
    [
      app: :blackjack_cli,
      version: "0.1.0",
      elixir: "~> 1.13.4",
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
      {:gun, "~> 1.3.3"},
      {:cowlib, "~> 2.7"},
      {:dotenvy, "~> 0.3.0"},
      {:jason, "~> 1.3"},
      {:libcluster, " ~> 3.3.1"},
      {:ratatouille, "~> 0.5.1"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end

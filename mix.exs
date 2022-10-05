defmodule Luminous.MixProject do
  use Mix.Project

  def project do
    [
      app: :luminous,
      version: "0.1.0",
      elixir: ">= 1.12.0",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:prod), do: ["lib"]
  defp elixirc_paths(_), do: ["lib", "dev", "test/support"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # production dependencies
      {:decimal, "~> 2.0"},
      {:jason, "~> 1.2"},
      {:phoenix_live_view, "~> 0.17.0"},
      {:tzdata, "~> 1.1"},

      # dev & test dependencies
      {:tailwind, "~> 0.1.8", runtime: Mix.env() == :dev},
      {:esbuild, "~> 0.5", runtime: Mix.env() == :dev},
      {:plug_cowboy, "~> 2.0", only: :dev},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:floki, ">= 0.30.0", only: :test}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "cmd --cd assets npm install"],
      dev: "run --no-halt dev/run.exs",
      "assets.build": ["esbuild dist"]
    ]
  end

  defp package do
    [
      maintainers: ["Kyriakos Kentzoglanakis", "Thanasis Karetsos"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/elinverd/luminous"},
      files: ~w(dist lib mix.exs README.md)
    ]
  end
end

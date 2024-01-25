defmodule Luminous.MixProject do
  use Mix.Project

  def project do
    [
      app: :luminous,
      version: "2.1.0",
      elixir: ">= 1.12.0",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      package: package(),
      description: description(),
      # Docs
      name: "luminous",
      source_url: "https://github.com/elinverd/luminous",
      homepage_url: "https://github.com/elinverd/luminous",
      docs: [
        # The main page in the docs
        main: "Luminous",
        extras: ["README.md", "docs/Applying custom CSS.md"],
        # `Elixir.Luminous.Router.Helpers` is an auto-generated module and we cannot
        # exclude it with `@moduledoc false`. Therefore, we use the following option.
        # https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html#module-configuration
        filter_modules: &filter_modules_for_ex_doc/2
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
  defp elixirc_paths(:prod), do: ["lib"]
  defp elixirc_paths(:dev), do: ["lib", "env"]
  defp elixirc_paths(:test), do: ["lib", "env", "test/support"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # production dependencies
      {:decimal, "~> 2.0"},
      {:jason, "~> 1.2"},
      {:nimble_options, "~> 1.0"},
      {:phoenix_live_view, ">= 0.20.2"},
      {:phoenix_view, "~> 2.0"},
      {:tzdata, "~> 1.1"},

      # dev & test dependencies
      {:tailwind, "~> 0.2", only: [:dev, :test]},
      {:esbuild, "~> 0.8", only: [:dev, :test]},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:plug_cowboy, "~> 2.0", only: :dev},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:floki, ">= 0.30.0", only: :test},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "cmd --cd assets npm install"],
      run: "run --no-halt env/run.exs",
      install: ["tailwind.install", "esbuild.install"],
      "assets.build": ["tailwind dist", "esbuild dist"]
    ]
  end

  defp package do
    [
      maintainers: ["Kyriakos Kentzoglanakis", "Thanasis Karetsos"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/elinverd/luminous"},
      files: ~w(dist lib mix.exs package.json README.md)
    ]
  end

  defp description do
    "A dashboard framework for Phoenix Live View"
  end

  defp filter_modules_for_ex_doc(module, _metadata) do
    module != Luminous.Router.Helpers
  end
end

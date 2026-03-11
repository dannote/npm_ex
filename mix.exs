defmodule NPM.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/dannote/npm"

  def project do
    [
      app: :npm,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      dialyzer: [plt_add_apps: [:mix, :inets, :ssl, :public_key, :crypto]],
      name: "NPM",
      description:
        "npm package manager for Elixir — resolve, fetch, and manage npm dependencies with Mix tasks.",
      source_url: @source_url,
      homepage_url: @source_url,
      package: package(),
      docs: docs()
    ]
  end

  def application do
    [extra_applications: [:inets, :ssl, :public_key, :crypto]]
  end

  defp aliases do
    [
      lint: [
        "format --check-formatted",
        "credo --strict",
        "dialyzer"
      ],
      ci: ["lint", "cmd MIX_ENV=test mix test"]
    ]
  end

  defp deps do
    [
      {:npm_semver, "~> 0.1.0"},
      {:hex_solver, "~> 0.2"},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.35", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w[lib mix.exs README.md LICENSE CHANGELOG.md]
    ]
  end

  defp docs do
    [
      main: "NPM",
      extras: ["README.md", "CHANGELOG.md"],
      source_ref: "v#{@version}"
    ]
  end
end

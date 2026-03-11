defmodule Mix.Tasks.Npm.Install do
  @shortdoc "Install npm packages"

  @moduledoc """
  Install npm packages.

      mix npm.install              # Install all deps from package.json
      mix npm.install lodash       # Add latest version
      mix npm.install lodash@^4.0  # Add with specific range

  Resolves all dependencies using the PubGrub solver, writes `npm.lock`,
  and extracts packages into `deps/npm/`.
  """

  use Mix.Task

  @impl true
  def run([]) do
    Mix.Task.run("app.config")
    NPM.install()
  end

  def run([spec]) do
    Mix.Task.run("app.config")

    case String.split(spec, "@", parts: 2) do
      [name, range] -> NPM.install(name, range)
      [name] -> NPM.install(name)
    end
  end

  def run(_) do
    Mix.shell().error("Usage: mix npm.install [package[@range]]")
  end
end

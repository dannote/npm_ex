defmodule Mix.Tasks.Npm.Rebuild do
  @shortdoc "Rebuild node_modules from lockfile"

  @moduledoc """
  Remove `node_modules/` and reinstall from the lockfile.

      mix npm.rebuild

  Equivalent to `mix npm.clean` followed by `mix npm.get`.
  """

  use Mix.Task

  @impl true
  def run([]) do
    Mix.Task.run("app.config")

    if File.exists?("node_modules") do
      File.rm_rf!("node_modules")
      Mix.shell().info("Removed node_modules/")
    end

    NPM.get()
  end

  def run(_) do
    Mix.shell().error("Usage: mix npm.rebuild")
  end
end

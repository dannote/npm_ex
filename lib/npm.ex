defmodule NPM do
  @moduledoc """
  npm package manager for Elixir.

  Resolves, fetches, and installs npm packages using Mix tasks.
  Dependencies are declared in `package.json` and locked in `npm.lock`.

  ## Mix tasks

      mix npm.install           # Install all deps from package.json
      mix npm.install lodash    # Add and install a package
      mix npm.get               # Fetch locked deps without resolving

  ## Programmatic API

      NPM.install()
      NPM.install("lodash", "^4.17.0")
      NPM.get()

  Packages are installed into `deps/npm/<name>/`.
  """

  @deps_dir "deps/npm"

  @doc """
  Install all dependencies from `package.json`.

  Resolves versions using the PubGrub solver, writes `npm.lock`,
  downloads tarballs, and extracts into `deps/npm/`.
  """
  @spec install :: :ok | {:error, term()}
  def install do
    with {:ok, deps} <- NPM.PackageJson.read(),
         :ok <- do_install(deps) do
      :ok
    end
  end

  @doc """
  Add a package to `package.json` and install all dependencies.
  """
  @spec install(String.t(), String.t()) :: :ok | {:error, term()}
  def install(name, range \\ "latest") do
    range = if range == "latest", do: resolve_latest(name), else: range

    case range do
      {:error, reason} ->
        {:error, reason}

      range_str ->
        with :ok <- NPM.PackageJson.add_dep(name, range_str),
             {:ok, deps} <- NPM.PackageJson.read(),
             :ok <- do_install(deps) do
          :ok
        end
    end
  end

  @doc """
  Fetch locked dependencies without re-resolving.

  Reads `npm.lock` and downloads any missing packages.
  """
  @spec get :: :ok | {:error, term()}
  def get do
    with {:ok, lockfile} <- NPM.Lockfile.read() do
      if lockfile == %{} do
        Mix.shell().info("No npm.lock found, run `mix npm.install` first.")
        :ok
      else
        fetch_locked(lockfile)
      end
    end
  end

  @doc "Path where npm packages are installed."
  @spec deps_dir :: String.t()
  def deps_dir, do: @deps_dir

  # --- Private ---

  defp do_install(deps) when map_size(deps) == 0 do
    Mix.shell().info("No npm dependencies found in package.json.")
    :ok
  end

  defp do_install(deps) do
    Mix.shell().info("Resolving npm dependencies...")

    NPM.Resolver.clear_cache()

    case NPM.Resolver.resolve(deps) do
      {:ok, resolved} ->
        lockfile = build_lockfile(resolved)

        with :ok <- NPM.Lockfile.write(lockfile),
             :ok <- fetch_locked(lockfile) do
          count = map_size(lockfile)
          Mix.shell().info("Installed #{count} npm package#{if count == 1, do: "", else: "s"}.")
          :ok
        end

      {:error, message} ->
        Mix.shell().error("Resolution failed:\n#{message}")
        {:error, :resolution_failed}
    end
  end

  defp build_lockfile(resolved) do
    for {name, version_str} <- resolved, into: %{} do
      {:ok, packument} = NPM.Registry.get_packument(name)
      info = Map.fetch!(packument.versions, version_str)

      {name,
       %{
         version: version_str,
         integrity: info.dist.integrity,
         tarball: info.dist.tarball,
         dependencies: info.dependencies
       }}
    end
  end

  defp fetch_locked(lockfile) do
    File.mkdir_p!(@deps_dir)

    lockfile
    |> Task.async_stream(
      fn {name, entry} -> fetch_package(name, entry) end,
      max_concurrency: 8,
      timeout: 60_000
    )
    |> Enum.reduce(:ok, fn
      {:ok, :ok}, :ok -> :ok
      {:ok, {:error, reason}}, _ -> {:error, reason}
      {:exit, reason}, _ -> {:error, reason}
      _, acc -> acc
    end)
  end

  defp fetch_package(name, entry) do
    dest = Path.join(@deps_dir, name)

    if File.exists?(Path.join(dest, "package.json")) do
      :ok
    else
      Mix.shell().info("  Fetching #{name}@#{entry.version}")

      case NPM.Tarball.fetch_and_extract(entry.tarball, entry.integrity, dest) do
        {:ok, _count} -> :ok
        {:error, reason} -> {:error, {name, reason}}
      end
    end
  end

  defp resolve_latest(name) do
    case NPM.Registry.get_packument(name) do
      {:ok, packument} ->
        packument.versions
        |> Map.keys()
        |> Enum.flat_map(fn v ->
          case Version.parse(v) do
            {:ok, ver} -> if ver.pre == [], do: [ver], else: []
            :error -> []
          end
        end)
        |> Enum.sort(Version)
        |> List.last()
        |> case do
          nil -> {:error, :no_versions}
          v -> "^#{v}"
        end

      {:error, reason} ->
        {:error, reason}
    end
  end
end

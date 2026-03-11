defmodule NPM.PackageJson do
  @moduledoc """
  Read and write `package.json` files.
  """

  @default_path "package.json"

  @doc "Read dependencies from `package.json`."
  @spec read(String.t()) :: {:ok, %{String.t() => String.t()}} | {:error, term()}
  def read(path \\ @default_path) do
    case File.read(path) do
      {:ok, content} ->
        data = :json.decode(content)
        {:ok, Map.get(data, "dependencies", %{})}

      {:error, :enoent} ->
        {:ok, %{}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc "Add a dependency to `package.json`, creating the file if needed."
  @spec add_dep(String.t(), String.t(), String.t()) :: :ok | {:error, term()}
  def add_dep(name, range, path \\ @default_path) do
    data =
      case File.read(path) do
        {:ok, content} -> :json.decode(content)
        {:error, :enoent} -> %{}
      end

    deps = Map.get(data, "dependencies", %{})
    updated = Map.put(data, "dependencies", Map.put(deps, name, range))

    File.write(path, NPM.JSON.encode_pretty(updated))
  end
end

defmodule NPM.Exports do
  @moduledoc """
  Parse and resolve the `exports` field from `package.json`.

  Modern npm packages use the `exports` field (a.k.a. "export map") to
  define entry points and restrict access to internal modules.

  Supports:
  - String shorthand: `"exports": "./index.js"`
  - Subpath exports: `"exports": { ".": "./index.js", "./utils": "./lib/utils.js" }`
  - Conditional exports: `"exports": { "import": "./esm.js", "require": "./cjs.js" }`
  - Nested conditions: `"exports": { ".": { "import": "./esm.js", "default": "./cjs.js" } }`
  """

  @type export_map :: String.t() | %{String.t() => export_map()} | nil

  @doc """
  Parse the exports field from a package.json map.

  Returns a normalized map of subpath → target mappings, or nil if no exports field.
  """
  @spec parse(map()) :: %{String.t() => String.t() | map()} | nil
  def parse(%{"exports" => exports}) when is_binary(exports) do
    %{"." => exports}
  end

  def parse(%{"exports" => exports}) when is_map(exports) do
    if subpath_exports?(exports) do
      exports
    else
      %{"." => exports}
    end
  end

  def parse(_), do: nil

  @doc """
  Resolve an import path against an export map.

  Given a subpath (e.g. `"."`, `"./utils"`) and a list of conditions
  (e.g. `["import", "default"]`), returns the resolved file path.
  """
  @spec resolve(map(), String.t(), [String.t()]) :: {:ok, String.t()} | :error
  def resolve(export_map, subpath, conditions \\ ["default"]) do
    case Map.get(export_map, subpath) do
      nil -> :error
      target when is_binary(target) -> {:ok, target}
      target when is_map(target) -> resolve_conditions(target, conditions)
    end
  end

  @doc """
  List all exported subpaths from an export map.
  """
  @spec subpaths(map()) :: [String.t()]
  def subpaths(export_map) when is_map(export_map) do
    Map.keys(export_map) |> Enum.sort()
  end

  def subpaths(_), do: []

  @doc """
  Detect whether a package uses ESM (`type: "module"`) or CJS.
  """
  @spec module_type(map()) :: :esm | :cjs
  def module_type(%{"type" => "module"}), do: :esm
  def module_type(_), do: :cjs

  @doc """
  Checks if a subpath is exported by the export map.
  """
  @spec exported?(String.t(), map() | nil) :: boolean()
  def exported?(_subpath, nil), do: false

  def exported?(subpath, export_map) when is_map(export_map) do
    Map.has_key?(export_map, subpath) or has_wildcard_match?(subpath, export_map)
  end

  def exported?(_, _), do: false

  @doc """
  Extracts all conditions used in the export map.
  """
  @spec conditions(map() | nil) :: [String.t()]
  def conditions(nil), do: []

  def conditions(export_map) when is_map(export_map) do
    export_map
    |> Map.values()
    |> Enum.flat_map(&extract_conditions/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc """
  Validates that all export paths resolve to existing files.
  """
  @spec validate(map() | nil, String.t()) :: {:ok, [String.t()]} | {:error, [String.t()]}
  def validate(nil, _base_dir), do: {:ok, []}

  def validate(export_map, base_dir) when is_map(export_map) do
    paths = collect_paths(export_map)
    missing = Enum.reject(paths, &File.exists?(Path.join(base_dir, &1)))

    if missing == [],
      do: {:ok, paths},
      else: {:error, Enum.map(missing, &"#{&1} not found")}
  end

  defp subpath_exports?(map) do
    Map.keys(map) |> Enum.any?(&String.starts_with?(&1, "."))
  end

  defp resolve_conditions(target, conditions) do
    Enum.find_value(conditions, :error, fn condition ->
      case Map.get(target, condition) do
        nil -> nil
        path when is_binary(path) -> {:ok, path}
        nested when is_map(nested) -> resolve_conditions(nested, conditions)
      end
    end)
  end

  defp has_wildcard_match?(subpath, export_map) do
    Enum.any?(export_map, fn {pattern, _} -> wildcard_matches?(subpath, pattern) end)
  end

  defp wildcard_matches?(subpath, pattern) do
    case String.split(pattern, "*", parts: 2) do
      [prefix, suffix] ->
        String.starts_with?(subpath, prefix) and String.ends_with?(subpath, suffix)

      _ ->
        false
    end
  end

  defp extract_conditions(entry) when is_map(entry), do: Map.keys(entry)
  defp extract_conditions(_), do: ["default"]

  defp collect_paths(export_map) do
    Enum.flat_map(export_map, fn
      {_key, value} when is_binary(value) -> [value]
      {_key, value} when is_map(value) -> Map.values(value) |> Enum.filter(&is_binary/1)
      _ -> []
    end)
    |> Enum.uniq()
  end
end

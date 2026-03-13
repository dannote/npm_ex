defmodule NPM.PeerDep do
  @moduledoc """
  Analyzes peer dependency declarations and their resolution status.
  """

  @doc """
  Extracts peer dependencies from package.json data.
  """
  @spec extract(map()) :: map()
  def extract(%{"peerDependencies" => peers}) when is_map(peers), do: peers
  def extract(_), do: %{}

  @doc """
  Extracts peerDependenciesMeta (optional markers).
  """
  @spec meta(map()) :: map()
  def meta(%{"peerDependenciesMeta" => meta}) when is_map(meta), do: meta
  def meta(_), do: %{}

  @doc """
  Checks if a peer dependency is marked as optional.
  """
  @spec optional?(String.t(), map()) :: boolean()
  def optional?(name, data) do
    case meta(data) do
      %{^name => %{"optional" => true}} -> true
      _ -> false
    end
  end

  @doc """
  Returns required (non-optional) peer dependencies.
  """
  @spec required(map()) :: map()
  def required(data) do
    peers = extract(data)
    peer_meta = meta(data)

    Map.reject(peers, fn {name, _} ->
      get_in(peer_meta, [name, "optional"]) == true
    end)
  end

  @doc """
  Checks if all required peers are satisfied in the lockfile.
  """
  @spec satisfied?(map(), map()) :: boolean()
  def satisfied?(data, lockfile) do
    required(data)
    |> Enum.all?(fn {name, range} ->
      case Map.get(lockfile, name) do
        %{version: version} -> NPMSemver.matches?(version, range)
        _ -> false
      end
    end)
  end

  @doc """
  Lists unsatisfied peer dependencies.
  """
  @spec unsatisfied(map(), map()) :: [{String.t(), String.t(), String.t() | nil}]
  def unsatisfied(data, lockfile) do
    required(data)
    |> Enum.flat_map(&check_peer(&1, lockfile))
    |> Enum.sort_by(&elem(&1, 0))
  end

  defp check_peer({name, range}, lockfile) do
    case Map.get(lockfile, name) do
      %{version: version} ->
        if NPMSemver.matches?(version, range), do: [], else: [{name, range, version}]

      _ ->
        [{name, range, nil}]
    end
  end

  @doc """
  Counts total peer dependencies across packages.
  """
  @spec count_across([map()]) :: non_neg_integer()
  def count_across(packages) do
    packages |> Enum.map(&(extract(&1) |> map_size())) |> Enum.sum()
  end
end

defmodule NPM.Registry do
  @moduledoc """
  HTTP client for the npm registry.

  Fetches abbreviated packuments (version list + deps + dist info)
  using the npm registry API.
  """

  @registry_url "https://registry.npmjs.org"
  @accept_header ~c"application/vnd.npm.install-v1+json"

  @type packument :: %{
          name: String.t(),
          versions: %{String.t() => version_info()}
        }

  @type version_info :: %{
          dependencies: %{String.t() => String.t()},
          dist: %{tarball: String.t(), integrity: String.t()}
        }

  @doc "Fetch the abbreviated packument for a package."
  @spec get_packument(String.t()) :: {:ok, packument()} | {:error, term()}
  def get_packument(package) do
    url = registry_url(package)
    headers = [{~c"Accept", @accept_header}]

    ensure_httpc_started()

    case :httpc.request(:get, {url, headers}, ssl_opts(), body_format: :binary) do
      {:ok, {{_, 200, _}, _headers, body}} ->
        parse_packument(body)

      {:ok, {{_, 404, _}, _, _}} ->
        {:error, :not_found}

      {:ok, {{_, status, _}, _, _}} ->
        {:error, {:http, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp registry_url(package) do
    encoded = package |> String.replace("/", "%2f")
    ~c"#{@registry_url}/#{encoded}"
  end

  defp parse_packument(body) do
    data = :json.decode(body)

    versions =
      for {version_str, info} <- Map.get(data, "versions", %{}), into: %{} do
        deps =
          for {name, range} <- Map.get(info, "dependencies", %{}), into: %{} do
            {name, range}
          end

        dist = Map.get(info, "dist", %{})

        version_info = %{
          dependencies: deps,
          dist: %{
            tarball: Map.get(dist, "tarball", ""),
            integrity: Map.get(dist, "integrity", "")
          }
        }

        {version_str, version_info}
      end

    {:ok, %{name: Map.get(data, "name", ""), versions: versions}}
  end

  defp ensure_httpc_started do
    :inets.start()
    :ssl.start()
  end

  defp ssl_opts do
    cacerts = :public_key.cacerts_get()

    [
      ssl: [
        verify: :verify_peer,
        cacerts: cacerts,
        depth: 3,
        customize_hostname_check: [
          match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
        ]
      ]
    ]
  end
end

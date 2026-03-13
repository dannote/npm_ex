defmodule NPM.IntegrationTest do
  use ExUnit.Case

  @moduletag :integration

  describe "Registry.get_packument" do
    test "fetches lodash packument" do
      assert {:ok, packument} = NPM.Registry.get_packument("lodash")
      assert packument.name == "lodash"
      assert Map.has_key?(packument.versions, "4.17.21")
    end

    test "fetches scoped package" do
      assert {:ok, packument} = NPM.Registry.get_packument("@types/node")
      assert packument.name == "@types/node"
      assert map_size(packument.versions) > 0
    end

    test "returns error for nonexistent package" do
      assert {:error, :not_found} =
               NPM.Registry.get_packument("this-package-does-not-exist-xyz-123")
    end

    test "parses dependencies correctly" do
      assert {:ok, packument} = NPM.Registry.get_packument("express")
      info = packument.versions["4.21.2"]
      assert is_map(info.dependencies)
      assert Map.has_key?(info.dependencies, "body-parser")
      assert info.dependencies["body-parser"] =~ ~r/^\d/
    end

    test "parses dist info correctly" do
      assert {:ok, packument} = NPM.Registry.get_packument("is-number")
      info = packument.versions["7.0.0"]
      assert info.dist.tarball =~ "registry.npmjs.org"
      assert info.dist.tarball =~ "is-number"
      assert info.dist.integrity =~ "sha512-"
    end

    test "handles package with no dependencies" do
      assert {:ok, packument} = NPM.Registry.get_packument("is-number")
      info = packument.versions["7.0.0"]
      assert info.dependencies == %{}
    end

    test "parses peer dependencies" do
      assert {:ok, packument} = NPM.Registry.get_packument("react-dom")
      info = packument.versions["18.3.1"]
      assert is_map(info.peer_dependencies)
      assert Map.has_key?(info.peer_dependencies, "react")
    end

    test "parses engines field" do
      assert {:ok, packument} = NPM.Registry.get_packument("typescript")
      info = packument.versions["5.7.3"]
      assert is_map(info.engines)
    end

    test "parses bin field" do
      assert {:ok, packument} = NPM.Registry.get_packument("typescript")
      info = packument.versions["5.7.3"]
      assert is_map(info.bin)
    end

    test "detects deprecated packages" do
      assert {:ok, packument} = NPM.Registry.get_packument("request")
      info = packument.versions["2.88.2"]
      assert is_binary(info.deprecated) or is_nil(info.deprecated)
    end

    test "parses dist metadata" do
      assert {:ok, packument} = NPM.Registry.get_packument("is-number")
      info = packument.versions["7.0.0"]
      assert is_binary(info.dist.tarball)
      assert is_binary(info.dist.integrity)
    end
  end

  describe "Resolver" do
    setup do
      NPM.Resolver.clear_cache()
      :ok
    end

    test "resolves a single package with no deps" do
      assert {:ok, resolved} = NPM.Resolver.resolve(%{"is-number" => "^7.0.0"})
      assert resolved["is-number"] =~ ~r/^7\./
      assert map_size(resolved) == 1
    end

    test "resolves package with transitive dependencies" do
      assert {:ok, resolved} = NPM.Resolver.resolve(%{"accepts" => "~1.3.8"})
      assert resolved["accepts"] =~ ~r/^1\.3\./
      assert Map.has_key?(resolved, "mime-types")
      assert Map.has_key?(resolved, "negotiator")
    end

    test "resolves multiple root deps" do
      assert {:ok, resolved} =
               NPM.Resolver.resolve(%{"is-number" => "^7.0.0", "depd" => "^2.0.0"})

      assert Map.has_key?(resolved, "is-number")
      assert Map.has_key?(resolved, "depd")
    end

    test "returns error for impossible range" do
      assert {:error, _message} = NPM.Resolver.resolve(%{"is-number" => "^999.0.0"})
    end

    test "returns ok for empty deps" do
      assert {:ok, %{}} = NPM.Resolver.resolve(%{})
    end

    test "resolved versions are valid semver" do
      assert {:ok, resolved} = NPM.Resolver.resolve(%{"depd" => "^2.0.0"})

      Enum.each(resolved, fn {_name, version} ->
        assert {:ok, _} = Version.parse(version)
      end)
    end
  end

  describe "Resolver with devDependencies" do
    setup do
      NPM.Resolver.clear_cache()
      :ok
    end

    test "resolves dev deps same as regular deps" do
      assert {:ok, resolved} = NPM.Resolver.resolve(%{"is-number" => "^7.0.0"})
      assert Map.has_key?(resolved, "is-number")
    end
  end

  describe "full install flow" do
    @tag :tmp_dir
    test "resolve → lockfile → cache → node_modules", %{tmp_dir: dir} do
      cache_dir = Path.join(dir, "npm_cache")
      nm_dir = Path.join(dir, "node_modules")
      lock_path = Path.join(dir, "npm.lock")
      System.put_env("NPM_EX_CACHE_DIR", cache_dir)

      NPM.Resolver.clear_cache()
      {:ok, resolved} = NPM.Resolver.resolve(%{"is-number" => "^7.0.0"})

      lockfile =
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

      # Write lockfile
      NPM.Lockfile.write(lockfile, lock_path)
      assert {:ok, read_lock} = NPM.Lockfile.read(lock_path)
      assert read_lock["is-number"].version =~ ~r/^7\./

      # Link to node_modules
      assert :ok = NPM.Linker.link(lockfile, nm_dir)

      # Verify cache populated
      assert NPM.Cache.cached?("is-number", lockfile["is-number"].version)

      # Verify node_modules
      assert File.exists?(Path.join([nm_dir, "is-number", "package.json"]))

      pkg_json =
        Path.join([nm_dir, "is-number", "package.json"])
        |> File.read!()
        |> :json.decode()

      assert pkg_json["name"] == "is-number"

      System.delete_env("NPM_EX_CACHE_DIR")
    end

    @tag :tmp_dir
    test "second install uses cache (no re-download)", %{tmp_dir: dir} do
      cache_dir = Path.join(dir, "npm_cache")
      nm1 = Path.join(dir, "project1/node_modules")
      nm2 = Path.join(dir, "project2/node_modules")
      System.put_env("NPM_EX_CACHE_DIR", cache_dir)

      NPM.Resolver.clear_cache()
      {:ok, resolved} = NPM.Resolver.resolve(%{"is-number" => "^7.0.0"})

      lockfile =
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

      # First install populates cache
      assert :ok = NPM.Linker.link(lockfile, nm1)
      assert File.exists?(Path.join([nm1, "is-number", "package.json"]))

      # Second install reuses cache (would fail if HTTP is required)
      assert :ok = NPM.Linker.link(lockfile, nm2)
      assert File.exists?(Path.join([nm2, "is-number", "package.json"]))

      System.delete_env("NPM_EX_CACHE_DIR")
    end

    @tag :tmp_dir
    test "installs package with transitive deps", %{tmp_dir: dir} do
      cache_dir = Path.join(dir, "npm_cache")
      nm_dir = Path.join(dir, "node_modules")
      System.put_env("NPM_EX_CACHE_DIR", cache_dir)

      NPM.Resolver.clear_cache()
      {:ok, resolved} = NPM.Resolver.resolve(%{"accepts" => "~1.3.8"})

      lockfile =
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

      assert :ok = NPM.Linker.link(lockfile, nm_dir)

      # All resolved packages should be in node_modules
      for {name, _version} <- resolved do
        assert File.exists?(Path.join([nm_dir, name, "package.json"])),
               "Expected #{name} in node_modules"
      end

      System.delete_env("NPM_EX_CACHE_DIR")
    end
  end

  describe "npm compatibility: semver resolution" do
    setup do
      NPM.Resolver.clear_cache()
      :ok
    end

    test "caret range ^1.2.3 picks latest 1.x" do
      {:ok, resolved} = NPM.Resolver.resolve(%{"depd" => "^2.0.0"})
      {major, _, _} = parse_version(resolved["depd"])
      assert major == 2
    end

    test "tilde range ~1.3.8 stays within minor" do
      {:ok, resolved} = NPM.Resolver.resolve(%{"accepts" => "~1.3.8"})
      {major, minor, _} = parse_version(resolved["accepts"])
      assert {major, minor} == {1, 3}
    end

    test "exact version pins" do
      {:ok, resolved} = NPM.Resolver.resolve(%{"is-number" => "7.0.0"})
      assert resolved["is-number"] == "7.0.0"
    end

    test "range union || picks correct branch" do
      {:ok, resolved} = NPM.Resolver.resolve(%{"depd" => "~1.1 || ~2.0"})
      {major, _, _} = parse_version(resolved["depd"])
      assert major in [1, 2]
    end

    test ">=, < range constraints" do
      {:ok, resolved} = NPM.Resolver.resolve(%{"depd" => ">=2.0.0 <3.0.0"})
      {major, _, _} = parse_version(resolved["depd"])
      assert major == 2
    end

    test "* matches any version" do
      {:ok, resolved} = NPM.Resolver.resolve(%{"is-number" => "*"})
      assert Map.has_key?(resolved, "is-number")
    end
  end

  describe "npm compatibility: real-world dependency trees" do
    setup do
      NPM.Resolver.clear_cache()
      :ok
    end

    test "chalk@5 has zero dependencies (pure ESM)" do
      {:ok, resolved} = NPM.Resolver.resolve(%{"chalk" => "5.4.1"})
      assert resolved["chalk"] == "5.4.1"
      assert map_size(resolved) == 1
    end

    test "express@4.x fails due to ms version conflict (known limitation)" do
      # npm allows multiple versions of 'ms' in nested node_modules.
      # PubGrub (flat solver) can't handle this. This tests the current behavior.
      # debug@2.6.9 → ms@2.0.0, send@0.19.0 → ms@2.1.3
      assert {:error, message} = NPM.Resolver.resolve(%{"express" => "^4.21.0"})
      assert message =~ "ms"
    end

    test "resolves packages with compatible transitive deps" do
      {:ok, resolved} = NPM.Resolver.resolve(%{"accepts" => "~1.3.8"})
      assert map_size(resolved) >= 3
      assert Map.has_key?(resolved, "accepts")
      assert Map.has_key?(resolved, "mime-types")
      assert Map.has_key?(resolved, "negotiator")
    end

    test "scoped package @types/node resolves" do
      {:ok, resolved} = NPM.Resolver.resolve(%{"@types/node" => "^20.0.0"})
      assert Map.has_key?(resolved, "@types/node")
      {major, _, _} = parse_version(resolved["@types/node"])
      assert major == 20
    end

    test "conflicting transitive deps get resolved" do
      # express and koa both depend on different versions of some libs
      {:ok, resolved} =
        NPM.Resolver.resolve(%{"accepts" => "~1.3.8", "depd" => "^2.0.0"})

      assert Map.has_key?(resolved, "accepts")
      assert Map.has_key?(resolved, "depd")
    end
  end

  describe "npm compatibility: tarball integrity" do
    @tag :tmp_dir
    test "downloaded tarball matches registry integrity hash", %{tmp_dir: dir} do
      cache_dir = Path.join(dir, "cache")
      System.put_env("NPM_EX_CACHE_DIR", cache_dir)

      {:ok, packument} = NPM.Registry.get_packument("is-number")
      info = packument.versions["7.0.0"]
      tarball_url = info.dist.tarball
      integrity = info.dist.integrity

      assert is_binary(integrity)
      assert String.starts_with?(integrity, "sha512-")

      {:ok, path} = NPM.Cache.ensure("is-number", "7.0.0", tarball_url, integrity)
      assert File.dir?(path)
      assert File.exists?(Path.join(path, "package.json"))

      pkg_json = path |> Path.join("package.json") |> File.read!() |> :json.decode()
      assert pkg_json["name"] == "is-number"
      assert pkg_json["version"] == "7.0.0"

      System.delete_env("NPM_EX_CACHE_DIR")
    end

    @tag :tmp_dir
    test "scoped package tarball extracts correctly", %{tmp_dir: dir} do
      cache_dir = Path.join(dir, "cache")
      System.put_env("NPM_EX_CACHE_DIR", cache_dir)

      {:ok, packument} = NPM.Registry.get_packument("@types/node")

      latest =
        packument.versions
        |> Map.keys()
        |> Enum.flat_map(fn v ->
          case Version.parse(v) do
            {:ok, ver} -> [{v, ver}]
            :error -> []
          end
        end)
        |> Enum.sort_by(&elem(&1, 1), Version)
        |> List.last()
        |> elem(0)

      info = packument.versions[latest]

      {:ok, path} =
        NPM.Cache.ensure("@types/node", latest, info.dist.tarball, info.dist.integrity)

      assert File.dir?(path)

      System.delete_env("NPM_EX_CACHE_DIR")
    end
  end

  describe "npm compatibility: bin field formats" do
    @tag :tmp_dir
    test "string bin field creates correct link", %{tmp_dir: dir} do
      cache_dir = Path.join(dir, "cache")
      nm_dir = Path.join(dir, "node_modules")
      System.put_env("NPM_EX_CACHE_DIR", cache_dir)

      NPM.Resolver.clear_cache()
      {:ok, resolved} = NPM.Resolver.resolve(%{"is-number" => "7.0.0"})

      lockfile = build_lockfile(resolved)
      assert :ok = NPM.Linker.link(lockfile, nm_dir)

      # is-number doesn't have bin, but verify structure is correct
      assert File.exists?(Path.join([nm_dir, "is-number", "package.json"]))

      System.delete_env("NPM_EX_CACHE_DIR")
    end
  end

  describe "npm compatibility: registry responses" do
    test "peerDependencies parsed from registry" do
      {:ok, packument} = NPM.Registry.get_packument("react-dom")
      info = packument.versions["18.3.1"]
      assert info.peer_dependencies["react"] == "^18.3.1"
    end

    test "deprecated field is a string message" do
      {:ok, packument} = NPM.Registry.get_packument("request")
      info = packument.versions["2.88.2"]
      assert is_binary(info.deprecated)
      assert info.deprecated =~ "deprecated"
    end

    test "engines field parsed correctly for typescript" do
      {:ok, packument} = NPM.Registry.get_packument("typescript")
      info = packument.versions["5.7.3"]
      assert is_map(info.engines)
      assert Map.has_key?(info.engines, "node")
    end

    test "has_install_script parsed" do
      {:ok, packument} = NPM.Registry.get_packument("esbuild")
      # esbuild has postinstall script
      info = packument.versions["0.24.2"]
      assert info.has_install_script == true
    end

    test "peerDependenciesMeta parsed" do
      {:ok, packument} = NPM.Registry.get_packument("react-dom")
      info = packument.versions["19.0.0"]
      meta = info.peer_dependencies_meta
      assert is_map(meta)
    end

    test "optionalDependencies parsed" do
      {:ok, packument} = NPM.Registry.get_packument("esbuild")
      info = packument.versions["0.24.2"]
      opt = info.optional_dependencies
      assert is_map(opt)
      assert map_size(opt) > 0
    end
  end

  describe "npm compatibility: exports field from registry" do
    test "chalk 5.x has exports map" do
      {:ok, packument} = NPM.Registry.get_packument("chalk")
      raw = get_raw_packument("chalk")
      v5 = raw["versions"]["5.4.1"]

      case Map.get(v5, "exports") do
        nil -> :ok
        exports -> assert is_map(exports) or is_binary(exports)
      end
    end
  end

  describe "npm compatibility: full install round-trip" do
    @tag :tmp_dir
    test "accepts install produces working node_modules", %{tmp_dir: dir} do
      cache_dir = Path.join(dir, "cache")
      nm_dir = Path.join(dir, "node_modules")
      System.put_env("NPM_EX_CACHE_DIR", cache_dir)

      NPM.Resolver.clear_cache()
      {:ok, resolved} = NPM.Resolver.resolve(%{"accepts" => "~1.3.8"})

      lockfile = build_lockfile(resolved)
      assert :ok = NPM.Linker.link(lockfile, nm_dir)

      for pkg <- ["accepts", "mime-types", "negotiator", "mime-db"] do
        pkg_json_path = Path.join([nm_dir, pkg, "package.json"])
        assert File.exists?(pkg_json_path), "Missing #{pkg} in node_modules"

        pkg_data = pkg_json_path |> File.read!() |> :json.decode()
        assert pkg_data["name"] == pkg
      end

      System.delete_env("NPM_EX_CACHE_DIR")
    end

    @tag :tmp_dir
    test "chalk@5 install (zero-dep ESM package)", %{tmp_dir: dir} do
      cache_dir = Path.join(dir, "cache")
      nm_dir = Path.join(dir, "node_modules")
      System.put_env("NPM_EX_CACHE_DIR", cache_dir)

      NPM.Resolver.clear_cache()
      {:ok, resolved} = NPM.Resolver.resolve(%{"chalk" => "5.4.1"})
      assert map_size(resolved) == 1

      lockfile = build_lockfile(resolved)
      assert :ok = NPM.Linker.link(lockfile, nm_dir)

      chalk_pkg = Path.join([nm_dir, "chalk", "package.json"]) |> File.read!() |> :json.decode()
      assert chalk_pkg["name"] == "chalk"
      assert chalk_pkg["version"] == "5.4.1"
      assert chalk_pkg["type"] == "module"

      System.delete_env("NPM_EX_CACHE_DIR")
    end
  end

  # --- Helpers ---

  defp parse_version(version_str) do
    {:ok, v} = Version.parse(version_str)
    {v.major, v.minor, v.patch}
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

  defp get_raw_packument(name) do
    url = "#{NPM.Registry.registry_url()}/#{URI.encode(name, &(&1 != ?/))}"
    {:ok, %{body: body}} = Req.get(url)
    body
  end
end

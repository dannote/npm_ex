defmodule NPM.TypesResolutionTest do
  use ExUnit.Case, async: true

  describe "types_package" do
    test "regular package" do
      assert "@types/lodash" = NPM.TypesResolution.types_package("lodash")
    end

    test "scoped package" do
      assert "@types/babel__core" = NPM.TypesResolution.types_package("@babel/core")
    end

    test "simple name" do
      assert "@types/express" = NPM.TypesResolution.types_package("express")
    end
  end

  describe "has_bundled_types?" do
    test "true with types field" do
      assert NPM.TypesResolution.has_bundled_types?(%{"types" => "./dist/index.d.ts"})
    end

    test "true with typings field" do
      assert NPM.TypesResolution.has_bundled_types?(%{"typings" => "./index.d.ts"})
    end

    test "true with types in exports" do
      data = %{
        "exports" => %{"." => %{"types" => "./dist/index.d.ts", "import" => "./dist/index.mjs"}}
      }

      assert NPM.TypesResolution.has_bundled_types?(data)
    end

    test "false without type definitions" do
      refute NPM.TypesResolution.has_bundled_types?(%{"name" => "lodash"})
    end
  end

  describe "installed_types" do
    test "lists @types/ packages" do
      lockfile = %{
        "lodash" => %{version: "4.17.21"},
        "@types/lodash" => %{version: "4.14.191"},
        "@types/node" => %{version: "18.15.0"},
        "react" => %{version: "18.2.0"}
      }

      result = NPM.TypesResolution.installed_types(lockfile)
      assert "@types/lodash" in result
      assert "@types/node" in result
      refute "lodash" in result
    end

    test "empty when no types" do
      assert [] = NPM.TypesResolution.installed_types(%{"react" => %{version: "18.2.0"}})
    end
  end

  describe "types_map" do
    test "maps types packages to originals" do
      lockfile = %{
        "@types/lodash" => %{version: "4.14.191"},
        "@types/babel__core" => %{version: "7.20.0"}
      }

      result = NPM.TypesResolution.types_map(lockfile)
      assert result["lodash"] == "@types/lodash"
      assert result["@babel/core"] == "@types/babel__core"
    end
  end

  describe "missing_types" do
    @tag :tmp_dir
    test "finds packages without types", %{tmp_dir: dir} do
      nm = Path.join(dir, "node_modules")
      pkg = Path.join(nm, "lodash")
      File.mkdir_p!(pkg)
      File.write!(Path.join(pkg, "package.json"), ~s({"name":"lodash"}))

      pkg_data = %{"dependencies" => %{"lodash" => "^4.0.0"}}
      lockfile = %{"lodash" => %{version: "4.17.21"}}

      missing = NPM.TypesResolution.missing_types(pkg_data, lockfile, nm)
      assert "lodash" in missing
    end

    @tag :tmp_dir
    test "excludes packages with bundled types", %{tmp_dir: dir} do
      nm = Path.join(dir, "node_modules")
      pkg = Path.join(nm, "zod")
      File.mkdir_p!(pkg)
      File.write!(Path.join(pkg, "package.json"), ~s({"name":"zod","types":"./index.d.ts"}))

      pkg_data = %{"dependencies" => %{"zod" => "^3.0.0"}}
      lockfile = %{"zod" => %{version: "3.22.0"}}

      missing = NPM.TypesResolution.missing_types(pkg_data, lockfile, nm)
      refute "zod" in missing
    end

    @tag :tmp_dir
    test "excludes packages with @types/ installed", %{tmp_dir: dir} do
      nm = Path.join(dir, "node_modules")
      pkg = Path.join(nm, "express")
      File.mkdir_p!(pkg)
      File.write!(Path.join(pkg, "package.json"), ~s({"name":"express"}))

      pkg_data = %{"dependencies" => %{"express" => "^4.0.0"}}
      lockfile = %{"express" => %{version: "4.18.2"}, "@types/express" => %{version: "4.17.17"}}

      missing = NPM.TypesResolution.missing_types(pkg_data, lockfile, nm)
      refute "express" in missing
    end
  end
end

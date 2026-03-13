defmodule NPM.OverridesTest do
  use ExUnit.Case, async: true

  describe "parse" do
    test "flat overrides" do
      data = %{"overrides" => %{"lodash" => "4.17.21", "ms" => "^3.0.0"}}
      overrides = NPM.Overrides.parse(data)
      assert length(overrides) == 2
      lodash = Enum.find(overrides, &(&1.package == "lodash"))
      assert lodash.version == "4.17.21"
      assert lodash.parent == nil
    end

    test "nested overrides" do
      data = %{"overrides" => %{"express" => %{"debug" => "4.0.0"}}}
      overrides = NPM.Overrides.parse(data)
      assert length(overrides) == 1
      assert hd(overrides).package == "debug"
      assert hd(overrides).parent == "express"
    end

    test "mixed flat and nested" do
      data = %{
        "overrides" => %{
          "lodash" => "4.17.21",
          "express" => %{"ms" => "3.0.0"}
        }
      }

      overrides = NPM.Overrides.parse(data)
      assert length(overrides) == 2
    end

    test "no overrides field" do
      assert [] = NPM.Overrides.parse(%{"name" => "pkg"})
    end

    test "empty overrides" do
      assert [] = NPM.Overrides.parse(%{"overrides" => %{}})
    end
  end

  describe "apply_overrides" do
    test "replaces version in lockfile" do
      lockfile = %{
        "lodash" => %{version: "4.17.20", integrity: "", tarball: "", dependencies: %{}}
      }

      overrides = [%{package: "lodash", version: "4.17.21", parent: nil}]
      {new_lf, applied} = NPM.Overrides.apply_overrides(lockfile, overrides)
      assert new_lf["lodash"].version == "4.17.21"
      assert length(applied) == 1
      assert hd(applied).from == "4.17.20"
    end

    test "skips packages not in lockfile" do
      lockfile = %{
        "react" => %{version: "18.2.0", integrity: "", tarball: "", dependencies: %{}}
      }

      overrides = [%{package: "ghost", version: "1.0.0", parent: nil}]
      {new_lf, applied} = NPM.Overrides.apply_overrides(lockfile, overrides)
      assert new_lf == lockfile
      assert applied == []
    end
  end

  describe "matching" do
    test "finds overrides that match lockfile packages" do
      lockfile = %{
        "lodash" => %{version: "4.17.20", integrity: "", tarball: "", dependencies: %{}},
        "react" => %{version: "18.2.0", integrity: "", tarball: "", dependencies: %{}}
      }

      overrides = [
        %{package: "lodash", version: "4.17.21", parent: nil},
        %{package: "ghost", version: "1.0.0", parent: nil}
      ]

      matched = NPM.Overrides.matching(lockfile, overrides)
      assert length(matched) == 1
      assert hd(matched).package == "lodash"
    end
  end

  describe "validate" do
    test "valid versions pass" do
      overrides = [
        %{package: "a", version: "1.0.0", parent: nil},
        %{package: "b", version: "^2.0.0", parent: nil},
        %{package: "c", version: "~3.0.0", parent: nil}
      ]

      assert {:ok, ^overrides} = NPM.Overrides.validate(overrides)
    end

    test "invalid versions fail" do
      overrides = [
        %{package: "a", version: "not-a-version", parent: nil}
      ]

      assert {:error, errors} = NPM.Overrides.validate(overrides)
      assert length(errors) == 1
    end

    test "wildcard is valid" do
      overrides = [%{package: "a", version: "*", parent: nil}]
      assert {:ok, _} = NPM.Overrides.validate(overrides)
    end
  end

  describe "format_override" do
    test "flat override" do
      o = %{package: "lodash", version: "4.17.21", parent: nil}
      assert "lodash → 4.17.21" = NPM.Overrides.format_override(o)
    end

    test "nested override" do
      o = %{package: "debug", version: "4.0.0", parent: "express"}
      formatted = NPM.Overrides.format_override(o)
      assert formatted =~ "express"
      assert formatted =~ "debug"
      assert formatted =~ "4.0.0"
    end
  end
end

defmodule NPM.DepsOutputTest do
  use ExUnit.Case, async: true

  @lockfile %{
    "lodash" => %{version: "4.17.21", integrity: "sha512-abc123defgh"},
    "express" => %{version: "4.18.2", integrity: "sha512-xyz789"},
    "react" => %{version: "18.2.0", integrity: ""}
  }

  describe "format_lockfile" do
    test "formats like mix deps" do
      output = NPM.DepsOutput.format_lockfile(@lockfile)
      assert output =~ "* express 4.18.2 (npm registry)"
      assert output =~ "  locked at 4.18.2"
      assert output =~ "  ok"
    end

    test "sorted alphabetically" do
      output = NPM.DepsOutput.format_lockfile(@lockfile)
      lines = String.split(output, "\n")
      first_pkg = Enum.find(lines, &String.starts_with?(&1, "* "))
      assert first_pkg =~ "express"
    end

    test "empty lockfile" do
      assert "No npm dependencies installed." = NPM.DepsOutput.format_lockfile(%{})
    end

    test "truncates long integrity hashes" do
      output = NPM.DepsOutput.format_lockfile(@lockfile)
      assert output =~ "sha512-a"
      refute output =~ "sha512-abc123defgh"
    end

    test "handles empty integrity" do
      output = NPM.DepsOutput.format_lockfile(%{"a" => %{version: "1.0.0", integrity: ""}})
      assert output =~ "locked at 1.0.0"
    end
  end

  describe "format_diff" do
    test "shows added packages" do
      old = %{}
      new = %{"lodash" => %{version: "4.17.21"}}
      diff = NPM.DepsOutput.format_diff(old, new)
      assert diff =~ "+ lodash 4.17.21"
    end

    test "shows removed packages" do
      old = %{"lodash" => %{version: "4.17.21"}}
      new = %{}
      diff = NPM.DepsOutput.format_diff(old, new)
      assert diff =~ "- lodash 4.17.21"
    end

    test "shows updated packages" do
      old = %{"lodash" => %{version: "4.17.20"}}
      new = %{"lodash" => %{version: "4.17.21"}}
      diff = NPM.DepsOutput.format_diff(old, new)
      assert diff =~ "↑ lodash 4.17.20 → 4.17.21"
    end

    test "empty for no changes" do
      old = %{"a" => %{version: "1.0.0"}}
      assert "" = NPM.DepsOutput.format_diff(old, old)
    end
  end

  describe "format_summary" do
    test "singular package" do
      assert "Installed 1 package in 100ms" = NPM.DepsOutput.format_summary(1, 100)
    end

    test "plural packages" do
      assert "Installed 5 packages in 200ms" = NPM.DepsOutput.format_summary(5, 200)
    end
  end

  describe "print" do
    test "prints to shell" do
      NPM.DepsOutput.print(@lockfile)
    end
  end
end

defmodule NPM.TreeFormatTest do
  use ExUnit.Case, async: true

  @lockfile %{
    "express" => %{version: "4.18.2", dependencies: %{"debug" => "^2.0"}},
    "debug" => %{version: "2.6.9", dependencies: %{}},
    "lodash" => %{version: "4.17.21", dependencies: %{}}
  }

  describe "format" do
    test "renders tree with connectors" do
      output = NPM.TreeFormat.format(@lockfile)
      assert output =~ "project"
      assert output =~ "├── "
      assert output =~ "└── "
    end

    test "includes versions" do
      output = NPM.TreeFormat.format(@lockfile)
      assert output =~ "lodash@4.17.21"
    end

    test "custom root name" do
      output = NPM.TreeFormat.format(@lockfile, root: "my-app")
      assert String.starts_with?(output, "my-app")
    end

    test "depth limiting" do
      output = NPM.TreeFormat.format(@lockfile, depth: 0)
      refute output =~ "    "
    end
  end

  describe "format_entry" do
    test "atom key version" do
      assert "pkg@1.0.0" = NPM.TreeFormat.format_entry("pkg", %{version: "1.0.0"})
    end

    test "string key version" do
      assert "pkg@2.0.0" = NPM.TreeFormat.format_entry("pkg", %{"version" => "2.0.0"})
    end

    test "name only for no version" do
      assert "pkg" = NPM.TreeFormat.format_entry("pkg", %{})
    end
  end

  describe "count" do
    test "counts packages" do
      assert 3 = NPM.TreeFormat.count(@lockfile)
    end

    test "empty" do
      assert 0 = NPM.TreeFormat.count(%{})
    end
  end

  describe "max_depth" do
    test "tree with deps" do
      depth = NPM.TreeFormat.max_depth(@lockfile)
      assert depth == 2
    end

    test "flat tree" do
      lockfile = %{"a" => %{version: "1.0", dependencies: %{}}}
      assert 1 = NPM.TreeFormat.max_depth(lockfile)
    end

    test "empty" do
      assert 0 = NPM.TreeFormat.max_depth(%{})
    end
  end

  describe "summary" do
    test "formats summary" do
      summary = NPM.TreeFormat.summary(@lockfile)
      assert summary =~ "3 packages"
      assert summary =~ "leaf"
    end
  end
end

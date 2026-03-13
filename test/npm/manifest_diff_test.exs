defmodule NPM.ManifestDiffTest do
  use ExUnit.Case, async: true

  @old %{
    "name" => "my-app",
    "version" => "1.0.0",
    "dependencies" => %{"lodash" => "^4.17.0", "express" => "^4.17.0"},
    "devDependencies" => %{"jest" => "^29.0.0"},
    "scripts" => %{"test" => "jest", "build" => "tsc"}
  }

  @new %{
    "name" => "my-app",
    "version" => "1.1.0",
    "dependencies" => %{"lodash" => "^4.17.21", "react" => "^18.0.0"},
    "devDependencies" => %{"jest" => "^29.0.0"},
    "scripts" => %{"test" => "jest", "build" => "tsc", "lint" => "eslint ."}
  }

  describe "diff" do
    test "detects version change" do
      d = NPM.ManifestDiff.diff(@old, @new)
      assert d.version_changed == {"1.0.0", "1.1.0"}
    end

    test "detects added dependency" do
      d = NPM.ManifestDiff.diff(@old, @new)
      deps = d.deps["dependencies"]
      assert "react" in deps.added
    end

    test "detects removed dependency" do
      d = NPM.ManifestDiff.diff(@old, @new)
      deps = d.deps["dependencies"]
      assert "express" in deps.removed
    end

    test "detects changed version range" do
      d = NPM.ManifestDiff.diff(@old, @new)
      deps = d.deps["dependencies"]
      assert Enum.any?(deps.changed, fn {name, _, _} -> name == "lodash" end)
    end

    test "detects added script" do
      d = NPM.ManifestDiff.diff(@old, @new)
      assert "lint" in d.scripts.added
    end

    test "name not changed" do
      d = NPM.ManifestDiff.diff(@old, @new)
      refute d.name_changed
    end

    test "no devDependencies diff when identical" do
      d = NPM.ManifestDiff.diff(@old, @new)
      refute Map.has_key?(d.deps, "devDependencies")
    end
  end

  describe "diff_deps" do
    test "diffs two dep maps" do
      old = %{"a" => "^1.0", "b" => "^2.0"}
      new = %{"a" => "^1.1", "c" => "^3.0"}
      d = NPM.ManifestDiff.diff_deps(old, new)
      assert "c" in d.added
      assert "b" in d.removed
      assert Enum.any?(d.changed, fn {name, _, _} -> name == "a" end)
    end
  end

  describe "equivalent?" do
    test "true for identical" do
      assert NPM.ManifestDiff.equivalent?(@old, @old)
    end

    test "false for different" do
      refute NPM.ManifestDiff.equivalent?(@old, @new)
    end
  end

  describe "format" do
    test "formats diff" do
      d = NPM.ManifestDiff.diff(@old, @new)
      formatted = NPM.ManifestDiff.format(d)
      assert formatted =~ "Version"
      assert formatted =~ "Dependencies changed"
    end

    test "no changes" do
      d = NPM.ManifestDiff.diff(@old, @old)
      assert "No changes." = NPM.ManifestDiff.format(d)
    end
  end
end

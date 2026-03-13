defmodule NPM.TypeFieldTest do
  use ExUnit.Case, async: true

  describe "get" do
    test "returns module" do
      assert "module" = NPM.TypeField.get(%{"type" => "module"})
    end

    test "returns commonjs explicitly" do
      assert "commonjs" = NPM.TypeField.get(%{"type" => "commonjs"})
    end

    test "defaults to commonjs" do
      assert "commonjs" = NPM.TypeField.get(%{})
    end
  end

  describe "esm?/cjs?" do
    test "esm for module type" do
      assert NPM.TypeField.esm?(%{"type" => "module"})
      refute NPM.TypeField.cjs?(%{"type" => "module"})
    end

    test "cjs for default" do
      assert NPM.TypeField.cjs?(%{})
      refute NPM.TypeField.esm?(%{})
    end
  end

  describe "module_type" do
    test ".mjs is always ESM" do
      assert :esm = NPM.TypeField.module_type("lib/utils.mjs", %{})
    end

    test ".cjs is always CJS" do
      assert :cjs = NPM.TypeField.module_type("lib/utils.cjs", %{"type" => "module"})
    end

    test ".mts is ESM" do
      assert :esm = NPM.TypeField.module_type("src/index.mts", %{})
    end

    test ".cts is CJS" do
      assert :cjs = NPM.TypeField.module_type("src/index.cts", %{})
    end

    test ".js follows package type" do
      assert :esm = NPM.TypeField.module_type("index.js", %{"type" => "module"})
      assert :cjs = NPM.TypeField.module_type("index.js", %{})
    end
  end

  describe "stats" do
    test "counts ESM vs CJS" do
      packages = [
        %{"type" => "module"},
        %{"type" => "module"},
        %{"type" => "commonjs"},
        %{}
      ]

      stats = NPM.TypeField.stats(packages)
      assert stats.esm == 2
      assert stats.cjs == 2
      assert stats.esm_pct == 50.0
    end

    test "empty packages" do
      stats = NPM.TypeField.stats([])
      assert stats.total == 0
      assert stats.esm_pct == 0.0
    end
  end

  describe "dual?" do
    test "true with exports and main" do
      data = %{"main" => "./dist/index.js", "exports" => %{"." => "./dist/index.js"}}
      assert NPM.TypeField.dual?(data)
    end

    test "true with main and module" do
      data = %{"main" => "./dist/cjs/index.js", "module" => "./dist/esm/index.mjs"}
      assert NPM.TypeField.dual?(data)
    end

    test "false with only main" do
      refute NPM.TypeField.dual?(%{"main" => "./index.js"})
    end

    test "false for bare package" do
      refute NPM.TypeField.dual?(%{})
    end
  end
end

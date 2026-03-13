defmodule NPM.ImportMapTest do
  use ExUnit.Case, async: true

  @lockfile %{
    "react" => %{version: "18.2.0"},
    "lodash" => %{version: "4.17.21"}
  }

  describe "generate" do
    test "creates import map from lockfile" do
      result = NPM.ImportMap.generate(@lockfile)
      assert result["imports"]["react"] == "https://esm.sh/react@18.2.0"
      assert result["imports"]["lodash"] == "https://esm.sh/lodash@4.17.21"
    end

    test "custom CDN" do
      result = NPM.ImportMap.generate(@lockfile, cdn: "https://cdn.skypack.dev")
      assert result["imports"]["react"] =~ "cdn.skypack.dev"
    end
  end

  describe "generate_for" do
    test "generates for specific packages" do
      result = NPM.ImportMap.generate_for(@lockfile, ["react"])
      assert Map.has_key?(result["imports"], "react")
      refute Map.has_key?(result["imports"], "lodash")
    end
  end

  describe "to_json" do
    test "serializes to JSON" do
      map = NPM.ImportMap.generate(@lockfile)
      json = NPM.ImportMap.to_json(map)
      assert is_binary(json)
      assert json =~ "react"
    end
  end

  describe "to_html" do
    test "generates script tag" do
      map = NPM.ImportMap.generate(@lockfile)
      html = NPM.ImportMap.to_html(map)
      assert html =~ ~s(<script type="importmap">)
      assert html =~ "</script>"
    end
  end

  describe "merge" do
    test "merges two import maps" do
      base = %{"imports" => %{"react" => "https://esm.sh/react@18.0.0"}}

      override = %{
        "imports" => %{
          "react" => "https://esm.sh/react@18.2.0",
          "vue" => "https://esm.sh/vue@3.0.0"
        }
      }

      merged = NPM.ImportMap.merge(base, override)
      assert merged["imports"]["react"] =~ "18.2.0"
      assert Map.has_key?(merged["imports"], "vue")
    end
  end

  describe "count" do
    test "counts imports" do
      map = NPM.ImportMap.generate(@lockfile)
      assert 2 = NPM.ImportMap.count(map)
    end

    test "zero for empty" do
      assert 0 = NPM.ImportMap.count(%{})
    end
  end
end

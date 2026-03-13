defmodule NPM.DepFreshnessTest do
  use ExUnit.Case, async: true

  describe "classify" do
    test "current version" do
      assert :current = NPM.DepFreshness.classify("4.17.21", "4.17.21")
    end

    test "slightly behind" do
      assert :slightly_behind = NPM.DepFreshness.classify("4.17.0", "4.18.0")
    end

    test "minor behind" do
      assert :minor_behind = NPM.DepFreshness.classify("4.10.0", "4.18.0")
    end

    test "major behind" do
      assert :major_behind = NPM.DepFreshness.classify("3.0.0", "4.0.0")
    end

    test "very outdated" do
      assert :very_outdated = NPM.DepFreshness.classify("1.0.0", "4.0.0")
    end
  end

  describe "group" do
    test "groups by freshness" do
      packages = [
        {"lodash", "4.17.21", "4.17.21"},
        {"express", "3.0.0", "4.18.2"},
        {"react", "18.1.0", "18.2.0"}
      ]

      groups = NPM.DepFreshness.group(packages)
      assert "lodash" in groups[:current]
      assert "express" in groups[:major_behind]
    end
  end

  describe "score" do
    test "100 for all current" do
      packages = [{"a", "1.0.0", "1.0.0"}, {"b", "2.0.0", "2.0.0"}]
      assert 100 = NPM.DepFreshness.score(packages)
    end

    test "lower for outdated" do
      packages = [{"a", "1.0.0", "4.0.0"}]
      score = NPM.DepFreshness.score(packages)
      assert score < 50
    end

    test "100 for empty" do
      assert 100 = NPM.DepFreshness.score([])
    end
  end

  describe "format" do
    test "formats groups" do
      groups = %{current: ["a", "b"], major_behind: ["c"]}
      formatted = NPM.DepFreshness.format(groups)
      assert formatted =~ "current: 2 packages"
      assert formatted =~ "major_behind: 1 packages"
    end
  end
end

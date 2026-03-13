defmodule NPM.DeprecationAnalysisTest do
  use ExUnit.Case, async: true

  describe "replacement" do
    test "extracts 'use X instead' pattern" do
      assert "safe-buffer" = NPM.DeprecationAnalysis.replacement("use safe-buffer instead")
    end

    test "extracts 'replaced by' pattern" do
      assert "@babel/plugin" =
               NPM.DeprecationAnalysis.replacement(
                 "This package has been replaced by @babel/plugin"
               )
    end

    test "extracts 'moved to' pattern" do
      assert "@org/new-pkg" =
               NPM.DeprecationAnalysis.replacement("This module has moved to @org/new-pkg")
    end

    test "nil for no replacement" do
      assert nil == NPM.DeprecationAnalysis.replacement("This package is deprecated")
    end
  end

  describe "categorize" do
    test "security" do
      assert :security =
               NPM.DeprecationAnalysis.categorize("This package has security vulnerabilities")
    end

    test "renamed" do
      assert :renamed = NPM.DeprecationAnalysis.categorize("Package has been renamed")
    end

    test "replaced" do
      assert :replaced = NPM.DeprecationAnalysis.categorize("Use lodash instead")
    end

    test "unmaintained" do
      assert :unmaintained = NPM.DeprecationAnalysis.categorize("No longer maintained")
    end

    test "broken" do
      assert :broken = NPM.DeprecationAnalysis.categorize("This package is broken, do not use")
    end

    test "other" do
      assert :other = NPM.DeprecationAnalysis.categorize("deprecated")
    end
  end

  describe "analyze" do
    test "analyzes deprecation list" do
      deprecations = [
        {"request", "Use undici instead"},
        {"left-pad", "No longer maintained"},
        {"core-js", "This package has security vulnerabilities"}
      ]

      result = NPM.DeprecationAnalysis.analyze(deprecations)
      assert result.total == 3
      assert result.with_replacement == 1
      assert {"request", "undici"} in result.replacements
    end

    test "empty list" do
      result = NPM.DeprecationAnalysis.analyze([])
      assert result.total == 0
    end
  end

  describe "format_report" do
    test "no deprecated message" do
      assert "No deprecated packages." = NPM.DeprecationAnalysis.format_report(%{total: 0})
    end

    test "formats with categories and replacements" do
      analysis = %{
        total: 2,
        by_category: %{replaced: 1, unmaintained: 1},
        with_replacement: 1,
        replacements: [{"request", "undici"}]
      }

      report = NPM.DeprecationAnalysis.format_report(analysis)
      assert report =~ "2 deprecated"
      assert report =~ "request → undici"
    end
  end
end

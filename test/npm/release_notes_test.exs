defmodule NPM.ReleaseNotesTest do
  use ExUnit.Case, async: true

  @changelog """
  # Changelog

  ## 3.0.0

  - Breaking: new API
  - Removed deprecated methods

  ## 2.1.0

  - Added feature X
  - Fixed bug Y

  ## 2.0.0

  - Major rewrite
  - New architecture

  ## 1.0.0

  - Initial release
  """

  describe "sections" do
    test "extracts all version sections" do
      sects = NPM.ReleaseNotes.sections(@changelog)
      versions = Enum.map(sects, &elem(&1, 0))
      assert "3.0.0" in versions
      assert "2.1.0" in versions
      assert "1.0.0" in versions
    end

    test "empty for no versions" do
      assert [] = NPM.ReleaseNotes.sections("Just some text")
    end
  end

  describe "for_version" do
    test "finds specific version" do
      notes = NPM.ReleaseNotes.for_version(@changelog, "2.1.0")
      assert notes =~ "feature X"
    end

    test "nil for missing version" do
      assert nil == NPM.ReleaseNotes.for_version(@changelog, "9.9.9")
    end
  end

  describe "between" do
    test "extracts range of versions" do
      notes = NPM.ReleaseNotes.between(@changelog, "2.0.0", "3.0.0")
      assert length(notes) == 3
    end

    test "single version range" do
      notes = NPM.ReleaseNotes.between(@changelog, "2.1.0", "2.1.0")
      assert length(notes) == 1
    end

    test "empty for no matching range" do
      assert [] = NPM.ReleaseNotes.between(@changelog, "5.0.0", "6.0.0")
    end
  end

  describe "version_count" do
    test "counts versions" do
      assert 4 = NPM.ReleaseNotes.version_count(@changelog)
    end
  end

  describe "latest_version" do
    test "returns first version" do
      assert "3.0.0" = NPM.ReleaseNotes.latest_version(@changelog)
    end

    test "nil for empty" do
      assert nil == NPM.ReleaseNotes.latest_version("no versions here")
    end
  end
end

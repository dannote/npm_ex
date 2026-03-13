defmodule NPM.SnapshotDiffTest do
  use ExUnit.Case, async: true

  @old %{
    "lodash" => %{version: "4.17.20"},
    "express" => %{version: "4.17.0"},
    "debug" => %{version: "4.3.0"}
  }

  @new %{
    "lodash" => %{version: "4.17.21"},
    "express" => %{version: "4.17.0"},
    "react" => %{version: "18.2.0"}
  }

  describe "diff" do
    test "detects added packages" do
      d = NPM.SnapshotDiff.diff(@old, @new)
      assert "react" in d.added
    end

    test "detects removed packages" do
      d = NPM.SnapshotDiff.diff(@old, @new)
      assert "debug" in d.removed
    end

    test "detects updated versions" do
      d = NPM.SnapshotDiff.diff(@old, @new)
      updated = Enum.find(d.updated, &(&1.name == "lodash"))
      assert updated.from == "4.17.20"
      assert updated.to == "4.17.21"
    end

    test "counts unchanged" do
      d = NPM.SnapshotDiff.diff(@old, @new)
      assert d.unchanged == 1
    end

    test "empty diff for identical lockfiles" do
      d = NPM.SnapshotDiff.diff(@old, @old)
      assert d.added == []
      assert d.removed == []
      assert d.updated == []
    end
  end

  describe "identical?" do
    test "true for same lockfile" do
      assert NPM.SnapshotDiff.identical?(@old, @old)
    end

    test "false for different lockfiles" do
      refute NPM.SnapshotDiff.identical?(@old, @new)
    end
  end

  describe "summary" do
    test "formats change counts" do
      d = NPM.SnapshotDiff.diff(@old, @new)
      summary = NPM.SnapshotDiff.summary(d)
      assert summary =~ "1 added"
      assert summary =~ "1 removed"
      assert summary =~ "1 updated"
    end

    test "no changes message" do
      d = NPM.SnapshotDiff.diff(@old, @old)
      assert "No changes." = NPM.SnapshotDiff.summary(d)
    end
  end

  describe "format" do
    test "formats detailed diff" do
      d = NPM.SnapshotDiff.diff(@old, @new)
      formatted = NPM.SnapshotDiff.format(d)
      assert formatted =~ "+ react"
      assert formatted =~ "- debug"
      assert formatted =~ "~ lodash"
    end

    test "no changes" do
      d = NPM.SnapshotDiff.diff(@old, @old)
      assert "No changes." = NPM.SnapshotDiff.format(d)
    end
  end
end

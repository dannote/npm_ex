defmodule NPM.MigrationTest do
  use ExUnit.Case, async: true

  describe "lockfile_version" do
    test "npm 6 uses lockfile v1" do
      assert 1 = NPM.Migration.lockfile_version("6.14.0")
    end

    test "npm 8 uses lockfile v2" do
      assert 2 = NPM.Migration.lockfile_version("8.19.0")
    end

    test "npm 10 uses lockfile v3" do
      assert 3 = NPM.Migration.lockfile_version("10.2.0")
    end
  end

  describe "needs_migration?" do
    test "true when versions differ" do
      assert NPM.Migration.needs_migration?(1, "10.2.0")
    end

    test "false when matching" do
      refute NPM.Migration.needs_migration?(3, "10.2.0")
    end
  end

  describe "breaking_changes" do
    test "lists changes between versions" do
      changes = NPM.Migration.breaking_changes(6, 9)
      assert changes != []
      assert Enum.any?(changes, &String.contains?(&1, "peer"))
    end

    test "empty for same version" do
      assert [] = NPM.Migration.breaking_changes(9, 9)
    end

    test "empty for downgrade" do
      assert [] = NPM.Migration.breaking_changes(10, 8)
    end
  end

  describe "steps" do
    test "upgrade steps" do
      steps = NPM.Migration.steps(1, 3)
      assert length(steps) >= 3
      assert Enum.any?(steps, &String.contains?(&1, "Delete"))
    end

    test "no migration needed" do
      assert ["No migration needed."] = NPM.Migration.steps(3, 3)
    end

    test "downgrade not recommended" do
      assert ["Downgrade not recommended."] = NPM.Migration.steps(3, 1)
    end
  end

  describe "format_guide" do
    test "formats guide with numbered steps" do
      guide = NPM.Migration.format_guide(1, 3)
      assert guide =~ "Migration from lockfileVersion 1 to 3"
      assert guide =~ "1."
    end
  end
end

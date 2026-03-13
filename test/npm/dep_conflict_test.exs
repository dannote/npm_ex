defmodule NPM.DepConflictTest do
  use ExUnit.Case, async: true

  @conflicting %{
    "dependencies" => %{"lodash" => "^4.17.0"},
    "devDependencies" => %{"lodash" => "^3.10.0", "jest" => "^29.0"},
    "peerDependencies" => %{"react" => "^18.0"}
  }

  @no_conflict %{
    "dependencies" => %{"express" => "^4.18"},
    "devDependencies" => %{"jest" => "^29.0"}
  }

  describe "find" do
    test "detects conflicting ranges" do
      conflicts = NPM.DepConflict.find(@conflicting)
      assert length(conflicts) == 1
      assert hd(conflicts).name == "lodash"
      assert length(hd(conflicts).ranges) == 2
    end

    test "no conflicts when ranges match" do
      data = %{
        "dependencies" => %{"lodash" => "^4.17.0"},
        "devDependencies" => %{"lodash" => "^4.17.0"}
      }

      assert [] = NPM.DepConflict.find(data)
    end

    test "no conflicts when no overlap" do
      assert [] = NPM.DepConflict.find(@no_conflict)
    end
  end

  describe "conflicts?" do
    test "true with conflicts" do
      assert NPM.DepConflict.conflicts?(@conflicting)
    end

    test "false without" do
      refute NPM.DepConflict.conflicts?(@no_conflict)
    end
  end

  describe "count" do
    test "counts conflicts" do
      assert 1 = NPM.DepConflict.count(@conflicting)
    end
  end

  describe "duplicated" do
    test "finds packages in multiple groups" do
      duped = NPM.DepConflict.duplicated(@conflicting)
      assert Enum.any?(duped, &(&1.name == "lodash"))
    end

    test "includes same-range duplicates" do
      data = %{
        "dependencies" => %{"lodash" => "^4.17.0"},
        "devDependencies" => %{"lodash" => "^4.17.0"}
      }

      duped = NPM.DepConflict.duplicated(data)
      assert length(duped) == 1
    end

    test "empty when no duplication" do
      assert [] = NPM.DepConflict.duplicated(@no_conflict)
    end
  end

  describe "format" do
    test "no conflicts message" do
      assert "No version conflicts." = NPM.DepConflict.format([])
    end

    test "formats conflict details" do
      conflicts = NPM.DepConflict.find(@conflicting)
      formatted = NPM.DepConflict.format(conflicts)
      assert formatted =~ "lodash"
      assert formatted =~ "dependencies"
      assert formatted =~ "devDependencies"
    end
  end
end

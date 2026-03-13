defmodule NPM.PeerDepTest do
  use ExUnit.Case, async: true

  @pkg %{
    "peerDependencies" => %{"react" => "^18.0.0", "react-dom" => "^18.0.0"},
    "peerDependenciesMeta" => %{"react-dom" => %{"optional" => true}}
  }

  @lockfile %{
    "react" => %{version: "18.2.0", integrity: "", tarball: "", dependencies: %{}},
    "react-dom" => %{version: "18.2.0", integrity: "", tarball: "", dependencies: %{}}
  }

  describe "extract" do
    test "extracts peer deps" do
      peers = NPM.PeerDep.extract(@pkg)
      assert peers["react"] == "^18.0.0"
    end

    test "empty for no peers" do
      assert %{} = NPM.PeerDep.extract(%{})
    end
  end

  describe "meta" do
    test "extracts peer meta" do
      m = NPM.PeerDep.meta(@pkg)
      assert m["react-dom"]["optional"] == true
    end

    test "empty for no meta" do
      assert %{} = NPM.PeerDep.meta(%{})
    end
  end

  describe "optional?" do
    test "true for optional peer" do
      assert NPM.PeerDep.optional?("react-dom", @pkg)
    end

    test "false for required peer" do
      refute NPM.PeerDep.optional?("react", @pkg)
    end
  end

  describe "required" do
    test "excludes optional peers" do
      req = NPM.PeerDep.required(@pkg)
      assert Map.has_key?(req, "react")
      refute Map.has_key?(req, "react-dom")
    end
  end

  describe "satisfied?" do
    test "true when all required peers present" do
      assert NPM.PeerDep.satisfied?(@pkg, @lockfile)
    end

    test "false when missing required peer" do
      lockfile = Map.delete(@lockfile, "react")
      refute NPM.PeerDep.satisfied?(@pkg, lockfile)
    end

    test "false when version mismatch" do
      lockfile =
        Map.put(@lockfile, "react", %{
          version: "17.0.0",
          integrity: "",
          tarball: "",
          dependencies: %{}
        })

      refute NPM.PeerDep.satisfied?(@pkg, lockfile)
    end
  end

  describe "unsatisfied" do
    test "empty when satisfied" do
      assert [] = NPM.PeerDep.unsatisfied(@pkg, @lockfile)
    end

    test "lists missing peers" do
      result = NPM.PeerDep.unsatisfied(@pkg, %{})
      assert length(result) == 1
      {name, _range, version} = hd(result)
      assert name == "react"
      assert version == nil
    end

    test "lists version mismatches" do
      lockfile =
        Map.put(@lockfile, "react", %{
          version: "17.0.0",
          integrity: "",
          tarball: "",
          dependencies: %{}
        })

      result = NPM.PeerDep.unsatisfied(@pkg, lockfile)
      assert {_, _, "17.0.0"} = hd(result)
    end
  end

  describe "count_across" do
    test "sums peer deps" do
      packages = [@pkg, %{"peerDependencies" => %{"vue" => "^3.0"}}]
      assert 3 = NPM.PeerDep.count_across(packages)
    end

    test "zero for no peers" do
      assert 0 = NPM.PeerDep.count_across([%{}, %{}])
    end
  end
end

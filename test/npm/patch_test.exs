defmodule NPM.PatchTest do
  use ExUnit.Case, async: true

  describe "list" do
    @tag :tmp_dir
    test "lists patch files", %{tmp_dir: dir} do
      patches_dir = Path.join(dir, "patches")
      File.mkdir_p!(patches_dir)
      File.write!(Path.join(patches_dir, "lodash+4.17.21.patch"), "diff")
      File.write!(Path.join(patches_dir, "react+18.2.0.patch"), "diff")

      result = NPM.Patch.list(dir)
      assert length(result) == 2
      assert Enum.any?(result, &(&1.package == "lodash"))
    end

    @tag :tmp_dir
    test "ignores non-patch files", %{tmp_dir: dir} do
      patches_dir = Path.join(dir, "patches")
      File.mkdir_p!(patches_dir)
      File.write!(Path.join(patches_dir, "lodash+4.17.21.patch"), "diff")
      File.write!(Path.join(patches_dir, "README.md"), "info")

      result = NPM.Patch.list(dir)
      assert length(result) == 1
    end

    @tag :tmp_dir
    test "empty when no patches dir", %{tmp_dir: dir} do
      assert [] = NPM.Patch.list(dir)
    end
  end

  describe "patched?" do
    @tag :tmp_dir
    test "true for patched package", %{tmp_dir: dir} do
      patches_dir = Path.join(dir, "patches")
      File.mkdir_p!(patches_dir)
      File.write!(Path.join(patches_dir, "lodash+4.17.21.patch"), "diff")

      assert NPM.Patch.patched?("lodash", dir)
    end

    @tag :tmp_dir
    test "false for unpatched package", %{tmp_dir: dir} do
      File.mkdir_p!(Path.join(dir, "patches"))
      refute NPM.Patch.patched?("react", dir)
    end
  end

  describe "extract_package_name" do
    test "simple package" do
      assert "lodash" = NPM.Patch.extract_package_name("lodash+4.17.21.patch")
    end

    test "scoped package" do
      assert "@babel/core" = NPM.Patch.extract_package_name("@babel+core+7.23.0.patch")
    end
  end

  describe "filename" do
    test "generates simple filename" do
      assert "lodash+4.17.21.patch" = NPM.Patch.filename("lodash", "4.17.21")
    end

    test "generates scoped filename" do
      assert "@babel+core+7.23.0.patch" = NPM.Patch.filename("@babel/core", "7.23.0")
    end
  end

  describe "count" do
    @tag :tmp_dir
    test "counts patches", %{tmp_dir: dir} do
      patches_dir = Path.join(dir, "patches")
      File.mkdir_p!(patches_dir)
      File.write!(Path.join(patches_dir, "a+1.0.patch"), "")
      File.write!(Path.join(patches_dir, "b+2.0.patch"), "")

      assert 2 = NPM.Patch.count(dir)
    end
  end

  describe "patched_packages" do
    @tag :tmp_dir
    test "returns unique package names", %{tmp_dir: dir} do
      patches_dir = Path.join(dir, "patches")
      File.mkdir_p!(patches_dir)
      File.write!(Path.join(patches_dir, "lodash+4.17.20.patch"), "")
      File.write!(Path.join(patches_dir, "react+18.2.0.patch"), "")

      pkgs = NPM.Patch.patched_packages(dir)
      assert "lodash" in pkgs
      assert "react" in pkgs
    end

    @tag :tmp_dir
    test "empty when no patches", %{tmp_dir: dir} do
      assert [] = NPM.Patch.patched_packages(dir)
    end
  end

  describe "extract_package_name edge cases" do
    test "package with dots in name" do
      assert "co.pilot" = NPM.Patch.extract_package_name("co.pilot+1.0.0.patch")
    end

    test "single name without version" do
      assert "lodash" = NPM.Patch.extract_package_name("lodash.patch")
    end

    test "scoped with long version" do
      assert "@types/node" = NPM.Patch.extract_package_name("@types+node+18.15.0.patch")
    end
  end
end

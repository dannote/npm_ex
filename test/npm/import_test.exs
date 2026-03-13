defmodule NPM.ImportTest do
  use ExUnit.Case, async: true

  describe "detect" do
    @tag :tmp_dir
    test "detects npm lockfile", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "package-lock.json"), "{}")
      assert :npm in NPM.Import.detect(dir)
    end

    @tag :tmp_dir
    test "detects yarn lockfile", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "yarn.lock"), "")
      assert :yarn in NPM.Import.detect(dir)
    end

    @tag :tmp_dir
    test "detects pnpm lockfile", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "pnpm-lock.yaml"), "")
      assert :pnpm in NPM.Import.detect(dir)
    end

    @tag :tmp_dir
    test "detects npm_ex lockfile", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "npm.lock"), "{}")
      assert :npm_ex in NPM.Import.detect(dir)
    end

    @tag :tmp_dir
    test "detects multiple managers", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "package-lock.json"), "{}")
      File.write!(Path.join(dir, "yarn.lock"), "")
      managers = NPM.Import.detect(dir)
      assert :npm in managers
      assert :yarn in managers
    end

    @tag :tmp_dir
    test "empty for no lockfiles", %{tmp_dir: dir} do
      assert [] = NPM.Import.detect(dir)
    end
  end

  describe "from_package_lock" do
    @tag :tmp_dir
    test "reads v3 lockfile with packages field", %{tmp_dir: dir} do
      lock = %{
        "lockfileVersion" => 3,
        "packages" => %{
          "" => %{"dependencies" => %{"react" => "^18.0.0"}},
          "node_modules/react" => %{
            "version" => "18.2.0",
            "integrity" => "sha512-abc",
            "resolved" => "https://registry.npmjs.org/react/-/react-18.2.0.tgz"
          }
        }
      }

      path = Path.join(dir, "package-lock.json")
      File.write!(path, :json.encode(lock))

      {:ok, packages} = NPM.Import.from_package_lock(path)
      assert Map.has_key?(packages, "react")
      assert packages["react"].version == "18.2.0"
    end

    @tag :tmp_dir
    test "reads v1 lockfile with dependencies field", %{tmp_dir: dir} do
      lock = %{
        "lockfileVersion" => 1,
        "dependencies" => %{
          "lodash" => %{
            "version" => "4.17.21",
            "integrity" => "sha512-xyz",
            "resolved" => "https://registry.npmjs.org/lodash/-/lodash-4.17.21.tgz"
          }
        }
      }

      path = Path.join(dir, "package-lock.json")
      File.write!(path, :json.encode(lock))

      {:ok, packages} = NPM.Import.from_package_lock(path)
      assert packages["lodash"].version == "4.17.21"
    end

    test "returns error for missing file" do
      assert {:error, :enoent} =
               NPM.Import.from_package_lock(
                 "/tmp/nonexistent_#{System.unique_integer([:positive])}"
               )
    end
  end

  describe "migration_needed?" do
    @tag :tmp_dir
    test "true when npm lockfile exists but no npm.lock", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "package-lock.json"), "{}")
      assert NPM.Import.migration_needed?(dir)
    end

    @tag :tmp_dir
    test "false when npm.lock exists", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "package-lock.json"), "{}")
      File.write!(Path.join(dir, "npm.lock"), "{}")
      refute NPM.Import.migration_needed?(dir)
    end

    @tag :tmp_dir
    test "false when no lockfiles exist", %{tmp_dir: dir} do
      refute NPM.Import.migration_needed?(dir)
    end
  end

  describe "primary_manager" do
    @tag :tmp_dir
    test "returns first detected manager", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "package-lock.json"), "{}")
      assert :npm = NPM.Import.primary_manager(dir)
    end

    @tag :tmp_dir
    test "nil when no lockfiles", %{tmp_dir: dir} do
      assert nil == NPM.Import.primary_manager(dir)
    end
  end
end

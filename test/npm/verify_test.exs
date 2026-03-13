defmodule NPM.VerifyTest do
  use ExUnit.Case, async: true

  describe "check" do
    @tag :tmp_dir
    test "clean install has no issues", %{tmp_dir: dir} do
      nm = Path.join(dir, "node_modules")
      File.mkdir_p!(Path.join(nm, "react"))

      File.write!(
        Path.join([nm, "react", "package.json"]),
        ~s({"name":"react","version":"18.2.0"})
      )

      lockfile = %{
        "react" => %{version: "18.2.0", integrity: "", tarball: "", dependencies: %{}}
      }

      assert [] = NPM.Verify.check(nm, lockfile)
    end

    @tag :tmp_dir
    test "detects missing packages", %{tmp_dir: dir} do
      nm = Path.join(dir, "node_modules")
      File.mkdir_p!(nm)

      lockfile = %{
        "lodash" => %{version: "4.17.21", integrity: "", tarball: "", dependencies: %{}}
      }

      issues = NPM.Verify.check(nm, lockfile)
      assert length(issues) == 1
      assert hd(issues).type == :missing
      assert hd(issues).package == "lodash"
    end

    @tag :tmp_dir
    test "detects version mismatch", %{tmp_dir: dir} do
      nm = Path.join(dir, "node_modules")
      File.mkdir_p!(Path.join(nm, "react"))

      File.write!(
        Path.join([nm, "react", "package.json"]),
        ~s({"name":"react","version":"17.0.2"})
      )

      lockfile = %{
        "react" => %{version: "18.2.0", integrity: "", tarball: "", dependencies: %{}}
      }

      issues = NPM.Verify.check(nm, lockfile)
      mismatch = Enum.find(issues, &(&1.type == :version_mismatch))
      assert mismatch.expected == "18.2.0"
      assert mismatch.actual == "17.0.2"
    end

    @tag :tmp_dir
    test "detects extraneous packages", %{tmp_dir: dir} do
      nm = Path.join(dir, "node_modules")
      File.mkdir_p!(Path.join(nm, "stale-pkg"))

      File.write!(
        Path.join([nm, "stale-pkg", "package.json"]),
        ~s({"name":"stale-pkg","version":"1.0.0"})
      )

      issues = NPM.Verify.check(nm, %{})
      assert length(issues) == 1
      assert hd(issues).type == :extraneous
    end
  end

  describe "clean?" do
    @tag :tmp_dir
    test "true when all packages match", %{tmp_dir: dir} do
      nm = Path.join(dir, "node_modules")
      File.mkdir_p!(Path.join(nm, "ms"))

      File.write!(
        Path.join([nm, "ms", "package.json"]),
        ~s({"name":"ms","version":"2.1.3"})
      )

      lockfile = %{
        "ms" => %{version: "2.1.3", integrity: "", tarball: "", dependencies: %{}}
      }

      assert NPM.Verify.clean?(nm, lockfile)
    end

    @tag :tmp_dir
    test "false when issues exist", %{tmp_dir: dir} do
      nm = Path.join(dir, "node_modules")
      File.mkdir_p!(nm)

      lockfile = %{
        "missing" => %{version: "1.0.0", integrity: "", tarball: "", dependencies: %{}}
      }

      refute NPM.Verify.clean?(nm, lockfile)
    end
  end

  describe "summary" do
    test "counts by issue type" do
      issues = [
        %{package: "a", type: :missing, expected: "1.0.0", actual: nil},
        %{package: "b", type: :missing, expected: "2.0.0", actual: nil},
        %{package: "c", type: :version_mismatch, expected: "1.0.0", actual: "2.0.0"},
        %{package: "d", type: :extraneous, expected: nil, actual: "1.0.0"}
      ]

      s = NPM.Verify.summary(issues)
      assert s.total == 4
      assert s.missing == 2
      assert s.mismatched == 1
      assert s.extraneous == 1
    end

    test "empty issues" do
      s = NPM.Verify.summary([])
      assert s.total == 0
    end
  end

  describe "format_issue" do
    test "formats missing" do
      issue = %{package: "lodash", type: :missing, expected: "4.17.21", actual: nil}
      formatted = NPM.Verify.format_issue(issue)
      assert formatted =~ "MISSING"
      assert formatted =~ "lodash"
    end

    test "formats mismatch" do
      issue = %{package: "react", type: :version_mismatch, expected: "18.2.0", actual: "17.0.2"}
      formatted = NPM.Verify.format_issue(issue)
      assert formatted =~ "MISMATCH"
      assert formatted =~ "18.2.0"
      assert formatted =~ "17.0.2"
    end

    test "formats extraneous" do
      issue = %{package: "stale", type: :extraneous, expected: nil, actual: "1.0.0"}
      formatted = NPM.Verify.format_issue(issue)
      assert formatted =~ "EXTRANEOUS"
    end
  end
end

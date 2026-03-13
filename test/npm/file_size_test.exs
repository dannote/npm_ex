defmodule NPM.FileSizeTest do
  use ExUnit.Case, async: true

  describe "analyze" do
    @tag :tmp_dir
    test "lists files with sizes", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "small.js"), "x")
      File.write!(Path.join(dir, "big.js"), String.duplicate("x", 1000))

      files = NPM.FileSize.analyze(dir)
      assert length(files) == 2
      assert hd(files).size >= 1000
    end

    @tag :tmp_dir
    test "includes nested files", %{tmp_dir: dir} do
      File.mkdir_p!(Path.join(dir, "lib"))
      File.write!(Path.join(dir, "lib/index.js"), "code")

      files = NPM.FileSize.analyze(dir)
      assert Enum.any?(files, &String.contains?(&1.path, "index.js"))
    end

    test "empty for nonexistent dir" do
      assert [] = NPM.FileSize.analyze("/tmp/nonexistent_#{System.unique_integer([:positive])}")
    end
  end

  describe "largest" do
    @tag :tmp_dir
    test "returns top N files", %{tmp_dir: dir} do
      for i <- 1..5, do: File.write!(Path.join(dir, "f#{i}.js"), String.duplicate("x", i * 100))

      result = NPM.FileSize.largest(dir, 3)
      assert length(result) == 3
      assert hd(result).size >= 400
    end
  end

  describe "by_extension" do
    @tag :tmp_dir
    test "groups by extension", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "a.js"), "xxx")
      File.write!(Path.join(dir, "b.js"), "yyy")
      File.write!(Path.join(dir, "c.css"), "zzz")

      result = NPM.FileSize.by_extension(dir)
      assert Map.has_key?(result, ".js")
      assert Map.has_key?(result, ".css")
    end
  end

  describe "total" do
    @tag :tmp_dir
    test "sums all file sizes", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "a.js"), String.duplicate("x", 100))
      File.write!(Path.join(dir, "b.js"), String.duplicate("y", 200))

      assert NPM.FileSize.total(dir) == 300
    end

    @tag :tmp_dir
    test "zero for empty dir", %{tmp_dir: dir} do
      assert 0 = NPM.FileSize.total(dir)
    end
  end

  describe "format_size" do
    test "bytes" do
      assert "512 B" = NPM.FileSize.format_size(512)
    end

    test "kilobytes" do
      assert "10.0 KB" = NPM.FileSize.format_size(10_240)
    end

    test "megabytes" do
      assert "1.5 MB" = NPM.FileSize.format_size(1_572_864)
    end

    test "zero" do
      assert "0 B" = NPM.FileSize.format_size(0)
    end
  end
end

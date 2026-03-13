defmodule NPM.DistTest do
  use ExUnit.Case, async: true

  @registry_entry %{
    "dist" => %{
      "tarball" => "https://registry.npmjs.org/lodash/-/lodash-4.17.21.tgz",
      "shasum" => "679591c564c3bffaae8454cf0b3df370c3d6911c",
      "integrity" =>
        "sha512-v2kDEe57lecTulaDIuNTPy3Ry4gLGJ6Z1O3vE1krgXZNrsQ+LFTGHVxVjcXPs17LhbZVGedAJv8XZ1tvj5FvSg==",
      "unpackedSize" => 1_412_415,
      "fileCount" => 1054
    }
  }

  describe "extract" do
    test "extracts all dist fields" do
      dist = NPM.Dist.extract(@registry_entry)
      assert dist.tarball =~ "lodash"
      assert dist.shasum =~ "679591"
      assert dist.integrity =~ "sha512"
      assert dist.unpacked_size == 1_412_415
      assert dist.file_count == 1054
    end

    test "defaults for missing dist" do
      dist = NPM.Dist.extract(%{})
      assert dist.tarball == nil
      assert dist.shasum == nil
    end
  end

  describe "has_integrity?" do
    test "true with integrity" do
      dist = NPM.Dist.extract(@registry_entry)
      assert NPM.Dist.has_integrity?(dist)
    end

    test "false without integrity" do
      refute NPM.Dist.has_integrity?(%{integrity: nil})
    end

    test "false with empty integrity" do
      refute NPM.Dist.has_integrity?(%{integrity: ""})
    end
  end

  describe "tarball_url" do
    test "returns tarball URL" do
      dist = NPM.Dist.extract(@registry_entry)
      assert NPM.Dist.tarball_url(dist) =~ "lodash-4.17.21.tgz"
    end

    test "nil for missing" do
      assert nil == NPM.Dist.tarball_url(%{})
    end
  end

  describe "format_size" do
    test "bytes" do
      assert "512 B" = NPM.Dist.format_size(512)
    end

    test "kilobytes" do
      assert "5.5 KB" = NPM.Dist.format_size(5632)
    end

    test "megabytes" do
      assert "1.3 MB" = NPM.Dist.format_size(1_412_415)
    end

    test "unknown for nil" do
      assert "unknown" = NPM.Dist.format_size(nil)
    end
  end

  describe "default_tarball_url" do
    test "generates URL for unscoped package" do
      url = NPM.Dist.default_tarball_url("https://registry.npmjs.org", "lodash", "4.17.21")
      assert url == "https://registry.npmjs.org/lodash/-/lodash-4.17.21.tgz"
    end

    test "generates URL for scoped package" do
      url = NPM.Dist.default_tarball_url("https://registry.npmjs.org", "@babel/core", "7.23.0")
      assert url =~ "core-7.23.0.tgz"
    end
  end

  describe "valid?" do
    test "true with tarball URL" do
      assert NPM.Dist.valid?(%{tarball: "https://example.com/pkg.tgz"})
    end

    test "false without tarball" do
      refute NPM.Dist.valid?(%{tarball: nil})
    end

    test "false with empty tarball" do
      refute NPM.Dist.valid?(%{tarball: ""})
    end
  end
end

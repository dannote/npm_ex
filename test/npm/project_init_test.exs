defmodule NPM.ProjectInitTest do
  use ExUnit.Case, async: true

  describe "initialized?" do
    @tag :tmp_dir
    test "false for empty dir", %{tmp_dir: dir} do
      refute NPM.ProjectInit.initialized?(dir)
    end

    @tag :tmp_dir
    test "true when package.json exists", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "package.json"), "{}")
      assert NPM.ProjectInit.initialized?(dir)
    end
  end

  describe "create_package_json" do
    @tag :tmp_dir
    test "creates package.json", %{tmp_dir: dir} do
      assert :ok = NPM.ProjectInit.create_package_json(dir, name: "my-app")
      content = dir |> Path.join("package.json") |> File.read!() |> :json.decode()
      assert content["name"] == "my-app"
      assert content["private"] == true
    end

    @tag :tmp_dir
    test "error if already exists", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "package.json"), "{}")
      assert {:error, :already_exists} = NPM.ProjectInit.create_package_json(dir)
    end

    @tag :tmp_dir
    test "force overwrites", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "package.json"), "{}")
      assert :ok = NPM.ProjectInit.create_package_json(dir, force: true, name: "new")
    end
  end

  describe "checklist" do
    @tag :tmp_dir
    test "all fail for empty dir", %{tmp_dir: dir} do
      items = NPM.ProjectInit.checklist(dir)
      assert Enum.all?(items, &(not &1.ok))
    end

    @tag :tmp_dir
    test "package.json check passes", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "package.json"), "{}")
      items = NPM.ProjectInit.checklist(dir)
      pkg_item = Enum.find(items, &(&1.item =~ "package.json"))
      assert pkg_item.ok
    end
  end

  describe "ready?" do
    @tag :tmp_dir
    test "false for incomplete setup", %{tmp_dir: dir} do
      refute NPM.ProjectInit.ready?(dir)
    end
  end

  describe "format_checklist" do
    test "formats with checkmarks" do
      items = [
        %{item: "package.json exists", ok: true},
        %{item: "gitignore ok", ok: false}
      ]

      output = NPM.ProjectInit.format_checklist(items)
      assert output =~ "✓ package.json exists"
      assert output =~ "✗ gitignore ok"
    end
  end
end

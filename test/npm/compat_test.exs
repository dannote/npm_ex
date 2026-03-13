defmodule NPM.CompatTest do
  use ExUnit.Case, async: true

  @packages [
    {"lodash", %{}},
    {"express", %{"engines" => %{"node" => ">=14"}}},
    {"modern-pkg", %{"engines" => %{"node" => ">=20"}}}
  ]

  describe "compatible?" do
    test "true without engines" do
      assert NPM.Compat.compatible?(%{}, "18.0.0")
    end

    test "true when version satisfies" do
      data = %{"engines" => %{"node" => ">=16"}}
      assert NPM.Compat.compatible?(data, "18.0.0")
    end

    test "false when version doesn't satisfy" do
      data = %{"engines" => %{"node" => ">=20"}}
      refute NPM.Compat.compatible?(data, "18.0.0")
    end
  end

  describe "incompatible" do
    test "finds incompatible packages" do
      result = NPM.Compat.incompatible(@packages, "18.0.0")
      names = Enum.map(result, &elem(&1, 0))
      assert "modern-pkg" in names
      refute "express" in names
    end

    test "empty when all compatible" do
      assert [] = NPM.Compat.incompatible(@packages, "22.0.0")
    end
  end

  describe "summary" do
    test "computes summary" do
      sum = NPM.Compat.summary(@packages, "18.0.0")
      assert sum.target == "18.0.0"
      assert sum.total == 3
      assert sum.incompatible == 1
    end
  end

  describe "format_report" do
    test "all compatible" do
      sum = NPM.Compat.summary(@packages, "22.0.0")
      report = NPM.Compat.format_report(sum)
      assert report =~ "All"
      assert report =~ "compatible"
    end

    test "incompatible packages" do
      sum = NPM.Compat.summary(@packages, "18.0.0")
      report = NPM.Compat.format_report(sum)
      assert report =~ "1 packages incompatible"
      assert report =~ "modern-pkg"
    end
  end
end

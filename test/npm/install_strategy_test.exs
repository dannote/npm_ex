defmodule NPM.InstallStrategyTest do
  use ExUnit.Case, async: true

  describe "detect" do
    test "defaults to hoisted" do
      assert :hoisted = NPM.InstallStrategy.detect(%{})
    end

    test "detects nested" do
      assert :nested = NPM.InstallStrategy.detect(%{"install-strategy" => "nested"})
    end

    test "detects shallow" do
      assert :shallow = NPM.InstallStrategy.detect(%{"install-strategy" => "shallow"})
    end

    test "detects linked" do
      assert :linked = NPM.InstallStrategy.detect(%{"install-strategy" => "linked"})
    end

    test "handles underscore variant" do
      assert :nested = NPM.InstallStrategy.detect(%{"install_strategy" => "nested"})
    end
  end

  describe "strategies" do
    test "returns all strategies" do
      assert length(NPM.InstallStrategy.strategies()) == 4
    end
  end

  describe "valid?" do
    test "known strategies are valid" do
      assert NPM.InstallStrategy.valid?(:hoisted)
      assert NPM.InstallStrategy.valid?(:nested)
    end

    test "unknown is invalid" do
      refute NPM.InstallStrategy.valid?(:custom)
    end
  end

  describe "describe" do
    test "describes hoisted" do
      desc = NPM.InstallStrategy.describe(:hoisted)
      assert desc =~ "Hoist"
    end

    test "unknown strategy" do
      assert "Unknown strategy" = NPM.InstallStrategy.describe(:custom)
    end
  end

  describe "recommend" do
    test "hoisted for many workspaces" do
      data = %{"workspaces" => ["a", "b", "c", "d"]}
      assert :hoisted = NPM.InstallStrategy.recommend(data)
    end

    test "nested for conflicting versions" do
      data = %{
        "dependencies" => %{"lodash" => "^4.0"},
        "devDependencies" => %{"lodash" => "^3.0"}
      }

      assert :nested = NPM.InstallStrategy.recommend(data)
    end

    test "hoisted by default" do
      assert :hoisted = NPM.InstallStrategy.recommend(%{})
    end
  end

  describe "max_depth" do
    test "nested is infinity" do
      assert :infinity = NPM.InstallStrategy.max_depth(:nested)
    end

    test "hoisted is 1" do
      assert 1 = NPM.InstallStrategy.max_depth(:hoisted)
    end
  end
end

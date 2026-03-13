defmodule NPM.NormalizeTest do
  use ExUnit.Case, async: true

  describe "normalize" do
    test "applies all normalizations" do
      data = %{"name" => "pkg", "author" => "John <john@example.com>"}
      result = NPM.Normalize.normalize(data)
      assert result["main"] == "index.js"
      assert result["author"]["name"] == "John"
    end
  end

  describe "normalize_main" do
    test "defaults to index.js when missing" do
      assert %{"main" => "index.js"} = NPM.Normalize.normalize_main(%{})
    end

    test "preserves existing main" do
      data = %{"main" => "./dist/index.mjs"}
      assert data == NPM.Normalize.normalize_main(data)
    end
  end

  describe "normalize_repository" do
    test "github shorthand" do
      data = %{"repository" => "github:user/repo"}
      result = NPM.Normalize.normalize_repository(data)
      assert result["repository"]["url"] == "https://github.com/user/repo"
      assert result["repository"]["type"] == "git"
    end

    test "gitlab shorthand" do
      data = %{"repository" => "gitlab:user/repo"}
      result = NPM.Normalize.normalize_repository(data)
      assert result["repository"]["url"] == "https://gitlab.com/user/repo"
    end

    test "bitbucket shorthand" do
      data = %{"repository" => "bitbucket:user/repo"}
      result = NPM.Normalize.normalize_repository(data)
      assert result["repository"]["url"] =~ "bitbucket.org"
    end

    test "bare user/repo defaults to github" do
      data = %{"repository" => "user/repo"}
      result = NPM.Normalize.normalize_repository(data)
      assert result["repository"]["url"] == "https://github.com/user/repo"
    end

    test "full URL kept as-is" do
      data = %{"repository" => "https://github.com/user/repo.git"}
      result = NPM.Normalize.normalize_repository(data)
      assert result["repository"]["url"] == "https://github.com/user/repo.git"
    end

    test "object repository unchanged" do
      data = %{"repository" => %{"type" => "git", "url" => "https://example.com"}}
      assert data == NPM.Normalize.normalize_repository(data)
    end
  end

  describe "normalize_bugs" do
    test "string url converted to map" do
      data = %{"bugs" => "https://github.com/user/repo/issues"}
      result = NPM.Normalize.normalize_bugs(data)
      assert result["bugs"]["url"] == "https://github.com/user/repo/issues"
    end

    test "object bugs unchanged" do
      data = %{"bugs" => %{"url" => "https://example.com"}}
      assert data == NPM.Normalize.normalize_bugs(data)
    end
  end

  describe "normalize_homepage" do
    test "removes trailing slash" do
      data = %{"homepage" => "https://example.com/"}
      result = NPM.Normalize.normalize_homepage(data)
      assert result["homepage"] == "https://example.com"
    end

    test "no change without trailing slash" do
      data = %{"homepage" => "https://example.com"}
      assert data == NPM.Normalize.normalize_homepage(data)
    end
  end

  describe "parse_person" do
    test "full person string" do
      result = NPM.Normalize.parse_person("John Doe <john@example.com> (https://john.dev)")
      assert result["name"] == "John Doe"
      assert result["email"] == "john@example.com"
      assert result["url"] == "https://john.dev"
    end

    test "name and email only" do
      result = NPM.Normalize.parse_person("Jane <jane@example.com>")
      assert result["name"] == "Jane"
      assert result["email"] == "jane@example.com"
      refute Map.has_key?(result, "url")
    end

    test "name only" do
      result = NPM.Normalize.parse_person("Bob")
      assert result["name"] == "Bob"
    end

    test "already a map" do
      input = %{"name" => "Alice"}
      assert input == NPM.Normalize.parse_person(input)
    end
  end

  describe "normalize_people" do
    test "normalizes author string" do
      data = %{"author" => "John <john@test.com>"}
      result = NPM.Normalize.normalize_people(data)
      assert result["author"]["name"] == "John"
    end

    test "normalizes contributors list" do
      data = %{"contributors" => ["Alice <a@test.com>", "Bob <b@test.com>"]}
      result = NPM.Normalize.normalize_people(data)
      assert length(result["contributors"]) == 2
      assert hd(result["contributors"])["name"] == "Alice"
    end
  end
end

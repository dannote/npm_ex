# NPM

npm package manager for Elixir.

Resolve, fetch, and install npm packages directly from Mix — no Node.js required.

## Installation

```elixir
def deps do
  [{:npm, "~> 0.1.0"}]
end
```

## Usage

```sh
# Install all deps from package.json
mix npm.install

# Add a package
mix npm.install lodash

# Add with version range
mix npm.install lodash@^4.0
```

## How it works

1. Reads dependencies from `package.json`
2. Resolves the full dependency tree using [PubGrub](https://hex.pm/packages/hex_solver) with [npm semver](https://hex.pm/packages/npm_semver)
3. Downloads tarballs from the npm registry with SHA-512 integrity verification
4. Extracts packages into `deps/npm/`
5. Locks versions in `npm.lock`

## License

MIT

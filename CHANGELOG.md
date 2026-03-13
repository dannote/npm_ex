# Changelog

## 0.4.0

### New Tasks (22 new, 26 total)
- `mix npm.init` — create a new `package.json`
- `mix npm.update` — update all or specific packages
- `mix npm.outdated` — show packages with newer versions available
- `mix npm.tree` — display full dependency tree with circular detection
- `mix npm.why` — explain why a package is installed
- `mix npm.info` — show package details from the registry
- `mix npm.search` — search the npm registry
- `mix npm.run` — run scripts from `package.json`
- `mix npm.exec` — execute binaries from `node_modules/.bin/`
- `mix npm.ci` — frozen lockfile install (CI shortcut)
- `mix npm.check` — verify installation state
- `mix npm.clean` — remove `node_modules/`
- `mix npm.cache status|clean` — manage global cache
- `mix npm.config` — show configuration
- `mix npm.version` — show npm_ex version
- `mix npm.link` — link local packages for development
- `mix npm.diff` — show lockfile changes since last commit
- `mix npm.pack` — create a tarball of the current package
- `mix npm.audit` — check for security vulnerabilities
- `mix npm.dedupe` — re-resolve to minimize duplicates
- `mix npm.prune` — remove extraneous packages
- `mix npm.fund` — show package funding info
- `mix npm.rebuild` — clean and reinstall from lockfile
- `mix npm.uninstall` — alias for `npm.remove`

### Features
- `devDependencies` support (`--save-dev`, `--production`)
- `optionalDependencies` support (`--save-optional`)
- `--save-exact` flag for pinning exact versions
- `node_modules/.bin/` executable linking (string, map, and `directories.bin`)
- Stale package pruning from `node_modules/` on re-install (preserves dotfiles)
- Peer dependency warnings during resolution
- Deprecation warnings during install
- Lockfile diff output showing added/removed/updated packages
- `overrides` support in `package.json`
- Workspaces support (`workspaces` field with glob patterns)
- Custom registry URL via `NPM_REGISTRY` env var
- Auth token support via `NPM_TOKEN` env var
- SHA-256 integrity verification (in addition to SHA-512 and SHA-1)
- Retry with exponential backoff for failed HTTP requests
- `engines`, `bin`, `deprecated`, `hasInstallScript` registry metadata parsing
- `NPM.Validator` module for name/range validation
- `NPM.Compiler` — Mix compiler for automatic npm installs
- `file:` dependency references
- Fix: scoped package copy strategy now creates parent directories
- Fix: prune preserves `.bin/` and other dotfile directories
- 200+ tests (up from 64)

## 0.3.1

- Rename repository to [npm_ex](https://github.com/dannote/npm_ex)

## 0.3.0

- `mix npm.remove` — remove a package from `package.json`
- `mix npm.list` — show installed packages with versions
- `mix npm.install --frozen` — fail if lockfile is stale (CI mode)
- Fix scoped package parsing (`@scope/pkg@^1.0` was splitting incorrectly)
- Timing output for resolve and install steps
- Rename `install/2` to `add/2` in the public API
- Expand test suite to 64 tests

## 0.2.0

- Global package cache at `~/.npm_ex/cache/` — download once, reuse across projects
- `node_modules/` linking via symlinks (unix) or copies (Windows)
- Hoisted flat layout
- Switch from `:httpc` to Req for HTTP
- Add `mix npm.get` task
- Add credo, ex_slop, ex_dna, dialyzer
- Add unit and integration tests
- Add GitHub Actions CI

## 0.1.0

Initial release.

- `mix npm.install` — resolve and install all deps from `package.json`
- `mix npm.install <pkg>` — add a package and install
- PubGrub dependency resolution via `hex_solver`
- npm registry client with abbreviated packuments
- SHA-512 integrity verification
- `npm.lock` lockfile for reproducible installs

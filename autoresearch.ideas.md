# Autoresearch Ideas

## Status: 124 lib modules, 135 test files, 2500 tests

## New Modules
- `NPM.Alias` extensions — resolve npm:pkg@ver aliases, detect alias cycles, expand aliases in lockfile
- `NPM.Gitignore` — generate/validate .gitignore entries for node_modules, lockfiles
- `NPM.PackageUpdate` — compute update operations (major/minor/patch updates available per package)
- `NPM.DependencyGraph` — full transitive closure, shortest path between packages
- `NPM.ManifestDiff` — diff two package.json files (added/removed/changed deps, scripts)
- `NPM.ScriptRunner` — validate script names, detect common patterns (build, test, lint)
- `NPM.ReleaseNotes` — extract release notes from changelog for specific version ranges
- `NPM.IntegrityCheck` — verify installed packages match lockfile (beyond just file existence)
- `NPM.NpmrcMerge` — multi-layer .npmrc resolution (project → user → global)
- `NPM.DepConflict` — detect and report version conflicts between dependency groups

## More Tests for Existing Modules
- Registry error handling paths (network failures, invalid JSON, 404)
- Tarball error paths (corrupt archive, integrity mismatch)
- Resolver edge cases (circular deps, conflicting ranges)
- LockMerge edge cases (conflicting merges, missing entries)
- PackageSpec complex ranges (pre-release, build metadata, tags)
- Mix task tests (argument parsing, output format)
- Compiler edge cases (missing package.json, invalid JSON)
- FrozenInstall additional validation scenarios

## Enhance Existing
- Workspace: workspace:* protocol range support
- CI: clean_and_install! action
- Overrides: flatten nested overrides, validate override specs

# Autoresearch Ideas

## Implemented
- ~~Nested linker, PeerDeps, Dedupe, Workspace, Outdated, Audit, Why, Diff, Fund, License~~
- ~~Prune, Pack, Shrinkwrap, DepCheck, Deprecation, Tree, Search, Stats, Overrides, Verify~~
- ~~Scripts, Token, Publish, Size, BinResolver tests, Compiler tests~~
- ~~Split monolith test file, ex_dna quality gate, fixed code clones~~
- ~~Init, Link, CI, Doctor, Completion, Resolutions, Import, EngineCheck~~
- ~~BundleDeps, OptionalDeps, DevDeps~~

## Medium Priority: New Modules
- `NPM.Exports` — package.json "exports" field parsing (conditional exports, subpath patterns)
- `NPM.TypesResolution` — resolve @types/ packages for TypeScript consumers
- `NPM.PeerDepsCheck` — deep peer dependency compatibility scanner across all installed packages
- `NPM.Workspaces` — monorepo workspace protocol support (workspace:* ranges)
- `NPM.Config` — .npmrc config file parsing and merging (project + user + global)
- `NPM.Exec` — npx-style: resolve and run binaries from packages
- `NPM.ScopeRegistry` — per-scope registry mapping
- `NPM.Rebuild` — rebuild native addons after install

## Medium Priority: More Tests
- Error handling paths in Registry, Tarball, Cache
- Edge cases in Resolver, Linker, LockMerge
- More tests for existing mix tasks
- Lockfile round-trip (write then read) edge cases
- PackageSpec complex range parsing edge cases

## Lower Priority: Enhance Existing
- Pre/post install script execution in Hooks
- devDependencies support in Resolver (--production flag)
- CI module: clean_and_install! action
- Link module: global link registry

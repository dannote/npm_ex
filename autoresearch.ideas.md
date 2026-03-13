# Autoresearch Ideas

## Implemented
- ~~Nested linker~~ (two-phase resolver, nested version conflicts)
- ~~PeerDeps module~~ (extract, check, format_warnings, optional peers)
- ~~Dedupe module~~ (find_duplicates, best_shared_version, savings_estimate)
- ~~Workspace module~~ (discover, dep_graph, build_order, topo sort)
- ~~Outdated module~~ (check, filter_by_type, summary)
- ~~Audit module~~ (check, fixable?, filter_by_severity, compare_severity)
- ~~Why module~~ (explain, direct?, dependents, format_reasons)
- ~~Diff module~~ (compare_files, file_hashes, summary, format_changes)
- ~~Fund module~~ (extract, collect, group_by_url, summary)
- ~~Split monolith test file into per-module files~~

## Medium Priority: New Modules
- `NPM.Prune` — remove extraneous packages from node_modules not in lockfile
- `NPM.Pack` — create tarball from local project (the reverse of extract)
- `NPM.Shrinkwrap` — freeze lockfile to prevent changes
- `NPM.License` — scan and report licenses across dependency tree
- `NPM.Size` — estimate install size, disk usage per package
- `NPM.DepCheck` — find unused dependencies in a project

## Medium Priority: Enhance Existing Modules
- Pre/post install script execution in Hooks (currently only detection)
- bundleDependencies handling in Tarball
- devDependencies support in Resolver (--production flag to skip)
- Progress/streaming output during multi-package downloads

## Lower Priority: More Tests for Existing Code
- Edge cases in existing modules (Resolver, Linker, Lockfile)
- Error handling paths in Registry, Tarball, Cache
- Concurrent access patterns in Cache, NodeModules

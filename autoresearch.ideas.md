# Autoresearch Ideas

## Completed
- ✅ devDependencies support (read_all, add_dep dev:true, --production, --save-dev)
- ✅ Stale package pruning in linker
- ✅ mix npm.outdated
- ✅ bin linking (node_modules/.bin/, string/map/directories.bin)
- ✅ mix npm.update (all / specific package)
- ✅ mix npm.run (scripts from package.json)
- ✅ mix npm.info (inspect package from registry)
- ✅ mix npm.why (dependency chain explanation)
- ✅ mix npm.cache status/clean
- ✅ mix npm.exec (run package binaries)
- ✅ mix npm.init (create package.json)
- ✅ mix npm.clean (remove node_modules)
- ✅ mix npm.ci (frozen lockfile shortcut)
- ✅ mix npm.check (verify installation state)
- ✅ mix npm.tree (full dependency tree with circular detection)
- ✅ mix npm.search (search npm registry)
- ✅ peerDependencies warnings
- ✅ optionalDependencies parsing
- ✅ engines field parsing
- ✅ Custom registry URL (NPM_REGISTRY env var)
- ✅ Auth tokens (NPM_TOKEN env var)
- ✅ Retry logic with exponential backoff
- ✅ overrides support in package.json
- ✅ .bin pruning protection

## Pending Ideas
- Lockfile diff on update (show what changed)
- `--save-exact` flag (pin exact version, no ^ prefix)
- `--save-optional` flag for optionalDependencies
- Workspaces support (monorepo package.json workspaces field)
- `.npmrc` file support for registry config
- Lock file migration (detect old format, upgrade)
- `mix npm.fund` — show funding info for installed packages
- `mix npm.pack` — create tarball of current project
- `mix npm.publish` — publish to npm registry
- `mix npm.link` — link local packages for development
- Parallel cache downloads with progress bar
- `npm.lock` hash in ETS for fast staleness checks
- `engines` field warnings during install
- Conditional exports support (package.json "exports" field)
- `mix npm.rebuild` — rebuild native packages
- `type: "module"` detection and ES module support
- SHA-256 integrity support (currently only sha512 and sha1)

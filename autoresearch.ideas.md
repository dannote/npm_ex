# Autoresearch Ideas

## Status: ~135 lib modules, ~150 test files, 2675 tests

## New Modules
- `NPM.CacheStats` — cache hit/miss metrics, size, cleanup suggestions
- `NPM.PlatformCheck` — verify packages for current OS/arch/libc
- `NPM.RegistryHealth` — check registry connectivity, latency, mirrors
- `NPM.LockfileVersion` — detect/convert between lockfile format versions
- `NPM.TypesCompanion` — suggest @types/* packages for dependencies
- `NPM.PeerDepTree` — build and validate peer dependency trees
- `NPM.AuditFix` — suggest fixes for audit vulnerabilities (upgrade paths)

## More Tests for Existing Modules
- Registry error handling paths (network failures, invalid JSON, 404)
- Tarball error paths (corrupt archive, integrity mismatch)
- Resolver edge cases (circular deps, conflicting ranges)
- Mix task tests (argument parsing, output format)

## Enhance Existing
- Workspace: workspace:* protocol range support
- CI: clean_and_install! action
- Overrides: flatten nested overrides, validate override specs

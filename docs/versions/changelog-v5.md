# Soil v5

No migration necessary from v4.

---

## New Features & Improvements

### Automatic Change Tracking (removes the need for `markDirty:`)

- Added `#soilRecursiveHash`, a recursive content hash implemented for fixed, byte and variable layouts (plus `Ephemeron`, `Behavior`, and a `WeakLayout` variant for Pharo 11 compatibility)
- Introduced a **commit strategy** abstraction on the transaction (`readOnly`, `manual tracking`, `automatic tracking`) — automatic tracking is now the default
- Fingerprints are generated from the recursive hash only once and cached per cluster, avoiding repeated hashing
- This closes the item announced as planned for v5 in the [v4 announcement](ann-v4.md): removing the need for explicit `markDirty:` calls

### Read-Only Transactions Hardened

- Separated **intentional** read-only (`isReadOnly`) from **effective** read-only (a writable transaction that ends up with no changes / `hasChanges`) so each can be reasoned about independently
- Read-only transactions now abort automatically instead of silently committing a no-op
- Read-only transactions in check mode use the fingerprint to detect modification attempts

### Non-Root Indexed Collections

- `SoilPersistentDictionary` can now be used as a non-root object
- Indexed dictionaries can likewise be non-root; index-creation journal entries can be added to the head or tail of the journal so ordering stays correct

### Commit Error Hierarchy

- Added `SoilCommitError` as a common superclass so callers can catch any commit-time failure generically
- Concurrent-modification conflicts are now raised as a `SoilCommitError` as well

### Garbage Collection Foundations

- **First working offline GC:** `Soil>>garbageCollect` compacts each object segment by building a clone and atomically swapping it in (new `SoilObjectSegment>>replaceWith:`, the segment-level counterpart to `SoilIndexRewriter>>replaceIndex`)
- Extracted `SoilCopyingVisitor` as the shared traverse-and-copy core used by both backup and the new GC vacuum
- Added opt-in `Soil>>checkConsistency`, a separate structural/version consistency check (deliberately *not* run automatically as part of `garbageCollect`, which stays lean and fast)
- `garbageCollect` runs now update `SoilMetadata>>lastGarbageCollect`
- Landed the data-layer primitives for a future **online/segment-based** GC (`copyClusterVersionChain:`, `copyVersionChain:upToReadVersion:` gated by `smallestReadVersion`) — foundation only, not yet wired to a GC entry point

### Misc

- Added `at:ifAbsentPut:`
- Removed the `fuel` dependency from the baseline (no longer needed)

---

## Bug Fixes

- Fixed `SoilBehaviorRegistry>>detectIndex:` crashing on `NotFound`
- Fixed the `SoilBehaviorRegistry` version-history cache going stale after commit — reworked to append instead of invalidate
- Fixed `SoilBackupVisitor` not copying the full version history for all segments
- Fixed `SoilFindRecordsVisitor` aborting the entire scan when it hit one bad object
- Fixed `SoilVisitor` depth-first traversal crashing because its `seen` set was left `nil` (two follow-up fixes for related regressions)
- Fixed silent data loss caused by mutating `objectMap` while iterating it during `prepareCommit`
- Fixed `SoilTransaction>>behaviorDescriptionFor:` crashing on a cross-transaction visibility gap
- Fixed silent data corruption in `SoilGraphExporter` / `SoilGraphImporter`
- Fixed imported behavior not surviving a database close/reopen

---

## Refactoring & Internals

- Removed old (pre-v4) index-format code now that the v4 migration guarantees it is unreachable
- `SoilFreePage` no longer writes an unused `#latestVersion`
- `uniqueKeys` is now stored as a bit (`asBit`) instead of a boolean
- Redesigned behavior descriptions towards immutability
- Renamed `objectAtLatestVersionWithId:` to `latestObjectWithId:`
- Disambiguated several "shouldn't happen" exceptions that were previously indistinguishable
- Added class comments across core classes (`SoilObjectTable`, `SoilPersistentDictionary`, serializer/materializer, ...)

---

## Tests & Documentation

- Added tests for cyclic object structures, duplicate-key edge cases, and `at:ifAbsentPut:`
- Added a FAQ entry on cyclic structures
- README updates (ESUG 2026 talk, blog link, PDF links)

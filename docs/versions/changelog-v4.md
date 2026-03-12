# Soil v4

> ⚠️ **Breaking Change:** The new database format is not backwards compatible with v3. See [Migration to v4](migration-v4.md)

---

## New Features & Improvements

### Indexes

- Duplicate key support in indexes
  - `removeKey:value:` – removes a specific key/value pair
  - `removeKey:` – removes all entries for a given key
  - Restore of duplicate keys during journal recovery now works correctly
  - Fixed off-by-one in iterator positioning after `find` in multi-key mode
- Indexes can now be defined on non-root objects
  - Previously only possible on root objects

### Read-Only Transactions

- Added support for read-only transactions
  - Optimised for read-only access without journal overhead

### Journal & Persistence

- Journal is created early and index changes are written to it
  - Changes to the index dictionary are now recorded in the journal
  - Improved consistency during crash recovery
- All modified pages are reliably persisted on commit
  - Fixed an issue where split pages were not fully written to disk

### Graph Exporter / Importer

- Graph exporter and importer ported from the v3 branch into main
  - Enables export and import of the full object graph

### Materializer / Serializer Performance

- Serializer optimisation: classes without `soilTransientInstVars` are serialized faster
  - `hasSoilTransientInstVars` now checks only the direct class, not the full hierarchy
- Materializer now calls `materialized` on all objects, not just root objects
  - `SoilClusterRecord`: `behaviorDescriptions` ivar now holds IDs instead of instances

### Conflict Detection

- Improved error messages for transaction conflicts
  - `ObjectId` is passed as state in the error instead of being prematurely added to the store

### Index Restore / Recovery

- Index restore now takes the index ID into account when opening an existing database
  - Prevents incorrect associations when multiple indexes share the same name

---

## Bug Fixes

- Databases in the old format can no longer be accidentally opened with v4 code
  - Clear error message when attempting to open a v3 database with v4

---

## Refactoring & Internals

- Restore code path now uses item instead of key→value association
- Index version handling refactored
- Segment lookup now uses blocks for deferred evaluation
- `soilTransientInstVars` handling unified

---

## Tests & Documentation

- `SoilIndexIteratorTest`: added `uniqueKeys` dimension
- Documentation and README updated (added YouTube talk links)

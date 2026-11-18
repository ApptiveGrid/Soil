# Soil v6

No migration necessary from v5. The on-disk format is unchanged; journal fragments written by v5 are still read.

> ⚠️ **API changes to be aware of:** `Soil>>checkConsistency` is gone (replaced by trackers, see below), transactions now ignore write attempts by default, and the file lock classes got the `Soil` prefix. Details are listed under [Behavior changes](#behavior-changes).

---

## New Features & Improvements

### Windows Support

- Soil runs on Windows: added `SoilWindowsFileLock` and `SoilWinOverlappedStruct`, building on the original Windows work (PR #974/#980 and #1159) by @mumez and @riverdusty
- File flushing goes through the platform (`FlushFileBuffers` on Windows, `fsync(2)` elsewhere)
- All file handles are closed explicitly; `Soil>>close` closes every part and reports the ones that would not close
- The test suite runs on Windows in CI
- Pharo 14 is a supported load target

### Residents

- Added the `Soil-Resident` package: residents that live in a database, with a supervisor
- Added restarting of a dead resident, giving up after repeated failures, and reporting of a resident stuck in a work unit
- Added stopping, restarting and persistently switching off a single resident
- Added detached objects so a resident can hold an object across transactions

### Consistency Check

- Replaced `Soil>>checkConsistency` by trackers that report findings instead of raising on the first violation
- Added repairs for findings: index size, skip list links, version chains, segment index, behavior registry entries, empty records
- Added checks for index size drift, broken skip list links and version chains, missing behavior descriptions, broken registry entries, empty and unreadable records, outdated index headers
- The check runs on a live database at the version of its transaction
- Added a Roassal view of the object graph with findings (`Soil-Roassal`)

### Indexes

- Added `SoilCursor`, a persistent position on an index that outlives its transaction
- Scans can be bound to a key prefix (`SoilPrefixRange`, `SoilIndexRange`)
- `SoilIndexIterator` can move an entry to a new key without materializing its value
- `nextKeyCloseTo:` answers the key that actually comes after and no longer answers a key its transaction cannot see
- Added recomputing the size of an index

### Backup

- A backup copies indexes at the version its records are read at
- The source journal is left out of a backup unless asked for it (`copyJournal`)
- A database with only its root can be backed up

### Application Migration

- `migrateUpToVersion:` no longer executes the first step twice; each version step has its own transaction and commit
- Progress is reported through `log:` (`SoilSignal`) and the invocation of a version step can be wrapped (`runMigration:withTransaction:`)
- Separated `targetVersion` from `availableVersions`

### Export / Import

- The importer knows the version chain of a behavior, importing a different shape of a class no longer fails; older exports have to be asked for (`acceptExportsFromOlderVersions`)
- A migration can name one object instead of a class, reaches objects embedded in other clusters and can drop an object by answering `nil`
- Replaced objects are paired by name instead of by counting
- An export stream says which format it is and refuses what it cannot carry (`SoilIncompatibleExportFormat`, `SoilUnsupportedError`)
- Export works on a read-only source; an imported record is readable by the transaction that ran the import; imported indexes get an id of their own

### Read-Only Databases & Recovery

- Added `Soil>>readOnly`, which opens every file of a database non-writable
- A reader opens past a journal that is not checkpointed yet
- A read-only open repairs nothing; recovery that is needed but cannot be written refuses with a message that says what it found (`SoilDatabaseNeedsRecovery`)
- Recovery reports which way it went
- A new database gets its first journal fragment right away

### Diagnostics

- Metrics report how far the oldest reader lags (`oldestReaderLag`)
- Added `SoilRecordLocation`, telling where the versions a reader still needs lie (groundwork for the online garbage collector)
- An unreadable record is reported as `SoilUnreadableRecord` and names its object

---

## Behavior changes

- **Removed `Soil>>checkConsistency`**, `SoilConsistencyVisitor`, `SoilConsistencyInspectorVisitor`, `SoilCompareVersionsVisitor` and `SoilTransactionalVisitor` — use trackers and findings
- **Transactions ignore write attempts by default**; `errorOnWriteAttempts` is now a deliberate choice
- **Concurrent removal of a key** is reported as `SoilIndexHasConcurrentChange` (a `SoilCommitError`) instead of `KeyNotFound`
- A visitor reads records and indexes at the version of the transaction it is handed
- `MacOSFileLock` and `UnixFileLock` are now `SoilMacOSFileLock` and `SoilUnixFileLock`
- `SoilObjectIdNotInitialized` and `SoilUnsupportedInExport` are removed; `SoilUnsupportedError` replaces the latter
- A backup no longer copies the source journal by default
- The add key entry writes its old value as part of the entry (version 2; version 1 entries are still read)

---

## Performance

- A commit and an import write their records in one go
- A commit finds its records by hash instead of a linear search
- Writing an object does not read the clusters it points at
- Saying an object is a root again, or writing a value in place into a `SoilPersistentDictionary`, writes nothing
- Index conflicts are detected from the journals alone

---

## Bug Fixes

- Fixed a BTree root split that never marked the new page for writing (#1339, Paul Wilke)
- Fixed a key removal that did not mark its page for writing
- Fixed a reader on an older version failing with `KeyNotFound` for journals no longer in memory; they are read from disk
- Fixed a version chain that leads back into itself looping forever
- Fixed a range lock that the file refused staying registered
- Fixed metadata fields written by different hosts over NFS
- Fixed the index header being read without the stream lock
- Fixed index values compared across their representations failing after a reopen
- Fixed `smallestReadVersion` failing when the last transaction was removed in between
- Fixed the journal fragment of a database that was never committed to and a fragment deleted while still open (Windows)
- Fixed `SoilReadOnlyStrategy` missing a default for `ignoreWriteAttempts`
- Fixed `Soil>>printOn:` printing empty brackets
- Fixed `Boolean` missing `#soilRecursiveHash`
- Fixed the garbage collector deleting its clones without closing them
- Fixed a database with an index header in a format no longer read: it is named (`SoilOutdatedIndexHeader`), not fatal

---

## Refactoring & Internals

- Turning an object into a record is the transaction's job, writing a behavior description the segment's; the importer no longer knows where they live
- An index knows its segment, not the database
- Removed the file-descriptor helpers (`fileno`) and the metadata file's legacy repair
- Clean-code tests now also cover `Soil-Resident` and `Soil-Serializer` and run on every supported Pharo

---

## Tests & Documentation

- Several hundred new tests, mostly for trackers/repairs, residents, export/import, journal and index conflicts, and Windows file handling
- README: Windows support announced, Pharo 14 added, ESUG 2026 talk links

---

## Contributors

Norbert Hartl, Marcus Denker, Andrzej Prochyra, Paul Wilke, Astares, @mumez and @riverdusty (Windows support)

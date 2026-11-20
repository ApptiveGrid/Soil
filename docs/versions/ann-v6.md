# [ANN] Soil v6

We are happy to announce the availability of Soil version 6.

No migration is necessary from v5. The on-disk format is unchanged.

## What is new?

**Soil on Windows.** Soil now runs on Windows. The file locking and flushing is done through the platform (`LockFileEx`, `FlushFileBuffers`), every file handle is closed explicitly, and the test suite runs on Windows in CI. This builds on the original Windows work by @mumez and @riverdusty — thank you both. Pharo 14 is a supported load target as well.

**Residents.** A new package `Soil-Resident` brings active components that live inside a database: a persisted description, a transient resident created from it when the database opens, and a supervisor that starts, ticks, restarts and stops them. Residents get a process and a cadence (interval, coalescing or signal-driven run strategies), can be stopped, restarted or switched off individually, are given up on when their process keeps dying, and are reported when they are stuck in a work unit. Because a resident outlives many transactions, it can hold *detached objects* — stand-ins that compare by object id and can be written back as the next version.

**Consistency check and repair.** Consistency is no longer one check that stops at the first error. A tracking visitor walks the database once and hands everything it reaches to *trackers*, which report *findings*. A finding knows the repair actions that fit it; a person chooses and a repair visitor carries them out: recompute an index size, rebuild broken skip list links, cut a broken version chain, raise a segment index, remove a broken registry entry, write `nil` into an empty record. The check works on a live database and reads at the version of its transaction. `Soil>>checkConsistency` is gone; the trackers replace it. A Roassal view draws the object graph with the findings attached.

**Indexes.** New persistent cursors (a position on an index that outlives its transaction), scans bounded to a key prefix so several structures can share one index, and a move operation that re-keys an entry without materializing its value. `nextKeyCloseTo:` was corrected and no longer answers keys a transaction cannot see. Concurrent removal of a key is now reported as a commit conflict instead of a `KeyNotFound`, and index conflicts are detected from the journals alone. A BTree root split that was never written to disk is fixed (thanks to Paul Wilke).

**Backup, read-only and recovery.** A backup copies indexes at the version its records are read at, leaves the source journal out unless asked for it, and works on a database with only its root. `Soil>>readOnly` opens a whole database read-only, a reader opens past a journal that is not checkpointed yet, and recovery says which way it went — and refuses with a clear message when it is needed but cannot be written.

**Export, import and migration.** The graph importer understands the version chain of a class, so importing into a database that holds another shape no longer fails. A migration can name a single object, reach objects embedded in other clusters and drop an object by answering `nil`. An application migration runs step by step with its own transaction per version, reports its progress and can be wrapped by the application.

**Performance.** Commits and imports write their records in one go, a commit finds its records by hash instead of a linear search, and writing an object no longer reads everything it points at.

A few API changes to be aware of: transactions now ignore write attempts by default, `MacOSFileLock` and `UnixFileLock` got the `Soil` prefix, and `checkConsistency` was replaced as described above.

The more detailed view can be seen here: https://github.com/ApptiveGrid/Soil/blob/main/docs/versions/changelog-v6.md

## What is planned next?

- Multi-index collections and partial indexes (carried over from v4/v5)
- Finishing the online/24-7 garbage collector on top of the offline GC primitives
- Copy-on-write for index pages, so a transaction that only reads copies nothing
- Making Windows support official (removing the allowed-failure from CI)

Hope you like it. Give it a spin and then tell us!

Norbert & Marcus

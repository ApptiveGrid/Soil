# [ANN] Soil v5

We are happy to announce the availability of Soil version 5.

## What is new?

- Automatic change tracking: Soil now computes a recursive content hash for objects and uses it to detect modifications automatically. This removes the need for the explicit `markDirty:` calls that were previously required — something we called out as a goal back in the v4 announcement.
- Read-only transactions have been hardened: we now distinguish a transaction that is *intentionally* read-only from one that just happens to end up with no changes, and read-only transactions abort automatically instead of committing a no-op.
- Indexed collections (`SoilPersistentDictionary` and indexed dictionaries) can now be used as non-root objects, not just at the root of the database.
- A first working garbage collector has landed: `Soil>>garbageCollect` compacts object segments offline by cloning and atomically swapping them in. There's also a new opt-in `Soil>>checkConsistency` you can run separately (e.g. after a GC, or in CI) without slowing down the GC itself. The primitives for a future online/segment-based GC are also in place, though not yet wired up.
- A new `SoilCommitError` hierarchy lets you catch any commit-time failure with one exception class instead of several unrelated ones.
- A good number of crash and silent-data-corruption fixes, notably around the graph exporter/importer, backup version history, and depth-first traversal.

The more detailed view can be seen here: https://github.com/ApptiveGrid/Soil/blob/main/docs/versions/changelog-v5.md

## What is planned next?

- Multi-index collections — one list of objects, multiple indexes over it for different lookup use cases (carried over from v4's plan)
- Partial indexes — an index restricted to a predicate, for fast filtered search and near-free size
- Windows support — the outstanding PR (#980) needs rework since Soil's stream handling isn't currently Windows-compatible (carried over from v4's plan)
- Finishing the online/24-7 garbage collector (Track B) on top of the offline GC primitives that landed in v5
- The remaining offline-GC piece: trimming the meta/behavior-description tail during a GC run

Hope you like it. Give it a spin and then tell us!

Norbert & Marcus

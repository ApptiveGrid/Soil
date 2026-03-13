# [ANN] Soil v4

We are happy to announce the availability of Soil version 4. 


## What is new?

- Indexes (both skip list and Btree+) now have forward and backward pointer (those have been added) so there is new possibilities to have indexes that are traversable in each direction. This needed to be done in a not backward-compatible way. All databases prior to v4 need to be migrated. A migration procedure is available at https://github.com/ApptiveGrid/Soil/blob/main/docs/versions/migration.md
- The indexes prior to v4 have been implemented closely to the interface and behavior of a Dictionary. We've added support for duplicated keys which is necessary when doing secondary indexes. A lot of the changes in v4 are regarding to that because it changed quite a bit how things work. NOTE: duplicate keys are considered a preview in v4. They should be usable but might need to settle a bit more. Until now there is no feature supported making use of duplicated keys. Indexes have unique keys as default. They resemble the old behavior and should just work as before
- journals are now used by a transaction right from the start and creates it while the code operates on it. This way we could remove all brittle intermediate dictionaries like newValues, removedValues in the handling which improved the code a lot
- There is a first version of read-only transactions where one can make sure every attempt to write to the database should end up in an error
- There is also a first version of a graph exporter and importer. This can export a graph on the database level which works even if the application code is not present. This is useful for copying or moving a sub-graph from one database to another in an efficient way. 
- There are plenty of code cleanups and performance improvements. 

The more detailled view can be seen here: https://github.com/ApptiveGrid/Soil/blob/main/docs/versions/changelog-v4.md

## What is planned for v5?

- Multi-index collection. This resembles what most other database have. You have one list of objects but multiple indexes to the same data in order to speed up search for different use cases
- partial indexes. These is a special kind of view to a database index. It consists of a predicate and stores only the elements that pass the predicate. Searching is way faster and things like size are almost for free
- windows support. There has been a PR provided https://github.com/ApptiveGrid/Soil/pull/980 which needs to be fixed as the way soil handles streams is not compatible with windows
- If all goes well we will remove the need for the markDirty: calls completely. Cluster modification tracking will then be automatic and removes a huge annoyance when using soil

Hope you like it. Give it a spin and then tell us!

Norbert & Marcus

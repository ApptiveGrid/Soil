# Changelog

## v2 

release date: **2024-07-19**

**improvements for thi release**

- time serialization now includes nano seconds
- fsync() system call is used instead of fdatasync to make sure file sizes get reported correctly
- behavior registry can be recreated completely from the objects in segment #0 (#recreateIndex)
- file/memory locking can now be configured
- journal has been improved in handling files and also only to keep a fixed amount of files
- checkpoint has been improved to be better aligned with the transaction commit. This should avoid prior journal corruptions
- fsync can be switched off for testing (20x faster)
- backup now uses a readVersion to make a consistent backup which can be done online
- added pharo13 to the build


**corresponding commits**

b7a06b7 fixed time serialization to include nano seconds
25a7d93 use fsync instead of fdatasync to be sure file metadata is up to date
fb489e2 moved methods from apptive grid to soil that are preventing fuel to serialize the whole database
3438d22 Merge pull request #771 from ApptiveGrid/SoilBehaviorRegistry-Cleanup-
f5db1ab Added multiple options to configure lockable stream
edd55c3 enabling to switch off fsync better
1b53023 close journal as well as it is holding the current journal fragment files
152ed83 added rewrite and compact of the index
c2ccad5 reduce possibility that stream position can be changed in between
77a926a fixed/improved initial checkpoint setting. Added guard that file offsets are limited to 24 bit
401b85a Pinned backup to a distinct version
8c61b40 optimize writing journal by using a single lock, flush and sync for a whole collection of entries
bdffed8 Merge pull request #706 from ApptiveGrid/dont-append-checkpoint-on-file-too-big
f8e7aae journal needs to cycle before checkpoint entry is written with an invalid position
fee12b4 Fix checkpoint. Before it was syncing files first and then creating a checkpoint position. Now it syncs at the end to have everything on disk
6799369 Update build.yml: add Pharo13
baaf170 added support for keeping only n fragment files on disk
ab3edf0 fix leaking locks in SoilLockableStream. Now having the lock at hand is sufficient to release it properly

- lots of btree improvements

## v1 

release date: **2024-04-24**

This is the initial release
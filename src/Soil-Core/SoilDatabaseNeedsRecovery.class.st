"
The database's journal needs recovery before what it says is in the database -
but this image may not write to it, either because the Soil instance was opened
read-only or because the filesystem refuses.

#open signals me for damage only: the fragment file of the last checkpoint is
gone, or the checkpoint does not read back. Entries past the last checkpoint are
not damage. A commit writes its journal, then the heap, then the checkpoint, so
every commit leaves them for a moment, and a writer that broke off in between
leaves them for good. A reader cannot tell the two apart, and a reader of a
database that is being written meets the first all the time - refusing them made
its open a bet on the writer's timing. Opened read-only, the database is read as
it is on disk, which may hold the heap of a commit halfway written.

A reader that must not take that for the database asks Soil>>checkForRecovery
after #open, and gets me for entries past the last checkpoint as well. A backup
is such a reader: it would preserve the halfway state.

The repair needs write access, and it is the caller's to make - not something
#open performs behind your back, and not something worth wrapping in a method
of its own, because every step of it is a decision. Opening writable is what
makes recovery run:

	db := Soil path: aPath.
	db open.
	db close.
	db readOnly: true.
	db open.

Whether to repair at all is one of those decisions: the repair writes to the
database, and a copy kept for a post-mortem may be worth more unrepaired. On
genuinely read-only media it cannot be done at all, and then this exception is
the honest answer rather than a failure deep inside a write.
"
Class {
	#name : #SoilDatabaseNeedsRecovery,
	#superclass : #SoilError,
	#instVars : [
		'soil',
		'reason'
	],
	#category : #'Soil-Core-Error'
}

{ #category : #accessing }
SoilDatabaseNeedsRecovery >> messageText [

	^ messageText ifNil: [
		'the database at ',
		(soil ifNil: [ '<unknown>' ] ifNotNil: [ soil path pathString ]),
		' needs recovery, but it cannot be written to',
		(reason ifNil: [ '' ] ifNotNil: [ :each | ': ', each ]) ]
]

{ #category : #accessing }
SoilDatabaseNeedsRecovery >> reason [
	"what made recovery necessary, as SoilDatabaseRecovery>>isNeeded found it"
	^ reason
]

{ #category : #accessing }
SoilDatabaseNeedsRecovery >> reason: aString [
	reason := aString
]

{ #category : #accessing }
SoilDatabaseNeedsRecovery >> soil [

	^ soil
]

{ #category : #accessing }
SoilDatabaseNeedsRecovery >> soil: aSoil [

	soil := aSoil
]

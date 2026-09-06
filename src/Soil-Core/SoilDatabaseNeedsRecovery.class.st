"
The database has journal entries past its last checkpoint, so it has to be
recovered before it can be read - but this image may not write to it, either
because the Soil instance was opened read-only or because the filesystem
refuses.

Recovery is not optional for a reader. A commit writes the heap and then
checkpoints, and the two do not become visible atomically, so a database that
needs recovery can hold half-written object data. Reading it without replaying
the journal would read that halfway state.

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
		'soil'
	],
	#category : #'Soil-Core-Error'
}

{ #category : #accessing }
SoilDatabaseNeedsRecovery >> messageText [

	^ messageText ifNil: [
		'the database at ',
		(soil ifNil: [ '<unknown>' ] ifNotNil: [ soil path pathString ]),
		' needs recovery, but it cannot be written to' ]
]

{ #category : #accessing }
SoilDatabaseNeedsRecovery >> soil [

	^ soil
]

{ #category : #accessing }
SoilDatabaseNeedsRecovery >> soil: aSoil [

	soil := aSoil
]

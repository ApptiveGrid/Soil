Class {
	#name : #SoilGarbageCollectorTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #running }
SoilGarbageCollectorTest >> setUp [
	super setUp.
	soil := (Soil new path: 'soil-gc-tests')
		destroy;
		initializeFilesystem;
		yourself
]

{ #category : #running }
SoilGarbageCollectorTest >> tearDown [
	super tearDown.
	soil ifNotNil: [ soil close ]
]

{ #category : #tests }
SoilGarbageCollectorTest >> testVacuumCurtailedLeavesDatabaseIntact [
	"if the vacuum fails mid-run (injected during the copy phase, after clones are built),
	ifCurtailed deletes the clones and the original database is untouched."
	| tx clonePath |
	tx := soil newTransaction.
	tx root: (SoilTestGraphRoot new nested: (SoilTestNestedObject new label: #kept)).
	tx makeRoot: tx root nested.
	tx commit.
	soil checkpoint.
	clonePath := soil objectRepository firstSegment path, #gc.
	[ SoilGarbageCollectorFailingVisitor new soil: soil; run ]
		on: Error do: [ :e | ].
	self deny: clonePath exists.
	tx := soil newTransaction.
	[ self assert: tx root nested label equals: #kept ] ensure: [ tx abort ]
]

{ #category : #tests }
SoilGarbageCollectorTest >> testVacuumDropsUnreachableObject [
	"an object no longer reachable from root is not copied into the compacted segment."
	| tx dead deadOid tx2 |
	tx := soil newTransaction.
	dead := SoilTestNestedObject new label: #dead.
	tx makeRoot: dead.
	tx root: (Dictionary new at: #dead put: dead; yourself).
	tx commit.
	tx := soil newTransaction.
	deadOid := tx objectIdOf: (tx root at: #dead).
	tx abort.
	tx2 := soil newTransaction.
	tx2 root removeKey: #dead.
	tx2 markDirty: tx2 root.
	tx2 commit.
	soil checkpoint.
	self assert: (soil objectRepository firstSegment basicAt: deadOid index ifAbsent: [ nil ]) notNil.
	soil vacuum.
	self assert: (soil objectRepository firstSegment basicAt: deadOid index ifAbsent: [ #gone ]) equals: #gone
]

{ #category : #tests }
SoilGarbageCollectorTest >> testVacuumKeepsCurrentVersionAndReclaimsOldVersions [
	"no open reader: the current version stays readable, the superseded version is
	dropped, and the objects file shrinks."
	| tx tx2 sizeBefore oid |
	tx := soil newTransaction.
	tx root: (SoilTestGraphRoot new nested: (SoilTestNestedObject new label: #v1)).
	tx makeRoot: tx root nested.
	tx commit.
	tx2 := soil newTransaction.
	tx2 root nested label: #v2.
	tx2 markDirty: tx2 root nested.
	tx2 commit.
	tx := soil newTransaction.
	oid := tx objectIdOf: tx root nested.
	tx abort.
	soil checkpoint.
	sizeBefore := (soil objectRepository firstSegment path / #objects) size.
	self assert: (soil objectRepository firstSegment allVersionsAt: oid index) size equals: 2.
	soil vacuum.
	tx := soil newTransaction.
	[ self assert: tx root nested label equals: #v2 ] ensure: [ tx abort ].
	self assert: (soil objectRepository firstSegment allVersionsAt: oid index) size equals: 1.
	self assert: (soil objectRepository firstSegment path / #objects) size < sizeBefore
]

{ #category : #tests }
SoilGarbageCollectorTest >> testVacuumKeepsVersionsAnOpenReaderNeeds [
	"a reader pinned at an old readVersion must still find its version after the vacuum."
	| tx tx2 oid readerTx |
	tx := soil newTransaction.
	tx root: (SoilTestGraphRoot new nested: (SoilTestNestedObject new label: #v1)).
	tx makeRoot: tx root nested.
	tx commit.
	tx2 := soil newTransaction.
	tx2 root nested label: #v2.
	tx2 markDirty: tx2 root nested.
	tx2 commit.
	tx := soil newTransaction.
	oid := tx objectIdOf: tx root nested.
	tx abort.
	readerTx := soil newTransactionForVersion: 1.
	[ soil vacuum.
	  self assert: (soil objectRepository firstSegment allVersionsAt: oid index) size equals: 2.
	  self assert: readerTx root nested label equals: #v1 ]
		ensure: [ readerTx abort ]
]

{ #category : #tests }
SoilGarbageCollectorTest >> testVacuumLeavesNoCloneDirectory [
	"after a successful vacuum the clone directory has been renamed into place, not left behind."
	| tx |
	tx := soil newTransaction.
	tx root: (SoilTestGraphRoot new nested: (SoilTestNestedObject new label: #kept)).
	tx makeRoot: tx root nested.
	tx commit.
	soil checkpoint.
	soil vacuum.
	self deny: (soil objectRepository firstSegment path, #gc) exists
]

{ #category : #tests }
SoilGarbageCollectorTest >> testVacuumPreservesIndexedDictionary [
	"indexes are carried verbatim; the indexed dictionary and its index-only-reachable
	value must still resolve after the vacuum."
	| tx |
	tx := soil newTransaction.
	tx root: ((SoilIndexedDictionary newWithBackend: SoilSkipList) keySize: 8; maxLevel: 16; yourself).
	tx root at: #foo put: (SoilTestNestedObject new label: #indexed).
	tx commit.
	soil checkpoint.
	soil vacuum.
	tx := soil newTransaction.
	[ self assert: (tx root at: #foo) label equals: #indexed ] ensure: [ tx abort ]
]

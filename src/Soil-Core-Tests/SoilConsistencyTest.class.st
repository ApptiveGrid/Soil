Class {
	#name : #SoilConsistencyTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #helpers }
SoilConsistencyTest >> assertConsistent [
	"what Soil>>checkConsistency used to ask, now that consistency is not one check
	any more: index against heap on both levels, as findings of the trackers of one
	walk (I3), and the versions against the control file (I6)"
	| visitor database application |
	visitor := SoilTrackingVisitor new.
	database := visitor addTracker: SoilDatabaseConsistencyTracker new.
	application := visitor addTracker: SoilApplicationConsistencyTracker new.
	visitor track: soil.
	self assert: (SoilConsistencyReport of: { database. application } readAt: visitor databaseVersion) isEmpty.
	self shouldnt: [ SoilCompareVersionsVisitor new validate: soil ] raise: Error
]

{ #category : #helpers }
SoilConsistencyTest >> commitSampleGraph [
	| tx |
	tx := soil newTransaction.
	tx root: (SoilTestGraphRoot new nested: (SoilTestNestedObject new label: #v1)).
	tx makeRoot: tx root nested.
	tx commit.
	tx := soil newTransaction.
	tx root nested label: #v2.
	tx markDirty: tx root nested.
	tx commit
]

{ #category : #running }
SoilConsistencyTest >> setUp [
	super setUp.
	soil := (Soil new path: 'soil-consistency-tests')
		destroy;
		initializeFilesystem;
		yourself
]

{ #category : #running }
SoilConsistencyTest >> tearDown [
	super tearDown.
	soil ifNotNil: [ soil close ]
]

{ #category : #tests }
SoilConsistencyTest >> testAGarbageCollectLeavesTheDatabaseConsistent [
	"the GC must leave the database I3/I6-consistent."
	self commitSampleGraph.
	soil garbageCollect.
	self assertConsistent
]

{ #category : #tests }
SoilConsistencyTest >> testAHealthyDatabaseIsConsistent [
	self commitSampleGraph.
	self assertConsistent
]

{ #category : #tests }
SoilConsistencyTest >> testADatabaseWithAnIndexIsConsistent [
	"an index page of the latest version is not bogus. The check still stopped at
	version 2, and every index written since the pages got their back links was
	reported as broken"
	| tx dict |
	dict := (SoilIndexedDictionary newWithBackend: SoilSkipList)
		keySize: 10;
		maxLevel: 8;
		yourself.
	tx := soil newTransaction.
	tx root: dict.
	dict at: 1 put: (SoilTestNestedObject new label: #one).
	tx commit.
	self assertConsistent
]

{ #category : #tests }
SoilConsistencyTest >> testAVersionMismatchIsCaught [
	"I6: a divergence between scanned max version and control databaseVersion is caught."
	self commitSampleGraph.
	soil control databaseVersion: 999.
	self should: [ SoilCompareVersionsVisitor new validate: soil ] raise: Error
]

{ #category : #tests }
SoilConsistencyTest >> testTheTrackersCheckAtTheVersionOfTheirTransaction [
	"The consistency trackers read records and indexes at the version of the
	transaction the walk runs with. An index entry committed after that version points
	to an object that has no version there, and reading the index as it is now ended
	the check in 'nil objectId:'"
	| tx dict reader writer visitor database application |
	dict := (SoilIndexedDictionary newWithBackend: SoilSkipList)
		keySize: 10;
		maxLevel: 8;
		yourself.
	tx := soil newTransaction.
	tx root: dict.
	1 to: 3 do: [ :n | dict at: n put: (SoilTestNestedObject new label: n printString) ].
	tx commit.
	reader := soil newTransaction.
	writer := soil newTransaction.
	writer root at: 4 put: (SoilTestNestedObject new label: 'late').
	writer commit.

	visitor := SoilTrackingVisitor new.
	visitor transaction: reader.
	database := visitor addTracker: SoilDatabaseConsistencyTracker new.
	application := visitor addTracker: SoilApplicationConsistencyTracker new.
	[ self shouldnt: [ visitor track: soil ] raise: Error ]
		ensure: [ reader abort ].
	self assert: (SoilConsistencyReport of: { database. application } readAt: visitor databaseVersion) isEmpty
]

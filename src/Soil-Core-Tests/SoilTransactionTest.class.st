Class {
	#name : #SoilTransactionTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests-Model'
}

{ #category : #accessing }
SoilTransactionTest >> path [ 
	^ 'soil-tests'
]

{ #category : #running }
SoilTransactionTest >> setUp [ 
	super setUp.
	soil := Soil new 
		path: self path;
		destroy;
		initializeFilesystem;
		yourself.
]

{ #category : #running }
SoilTransactionTest >> tearDown [ 
	super tearDown.
	soil ifNotNil: [ 
		soil close ]
]

{ #category : #tests }
SoilTransactionTest >> testAddSameObjectIdTwice [
	| tx |
	tx := SoilTransaction new.
	tx atObjectId: (SoilObjectId segment: 1 index: 0) putObject: Object new. 
	tx atObjectId: (SoilObjectId segment: 1 index: 0) putObject: Object new. 
	self assert: tx commitStrategy records size equals: 2
]

{ #category : #tests }
SoilTransactionTest >> testCheckpointAndContinue [
	| tx |
	tx := soil newTransaction.
	tx root: Object new.
	tx commitAndContinue.
	self deny: tx needsCommit .
	 
	
]

{ #category : #tests }
SoilTransactionTest >> testConflictingReadVersion [
	| obj tx1 tx2 tx3 |
	obj := SoilTestGraphRoot new 
		nested: (SoilTestNestedObject new label: 'first').
	"make object to test to be in database"
	tx1 := soil newTransaction.
	tx1 root: obj.
	tx1 commit.
	"open a transaction, modify but do not commit"
	tx2 := soil newTransaction.
	tx2 root nested label: 'second'.
	tx2 markDirty: tx2 root.
	"open concurrent transaction, make concurrent modification
	and commit"
	tx3 := soil newTransaction.
	tx3 root nested label: 'third'.
	tx3 markDirty: tx3 root.
	tx3 commit.
	"when trying to commit the second transaction the concurrent
	modification should throw an exception"
	self 
		should: [ tx2 commit ]
		raise: SoilObjectHasConcurrentChange 
]

{ #category : #tests }
SoilTransactionTest >> testEmptyAbort [
	| tx |
	tx := soil newTransaction.
	tx root: Object new.
	tx abort.
	self assert: tx isAborted
]

{ #category : #tests }
SoilTransactionTest >> testFindObject [
	| tx object |
	tx := soil newTransaction.
	tx root: Object new.
	tx commit.
	
	tx := soil newTransaction.
	object := tx findObject: [ :each | true ].
	"we get the object we commited above"
	self assert: object class equals: Object.
	tx abort
]

{ #category : #tests }
SoilTransactionTest >> testFindRecords [
	| tx records |
	tx := soil newTransaction.
	tx root: Object new.
	tx commit.
	
	tx := soil newTransaction.
	records := tx findRecords: [ :each | true ].
	self assert: records size equals: 2.
	tx abort
]

{ #category : #tests }
SoilTransactionTest >> testPrepareCommitSurvivesObjectMapGrowingDuringScan [
	"prepareCommit iterates transaction objectMap to find changed records. If handling
	one record causes further objects to become known to the transaction (as a lazily
	materializing reference can), objectMap grows while it is being scanned. Pharo's
	HashedCollection>>do: does not tolerate that: growing the dictionary mid-iteration
	can silently skip entries that were already there before the growth, so a changed
	record can be dropped from the commit without any error. This reproduces that shape
	directly against objectMap, independent of what actually triggers the growth."
	| tx map growingRecord changedRecords |
	tx := SoilTransaction new.
	map := tx objectMap.
	changedRecords := OrderedCollection new.
	1 to: 8 do: [ :i | | record |
		record := SoilTestGrowingRecord new.
		record changed: true.
		changedRecords add: record.
		map at: Object new put: record ].
	growingRecord := changedRecords first.
	growingRecord onHasChanged: [
		1 to: 200 do: [ :i | map at: Object new put: SoilTestGrowingRecord new ] ].
	tx commitStrategy prepareCommit.
	changedRecords do: [ :record |
		self assert: (tx commitStrategy records includes: record) ]
]

{ #category : #tests }
SoilTransactionTest >> testRootObject [
	| tx obj |
	obj := Object new.
	tx := soil newTransaction.
	tx root: obj.
	self assert: (tx isRoot: obj).
	self assert: (tx isPersistent: obj)
	 

]

{ #category : #tests }
SoilTransactionTest >> testTwoRootsWithAlwaysRoot [
	| tx obj1 obj2 |
	tx := soil newTransaction.
	obj1 := SoilTestGraphRoot new.
	obj2 := SOTestClusterAlwaysRoot new.
	obj1 nested: obj2.
	tx makeRoot: obj1.
	self assert: tx commitStrategy records size equals: 1.
	"obj1 is made root but refers to an object that has a class
	side setting for being root. The second object is being made
	root when serializing obj1 "
	tx basicCommit.
	"expect 4 records: 2 instances and 2 classes"
	self assert: tx commitStrategy records size equals: 4
]

{ #category : #tests }
SoilTransactionTest >> testTwoRootsWithMakeRoot [
	| tx obj1 obj2 |
	tx := soil newTransaction.
	obj1 := Object new.
	obj2 := Object new.
	tx makeRoot: obj1.
	tx makeRoot: obj2.
	self assert: tx commitStrategy records size equals: 2
]

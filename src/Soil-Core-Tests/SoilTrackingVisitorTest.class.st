Class {
	#name : #SoilTrackingVisitorTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests-Visitor'
}

{ #category : #helpers }
SoilTrackingVisitorTest >> commitSampleGraph [
	"two clusters, the second in two versions, and an index with two values"
	| tx dict |
	tx := soil newTransaction.
	dict := (SoilIndexedDictionary newWithBackend: SoilSkipList)
		keySize: 10;
		maxLevel: 8;
		yourself.
	tx root: (SoilTestGraphRoot new 
		nested: (SoilTestNestedObject new 
			label: #v1;
			reference: dict;
			yourself);
		yourself).
	tx makeRoot: tx root nested.
	tx makeRoot: dict.
	dict at: 1 put: (SoilTestNestedObject new label: #one).
	dict at: 2 put: (SoilTestNestedObject new label: #two).
	tx commit.
	tx := soil newTransaction.
	tx root nested label: #v2.
	tx markDirty: tx root nested.
	tx commit
]

{ #category : #running }
SoilTrackingVisitorTest >> setUp [
	super setUp.
	soil := (Soil new path: 'soil-tracking-tests')
		destroy;
		initializeFilesystem;
		yourself
]

{ #category : #running }
SoilTrackingVisitorTest >> tearDown [
	super tearDown.
	soil ifNotNil: [ soil close ]
]

{ #category : #tests }
SoilTrackingVisitorTest >> testAnObjectIdBeyondItsSegmentIsCollected [
	"the old visitor ended the whole check on the first such id; a tracker collects it"
	| visitor tracker beyond |
	self commitSampleGraph.
	visitor := SoilTrackingVisitor new soil: soil; yourself.
	tracker := SoilDatabaseConsistencyTracker new.
	beyond := SoilObjectId segment: 1 index: (soil objectRepository segmentAt: 1) lastObjectIndex + 1.
	tracker trackObjectId: beyond in: visitor.
	tracker trackObjectId: (SoilObjectId segment: 2 index: 1) in: visitor.
	tracker trackObjectId: SoilObjectId root in: visitor.
	self assert: tracker errors size equals: 2.
	self assert: (tracker errors includesKey: beyond)
]

{ #category : #tests }
SoilTrackingVisitorTest >> testEveryTrackerSeesEveryClusterOnce [
	| visitor first second tx expected |
	self commitSampleGraph.
	tx := soil newTransaction.
	expected := ((tx findRecords: [ :each | true ]) collect: [ :each | each objectId ]) asSet.
	tx abort.
	visitor := SoilTrackingVisitor new.
	first := visitor addTracker: SoilTestCountingTracker new.
	second := visitor addTracker: SoilTestCountingTracker new.
	visitor track: soil.
	{ first. second } do: [ :each |
		self assert: each clusters size equals: expected size.
		self assert: each clusters asSet equals: expected.
		self deny: each indexes isEmpty ]
]

{ #category : #tests }
SoilTrackingVisitorTest >> testOnlyTheDatabaseLevelRunsWithoutATransaction [
	| visitor tracker |
	self commitSampleGraph.
	soil notificationHandler: SoilMetrics new.
	visitor := SoilTrackingVisitor new.
	tracker := visitor addTracker: SoilDatabaseConsistencyTracker new.
	visitor track: soil.
	self assert: visitor transaction isNil.
	self assert: soil notificationHandler transactionsCreated equals: 0.
	self assert: tracker errors isEmpty
]

{ #category : #tests }
SoilTrackingVisitorTest >> testTheApplicationLevelGetsOneTransactionForAllTrackers [
	| visitor |
	self commitSampleGraph.
	soil notificationHandler: SoilMetrics new.
	visitor := SoilTrackingVisitor new.
	visitor addTracker: SoilDatabaseConsistencyTracker new.
	visitor addTracker: SoilApplicationConsistencyTracker new.
	visitor addTracker: SoilApplicationConsistencyTracker new.
	visitor track: soil.
	self assert: soil notificationHandler transactionsCreated equals: 1.
	self assert: soil transactionManager smallestReadVersion isNil
]

{ #category : #tests }
SoilTrackingVisitorTest >> testTheConsistencyTrackersFindNothingOnAHealthyDatabase [
	| visitor database application |
	self commitSampleGraph.
	visitor := SoilTrackingVisitor new.
	database := visitor addTracker: SoilDatabaseConsistencyTracker new.
	application := visitor addTracker: SoilApplicationConsistencyTracker new.
	application materializeObjects.
	visitor track: soil.
	self assert: database errors isEmpty.
	self assert: application errors isEmpty
]

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
SoilTrackingVisitorTest >> testARepairRecomputesADriftedIndexSize [
	| tx indexId index visitor tracker repair |
	self commitSampleGraph.
	tx := soil newTransaction.
	indexId := tx root nested reference id.
	tx abort.
	index := (soil objectRepository segmentAt: 1) indexAt: indexId.
	index headerPage size: 5.
	visitor := SoilTrackingVisitor new.
	tracker := visitor addTracker: SoilDatabaseConsistencyTracker new.
	visitor track: soil.

	repair := (SoilRepairVisitor on: soil)
		repair: (tracker findings collect: [ :each | each defaultRepairAction ]);
		yourself.
	self assert: repair repaired size equals: 1.
	self assert: repair failed isEmpty.
	soil close; open.
	tx := soil newTransaction.
	self assert: tx root nested reference size equals: 2.
	tx abort.
	visitor := SoilTrackingVisitor new.
	tracker := visitor addTracker: SoilDatabaseConsistencyTracker new.
	visitor track: soil.
	self assert: tracker findings isEmpty
]

{ #category : #tests }
SoilTrackingVisitorTest >> testAReportIsPlainValues [
	"what the metabase stores or sends: a dictionary of numbers, strings and symbols"
	| report dictionary |
	report := SoilConsistencyReport 
		databaseVersion: 7 
		findings: { SoilIndexSizeDrift segment: 1 indexId: 'abc' stored: 5 counted: 2 }.
	dictionary := report asDictionary.
	self assert: (dictionary at: #databaseVersion) equals: 7.
	self assert: ((dictionary at: #findings) first at: #kind) equals: #indexSizeDrift.
	self assert: ((dictionary at: #findings) first at: #stored) equals: 5.
	self assert: ((dictionary at: #findings) first at: #counted) equals: 2.
	self assert: ((dictionary at: #findings) first at: #indexId) equals: 'abc'.
	self assert: (((dictionary at: #findings) first at: #repairActions) first at: #action) equals: #recomputeIndexSize.
	self assert: (((dictionary at: #findings) first at: #repairActions) first at: #default)
]

{ #category : #tests }
SoilTrackingVisitorTest >> testAnIndexWhoseSizeHasDriftedIsNamed [
	"named with what a repair needs to find it again: the segment and the index id"
	| tx indexId index visitor tracker finding |
	self commitSampleGraph.
	tx := soil newTransaction.
	indexId := tx root nested reference id.
	tx abort.
	"the index as the segment holds it; a transaction works on a copy-on-write layer
	over it"
	index := (soil objectRepository segmentAt: 1) indexAt: indexId.
	index headerPage size: 5.
	visitor := SoilTrackingVisitor new.
	tracker := visitor addTracker: SoilDatabaseConsistencyTracker new.
	visitor track: soil.
	self assert: tracker findings size equals: 1.
	finding := tracker findings first.
	self assert: finding class equals: SoilIndexSizeDrift.
	self assert: finding segment equals: 1.
	self assert: finding indexId equals: indexId.
	self assert: finding stored equals: 5.
	self assert: finding counted equals: 2.
	self assert: finding isRepairable.
	self assert: index headerPage size equals: 5
]

{ #category : #tests }
SoilTrackingVisitorTest >> testAnIndexSizeThatSettlesOnTheSecondReadIsNotNamed [
	"a commit between reading the header and counting shows a difference that is gone
	the next moment"
	| tracker |
	tracker := SoilTestSettlingSizeTracker new
		reads: { 5 -> 2. 2 -> 2 };
		yourself.
	tracker checkSizeOf: nil segment: nil.
	self assert: tracker findings isEmpty
]

{ #category : #tests }
SoilTrackingVisitorTest >> testAnIndexSizeThatStaysOffIsNamedWithTheSecondRead [
	| tracker segment |
	self commitSampleGraph.
	segment := soil objectRepository segmentAt: 1.
	tracker := SoilTestSettlingSizeTracker new
		reads: { 6 -> 2. 5 -> 2 };
		yourself.
	tracker checkSizeOf: (SoilSkipList new id: 'abc'; yourself) segment: segment.
	self assert: tracker findings size equals: 1.
	self assert: tracker findings first stored equals: 5.
	self assert: tracker findings first counted equals: 2
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
	self assert: tracker findings size equals: 2.
	self assert: (tracker findings collect: [ :each | each kind ]) asSet equals: #(objectIdOutsideSegment) asSet.
	self assert: tracker findings first objectId equals: beyond
]

{ #category : #tests }
SoilTrackingVisitorTest >> testAnUnexpectedErrorBecomesAFinding [
	| tracker |
	tracker := SoilDatabaseConsistencyTracker new.
	tracker check: #something using: [ Error signal: 'nobody expected this' ].
	self assert: tracker findings size equals: 1.
	self assert: tracker findings first kind equals: #unexpected.
	self assert: (tracker findings first description includesSubstring: 'nobody expected this')
]

{ #category : #tests }
SoilTrackingVisitorTest >> testAGraphTrackerLeadsFromAnIndexValueBackToTheRoot [
	"references and index values are both edges, and what points to a node is known
	without a second pass"
	| tx dictId valueId visitor graph valueNode |
	self commitSampleGraph.
	tx := soil newTransaction.
	dictId := tx objectIdOf: tx root nested reference.
	valueId := tx objectIdOf: (tx root nested reference at: 1).
	tx abort.
	visitor := SoilTrackingVisitor new.
	graph := visitor addTracker: SoilGraphTracker new.
	visitor track: soil.
	valueNode := graph nodeAt: valueId ifAbsent: [ nil ].
	self assert: valueNode notNil.
	self assert: valueNode isRead.
	self assert: ((valueNode incoming collect: [ :each | each objectId ]) includes: dictId).
	self assert: ((graph nodeAt: dictId ifAbsent: [ nil ]) outgoing includes: valueId).
	self assert: valueNode findRootPath last index equals: 1.
	self assert: graph unreadNodes isEmpty
]

{ #category : #tests }
SoilTrackingVisitorTest >> testAGraphTrackerKnowsWhichClusterHoldsAnIndex [
	| tx dict visitor graph |
	self commitSampleGraph.
	tx := soil newTransaction.
	dict := tx root nested reference.
	visitor := SoilTrackingVisitor new.
	graph := visitor addTracker: SoilGraphTracker new.
	visitor track: soil.
	self
		assert: (graph ownerOfIndex: dict id segment: 1) objectId
		equals: (tx objectIdOf: dict).
	tx abort
]

{ #category : #tests }
SoilTrackingVisitorTest >> testAGraphTrackerKeepsWhatLeadsNowhere [
	"a target that is pointed at and never read: the object id leads nowhere, and
	the node says who points to it"
	| graph from nowhere |
	graph := SoilGraphTracker new.
	from := graph nodeAt: (SoilObjectId segment: 1 index: 1).
	from beRead.
	nowhere := SoilObjectId segment: 1 index: 99.
	graph from: from to: nowhere.
	self assert: graph unreadNodes size equals: 1.
	self assert: graph unreadNodes first objectId equals: nowhere.
	self assert: (graph unreadNodes first incoming includes: from)
]

{ #category : #tests }
SoilTrackingVisitorTest >> testTheGraphViewPutsAFindingOnTheClusterItIsAbout [
	"a drifted index size is about the cluster that holds the index"
	| tx indexId dictId view |
	self commitSampleGraph.
	tx := soil newTransaction.
	indexId := tx root nested reference id.
	dictId := tx objectIdOf: tx root nested reference.
	tx abort.
	((soil objectRepository segmentAt: 1) indexAt: indexId) headerPage size: 5.
	view := SoilGraphView of: soil.
	self assert: view findings size equals: 1.
	self assert: view nodesWithFindings size equals: 1.
	self assert: view nodesWithFindings first objectId equals: dictId.
	self assert: view nodesWithFindings first findings first class equals: SoilIndexSizeDrift
]

{ #category : #tests }
SoilTrackingVisitorTest >> testATrackerIsToldTheIndexAValueCameFrom [
	| visitor counting tx dictId |
	self commitSampleGraph.
	tx := soil newTransaction.
	dictId := tx root nested reference id.
	tx abort.
	visitor := SoilTrackingVisitor new.
	counting := visitor addTracker: SoilTestCountingTracker new.
	visitor track: soil.
	self assert: (counting valuesOfIndex: dictId) size equals: 2
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
	self assert: tracker findings isEmpty
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
	self assert: database findings isEmpty.
	self assert: application findings isEmpty.
	self assert: (SoilConsistencyReport of: { database. application } readAt: visitor databaseVersion) isEmpty
]

{ #category : #tests }
SoilTrackingVisitorTest >> testAFailingRepairActionIsKeptAndTheOthersGoOn [
	| tx indexId index missing repair |
	self commitSampleGraph.
	tx := soil newTransaction.
	indexId := tx root nested reference id.
	tx abort.
	index := (soil objectRepository segmentAt: 1) indexAt: indexId.
	index headerPage size: 5.
	missing := SoilRecomputeIndexSize segment: 1 indexId: 'noSuchIndex'.
	repair := (SoilRepairVisitor on: soil)
		repair: { missing. SoilRecomputeIndexSize segment: 1 indexId: indexId };
		yourself.
	self assert: repair failed size equals: 1.
	self assert: repair failed first key equals: missing.
	self assert: repair repaired size equals: 1.
	self assert: index headerPage size equals: 2
]

{ #category : #tests }
SoilTrackingVisitorTest >> testAFindingWithoutRepairOffersNoAction [
	| finding |
	finding := SoilObjectIdOutsideSegment objectId: (SoilObjectId segment: 2 index: 1) reason: 'test'.
	self assert: finding repairActions isEmpty.
	self deny: finding isRepairable.
	self assert: finding defaultRepairAction isNil
]

{ #category : #tests }
SoilTrackingVisitorTest >> testARepairActionIsMadeAgainFromItsDictionary [
	"a script and a route start from the same form: the dictionary a finding offers"
	| action again |
	action := (SoilIndexSizeDrift segment: 1 indexId: 'abc' stored: 5 counted: 2) defaultRepairAction.
	again := SoilRepairAction fromDictionary: action asDictionary.
	self assert: again class equals: SoilRecomputeIndexSize.
	self assert: again segment equals: 1.
	self assert: again indexId equals: 'abc'.
	self assert: again isDefault
]

{ #category : #tests }
SoilTrackingVisitorTest >> testAnUnknownRepairActionIsRefused [
	self
		should: [ SoilRepairAction fromDictionary: { #action -> #formatTheDisk } asDictionary ]
		raise: SoilUnknownRepairAction.
	self
		should: [ SoilRepairAction fromDictionary: Dictionary new ]
		raise: SoilUnknownRepairAction
]

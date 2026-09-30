"
The graph a walk collects, and the findings of the same walk on its nodes.
"
Class {
	#name : #SoilGraphTrackerTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Roassal'
}

{ #category : #helpers }
SoilGraphTrackerTest >> commitSampleGraph [
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
SoilGraphTrackerTest >> setUp [
	super setUp.
	soil := (Soil new path: 'soil-graph-tests')
		destroy;
		initializeFilesystem;
		yourself
]

{ #category : #running }
SoilGraphTrackerTest >> tearDown [
	super tearDown.
	soil ifNotNil: [ soil close ]
]

{ #category : #tests }
SoilGraphTrackerTest >> testAGraphTrackerLeadsFromAnIndexValueBackToTheRoot [
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
SoilGraphTrackerTest >> testAGraphTrackerKnowsWhichClusterHoldsAnIndex [
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
SoilGraphTrackerTest >> testAGraphTrackerKeepsWhatLeadsNowhere [
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
SoilGraphTrackerTest >> testAFindingIsPutOnTheClusterItIsAbout [
	"a drifted index size is about the cluster that holds the index; #of: walks with the
	graph and both consistency trackers"
	| tx indexId dictId graph |
	self commitSampleGraph.
	tx := soil newTransaction.
	indexId := tx root nested reference id.
	dictId := tx objectIdOf: tx root nested reference.
	tx abort.
	((soil objectRepository segmentAt: 1) indexAt: indexId) headerPage size: 5.
	graph := SoilGraphTracker of: soil.
	self assert: graph findings size equals: 1.
	self assert: graph nodesWithFindings size equals: 1.
	self assert: graph nodesWithFindings first objectId equals: dictId.
	self assert: graph nodesWithFindings first findings first class equals: SoilIndexSizeDrift
]

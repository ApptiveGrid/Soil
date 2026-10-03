Class {
	#name : #SoilTrackingVisitorTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests-Visitor'
}

{ #category : #helpers }
SoilTrackingVisitorTest >> commitIndexOfManyPages [
	"an index with enough values to be several pages long; answers the index as the segment holds it"
	| tx dict indexId index |
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
	1 to: 600 do: [ :each | dict at: each put: each ].
	tx commit.
	tx := soil newTransaction.
	indexId := tx root nested reference id.
	tx abort.
	index := (soil objectRepository segmentAt: 1) indexAt: indexId.
	self assert: (index headerPage rightAt: 1) > 0.
	^ index
]

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

{ #category : #helpers }
SoilTrackingVisitorTest >> recordWithTwoVersions [
	"the current record of an object of the sample graph that has a previous version, as
	the segment holds it"
	| segment |
	segment := soil objectRepository segmentAt: 1.
	1 to: segment lastObjectIndex do: [ :index |
		(segment basicAt: index ifAbsent: [ nil ]) ifNotNil: [ :record |
			record hasPreviousVersion ifTrue: [ ^ record ] ] ].
	^ self fail: 'no object with two versions'
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
SoilTrackingVisitorTest >> testAHeaderThatDoesNotKnowTheTailIsNamed [
	| index tracker finding |
	index := self commitIndexOfManyPages.
	index headerPage leftAt: 1 put: 1.
	tracker := SoilDatabaseConsistencyTracker new.
	SoilTrackingVisitor new
		addTracker: tracker;
		track: soil.
	self assert: tracker findings size equals: 1.
	finding := tracker findings first.
	self assert: finding class equals: SoilBrokenPageLink.
	self assert: finding indexId equals: index id.
	self assert: finding pageOffset equals: index headerPage offset.
	self assert: finding level equals: 1
]

{ #category : #tests }
SoilTrackingVisitorTest >> testALeftPointerThatDoesNotLeadBackIsNamedAtItsPage [
	| index second tracker finding |
	index := self commitIndexOfManyPages.
	second := index store pageAt: (index headerPage rightAt: 1).
	second leftAt: 1 put: 99.
	tracker := SoilDatabaseConsistencyTracker new.
	SoilTrackingVisitor new
		addTracker: tracker;
		track: soil.
	self assert: tracker findings size equals: 1.
	finding := tracker findings first.
	self assert: finding class equals: SoilBrokenPageLink.
	self assert: finding pageOffset equals: second offset.
	self assert: finding level equals: 1.
	self assert: finding segment equals: 1.
	self assert: finding isRepairable not
]

{ #category : #tests }
SoilTrackingVisitorTest >> testALoopInTheRightPointersIsNamedAndEnds [
	"the tracker is asked directly: the visitor reads the values of an index by its next
	pointers after the trackers and would not end on a loop either"
	| index second tracker |
	index := self commitIndexOfManyPages.
	second := index store pageAt: (index headerPage rightAt: 1).
	second rightAt: 1 put: second offset.
	tracker := SoilDatabaseConsistencyTracker new.
	tracker trackIndex: index segment: (soil objectRepository segmentAt: 1) in: nil.
	self assert: (tracker findings anySatisfy: [ :each | 
		each class = SoilBrokenPageLink and: [ each pageOffset = second offset ] ]).
	"the pages are not iterated on a broken chain"
	self assert: (tracker findings noneSatisfy: [ :each | each class = SoilIndexSizeDrift ])
]

{ #category : #tests }
SoilTrackingVisitorTest >> testALoopInTheRightPointersDoesNotHangTheVisitor [
	"the visitor reads the values of an index by the next pointers too, so it has to leave
	an index alone whose chain a tracker named. Without that this test never ends and is
	stopped by the time limit of the test case"
	| index second tracker counting |
	index := self commitIndexOfManyPages.
	second := index store pageAt: (index headerPage rightAt: 1).
	second rightAt: 1 put: second offset.
	tracker := SoilDatabaseConsistencyTracker new.
	counting := SoilTestCountingTracker new.
	SoilTrackingVisitor new
		addTracker: tracker;
		addTracker: counting;
		track: soil.
	self assert: (tracker findings anySatisfy: [ :each | 
		each class = SoilBrokenPageLink and: [ each pageOffset = second offset ] ]).
	self assert: (counting valuesOfIndex: index id) isEmpty
]

{ #category : #tests }
SoilTrackingVisitorTest >> testADescriptionThatIsNotThereIsNamedOnceWithTheObjectThatReferredToIt [
	| record tracker visitor |
	self commitSampleGraph.
	record := self recordWithTwoVersions copy.
	record behaviorDescriptions: { (SoilVersionedObjectId segment: 0 index: 9999) version: 1; yourself }.
	tracker := SoilDatabaseConsistencyTracker new.
	visitor := SoilTrackingVisitor new soil: soil; yourself.
	tracker trackCluster: record in: visitor.
	tracker trackCluster: record in: visitor.
	self assert: tracker findings size equals: 1.
	self assert: tracker findings first class equals: SoilMissingBehaviorDescription.
	self assert: tracker findings first descriptionId index equals: 9999
]

{ #category : #tests }
SoilTrackingVisitorTest >> testADescriptionVersionThatIsNotInItsChainIsNamed [
	| record tracker visitor versioned |
	self commitSampleGraph.
	record := self recordWithTwoVersions.
	versioned := record behaviorDescriptions first.
	record := record copy.
	record behaviorDescriptions: { (SoilVersionedObjectId segment: 0 index: versioned index) version: 99; yourself }.
	tracker := SoilApplicationConsistencyTracker new.
	visitor := SoilTrackingVisitor new soil: soil; transaction: soil newTransaction; yourself.
	[ tracker trackCluster: record in: visitor ] ensure: [ visitor transaction abort ].
	self assert: (tracker findings anySatisfy: [ :each | 
		each class = SoilMissingBehaviorDescription and: [ each version = 99 ] ])
]

{ #category : #tests }
SoilTrackingVisitorTest >> testAPreviousVersionBeyondTheFileIsNamed [
	| record tracker finding |
	self commitSampleGraph.
	record := self recordWithTwoVersions copy.
	record previousVersionPosition: 100000000.
	tracker := SoilDatabaseConsistencyTracker new.
	tracker trackCluster: record in: (SoilTrackingVisitor new soil: soil; yourself).
	self assert: tracker findings size equals: 1.
	finding := tracker findings first.
	self assert: finding class equals: SoilBrokenVersionChain.
	self assert: finding objectId equals: record objectId.
	self assert: finding position equals: record position
]

{ #category : #tests }
SoilTrackingVisitorTest >> testAVersionChainThatReturnsToAPositionIsNamedAndEnds [
	| record tracker |
	self commitSampleGraph.
	record := self recordWithTwoVersions copy.
	record previousVersionPosition: record position.
	tracker := SoilDatabaseConsistencyTracker new.
	tracker trackCluster: record in: (SoilTrackingVisitor new soil: soil; yourself).
	self assert: tracker findings size equals: 1.
	self assert: tracker findings first class equals: SoilBrokenVersionChain
]

{ #category : #tests }
SoilTrackingVisitorTest >> testAVersionThatDoesNotComeBeforeTheNextIsNamed [
	| current older tracker |
	self commitSampleGraph.
	current := self recordWithTwoVersions.
	older := (soil objectRepository segmentAt: 1) headAtPosition: current previousVersionPosition.
	older objectId: current objectId.
	"the older record made to point to the newer one"
	older previousVersionPosition: current position.
	tracker := SoilDatabaseConsistencyTracker new.
	tracker trackCluster: older in: (SoilTrackingVisitor new soil: soil; yourself).
	self assert: tracker findings size equals: 1.
	self assert: (tracker findings first reason includesSubstring: 'does not come before')
]

{ #category : #tests }
SoilTrackingVisitorTest >> testACutOfABrokenVersionChainMakesTheObjectReadableAgain [
	| segment broken tracker finding repair index versionsBefore |
	self commitSampleGraph.
	segment := soil objectRepository segmentAt: 1.
	broken := self recordWithTwoVersions.
	index := broken objectId index.
	versionsBefore := (segment allVersionsAt: index) size.
	"the current version written again with a link to the previous one that leads beyond
	the file. It keeps its version number: a newer one would send the visitor itself into
	the chain, to find the version it is asked for"
	segment at: index putBytes: (broken copy
		previousVersionPosition: 100000000;
		serialize).
	tracker := SoilDatabaseConsistencyTracker new.
	SoilTrackingVisitor new
		addTracker: tracker;
		track: soil.
	finding := tracker findings detect: [ :each | each class = SoilBrokenVersionChain ].
	self assert: finding repairActions size equals: 1.
	self deny: finding defaultRepairAction notNil.
	repair := (SoilRepairVisitor on: soil)
		repair: { SoilRepairAction fromDictionary: finding repairActions first asDictionary };
		yourself.
	self assert: repair failed isEmpty.
	self assert: (segment allVersionsAt: index) size equals: 1.
	tracker := SoilDatabaseConsistencyTracker new.
	SoilTrackingVisitor new
		addTracker: tracker;
		track: soil.
	self assert: (tracker findings noneSatisfy: [ :each | each class = SoilBrokenVersionChain ])
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
SoilTrackingVisitorTest >> testAnObjectIdBeyondItsSegmentIsRepairedByRaisingTheIndex [
	"ids that point beyond what the segment handed out would be handed out again, to new
	objects. Raising the index to the highest of them stops that; the actions of the
	single ids come in any order"
	| visitor tracker last repair tx new |
	self commitSampleGraph.
	last := (soil objectRepository segmentAt: 1) lastObjectIndex.
	visitor := SoilTrackingVisitor new soil: soil; yourself.
	tracker := SoilDatabaseConsistencyTracker new.
	#(3 1 2) do: [ :each | 
		tracker trackObjectId: (SoilObjectId segment: 1 index: last + each) in: visitor ].
	self assert: tracker findings size equals: 3.
	self assert: (tracker findings allSatisfy: [ :each | each isRepairable ]).
	self assert: (tracker findings noneSatisfy: [ :each | each defaultRepairAction notNil ]).
	repair := (SoilRepairVisitor on: soil)
		repair: (tracker findings collect: [ :each | each repairActions first ]);
		yourself.
	self assert: repair failed isEmpty.
	self assert: repair repaired size equals: 3.
	self assert: (soil objectRepository segmentAt: 1) lastObjectIndex equals: last + 3.
	soil close; open.
	self assert: (soil objectRepository segmentAt: 1) lastObjectIndex equals: last + 3.
	"the next object is stored after them"
	tx := soil newTransaction.
	new := SoilTestNestedObject new label: #three; yourself.
	tx root nested reference at: 3 put: new.
	tx commit.
	tx := soil newTransaction.
	self assert: (tx objectIdOf: (tx root nested reference at: 3)) index equals: last + 4.
	tx abort
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

{ #category : #tests }
SoilTrackingVisitorTest >> testRaisingTheSegmentIndexStaysBeyondTheHighestRecord [
	"a record beyond the id the finding names: raised to that id alone, the next object
	would be stored on top of the record"
	| segment last visitor tracker repair |
	self commitSampleGraph.
	segment := soil objectRepository segmentAt: 1.
	last := segment lastObjectIndex.
	self assert: segment highestUsedObjectIndex equals: last.
	(segment instVarNamed: #indexFile) at: last + 6 putPosition: 1.
	self assert: segment highestUsedObjectIndex equals: last + 6.
	visitor := SoilTrackingVisitor new soil: soil; yourself.
	tracker := SoilDatabaseConsistencyTracker new.
	tracker trackObjectId: (SoilObjectId segment: 1 index: last + 2) in: visitor.
	repair := (SoilRepairVisitor on: soil)
		repair: (tracker findings collect: [ :each | each repairActions first ]);
		yourself.
	self assert: repair failed isEmpty.
	self assert: segment lastObjectIndex equals: last + 6
]

{ #category : #tests }
SoilTrackingVisitorTest >> testRaisingTheSegmentIndexIsMadeAgainFromItsDictionary [
	| action again |
	action := (SoilObjectIdOutsideSegment objectId: (SoilObjectId segment: 1 index: 20) beyond: 10) repairActions first.
	again := SoilRepairAction fromDictionary: action asDictionary.
	self assert: again class equals: SoilRaiseSegmentIndex.
	self assert: again segment equals: 1.
	self assert: again index equals: 20.
	self deny: again isDefault
]

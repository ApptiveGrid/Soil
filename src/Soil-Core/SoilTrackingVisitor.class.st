"
One walk over a database for a list of trackers (SoilTracker), each of which is shown every object id reached, every index and every cluster read, and collects what concerns it.

It opens a transaction only when one of its trackers asks for one, and then one for all of them: what the trackers find has to have been read at one version to fit together. Without such a tracker it reads at its databaseVersion alone, so trackers that only look at the structure on disk run on a copy or in an image without the application's classes as well.
"
Class {
	#name : #SoilTrackingVisitor,
	#superclass : #SoilVisitor,
	#instVars : [
		'trackers',
		'currentIndex',
		'currentSegment',
		'rereadDelays'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #accessing }
SoilTrackingVisitor >> addTracker: aTracker [
	^ trackers add: aTracker
]

{ #category : #initialization }
SoilTrackingVisitor >> initialize [ 
	super initialize.
	trackers := OrderedCollection new
]

{ #category : #testing }
SoilTrackingVisitor >> isLate: aSoilUnreadableRecord [
	"whether the record may still be on its way: the index of a database another
	process writes to sends the reader past the end of the objects file it sees. Over
	NFS that happens in two ways, and the metabase check of 674726be met both. The
	stream knows the file as long as the client last cached it - 1:2199 was 174 KB past
	that size, and there, intact; opening the file anew asks the server. And the
	writer's index can reach the server before its records, as writeback keeps no order
	between files - 1:2168 was 340 KB past the end of the file opened anew; only time
	helps there. A record inside the file is damaged, not late, and a writable
	database is the only one writing to its files"
	soil readOnly ifFalse: [ ^ false ].
	(aSoilUnreadableRecord position isNil or: [ aSoilUnreadableRecord fileSize isNil ]) ifTrue: [ ^ false ].
	^ aSoilUnreadableRecord position >= aSoilUnreadableRecord fileSize
]

{ #category : #testing }
SoilTrackingVisitor >> needsTransaction [
	^ trackers anySatisfy: [ :each | each needsTransaction ]
]

{ #category : #visiting }
SoilTrackingVisitor >> processIndexId: indexId segment: aSoilObjectSegment [
	"the one place that knows which segment an index belongs to - the index itself does
	not, so the trackers are told here.

	An index the walk opened is let go of once it has been read. The index manager keeps
	every index it is asked for open, file and all, and 62398e23 has 3319 of them against
	the 1024 files the scheduler may hold open: the check ended on the next index it
	opened. One that was open before stays open - it is not the walk's"
	| index previousIndex previousSegment wasOpen |
	wasOpen := aSoilObjectSegment indexManager indexes includesKey: indexId.
	index := aSoilObjectSegment indexAt: indexId.
	[ trackers do: [ :each | each trackIndex: index segment: aSoilObjectSegment in: self ].
	previousIndex := currentIndex.
	previousSegment := currentSegment.
	currentIndex := index.
	currentSegment := aSoilObjectSegment.
	[ "the values are read by following the next pointers of the pages. On a chain a
	tracker found broken that can skip pages or never end, so the values are left
	alone - the tracker has named the chain. This is the one place that knows which
	trackers there are; the visitors that do not track have no one to ask"
	(trackers anySatisfy: [ :each | each hasBrokenChainIn: index segment: aSoilObjectSegment ])
		ifFalse: [ self visit: index ] ] ensure: [
		currentIndex := previousIndex.
		currentSegment := previousSegment ] ]
			ensure: [
				wasOpen ifFalse: [ aSoilObjectSegment indexManager removeIndexWithId: indexId ] ]
]

{ #category : #visiting }
SoilTrackingVisitor >> processIndexValue: aSoilObjectId [
	"a value of the index being read, told with that index - #processObjectId: comes
	after and does not know where the id came from. The behavior registry is read
	outside #processIndexId:segment:, so its values arrive without an index and are
	not told"
	currentIndex ifNotNil: [ :index |
		trackers do: [ :each |
			each trackValue: aSoilObjectId ofIndex: index segment: currentSegment in: self ] ].
	^ super processIndexValue: aSoilObjectId
]

{ #category : #visiting }
SoilTrackingVisitor >> processObjectId: aSoilObjectId [ 
	trackers do: [ :each | each trackObjectId: aSoilObjectId in: self ].
	^ super processObjectId: aSoilObjectId 
]

{ #category : #visiting }
SoilTrackingVisitor >> reopenObjectFileOf: aSoilObjectSegment [
	"on NFS opening a file is what makes the client ask the server for its size, see
	#isLate:. Only for a read-only database, which is the only one that is late"
	| objectFile |
	objectFile := aSoilObjectSegment instVarNamed: #objectFile.
	objectFile close.
	objectFile stream: (soil streamOnPath: objectFile path)
]

{ #category : #accessing }
SoilTrackingVisitor >> rereadDelays [
	"the pauses in milliseconds before each further read of a record that is late, see
	#isLate:. The first read again follows at once; half a minute in all, more than a
	client's writeback usually keeps a page"
	^ rereadDelays ifNil: [ #( 0 1000 2000 4000 8000 15000 ) ]
]

{ #category : #accessing }
SoilTrackingVisitor >> rereadDelays: aCollection [
	rereadDelays := aCollection
]

{ #category : #api }
SoilTrackingVisitor >> track: aSoil [
	"walk aSoil once for all trackers. A transaction handed in before is used as it is"
	soil := aSoil.
	(transaction isNil and: [ self needsTransaction ])
		ifTrue: [ self visitWithTransaction: aSoil ]
		ifFalse: [ self visit: aSoil ]
]

{ #category : #accessing }
SoilTrackingVisitor >> trackers [
	^ trackers
]

{ #category : #visiting }
SoilTrackingVisitor >> visitDatabaseJournal: aJournal [
	"the journal has a check of its own, SoilJournalConsistencyVisitor"
	^ aJournal
]

{ #category : #visiting }
SoilTrackingVisitor >> visitMetaSegment: aSoilMetaSegment [
	"the behavior registry belongs to the meta segment, its values point into it"
	trackers do: [ :each | each trackBehaviorRegistry: soil behaviorRegistry in: self ].
	^ super visitMetaSegment: aSoilMetaSegment
]

{ #category : #visiting }
SoilTrackingVisitor >> visitPersistentClusterVersion: aSoilPersistentClusterVersion [ 
	trackers do: [ :each | each trackCluster: aSoilPersistentClusterVersion in: self ].
	^ super visitPersistentClusterVersion: aSoilPersistentClusterVersion 
]

{ #category : #visiting }
SoilTrackingVisitor >> visitRecordAt: aSoilObjectId [
	"a record that cannot be read is something for the trackers to name, not the end of
	the walk: one record the check could not read ended a walk of hours over a database
	of a million objects, and every object after it went unchecked. What only that
	record refers to is not reached.

	One that may still be on its way is read again first, see #isLate:"
	| record delays |
	delays := self rereadDelays readStream.
	record := [ self recordAt: aSoilObjectId ]
		on: SoilUnreadableRecord
		do: [ :error |
			(delays atEnd not and: [ self isLate: error ]) ifTrue: [ 
				(Delay forMilliseconds: delays next) wait.
				self reopenObjectFileOf: (soil objectRepository segmentAt: aSoilObjectId segment).
				error retry ].
			trackers do: [ :each | each trackUnreadableRecord: error in: self ].
			^ nil ].
	^ self visit: record
]

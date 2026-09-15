Class {
	#name : #SoilBackupVisitor,
	#superclass : #SoilCopyingVisitor,
	#instVars : [
		'target',
		'copiesJournal'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #api }
SoilBackupVisitor >> backup: aSoil [ 
	soil := aSoil.
	"if there is no version set we take the actual database version. This 
	is to create a consistent backup regardless if transactions are committed 
	while we are doing the backup"
	databaseVersion ifNil: [
		databaseVersion := aSoil control databaseVersion ]. 
	
	self visit: soil.
	target close
]

{ #category : #visiting }
SoilBackupVisitor >> copyIndexAt: indexId segment: segmentId [

	| sourceSegment sourceIndex targetSegment targetIndex iterator assoc isBehaviorIndex |
	"the behavior registry (identifier index of the meta segment) is already open
	via soil behaviorRegistry. Reuse that open index instead of opening the same
	file a second time through the index manager, which fails on Windows"
	isBehaviorIndex := (segmentId = 0) and: [ indexId = #identifier ].
	sourceSegment := soil objectRepository segmentAt: segmentId.
	sourceIndex := isBehaviorIndex
		               ifTrue: [ soil behaviorRegistry index ]
		               ifFalse: [ sourceSegment indexManager
				               at: indexId
				               ifAbsent: [ ^ self indexNotFound: indexId ] ].

	"create an index of same kind and configuration in the target database"
	targetSegment := target objectRepository segmentAt: segmentId.
	targetIndex := targetSegment indexManager
		               createIndexWithId: indexId
		               class: sourceIndex class.
	targetIndex initializeParametersFrom: sourceIndex.

	"copy all values to the new index"
	iterator := sourceIndex newIterator.
	[ (assoc := iterator nextAssociation) isNil ] whileFalse: [
		assoc value isRemoved ifFalse: [
			targetIndex basicAt: assoc key add: assoc value.
			"recurse further into the values of the index"
			self processObjectId: assoc value asSoilObjectId ] ].
	targetIndex
		flush;
		close.
	"do not close the behavior registry index here, it is owned by soil and
	still in use; only release indexes we opened through the index manager"
	isBehaviorIndex ifFalse: [
		sourceSegment indexManager removeIndexWithId: indexId ]
]

{ #category : #accessing }
SoilBackupVisitor >> copiesJournal [
	"whether the source's journal fragments go into the copy. False, because they are
	not needed to read it and they are not small.

	A backup is written by walking the source at a pinned databaseVersion and writing
	fresh object and index files into a freshly initialized target. The target's
	positions are therefore its own, and the source's journal entries describe
	positions in the source - measured on a database of forty commits, the fragments
	were half of the copy, and deleting them from it left every value readable.

	Kept as an option because a copy that is meant to be inspected rather than read
	may want the history, and because a caller that relied on the fragments being
	there should be able to say so rather than find out."
	^ copiesJournal ifNil: [ false ]
]

{ #category : #accessing }
SoilBackupVisitor >> copiesJournal: aBoolean [
	copiesJournal := aBoolean
]

{ #category : #accessing }
SoilBackupVisitor >> databaseVersion: anObject [

	databaseVersion := anObject
]

{ #category : #visiting }
SoilBackupVisitor >> indexNotFound: indexId [ 
	 Error signal: 'cannot find index with id ', indexId printString
]

{ #category : #api }
SoilBackupVisitor >> processLoop [ 
	super processLoop.
	target close
]

{ #category : #accessing }
SoilBackupVisitor >> target: aSoil [ 
	target := aSoil
]

{ #category : #copying }
SoilBackupVisitor >> targetSegmentFor: aSegmentId [
	^ target objectRepository segmentAt: aSegmentId
]

{ #category : #accessing }
SoilBackupVisitor >> version: anObject [

	databaseVersion := anObject
]

{ #category : #visiting }
SoilBackupVisitor >> visitControl: aSoilControlFile [ 
	target control 
		databaseFormatVersion: aSoilControlFile databaseFormatVersion;
		databaseVersion: aSoilControlFile databaseVersion;
		applicationVersion: aSoilControlFile applicationVersion;
		checkpoint: aSoilControlFile lastCheckpoint
]

{ #category : #visiting }
SoilBackupVisitor >> visitDatabaseJournal: aSoilJournal [ 
	"the directory is made either way. A copy is opened like any other database and
	writes its own journal from then on; what it does not need is the source's.

	The target's own fragments are cleared only when the source's are coming in: the
	target was created moments ago and brought a first fragment along which carries
	the same name as the source's first one and would make the copy fail. With
	nothing coming in there is nothing to collide with, and that fresh fragment is
	exactly what a new database should have."
	(target path / #journal) ensureCreateDirectory.
	self copiesJournal ifTrue: [
		target journal sortedFiles do: #delete ].
	^ super visitDatabaseJournal: aSoilJournal
]

{ #category : #visiting }
SoilBackupVisitor >> visitJournalFragmentFile: aSoilJournalFragmentFile [ 
	self copiesJournal ifFalse: [ ^ aSoilJournalFragmentFile ].
	aSoilJournalFragmentFile copyTo: target journal path / aSoilJournalFragmentFile basename.
	^ aSoilJournalFragmentFile 
]

{ #category : #visiting }
SoilBackupVisitor >> visitMetaSegment: aSoilMetaSegment [
	super visitMetaSegment: aSoilMetaSegment.
	"the target's behavior registry opened the identifier index when the target
	filesystem was initialized. Close it first so copyIndexAt: can rebuild that
	index without opening the same file a second time (which fails on Windows)"
	target behaviorRegistry close.
	self copyIndexAt: #identifier segment: 0.
	^ aSoilMetaSegment
]

{ #category : #visiting }
SoilBackupVisitor >> visitObjectSegment: aSoilObjectSegment [ 
	"the tolerant setter, not the strict one. A fresh target does not start empty:
	SoilObjectRepository>>initializeFilesystem gives its first segment
	lastObjectIndex 1 and its meta segment 2, as placeholders for the root and the
	meta description. #lastObjectIndex: demands strict growth and refuses anything
	that is not past those, so a database small enough that its own index has not
	overtaken the placeholder cannot be copied at all - and that is the one case
	where equality means the copy is faithful rather than an index that failed to
	grow."
	super visitObjectSegment: aSoilObjectSegment.
	(target objectRepository segmentAt: aSoilObjectSegment id)
		updateLastObjectIndex: aSoilObjectSegment lastObjectIndex
]

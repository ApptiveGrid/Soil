Class {
	#name : #SoilBackupVisitor,
	#superclass : #SoilCopyingVisitor,
	#instVars : [
		'target',
		'copyJournal'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #api }
SoilBackupVisitor >> backup: aSoil [ 
	"if there is no version set we take the actual database version. This 
	is to create a consistent backup regardless if transactions are committed 
	while we are doing the backup.

	The backup reads through a transaction at that version, open for as long as the
	backup runs. Being registered with the transaction manager is what keeps the index
	cleaner from discarding the state of an index page the backup still has to read: it
	only keeps what the smallest open read version needs, and with nothing open it keeps
	nothing"
	| reader |
	soil := aSoil.
	reader := databaseVersion
		ifNil: [ aSoil newTransaction ]
		ifNotNil: [ :version | aSoil newTransactionForVersion: version ].
	reader beReadOnly.
	databaseVersion := reader readVersion.
	[ self visit: soil ] ensure: [ reader abort ].
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

	"copy all values to the new index, as they were at the version the records are read
	at. Read as it is now, the index hands out entries committed after that version,
	which point to objects the backup does not copy. The behavior registry is read as it
	is now: its entries are not journaled as index entries, so there is nothing to
	restore them from, and what it points at is asked for instead, see
	#existsAtPinnedVersion:"
	iterator := sourceIndex newIterator.
	isBehaviorIndex ifFalse: [
		iterator
			journal: soil journal;
			readVersion: self databaseVersion ].
	[ (assoc := iterator nextAssociation) isNil ] whileFalse: [
		(assoc value isRemoved not and: [
			isBehaviorIndex not or: [ self existsAtPinnedVersion: assoc value asSoilObjectId ] ])
			ifTrue: [
				targetIndex basicAt: assoc key add: assoc value.
				"recurse further into the values of the index"
				self processObjectId: assoc value asSoilObjectId ] ].
	"both indexes are registered with their managers now, so both are released the same
	way - the target's too, which used to be closed by hand while staying registered"
	targetIndex flush.
	targetSegment indexManager removeIndexWithId: indexId.
	"do not close the behavior registry index here, it is owned by soil and
	still in use; only release indexes we opened through the index manager"
	isBehaviorIndex ifFalse: [
		sourceSegment indexManager removeIndexWithId: indexId ]
]

{ #category : #accessing }
SoilBackupVisitor >> copyJournal [
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
	^ copyJournal ifNil: [ false ]
]

{ #category : #accessing }
SoilBackupVisitor >> copyJournal: aBoolean [
	copyJournal := aBoolean
]

{ #category : #accessing }
SoilBackupVisitor >> databaseVersion: anObject [

	databaseVersion := anObject
]

{ #category : #visiting }
SoilBackupVisitor >> existsAtPinnedVersion: aSoilObjectId [
	"whether the object an entry of the behavior registry points at has a version at or
	below the one this backup is taken at. The registry is read as it is now - its
	entries are not journaled as index entries - so a class stored for the first time
	after the pin has an entry whose description did not exist then, and #processLoop
	read nil and failed on it. Left out, it is not in the copy either: an entry kept
	without its object would dangle there. The other indexes are read at the pinned
	version and need no asking.

	The record is read a second time when #processLoop gets to it. That is the price
	of asking here, before the entry is written into the target.

	The meta description has no record to ask: it is pre-initialized, and the
	behavior registry points at it from the first commit on - #processObjectId:
	skips it for the same reason"
	aSoilObjectId = SoilBehaviorDescription metaId ifTrue: [ ^ true ].
	^ ((soil objectRepository segmentAt: aSoilObjectId segment)
		basicAt: aSoilObjectId index
		version: self databaseVersion) notNil
]

{ #category : #visiting }
SoilBackupVisitor >> indexNotFound: indexId [ 
	 Error signal: 'cannot find index with id ', indexId printString
]

{ #category : #visiting }
SoilBackupVisitor >> processIndexId: indexId segment: aSegment [
	"copyIndexAt:segment: reads every index of a cluster that is copied, at the backup's
	version, and queues its values. Walking the index here as well read it a second time,
	and as it is now: entries committed after the backup's version queued objects that
	do not exist at that version"
	^ self
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
		applicationVersion: aSoilControlFile applicationVersion.
	"the checkpoint is a position in a journal, and it is the source's journal only
	when that journal comes along. Without it the source's checkpoint names a
	fragment the copy does not have: a writable open covers that up by starting a
	new fragment, a read-only open - the way a backup is read to be checked -
	refuses the copy as needing recovery. The target keeps the checkpoint it wrote
	into its own first fragment when it was initialized"
	self copyJournal ifTrue: [
		target control checkpoint: aSoilControlFile lastCheckpoint ]
]

{ #category : #visiting }
SoilBackupVisitor >> visitDatabaseJournal: aSoilJournal [ 
	"the directory is made either way. A copy is opened like any other database and
	writes its own journal from then on; what it does not need is the source's.

	The target's own fragments are cleared only when the source's are coming in: the
	target was created moments ago and brought a first fragment along which carries
	the same name as the source's first one and would make the copy fail. With
	nothing coming in there is nothing to collide with, and that fresh fragment is
	exactly what a new database should have.

	The fragment is closed before it is deleted. It is opened lazily, the first time
	anything touches the target's journal, and Windows refuses to delete a file that
	is still open - on POSIX the unlink succeeds and the open handle keeps the old
	inode alive, so this only ever showed there. Forgetting it afterwards lets the
	next write open a fresh one."
	(target path / #journal) ensureCreateDirectory.
	self copyJournal ifTrue: [
		target journal close.
		target journal sortedFiles do: #delete.
		target journal resetFragmentFile ].
	^ super visitDatabaseJournal: aSoilJournal
]

{ #category : #visiting }
SoilBackupVisitor >> visitJournalFragmentFile: aSoilJournalFragmentFile [ 
	self copyJournal ifFalse: [ ^ aSoilJournalFragmentFile ].
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

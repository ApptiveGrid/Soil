Class {
	#name : #SoilBackupVisitor,
	#superclass : #SoilCopyingVisitor,
	#instVars : [
		'target'
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

	| sourceSegment sourceIndex targetSegment targetIndex iterator assoc |
	sourceSegment := soil objectRepository segmentAt: segmentId.
	sourceIndex := sourceSegment indexManager
		               at: indexId
		               ifAbsent: [ ^ self indexNotFound: indexId ].

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
	sourceSegment indexManager removeIndexWithId: indexId
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
	(target path / #journal) ensureCreateDirectory.
	^ super visitDatabaseJournal: aSoilJournal
]

{ #category : #visiting }
SoilBackupVisitor >> visitJournalFragmentFile: aSoilJournalFragmentFile [ 
	aSoilJournalFragmentFile copyTo: target journal path / aSoilJournalFragmentFile basename.
	^ aSoilJournalFragmentFile 
]

{ #category : #visiting }
SoilBackupVisitor >> visitMetaSegment: aSoilMetaSegment [ 
	super visitMetaSegment: aSoilMetaSegment.
	self copyIndexAt: #identifier segment: 0. 
	^ aSoilMetaSegment  
]

{ #category : #visiting }
SoilBackupVisitor >> visitObjectSegment: aSoilObjectSegment [ 
	super visitObjectSegment: aSoilObjectSegment.
	(target objectRepository segmentAt: aSoilObjectSegment id)
		lastObjectIndex: aSoilObjectSegment lastObjectIndex  
]

Class {
	#name : #SoilBackupVisitor,
	#superclass : #SoilCloneVisitor,
	#instVars : [
		'target',
		'version'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #api }
SoilBackupVisitor >> backup: aSoil [ 
	soil := aSoil.
	"if there is no version set we take the actual database version. This 
	is to create a consistent backup regardless if transactions are committed 
	while we are doing the backup"
	version ifNil: [
		version := aSoil control databaseVersion ]. 
	
	self visit: soil.
	self traverseGraph.
	target close
]

{ #category : #visiting }
SoilBackupVisitor >> copyIndexAt: indexId segment: segmentId [
	| sourceSegment sourceIndex targetSegment targetIndex iterator assoc |
	
	sourceSegment := soil objectRepository segmentAt: segmentId.
	sourceIndex := sourceSegment indexManager 
		loadIndexWithId: indexId 
		ifNone: [ ^ self indexNotFound: indexId ].
	
	"create an index of same kind and configuration in the target database"
	targetSegment := target objectRepository segmentAt: segmentId.
	targetIndex := targetSegment indexManager 
		createIndexWithId: indexId 
		class: sourceIndex class.
	targetIndex initializeParametersFrom: sourceIndex. 
	
	"copy all values to the new index"
	iterator := sourceIndex newIterator.
	[ (assoc := iterator nextAssociation) isNil  ] whileFalse: [  
		assoc value isRemoved ifFalse: [ 
			targetIndex basicAt: assoc key put: assoc value.
			"recurse further into the values of the index"
			self processObjectId: assoc value asSoilObjectId ] ].
	targetIndex
		flush; 
		close.
]

{ #category : #visiting }
SoilBackupVisitor >> indexNotFound: indexId [ 
	 Error signal: 'cannot find index with id ', indexId printString
]

{ #category : #accessing }
SoilBackupVisitor >> target: aSoil [ 
	target := aSoil
]

{ #category : #api }
SoilBackupVisitor >> traverseGraph [ 
	| objectId |
	[ toBeProcessed isEmpty ] whileFalse: [  
		objectId := toBeProcessed  removeFirst.
		self visit: (soil objectRepository at: objectId version: version) ].
	target close
]

{ #category : #accessing }
SoilBackupVisitor >> version: anObject [

	version := anObject
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
	self visit: aSoilMetaSegment indexManager.
	self copyIndexAt: #identifier segment: 0. 
	^ aSoilMetaSegment  
]

{ #category : #visiting }
SoilBackupVisitor >> visitObjectSegment: aSoilObjectSegment [ 
	self processObjectId: SoilObjectId root.
	super visitObjectSegment: aSoilObjectSegment.
]

{ #category : #visiting }
SoilBackupVisitor >> visitPersistentClusterVersion: aSoilPersistentClusterVersion [ 
	| backupCluster |
	backupCluster := aSoilPersistentClusterVersion copy
		behaviorDescriptions: aSoilPersistentClusterVersion behaviorDescriptions;
		references: aSoilPersistentClusterVersion references;
		bytes: aSoilPersistentClusterVersion bytes;
		version: aSoilPersistentClusterVersion version;
		resetPreviousVersion.
	target objectRepository 
		at: backupCluster objectId
		putBytes: backupCluster serialize.
	backupCluster references do: [ :reference |
		self processObjectId: reference ].
	aSoilPersistentClusterVersion indexIds do:[ :indexId |
		self copyIndexAt: indexId segment: aSoilPersistentClusterVersion segment ].

	^ aSoilPersistentClusterVersion 
]

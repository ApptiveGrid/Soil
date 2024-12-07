Class {
	#name : #SoilBackupVisitor,
	#superclass : #SoilInstanceVisitor,
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
	self traverse. 
	target close
]

{ #category : #copying }
SoilBackupVisitor >> copyAllClusterVersions: aSoilPersistentClusterVersion [ 
	| versions position |
	"if there is no previous version is a single copy"
	aSoilPersistentClusterVersion hasPreviousVersion 
		ifFalse: [ ^ self copySourceCluster: aSoilPersistentClusterVersion  ].
	versions := (soil objectRepository segmentAt: aSoilPersistentClusterVersion objectId segment)
		allVersionsAt: aSoilPersistentClusterVersion objectId index.
	position := 0.
	"for multiple versions we need to iterate from oldest to newest to set the
	correct previous version positions"
	versions reverseDo: [ :cluster | | newCluster |
		newCluster := self makeCopy: cluster.
		newCluster previousVersionPosition: position.
		position := self copyCluster: newCluster ]
]

{ #category : #visiting }
SoilBackupVisitor >> copyCluster: aSoilPersistentClusterVersion [ 
	| position |
	position := target objectRepository 
		at: aSoilPersistentClusterVersion objectId
		putBytes: aSoilPersistentClusterVersion serialize.
	aSoilPersistentClusterVersion references do: [ :reference |
		self process: reference ].
	aSoilPersistentClusterVersion indexIds do:[ :indexId |
		self copyIndexAt: indexId segment: aSoilPersistentClusterVersion segment ].
	^ position 

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
			self process: assoc value asSoilObjectId ] ].
	targetIndex
		flush; 
		close.
]

{ #category : #visiting }
SoilBackupVisitor >> copySourceCluster: aSoilPersistentClusterVersion [ 
	| clusterCopy |
	clusterCopy := self makeCopy: aSoilPersistentClusterVersion.
	^ self copyCluster: clusterCopy
]

{ #category : #visiting }
SoilBackupVisitor >> indexNotFound: indexId [ 
	 Error signal: 'cannot find index with id ', indexId printString
]

{ #category : #visiting }
SoilBackupVisitor >> makeCopy: aSoilPersistentClusterVersion [ 
	^ aSoilPersistentClusterVersion copy
		behaviorDescriptions: aSoilPersistentClusterVersion behaviorDescriptions;
		references: aSoilPersistentClusterVersion references;
		bytes: aSoilPersistentClusterVersion bytes;
		version: aSoilPersistentClusterVersion version;
		resetPreviousVersion.
]

{ #category : #accessing }
SoilBackupVisitor >> target: aSoil [ 
	target := aSoil
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
	self visit: aSoilMetaSegment indexManager.
	self copyIndexAt: #identifier segment: 0. 
	^ aSoilMetaSegment  
]

{ #category : #visiting }
SoilBackupVisitor >> visitObjectSegment: aSoilObjectSegment [ 
	self process: SoilObjectId root.
	super visitObjectSegment: aSoilObjectSegment.
]

{ #category : #visiting }
SoilBackupVisitor >> visitPersistentClusterVersion: aSoilPersistentClusterVersion [ 
	(aSoilPersistentClusterVersion objectId segment = 0)
		ifTrue: [ 
			"as there could be very old objects we need to copy all  versions of 
			the behavior descriptions"
			self copyAllClusterVersions: aSoilPersistentClusterVersion  ]
		ifFalse: [  
			self copySourceCluster: (self makeCopy: aSoilPersistentClusterVersion) ].

	^ aSoilPersistentClusterVersion 
]

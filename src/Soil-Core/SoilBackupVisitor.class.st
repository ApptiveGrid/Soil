Class {
	#name : #SoilBackupVisitor,
	#superclass : #SoilVisitor,
	#instVars : [
		'source',
		'target',
		'seen',
		'toBeProcessed'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #'as yet unclassified' }
SoilBackupVisitor >> backup: aSoil [ 
	| objectId |
	source := aSoil.
	self visit: source.
	[ toBeProcessed isEmpty ] whileFalse: [  
		objectId := toBeProcessed  removeFirst.
		self visit: (source objectRepository at: objectId) ].
	target close
]

{ #category : #visiting }
SoilBackupVisitor >> copyIndexAt: aFileReference indexManager: anIndexManager [
	| sourceIndex targetPath targetIndex iterator assoc |
	sourceIndex := SoilSkipList new 
		path: aFileReference;
		open.
	targetPath := (target objectRepository segmentAt: anIndexManager segment id) indexManager path / aFileReference basename.
	targetIndex := SoilSkipList new 
		path: targetPath;
		initializeFilesystem;
		initializeHeaderPage;
		maxLevel: sourceIndex maxLevel;
		keySize: sourceIndex keySize;
		valueSize: sourceIndex valueSize.
	iterator := sourceIndex newIterator.
	[ (assoc := iterator nextAssociation) isNil  ] whileFalse: [  
		targetIndex 
			basicAt: assoc key put: assoc value.
		self process: assoc value ].
	targetIndex
		flush; 
		close.
]

{ #category : #initialization }
SoilBackupVisitor >> initialize [ 
	super initialize.
	seen := OrderedCollection new.
	toBeProcessed := OrderedCollection new
]

{ #category : #accessing }
SoilBackupVisitor >> process: aSoilObjectId [ 
	((aSoilObjectId segment = 0) and: [ aSoilObjectId index = 2 ]) ifTrue: [ ^ self ].
	(seen includes: aSoilObjectId) ifTrue: [ ^ self ].
	seen add: aSoilObjectId.
	toBeProcessed add: aSoilObjectId  
]

{ #category : #'as yet unclassified' }
SoilBackupVisitor >> target: aSoil [ 
	target := aSoil
]

{ #category : #visiting }
SoilBackupVisitor >> visitIndexManager: aSoilIndexManager [ 
	
	(aSoilIndexManager path childrenMatching: '*.index') do: [ :indexFile | 
		self copyIndexAt: indexFile indexManager: aSoilIndexManager  ]
]

{ #category : #visiting }
SoilBackupVisitor >> visitObjectSegment: aSoilObjectSegment [ 
	self process: SoilObjectId root.

	super visitObjectSegment: aSoilObjectSegment.
]

{ #category : #visiting }
SoilBackupVisitor >> visitParameters: aSoilParameterFile [ 
	target settings 
		databaseFormatVersion: aSoilParameterFile databaseFormatVersion;
		databaseVersion: 1;
		applicationVersion: aSoilParameterFile applicationVersion
]

{ #category : #'as yet unclassified' }
SoilBackupVisitor >> visitPersistentClusterVersion: aSoilPersistentClusterVersion [ 
	| backupCluster |
	backupCluster := aSoilPersistentClusterVersion copy
		behaviorDescriptions: aSoilPersistentClusterVersion behaviorDescriptions;
		references: aSoilPersistentClusterVersion references;
		bytes: aSoilPersistentClusterVersion bytes;
		resetPreviousVersion.
	target objectRepository 
		at: backupCluster objectId
		put: backupCluster serialize.
	backupCluster references do: [ :reference |
		self visit: (source objectRepository at: reference) ].
	^ aSoilPersistentClusterVersion 
]

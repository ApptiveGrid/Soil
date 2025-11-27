Class {
	#name : #SoilControlFile,
	#superclass : #SoilBinaryFile,
	#instVars : [
		'soil',
		'databaseFormatVersion',
		'applicationVersion',
		'semaphore',
		'currentDatabaseVersion'
	],
	#category : #'Soil-Core-Files'
}

{ #category : #visiting }
SoilControlFile >> acceptSoil: aSoilVisitor [ 
	^ aSoilVisitor visitControl: self
]

{ #category : #accessing }
SoilControlFile >> applicationVersion [
	^ semaphore critical: [  
		applicationVersion ifNil: [ 
			stream position: self applicationVersionPosition.
			applicationVersion := (stream next: self applicationVersionSize) asInteger ] ]
]

{ #category : #accessing }
SoilControlFile >> applicationVersion: anInteger [
	semaphore critical: [  
		self stream 
			position: self applicationVersionPosition;
			nextPutAll: (anInteger asByteArrayOfSize: self applicationVersionSize);
			flush.
		applicationVersion := anInteger ]
]

{ #category : #accessing }
SoilControlFile >> applicationVersionPosition [
	^ self databaseVersionPosition + self databaseVersionSize
]

{ #category : #accessing }
SoilControlFile >> applicationVersionSize [
	^ 8
]

{ #category : #private }
SoilControlFile >> basicDatabaseVersion: anInteger [
	semaphore critical: [
		currentDatabaseVersion := anInteger.  
		self stream 
			position: self databaseVersionPosition;
			nextPutAll: (anInteger asByteArrayOfSize: self databaseVersionSize);
			flush ]
]

{ #category : #accessing }
SoilControlFile >> checkpoint: anInteger [
	semaphore critical: [  
		self stream 
			position: self checkpointPosition;
			nextPutAll: (anInteger value asByteArrayOfSize: self checkpointPositionSize);
			flush ]
]

{ #category : #accessing }
SoilControlFile >> checkpointPosition [
	^ self applicationVersionPosition + self applicationVersionSize
]

{ #category : #accessing }
SoilControlFile >> checkpointPositionSize [
	^ 8
]

{ #category : #accessing }
SoilControlFile >> databaseFormatVersion [
	^ semaphore critical: [ 
		databaseFormatVersion ifNil: [ 
			stream position: self headerSize.
			databaseFormatVersion := (stream next: self databaseFormatVersionSize) asInteger ] ]
]

{ #category : #accessing }
SoilControlFile >> databaseFormatVersion: anInteger [
	semaphore critical: [   
		self stream 
			position: self headerSize;
			nextPutAll: (anInteger asByteArrayOfSize: self databaseFormatVersionSize);
			flush.
		databaseFormatVersion := anInteger ]
]

{ #category : #accessing }
SoilControlFile >> databaseFormatVersionSize [
	^ 1
]

{ #category : #accessing }
SoilControlFile >> databaseVersion [
	^ semaphore critical: [  
		stream position: self databaseVersionPosition.
		(stream next: self databaseVersionSize) asInteger ]
]

{ #category : #accessing }
SoilControlFile >> databaseVersion: anInteger [
	(currentDatabaseVersion < anInteger) ifFalse: [ 
		SoilInvalidDatabaseVersion signal: 'database version can only grow' ]. 
	(self databaseVersion < anInteger) ifFalse: [ 
		SoilInvalidDatabaseVersion signal: 'database version on disk is larger than in memory' ].
	self basicDatabaseVersion: anInteger
]

{ #category : #accessing }
SoilControlFile >> databaseVersionPosition [
	^ self headerSize + self databaseFormatVersionSize
]

{ #category : #accessing }
SoilControlFile >> databaseVersionSize [
	^ 8
]

{ #category : #initialization }
SoilControlFile >> initialize [ 
	super initialize.
	semaphore := Semaphore forMutualExclusion.
	currentDatabaseVersion := 0
]

{ #category : #initialization }
SoilControlFile >> initializeStart [
	self databaseFormatVersion: Soil databaseFormatVersion.
	self basicDatabaseVersion: 0.
	self applicationVersion: 1
]

{ #category : #inspector }
SoilControlFile >> inspectionControl: aBuilder [
	<inspectorPresentationOrder: 1000 title: 'control'>

	^ aBuilder newTable 
		items: self parameterNames;
		addColumn: (SpCompositeTableColumn new
			title: 'key';
			addColumn: (SpStringTableColumn evaluated: [:each | each printString ]));
		addColumn: (SpCompositeTableColumn new
			title: 'value';
			addColumn: (SpStringTableColumn evaluated: [:each | self perform: each asSymbol ]))
]

{ #category : #accessing }
SoilControlFile >> lastCheckpoint [
	^ semaphore critical: [  
		self stream 
			position: self checkpointPosition.
		(stream next: self checkpointPositionSize) asInteger asLogSequenceNumber ]
]

{ #category : #accessing }
SoilControlFile >> legacyPath [
	^ soil path / #settings
]

{ #category : #locking }
SoilControlFile >> lockDatabaseVersionFor: lockContext [
	^ stream 
		lockFrom: self headerSize
		length: self databaseVersionSize
		for: lockContext 
]

{ #category : #'open/close' }
SoilControlFile >> open [ 
	"convert legacy path to new one"
	self path exists ifFalse: [ 
		self legacyPath exists ifTrue: [ 
			self legacyPath moveTo: self path ] ].
	super open.
	(Soil databaseFormatVersion = self databaseFormatVersion)	
		ifFalse: [ 
			SoilIncompatibleDatabaseFormat signal: 'this code is incompatible with your database version. Please use branch v3 unless v4 is released which will provide a conversion'
			"SoilIncompatibleDatabaseFormat signal: 'database format version ', Soil databaseFormatVersion asString, ' does not match persisted database format version ', self databaseFormatVersion asString" ].
	currentDatabaseVersion := self databaseVersion  
]

{ #category : #accessing }
SoilControlFile >> parameterNames [
	^ #( databaseFormatVersion databaseVersion applicationVersion #lastCheckpoint ) 
]

{ #category : #accessing }
SoilControlFile >> path [
	^ soil path / #control
]

{ #category : #utilities }
SoilControlFile >> prefix [ 
	^ 'SOIL|PARAMETERS' asByteArray
]

{ #category : #accessing }
SoilControlFile >> soil [

	^ soil
]

{ #category : #accessing }
SoilControlFile >> soil: anObject [

	soil := anObject
]

{ #category : #accessing }
SoilControlFile >> updateDatabaseVersion: anInteger [
	(anInteger <= self databaseVersion) ifTrue: [ 
		"when doing a database recovery it is possible that the version 
		has been updated already. Prior updates that are replayed will
		have smaller numbers. We don't want to lower numbers so we just
		ignore them and let the journal catch up"
		^ self ].
	self databaseVersion: anInteger
]

{ #category : #writing }
SoilControlFile >> writeContentsToDisk [
	soil setup isFsyncEnabled ifTrue: [  
		stream sync ]
]

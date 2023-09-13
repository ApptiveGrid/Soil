Class {
	#name : #SoilParameterFile,
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
SoilParameterFile >> acceptSoil: aSoilVisitor [ 
	^ aSoilVisitor visitParameters: self
]

{ #category : #accessing }
SoilParameterFile >> applicationVersion [
	^ semaphore critical: [  
		applicationVersion ifNil: [ 
			stream position: self headerSize + self databaseFormatVersionSize + self databaseVersionSize.
			applicationVersion := (stream next: self applicationVersionSize) asInteger ] ]
]

{ #category : #accessing }
SoilParameterFile >> applicationVersion: anInteger [
	semaphore critical: [  
		self stream 
			position: self headerSize + self databaseFormatVersionSize + self databaseVersionSize;
			nextPutAll: (anInteger asByteArrayOfSize: self applicationVersionSize);
			flush.
		applicationVersion := anInteger ]
]

{ #category : #accessing }
SoilParameterFile >> applicationVersionSize [
	^ 8
]

{ #category : #private }
SoilParameterFile >> basicDatabaseVersion: anInteger [
	semaphore critical: [
		currentDatabaseVersion := anInteger.  
		self stream 
			position: self headerSize + self databaseFormatVersionSize;
			nextPutAll: (anInteger asByteArrayOfSize: self databaseVersionSize);
			flush ]
]

{ #category : #accessing }
SoilParameterFile >> databaseFormatVersion [
	^ semaphore critical: [ 
		databaseFormatVersion ifNil: [ 
			stream position: self headerSize.
			databaseFormatVersion := (stream next: self databaseFormatVersionSize) asInteger ] ]
]

{ #category : #accessing }
SoilParameterFile >> databaseFormatVersion: anInteger [
	semaphore critical: [   
		self stream 
			position: self headerSize;
			nextPutAll: (anInteger asByteArrayOfSize: self databaseFormatVersionSize);
			flush.
		databaseFormatVersion := anInteger ]
]

{ #category : #accessing }
SoilParameterFile >> databaseFormatVersionSize [
	^ 1
]

{ #category : #accessing }
SoilParameterFile >> databaseVersion [
	^ semaphore critical: [  
		stream position: self headerSize + self databaseFormatVersionSize.
		(stream next: self databaseVersionSize) asInteger ]
]

{ #category : #accessing }
SoilParameterFile >> databaseVersion: anInteger [
	(currentDatabaseVersion < anInteger) ifFalse: [ 
		SoilInvalidDatabaseVersion signal: 'database version can only grow' ]. 
	(self databaseVersion < anInteger) ifFalse: [ 
		SoilInvalidDatabaseVersion signal: 'database version on disk is larger than in memory' ].
	self basicDatabaseVersion: anInteger
]

{ #category : #accessing }
SoilParameterFile >> databaseVersionSize [
	^ 8
]

{ #category : #initialization }
SoilParameterFile >> initialize [ 
	super initialize.
	semaphore := Semaphore forMutualExclusion.
	currentDatabaseVersion := 0
]

{ #category : #initialization }
SoilParameterFile >> initializeStart [
	self databaseFormatVersion: 1.
	self basicDatabaseVersion: 0.
	self applicationVersion: 1
]

{ #category : #inspector }
SoilParameterFile >> inspectionParameters [
	<inspectorPresentationOrder: 1000 title: 'soil parameters'>

	^ SpTablePresenter new
		items: self parameterNames;
		addColumn: (SpCompositeTableColumn new
			title: 'key';
			addColumn: (SpStringTableColumn evaluated: [:each | each printString ]));
		addColumn: (SpCompositeTableColumn new
			title: 'value';
			addColumn: (SpStringTableColumn evaluated: [:each | self perform: each asSymbol ]))
]

{ #category : #locking }
SoilParameterFile >> lockDatabaseVersionFor: lockContext [
	^ stream 
		lockFrom: self headerSize
		length: self databaseVersionSize
		for: lockContext 
]

{ #category : #'open/close' }
SoilParameterFile >> open [ 
	super open.
	(Soil databaseFormatVersion = self databaseFormatVersion)	
		ifFalse: [ SoilIncompatibleDatabaseFormat signal: 'database format version ', Soil databaseFormatVersion asString, ' does not match persisted database format version ', self databaseFormatVersion asString ].
	currentDatabaseVersion := self databaseVersion  
]

{ #category : #accessing }
SoilParameterFile >> parameterNames [
	^ #( databaseFormatVersion databaseVersion applicationVersion ) 
]

{ #category : #accessing }
SoilParameterFile >> path [
	^ soil path / #settings
]

{ #category : #utilities }
SoilParameterFile >> prefix [ 
	^ 'SOIL|PARAMETERS' asByteArray
]

{ #category : #accessing }
SoilParameterFile >> soil [

	^ soil
]

{ #category : #accessing }
SoilParameterFile >> soil: anObject [

	soil := anObject
]

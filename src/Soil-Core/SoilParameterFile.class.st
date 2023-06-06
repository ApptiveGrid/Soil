Class {
	#name : #SoilParameterFile,
	#superclass : #SoilBinaryFile,
	#instVars : [
		'soil',
		'databaseFormatVersion',
		'applicationVersion'
	],
	#category : #'Soil-Core-Files'
}

{ #category : #visiting }
SoilParameterFile >> acceptSoil: aSoilVisitor [ 
	^ aSoilVisitor visitParameters: self
]

{ #category : #accessing }
SoilParameterFile >> applicationVersion [
	^ applicationVersion ifNil: [ 
		stream position: self headerSize + self databaseFormatVersionSize + self databaseVersionSize.
		applicationVersion := (stream next: self applicationVersionSize) asInteger ]
]

{ #category : #accessing }
SoilParameterFile >> applicationVersion: anInteger [
	self stream 
		position: self headerSize + self databaseFormatVersionSize + self databaseVersionSize;
		nextPutAll: (anInteger asByteArrayOfSize: self applicationVersionSize);
		flush.
	applicationVersion := anInteger 
]

{ #category : #accessing }
SoilParameterFile >> applicationVersionSize [
	^ 8
]

{ #category : #accessing }
SoilParameterFile >> databaseFormatVersion [
	^ databaseFormatVersion ifNil: [ 
		stream position: self headerSize.
		databaseFormatVersion := (stream next: self databaseFormatVersionSize) asInteger ]
]

{ #category : #accessing }
SoilParameterFile >> databaseFormatVersion: anInteger [
	self stream 
		position: self headerSize;
		nextPutAll: (anInteger asByteArrayOfSize: self databaseFormatVersionSize);
		flush.
	databaseFormatVersion := anInteger 
]

{ #category : #accessing }
SoilParameterFile >> databaseFormatVersionSize [
	^ 1
]

{ #category : #accessing }
SoilParameterFile >> databaseVersion [
	stream position: self headerSize + self databaseFormatVersionSize.
	^ (stream next: self databaseVersionSize) asInteger
	
]

{ #category : #accessing }
SoilParameterFile >> databaseVersion: anInteger [
	self stream 
		position: self headerSize + self databaseFormatVersionSize;
		nextPutAll: (anInteger asByteArrayOfSize: self databaseVersionSize);
		flush
]

{ #category : #accessing }
SoilParameterFile >> databaseVersionSize [
	^ 8
]

{ #category : #initialization }
SoilParameterFile >> initializeStart [
	self databaseFormatVersion: 1.
	self databaseVersion: 1.
	self applicationVersion: 1
]

{ #category : #'as yet unclassified' }
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

{ #category : #'as yet unclassified' }
SoilParameterFile >> lockDatabaseVersionFor: lockContext [
	^ stream 
		lockFrom: self headerSize
		length: self databaseVersionSize
		for: lockContext 
]

{ #category : #'instance creation' }
SoilParameterFile >> open [ 
	super open.
	(Soil databaseFormatVersion = self databaseFormatVersion)	
		ifFalse: [ SoilIncompatibleDatabaseFormat signal: 'database format version ', Soil databaseFormatVersion asString, ' does not match persisted database format version ', self databaseFormatVersion asString] 
]

{ #category : #'as yet unclassified' }
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

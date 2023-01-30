Class {
	#name : #SoilParameterFile,
	#superclass : #SOBinaryFile,
	#instVars : [
		'soil',
		'databaseVersion'
	],
	#category : #'Soil-Core-Files'
}

{ #category : #accessing }
SoilParameterFile >> databaseVersion [
	^ databaseVersion ifNil: [
		stream position: self headerSize.
		databaseVersion := (stream next: self databaseVersionSize) asInteger ]
]

{ #category : #accessing }
SoilParameterFile >> databaseVersion: anInteger [
	self stream
		position: self headerSize;
		nextPutAll: (anInteger asByteArrayOfSize: self databaseVersionSize);
		flush.
	databaseVersion := anInteger
]

{ #category : #accessing }
SoilParameterFile >> databaseVersionSize [
	^ 8
]

{ #category : #initialization }
SoilParameterFile >> initializeStart [
	self databaseVersion: 1
]

{ #category : #'as yet unclassified' }
SoilParameterFile >> lockDatabaseVersionFor: lockContext [
	^ stream
		lockFrom: self headerSize
		length: self databaseVersionSize
		for: lockContext
]

{ #category : #accessing }
SoilParameterFile >> path [
	^ soil path / #settings
]

{ #category : #utilities }
SoilParameterFile >> prefix [
	^ 'SOIL|PARAMETERS ' asByteArray
]

{ #category : #accessing }
SoilParameterFile >> soil [

	^ soil
]

{ #category : #accessing }
SoilParameterFile >> soil: anObject [

	soil := anObject
]

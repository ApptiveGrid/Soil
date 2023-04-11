Class {
	#name : #SoilBinaryFile,
	#superclass : #Object,
	#instVars : [
		'fileVersion',
		'stream'
	],
	#category : #'Soil-Core-Files'
}

{ #category : #testing }
SoilBinaryFile class >> isAbstract [
	<ignoreForCoverage>
	^ self == SoilBinaryFile
]

{ #category : #'initialize-release' }
SoilBinaryFile >> close [
	stream ifNotNil: [ 
		stream close ]
]

{ #category : #accessing }
SoilBinaryFile >> fileVersion [
	^ fileVersion
]

{ #category : #accessing }
SoilBinaryFile >> fileVersion: anInteger [ 
	self stream position: self prefix size.
	stream nextPutAll: (anInteger asByteArrayOfSize: self fileVersionSize)
]

{ #category : #utilities }
SoilBinaryFile >> fileVersionSize [
	^ 2
]

{ #category : #utilities }
SoilBinaryFile >> headerSize [ 
	"the file header stores a prefix and the version for the file format and 
	the version of fuel being used"
	^ self prefix size + self fileVersionSize
]

{ #category : #initialization }
SoilBinaryFile >> initializeFilesystem [
	self initializeHeader.
	self initializeStart.
	self stream 
		flush
]

{ #category : #initialization }
SoilBinaryFile >> initializeHeader [
	self stream 
		position: 0;
		nextPutAll: self prefix asByteArray.
	self fileVersion: 1
]

{ #category : #initialization }
SoilBinaryFile >> initializeStart [
	self subclassResponsibility 
]

{ #category : #locking }
SoilBinaryFile >> lockAppendingFor: lockContext [
	^ stream lockAppendingFor: lockContext 
]

{ #category : #accessing }
SoilBinaryFile >> open [
	stream := self soil lockableStream initializePath: self path
]

{ #category : #accessing }
SoilBinaryFile >> path [
	self subclassResponsibility 
]

{ #category : #utilities }
SoilBinaryFile >> prefix [
	self subclassResponsibility 
]

{ #category : #'private - decoding' }
SoilBinaryFile >> readHeader [
	| prefix |
	stream position: 0.
	prefix := stream next: self prefix size.
	(prefix = self prefix asByteArray) ifFalse: [ 
		Error signal: 'read incorrect prefix: ', prefix asString ].
	fileVersion := (stream next: self fileVersionSize) asInteger
]

{ #category : #accessing }
SoilBinaryFile >> soil [ 
	self subclassResponsibility
]

{ #category : #accessing }
SoilBinaryFile >> stream [
	^ stream ifNil: [ 
		stream := SoilLockableStream path: self path ]
]

{ #category : #accessing }
SoilBinaryFile >> stream: anObject [
	stream := anObject
]

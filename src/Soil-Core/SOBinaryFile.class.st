Class {
	#name : #SOBinaryFile,
	#superclass : #Object,
	#instVars : [
		'fileVersion',
		'stream'
	],
	#category : #'Soil-Core-Files'
}

{ #category : #testing }
SOBinaryFile class >> isAbstract [
	<ignoreForCoverage>
	^ self == SOBinaryFile
]

{ #category : #accessing }
SOBinaryFile >> fileVersion [
	^ fileVersion
]

{ #category : #accessing }
SOBinaryFile >> fileVersion: anInteger [ 
	self stream position: self prefix size.
	stream nextPutAll: (anInteger asByteArrayOfSize: self fileVersionSize)
]

{ #category : #utilities }
SOBinaryFile >> fileVersionSize [
	^ 2
]

{ #category : #utilities }
SOBinaryFile >> headerSize [ 
	"the file header stores a prefix and the version for the file format and 
	the version of fuel being used"
	^ self prefix size + self fileVersionSize
]

{ #category : #initialization }
SOBinaryFile >> initializeFilesystem [
	self initializeHeader.
	self initializeStart.
	self stream 
		flush; 
		close
]

{ #category : #initialization }
SOBinaryFile >> initializeHeader [
	self stream 
		position: 0;
		nextPutAll: self prefix asByteArray.
	self fileVersion: 1
]

{ #category : #initialization }
SOBinaryFile >> initializeStart [
	self subclassResponsibility
]

{ #category : #accessing }
SOBinaryFile >> open [
	stream := File openForWriteFileNamed:  self path pathString
]

{ #category : #utilities }
SOBinaryFile >> prefix [
	self subclassResponsibility
]

{ #category : #'private - decoding' }
SOBinaryFile >> readHeader [
	| prefix |
	stream position: 0.
	prefix := stream next: self prefix size.
	(prefix = self prefix asByteArray) ifFalse: [ 
		Error signal: 'read incorrect prefix: ', prefix asString ].
	fileVersion := (stream next: self fileVersionSize) asInteger
]

{ #category : #accessing }
SOBinaryFile >> stream [
	^ stream ifNil: [ 
		stream := self path binaryWriteStream ]
]

{ #category : #accessing }
SOBinaryFile >> stream: anObject [

	stream := anObject
]

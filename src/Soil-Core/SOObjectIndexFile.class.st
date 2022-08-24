Class {
	#name : #SOObjectIndexFile,
	#superclass : #Object,
	#instVars : [
		'id',
		'segment',
		'fileVersion',
		'fuelVersion',
		'lastObjectIndex',
		'stream'
	],
	#category : #'Soil-Core'
}

{ #category : #accessing }
SOObjectIndexFile >> fileVersion [
	^ fileVersion
]

{ #category : #accessing }
SOObjectIndexFile >> fileVersion: anInteger [ 
	self stream position: self prefix size.
	stream nextPutAll: (anInteger asByteArrayOfSize: self fileVersionSize)
]

{ #category : #'as yet unclassified' }
SOObjectIndexFile >> fileVersionSize [
	^ 2
]

{ #category : #accessing }
SOObjectIndexFile >> fuelVersion [
	^ fuelVersion
]

{ #category : #accessing }
SOObjectIndexFile >> fuelVersion: anInteger [ 
	stream position: self prefix size + self fileVersionSize.
	stream nextPutAll: (anInteger asByteArrayOfSize: self fuelVersionSize)
]

{ #category : #'as yet unclassified' }
SOObjectIndexFile >> fuelVersionSize [
	^ 2
]

{ #category : #writing }
SOObjectIndexFile >> headerSize [ 
	"the file header stores a prefix and the version for the file format and 
	the version of fuel being used"
	^ self prefix size + self fileVersionSize + self fuelVersionSize 
]

{ #category : #initialization }
SOObjectIndexFile >> initializeDatabase [
	self stream position: 0.
	self initializeHeader.
	self lastObjectIndex: 1.
	self stream 
		flush; 
		close
	
]

{ #category : #initialization }
SOObjectIndexFile >> initializeHeader [
	self stream 
		position: 0;
		nextPutAll: self prefix asByteArray.
	self fileVersion: 1.
	self fuelVersion: 1
]

{ #category : #accessing }
SOObjectIndexFile >> lastObjectIndex [
	^ lastObjectIndex ifNil: [ 
		lastObjectIndex := 1 ]
]

{ #category : #accessing }
SOObjectIndexFile >> lastObjectIndex: anInteger [ 
	self stream 
		position: self prefix size + self fileVersionSize + self fuelVersionSize ;
		nextPutAll: (anInteger asByteArrayOfSize: self objectIndexSize)
]

{ #category : #'as yet unclassified' }
SOObjectIndexFile >> objectIndexSize [
	^ 8
]

{ #category : #accessing }
SOObjectIndexFile >> path [
	^ segment path / #index
]

{ #category : #writing }
SOObjectIndexFile >> prefix [ 
	^ 'SOIL|OBJECT INDEX' asByteArray
]

{ #category : #'private - decoding' }
SOObjectIndexFile >> readHeader [
	| prefix |
	stream position: 0.
	prefix := stream next: self prefix size.
	(prefix = self prefix asByteArray) ifFalse: [ 
		Error signal: 'read incorrect prefix: ', prefix asString ].
	fileVersion := (stream next: self fileVersionSize) asInteger.
	fuelVersion := (stream next: self fuelVersionSize) asInteger
]

{ #category : #accessing }
SOObjectIndexFile >> segment: aSOObjectSegment [ 
	segment := aSOObjectSegment 
]

{ #category : #accessing }
SOObjectIndexFile >> stream [
	^ stream ifNil: [ 
		stream := self path binaryWriteStream ]
]

{ #category : #accessing }
SOObjectIndexFile >> stream: anObject [

	stream := anObject
]

{ #category : #writing }
SOObjectIndexFile >> writePrefixOn: aStream [ 
	aStream 
		nextPutAll: self prefix asByteArray
]

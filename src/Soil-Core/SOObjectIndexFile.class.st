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
	self stream position: self header size.
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
	stream position: self header size + self fileVersionSize.
	stream nextPutAll: (anInteger asByteArrayOfSize: self fuelVersionSize)
]

{ #category : #'as yet unclassified' }
SOObjectIndexFile >> fuelVersionSize [
	^ 2
]

{ #category : #writing }
SOObjectIndexFile >> header [ 
	^ 'SOIL|OBJECT INDEX' asByteArray
]

{ #category : #initialization }
SOObjectIndexFile >> initializeDatabase [
	self stream 
		position: 0;
		nextPutAll: self header asByteArray.
	self fileVersion: 1.
	self fuelVersion: 1.
	self lastObjectIndex: 1.
	self stream 
		flush; 
		close
	
]

{ #category : #accessing }
SOObjectIndexFile >> lastObjectIndex [
	^ lastObjectIndex ifNil: [ 
		lastObjectIndex := 1 ]
]

{ #category : #accessing }
SOObjectIndexFile >> lastObjectIndex: anInteger [ 
	self stream 
		position: self header size + self fileVersionSize + self fuelVersionSize ;
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

{ #category : #accessing }
SOObjectIndexFile >> segment: aSOObjectSegment [ 
	segment := aSOObjectSegment 
]

{ #category : #accessing }
SOObjectIndexFile >> stream [
	^ stream ifNil: [ 
		stream := self path binaryWriteStream ]
]

{ #category : #writing }
SOObjectIndexFile >> writeHeaderOn: aStream [ 
	aStream 
		nextPutAll: self header asByteArray
]

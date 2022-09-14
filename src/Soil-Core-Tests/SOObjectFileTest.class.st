Class {
	#name : #SOObjectFileTest,
	#superclass : #TestCase,
	#category : #'Soil-Core-Tests'
}

{ #category : #tests }
SOObjectFileTest >> testInitializeOnStream [
	| index bytes prefix fileVersion fuelVersion |
	bytes := ByteArray streamContents: [ :stream |
		index := SOObjectFile new stream: stream.
		index initializeFilesystem ].
	self assert: bytes size equals: index headerSize.
	prefix := bytes copyFrom: 1 to: index prefix size.
	self assert: prefix equals: 'SOIL|OBJECT ' asByteArray.
	fileVersion := bytes copyFrom: index prefix size + 1 to: (index prefix size + index fileVersionSize).
	self assert: fileVersion asInteger equals: 1.
	fuelVersion := bytes copyFrom: index prefix size + index fileVersionSize + 1 to: (index prefix size + index fileVersionSize + index fuelVersionSize).
	self assert: fuelVersion asInteger equals: 1
	 
]

{ #category : #tests }
SOObjectFileTest >> testInitializedFileVersion [
	| index bytes newIndex |
	bytes := ByteArray streamContents: [ :stream |
		index := SOObjectIndexFile new stream: stream.
		index initializeFilesystem ].
	newIndex := SOObjectIndexFile new 
		stream: bytes readStream;
		readHeader.
	self assert: newIndex fileVersion equals: 1
]

{ #category : #tests }
SOObjectFileTest >> testInitializedFuelVersion [
	| index bytes newIndex |
	bytes := ByteArray streamContents: [ :stream |
		index := SOObjectFile new stream: stream.
		index initializeFilesystem ].
	newIndex := SOObjectFile new 
		stream: bytes readStream;
		readHeader.
	self assert: newIndex fuelVersion equals: 1
]

{ #category : #tests }
SOObjectFileTest >> testWriteAndReadFirstObject [
	| index bytes newIndex n2 |
	bytes := ByteArray streamContents: [ :stream |
		index := SOObjectIndexFile new stream: stream.
		index initializeFilesystem ].
	newIndex := SOObjectIndexFile new 
		stream: (ReadWriteStream with: bytes);
		readHeader.
	newIndex lastObjectIndex: 1.
	newIndex at: 1 putPosition: 1000.
	n2 := SOObjectIndexFile new 
		stream: (ReadWriteStream with: bytes);
		readHeader.
	self assert: n2 lastObjectIndex equals: 1
]

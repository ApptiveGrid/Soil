Class {
	#name : #SoilObjectFileTest,
	#superclass : #TestCase,
	#category : #'Soil-Core-Tests'
}

{ #category : #tests }
SoilObjectFileTest >> testInitializeOnStream [
	| index bytes prefix fileVersion fuelVersion |
	bytes := ByteArray streamContents: [ :stream |
		index := SoilObjectFile new stream: stream.
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
SoilObjectFileTest >> testInitializedFileVersion [
	| index bytes newIndex |
	bytes := ByteArray streamContents: [ :stream |
		index := SoilObjectIndexFile new stream: stream.
		index initializeFilesystem ].
	newIndex := SoilObjectIndexFile new 
		stream: bytes readStream;
		readHeader.
	self assert: newIndex fileVersion equals: 1
]

{ #category : #tests }
SoilObjectFileTest >> testInitializedFuelVersion [
	| index bytes newIndex |
	bytes := ByteArray streamContents: [ :stream |
		index := SoilObjectFile new stream: stream.
		index initializeFilesystem ].
	newIndex := SoilObjectFile new 
		stream: bytes readStream;
		readHeader.
	self assert: newIndex fuelVersion equals: 1
]

{ #category : #tests }
SoilObjectFileTest >> testWriteAndReadFirstObject [
	| index bytes newIndex n2 |
	bytes := ByteArray streamContents: [ :stream |
		index := SoilObjectIndexFile new stream: stream.
		index initializeFilesystem ].
	newIndex := SoilObjectIndexFile new 
		stream: (ReadWriteStream with: bytes);
		readHeader.
	newIndex lastObjectIndex: 1.
	newIndex at: 1 putPosition: 1000.
	n2 := SoilObjectIndexFile new 
		stream: (ReadWriteStream with: bytes);
		readHeader.
	self assert: n2 lastObjectIndex equals: 1
]

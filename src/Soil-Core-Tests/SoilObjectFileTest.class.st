Class {
	#name : #SoilObjectFileTest,
	#superclass : #TestCase,
	#category : #'Soil-Core-Tests'
}

{ #category : #'instance creation' }
SoilObjectFileTest >> streamContents: aBlock [ 
	| stream |
	stream := ReadWriteStream on: ByteArray new.
	aBlock value: stream.
	^ stream contents.

]

{ #category : #tests }
SoilObjectFileTest >> testInitializeOnStream [
	| index bytes prefix |
	bytes := ByteArray streamContents: [ :stream |
		index := SoilObjectFile new stream: stream.
		index initializeFilesystem ].
	self assert: bytes size equals: index headerSize.
	prefix := bytes copyFrom: 1 to: index prefix size.
	self assert: prefix equals: 'SOIL|OBJECT ' asByteArray
]

{ #category : #tests }
SoilObjectFileTest >> testWriteAndReadFirstObject [
	| index bytes newIndex n2 |
	bytes := self streamContents: [ :stream |
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

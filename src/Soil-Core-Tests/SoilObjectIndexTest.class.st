Class {
	#name : #SoilObjectIndexTest,
	#superclass : #TestCase,
	#category : #'Soil-Core-Tests-Files'
}

{ #category : #tests }
SoilObjectIndexTest >> streamContents: aBlock [ 
	| stream |
	stream := ReadWriteStream on: ByteArray new.
	aBlock value: stream.
	^ stream contents.

]

{ #category : #tests }
SoilObjectIndexTest >> testInitializeOnStream [
	| index bytes prefix |
	bytes := self streamContents: [ :stream |
		index := SoilObjectIndexFile new stream: stream.
		index initializeFilesystem ].
	self assert: bytes size equals: index headerSize + index objectIndexSize +8 .
 	prefix := bytes copyFrom: 1 to: index prefix size.
	self assert: prefix equals: 'SOIL|OBJECT INDEX' asByteArray
]

{ #category : #tests }
SoilObjectIndexTest >> testWriteAndReadFirstObject [
	| index bytes newIndex n2 |
	bytes := self streamContents: [ :stream |
		index := SoilObjectIndexFile new stream: stream.
		index initializeFilesystem ].
	newIndex := SoilObjectIndexFile new 
		stream: (ReadWriteStream with: bytes);
		readHeader.
	newIndex lastObjectIndex: 2.
	newIndex at: 1 putPosition: 1000.
	n2 := SoilObjectIndexFile new 
		stream: (ReadWriteStream with: newIndex stream contents);
		readHeader.
	self assert: n2 lastObjectIndex equals: 2
]

Class {
	#name : #SOObjectIndexTest,
	#superclass : #TestCase,
	#category : #'Soil-Core-Tests'
}

{ #category : #tests }
SOObjectIndexTest >> testInitializeOnStream [
	| index bytes prefix fileVersion |
	bytes := ByteArray streamContents: [ :stream |
		index := SOObjectIndexFile new stream: stream.
		index initializeDatabase ].
	self assert: bytes size equals: index headerSize + index objectIndexSize +8 .
 	prefix := bytes copyFrom: 1 to: index prefix size.
	self assert: prefix equals: 'SOIL|OBJECT INDEX' asByteArray.
	fileVersion := bytes copyFrom: index prefix size + 1 to: (index prefix size + index fileVersionSize).
	self assert: fileVersion asInteger equals: 1
]

{ #category : #tests }
SOObjectIndexTest >> testInitializedFileVersion [
	| index bytes newIndex |
	bytes := ByteArray streamContents: [ :stream |
		index := SOObjectIndexFile new stream: stream.
		index initializeDatabase ].
	newIndex := SOObjectIndexFile new 
		stream: bytes readStream;
		readHeader.
	self assert: newIndex fileVersion equals: 1
]

{ #category : #tests }
SOObjectIndexTest >> testWriteAndReadFirstObject [
	| index bytes newIndex n2 |
	bytes := ByteArray streamContents: [ :stream |
		index := SOObjectIndexFile new stream: stream.
		index initializeDatabase ].
	newIndex := SOObjectIndexFile new 
		stream: (ReadWriteStream with: bytes);
		readHeader.
	newIndex lastObjectIndex: 1.
	newIndex at: 1 putPosition: 1000.
	n2 := SOObjectIndexFile new 
		stream: (ReadWriteStream with: newIndex stream contents);
		readHeader.
	self assert: n2 lastObjectIndex equals: 1
]

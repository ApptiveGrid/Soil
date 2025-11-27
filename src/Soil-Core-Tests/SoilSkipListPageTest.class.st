Class {
	#name : #SoilSkipListPageTest,
	#superclass : #TestCase,
	#category : #'Soil-Core-Tests-Index'
}

{ #category : #'instance creation' }
SoilSkipListPageTest >> readPageFrom: aStream [ 
	| page |
	page := (SoilIndexPage readPageClassFrom: aStream) new.
	page 
		keySize: 8;
		valueSize: 8.
	^ page readFrom: aStream
]

{ #category : #tests }
SoilSkipListPageTest >> testCreation [ 
	| page |
	page := SoilSkipListDataPage new 
		offset: 1;
		level: 8;
		pageSize: 4096;
		keySize: 16;
		valueSize: 8.
	self assert: page hasRoom
		
]

{ #category : #tests }
SoilSkipListPageTest >> testDataPageFull [
	| page bytes readPage |
	page := SoilSkipListDataPage new 
		keySize: 8;
		valueSize: 8;
		offset: 1;
		level: 8;
		pageSize: 4096.
	1 to: 255 do: [ :n |
		page addItem: (n -> n) ].
	self assert: page hasRoom equals: false.
	self assert: page needsWrite.
	bytes := ByteArray streamContents: [ :stream |
		page writeOn: stream ].
	self deny: page needsWrite.
	readPage := self readPageFrom: bytes readStream.
	1 to: 255 do: [ :n |
		self assert: (page itemAt: n ifAbsent: nil) value equals: n ]

]

{ #category : #tests }
SoilSkipListPageTest >> testDataPageFullStreamSize [
	| page bytes number |
	page := SoilSkipListDataPage new 
		keySize: 8;
		valueSize: 8;
		offset: 1;
		level: 5;
		pageSize: 4096.
	number := 1.
	[ page hasRoom ] whileTrue: [  
		page addItem: (number -> number).
		number := number + 1 ].
	self assert: page hasRoom equals: false.
	self assert: page needsWrite.
	bytes := ByteArray streamContents: [ :stream |
		page writeOn: stream ].
	self assert: bytes size <= page pageSize
]

{ #category : #tests }
SoilSkipListPageTest >> testDataPageSizeOfHeader [
	| page bytes |
	page := SoilSkipListDataPage new 
		keySize: 8;
		valueSize: 8;
		offset: 1;
		level: 8;
		pageSize: 4096.
	bytes := ByteArray streamContents: [ :stream |
		page writeHeaderOn: stream ].
	self assert: bytes size equals: page headerSize 
]

{ #category : #tests }
SoilSkipListPageTest >> testDataPageWriteAndRead [
	| page bytes readPage |
	page := SoilSkipListDataPage new 
		offset: 1;
		level: 8.
	self assert: page needsWrite.
	bytes := ByteArray streamContents: [ :stream |
		page writeOn: stream ].
	self deny: page needsWrite.
	readPage := self readPageFrom: bytes readStream.
	self assert: readPage level equals: 8.
	self deny: readPage needsWrite 
]

{ #category : #tests }
SoilSkipListPageTest >> testDataPageWriteAndReadRightArray [
	| page bytes readPage |
	page := SoilSkipListDataPage new 
		offset: 1;
		level: 8;
		setRight: #( 1 2 3 4 5 6 7 8 ).
	self assert: page needsWrite.
	bytes := ByteArray streamContents: [ :stream |
		page writeOn: stream ].
	self deny: page needsWrite.
	readPage := self readPageFrom: bytes readStream. 
	self assert: readPage level equals: 8.
	self assert: readPage right equals: #( 1 2 3 4 5 6 7 8).
	self deny: readPage needsWrite 
]

{ #category : #tests }
SoilSkipListPageTest >> testHeaderPageFull [
	| page bytes readPage |
	page := SoilSkipListHeaderPage new 
		keySize: 8;
		valueSize: 8;
		maxLevel: 16;
		offset: 1;
		level: 8;
		pageSize: 4096;
		lastPageOffset: 2.
	1 to: 253 do: [ :n |
		page addItem: (n -> n) ].
	self assert: page hasRoom equals: false.
	self assert: page needsWrite.
	bytes := ByteArray streamContents: [ :stream |
		page writeOn: stream ].
	self deny: page needsWrite.
	readPage := self readPageFrom: bytes readStream.
	1 to: 253 do: [ :n |
		self assert: (page itemAt: n ifAbsent: nil) value equals: n ]

]

{ #category : #tests }
SoilSkipListPageTest >> testHeaderPageFullStreamSize [
	| page bytes number |
	page := SoilSkipListHeaderPage new 
		keySize: 7;
		valueSize: 8;
		maxLevel: 8;
		lastPageOffset: 1;
		offset: 1;
		level: 6;
		pageSize: 4096.
	number := 1.
	[ page hasRoom ] whileTrue: [  
		page addItem: (number -> number).
		number := number + 1 ].
	self assert: page hasRoom equals: false.
	self assert: page needsWrite.
	bytes := ByteArray streamContents: [ :stream |
		page writeOn: stream ].
	self assert: bytes size <= page pageSize
]

{ #category : #tests }
SoilSkipListPageTest >> testHeaderPageSizeOfHeader [
	| page bytes |
	page := SoilSkipListHeaderPage new 
		keySize: 8;
		valueSize: 8;
		maxLevel: 16;
		offset: 1;
		level: 8;
		pageSize: 4096;
		lastPageOffset: 2.
	bytes := ByteArray streamContents: [ :stream |
		page writeHeaderOn: stream ].
	self assert: bytes size equals: page headerSize 
]

{ #category : #tests }
SoilSkipListPageTest >> testHeaderPageWriteAndRead [
	| page bytes readPage |
	page := SoilSkipListHeaderPage new 
		keySize: 16;
		valueSize: 8;
		maxLevel: 12;
		offset: 1;
		level: 8;
		lastPageOffset: 2.
	self assert: page needsWrite.
	bytes := ByteArray streamContents: [ :stream |
		page writeOn: stream ].
	self deny: page needsWrite.
	readPage := self readPageFrom: bytes readStream.
	self assert: readPage level equals: 8.
	self assert: readPage keySize equals: 16.
	self assert: readPage valueSize equals: 8.
	self assert: readPage maxLevel equals: 12.
	self assert: readPage lastPageOffset equals: 2.
	self deny: readPage needsWrite 
]

{ #category : #tests }
SoilSkipListPageTest >> testWriteOldVersion [
	| page bytes readPage |
	page := SoilSkipListHeaderPage new 
		keySize: 8;
		valueSize: 8;
		maxLevel: 16;
		offset: 1;
		level: 8;
		pageSize: 4096;
		lastPageOffset: 2;
		instVarNamed: #version put: 1;
		yourself.
	1 to: 10 do: [ :n |
		page addItem: (n -> n) ].
	self assert: page needsWrite.
	bytes := ByteArray streamContents: [ :stream |
		page writeOn: stream ].
	self deny: page needsWrite.
	readPage := self readPageFrom: bytes readStream.
	self assert: readPage version equals: 1.
	self assert: (readPage instVarNamed: #size) equals: -1 

]

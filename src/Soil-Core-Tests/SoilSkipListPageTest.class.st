Class {
	#name : #SoilSkipListPageTest,
	#superclass : #TestCase,
	#category : #'Soil-Core-Tests'
}

{ #category : #tests }
SoilSkipListPageTest >> testCreation [ 
	| page |
	page := SoilSkipListTruncPage new 
		index: 1;
		level: 8;
		pageSize: 4096;
		keySize: 16;
		valueSize: 8.
	self assert: page hasRoom
		
]

{ #category : #tests }
SoilSkipListPageTest >> testHeaderFull [
	| page bytes readPage |
	page := SoilSkipListHeaderPage new 
		keySize: 8;
		valueSize: 8;
		maxLevel: 16;
		index: 1;
		level: 8;
		pageSize: 4096;
		lastPageIndex: 2.
	1 to: 253 do: [ :n |
		page addItem: (n -> n) ].
	self assert: page hasRoom equals: false.
	self assert: page isDirty.
	bytes := ByteArray streamContents: [ :stream |
		page writeOn: stream ].
	self deny: page isDirty.
	readPage := SoilSkipListPage readPageFrom: bytes readStream keySize: 8 valueSize: 8.
	1 to: 253 do: [ :n |
		self assert: (page itemAt: n ifAbsent: nil) value equals: n ]

]

{ #category : #tests }
SoilSkipListPageTest >> testHeaderWriteAndRead [
	| page bytes readPage |
	page := SoilSkipListHeaderPage new 
		keySize: 16;
		valueSize: 8;
		maxLevel: 12;
		index: 1;
		level: 8;
		lastPageIndex: 2.
	self assert: page isDirty.
	bytes := ByteArray streamContents: [ :stream |
		page writeOn: stream ].
	self deny: page isDirty.
	readPage := SoilSkipListPage readPageFrom: bytes readStream keySize: 8 valueSize: 8.
	self assert: readPage index equals: 1.
	self assert: readPage level equals: 8.
	self assert: readPage keySize equals: 16.
	self assert: readPage valueSize equals: 8.
	self assert: readPage maxLevel equals: 12.
	self assert: readPage lastPageIndex equals: 2.
	self deny: readPage isDirty 
]

{ #category : #tests }
SoilSkipListPageTest >> testTruncFull [
	| page bytes readPage |
	page := SoilSkipListTruncPage new 
		keySize: 8;
		valueSize: 8;
		index: 1;
		level: 8;
		pageSize: 4096.
	1 to: 255 do: [ :n |
		page addItem: (n -> n) ].
	self assert: page hasRoom equals: false.
	self assert: page isDirty.
	bytes := ByteArray streamContents: [ :stream |
		page writeOn: stream ].
	self deny: page isDirty.
	readPage := SoilSkipListPage readPageFrom: bytes readStream keySize: 8 valueSize: 8.
	1 to: 255 do: [ :n |
		self assert: (page itemAt: n ifAbsent: nil) value equals: n ]

]

{ #category : #tests }
SoilSkipListPageTest >> testTruncWriteAndRead [
	| page bytes readPage |
	page := SoilSkipListTruncPage new 
		index: 1;
		level: 8.
	self assert: page isDirty.
	bytes := ByteArray streamContents: [ :stream |
		page writeOn: stream ].
	self deny: page isDirty.
	readPage := SoilSkipListPage readPageFrom: bytes readStream keySize: 8 valueSize: 8.
	self assert: readPage index equals: 1.
	self assert: readPage level equals: 8.
	self deny: readPage isDirty 
]

{ #category : #tests }
SoilSkipListPageTest >> testWriteAndReadRightArray [
	| page bytes readPage |
	page := SoilSkipListTruncPage new 
		index: 1;
		level: 8;
		setRight: #( 1 2 3 4 5 6 7 8 ).
	self assert: page isDirty.
	bytes := ByteArray streamContents: [ :stream |
		page writeOn: stream ].
	self deny: page isDirty.
	readPage := SoilSkipListPage readPageFrom: bytes readStream keySize: 8 valueSize: 8. 
	self assert: readPage index equals: 1.
	self assert: readPage level equals: 8.
	self assert: readPage right equals: #( 1 2 3 4 5 6 7 8).
	self deny: readPage isDirty 
]

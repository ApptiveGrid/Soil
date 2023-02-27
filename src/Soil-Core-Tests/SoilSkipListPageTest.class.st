Class {
	#name : #SoilSkipListPageTest,
	#superclass : #TestCase,
	#category : #'Soil-Core-Tests'
}

{ #category : #tests }
SoilSkipListPageTest >> testCreation [ 
	| page |
	page := SoilSkipListPage new 
		index: 1;
		level: 8.
	self assert: page hasRoom
		
]

{ #category : #tests }
SoilSkipListPageTest >> testWriteAndRead [
	| page bytes readPage |
	page := SoilSkipListPage new 
		index: 1;
		level: 8.
	self assert: page isDirty.
	bytes := ByteArray streamContents: [ :stream |
		page writeOn: stream ].
	self deny: page isDirty.
	readPage := SoilSkipListPage basicNew readFrom: bytes readStream.
	self assert: readPage index equals: 1.
	self assert: readPage level equals: 8.
	self deny: readPage isDirty 
]
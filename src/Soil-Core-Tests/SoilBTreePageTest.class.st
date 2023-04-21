Class {
	#name : #SoilBTreePageTest,
	#superclass : #TestCase,
	#category : #'Soil-Core-Tests'
}

{ #category : #tests }
SoilBTreePageTest >> testCreation [ 
	| page |
	page := SoilBTreeDataPage new 
		index: 1;
		pageSize: 4096;
		keySize: 16;
		valueSize: 8.
	self assert: page hasRoom
]

{ #category : #tests }
SoilBTreePageTest >> testCreationIndex [
	| page |
	page := SoilBTreeIndexPage new 
		index: 1;
		pageSize: 4096;
		keySize: 16;
		valueSize: 8.
	self assert: page hasRoom
]

{ #category : #tests }
SoilBTreePageTest >> testWriteAndRead [
	| page bytes readPage |
	page := SoilBTreeDataPage new 
		index: 1.
	self assert: page isDirty.
	bytes := ByteArray streamContents: [ :stream |
		page writeOn: stream ].
	self deny: page isDirty.
	readPage := SoilBTreeDataPage basicNew readFrom: bytes readStream.
	self assert: readPage index equals: 1.
	self deny: readPage isDirty 
]

{ #category : #tests }
SoilBTreePageTest >> testWriteAndReadIndex [
	| page bytes readPage |
	page := SoilBTreeIndexPage new 
		index: 1.
	self assert: page isDirty.
	bytes := ByteArray streamContents: [ :stream |
		page writeOn: stream ].
	self deny: page isDirty.
	readPage := SoilBTreeIndexPage basicNew readFrom: bytes readStream.
	self assert: readPage index equals: 1.
	self deny: readPage isDirty 
]

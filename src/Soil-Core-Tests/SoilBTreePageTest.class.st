Class {
	#name : #SoilBTreePageTest,
	#superclass : #TestCase,
	#category : #'Soil-Core-Tests'
}

{ #category : #helper }
SoilBTreePageTest >> readPageFrom: aStream [ 
	| page |
	page := (SoilIndexPage readPageClassFrom: aStream) new.
	page 
		keySize: 8;
		valueSize: 8.
	^ page readFrom: aStream
]

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
		keySize: 16.
	self assert: page hasRoom
]

{ #category : #tests }
SoilBTreePageTest >> testWriteAndRead [
	| page bytes readPage |
	page := SoilBTreeDataPage new 
		index: 1;
		valueSize: 8;
		keySize: 8.
		
	self assert: page isDirty.
	bytes := ByteArray streamContents: [ :stream |
		page writeOn: stream ].
	self deny: page isDirty.
	readPage := self readPageFrom: bytes readStream.
	self assert: readPage next equals: page next.
	self assert: readPage valueSize equals: page valueSize.
	self assert: readPage keySize equals: page keySize.
	
	self deny: readPage isDirty 
]

{ #category : #tests }
SoilBTreePageTest >> testWriteAndReadIndex [
	| page bytes readPage |
	page := SoilBTreeIndexPage new 
		index: 1;
		keySize: 8.
	self assert: page isDirty.
	bytes := ByteArray streamContents: [ :stream |
		page writeOn: stream ].
	self deny: page isDirty.
	readPage := self readPageFrom: bytes readStream.
	self deny: readPage isDirty
]

{ #category : #tests }
SoilBTreePageTest >> testWriteAndReadPageCode [
	| page bytes readPage |
	page := SoilBTreeDataPage new 
		index: 1;
		valueSize: 8;
		keySize: 8.
		
	self assert: page isDirty.
	bytes := ByteArray streamContents: [ :stream |
		page writeOn: stream ].
	self deny: page isDirty.
	readPage := self readPageFrom: bytes readStream.
	self assert: readPage next equals: page next.
	self assert: readPage valueSize equals: page valueSize.
	self assert: readPage keySize equals: page keySize.
	
	self deny: readPage isDirty 
]

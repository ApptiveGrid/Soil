Class {
	#name : #SoilBTreeHeaderPage,
	#superclass : #SoilBTreeDataPage,
	#instVars : [
		'lastPageIndex'
	],
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #'as yet unclassified' }
SoilBTreeHeaderPage class >> pageCode [ 
	^ 3
]

{ #category : #accessing }
SoilBTreeHeaderPage >> lastPageIndex: anObject [
	lastPageIndex := anObject.
	dirty := true
]

{ #category : #accessing }
SoilBTreeHeaderPage >> nextPageIndex [
	lastPageIndex := lastPageIndex + 1.
	dirty := true.
	^ lastPageIndex 
]

{ #category : #printing }
SoilBTreeHeaderPage >> printOn: aStream [ 
	aStream << 'header page : #' << index asString
]

{ #category : #writing }
SoilBTreeHeaderPage >> readFrom: aStream [ 
	dirty := false.
	self readPageCodeFrom: aStream.
	self readIndexFrom: aStream.
	self readNextFrom: aStream.
	self readHeaderFrom: aStream.

	self readItemsFrom: aStream
]

{ #category : #'initialize-release' }
SoilBTreeHeaderPage >> readHeaderFrom: aStream [
	keySize := (aStream next: 2) asInteger.
	valueSize := (aStream next: 2) asInteger.
	lastPageIndex :=(aStream next: 2) asInteger 
	
]

{ #category : #writing }
SoilBTreeHeaderPage >> writeOn: aStream [ 
	dirty := false.
	aStream 
		nextPut: self class pageCode;
		nextPutAll: (index asByteArrayOfSize: self indexSize);
		nextPutAll: (next asByteArrayOfSize: self pointerSize);
		nextPutAll: (keySize asByteArrayOfSize: 2);
		nextPutAll: (valueSize asByteArrayOfSize: 2);
		nextPutAll: (lastPageIndex asByteArrayOfSize: 2).
		
	self 
		writeItemsOn: aStream
]

"
The Header page is the first of the data pages. It knows the last page (and like all data pages the next page).

The header page is always there, even for an empty BTree.

It is easily accessible via #headerPage on the BTree index
"
Class {
	#name : #SoilBTreeHeaderPage,
	#superclass : #SoilBTreeDataPage,
	#instVars : [
		'lastPageIndex'
	],
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #accessing }
SoilBTreeHeaderPage class >> pageCode [ 
	^ 3
]

{ #category : #utilities }
SoilBTreeHeaderPage >> headerSize [
	^ super headerSize  
		+ 2 "valueSize"
		+ 2 "keySize"
		+ self pointerSize "lastPageIndex"
		
]

{ #category : #accessing }
SoilBTreeHeaderPage >> lastPageIndex [
	^ lastPageIndex
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
	"we do not read the pageCode, that was done before"
	self readLastTransactionFrom: aStream.
	self readNextFrom: aStream.
	keySize := (aStream next: 2) asInteger.
	valueSize := (aStream next: 2) asInteger.
	lastPageIndex :=(aStream next: self pointerSize) asInteger.
	self readItemsFrom: aStream
]

{ #category : #writing }
SoilBTreeHeaderPage >> writeHeaderOn: aStream [ 
	super writeHeaderOn: aStream.
	aStream
		nextPutAll: (keySize asByteArrayOfSize: 2);
		nextPutAll: (valueSize asByteArrayOfSize: 2);
		nextPutAll: (lastPageIndex asByteArrayOfSize: self pointerSize)
]

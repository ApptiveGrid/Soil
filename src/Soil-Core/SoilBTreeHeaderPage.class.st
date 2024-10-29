"
The Header page is the first of the data pages. It knows the last page (and like all data pages the next page).

The header page is always there, even for an empty BTree.

It is easily accessible via #headerPage on the BTree index
"
Class {
	#name : #SoilBTreeHeaderPage,
	#superclass : #SoilAbstractBTreeDataPage,
	#instVars : [
		'lastPageIndex',
		'firstFreePageIndex',
		'size'
	],
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #accessing }
SoilBTreeHeaderPage class >> pageCode [ 
	^ 3
]

{ #category : #utilities }
SoilBTreeHeaderPage >> decreaseSize [
 	size := size - 1.
 	needWrite := true
]

{ #category : #accessing }
SoilBTreeHeaderPage >> firstFreePageIndex [

	^ firstFreePageIndex
]

{ #category : #accessing }
SoilBTreeHeaderPage >> firstFreePageIndex: anObject [

	firstFreePageIndex := anObject
]

{ #category : #utilities }
SoilBTreeHeaderPage >> headerSize [
	^ super headerSize  
		+ 2 "valueSize"
		+ 2 "keySize"
		+ self pointerSize "lastPageIndex"
		+ self pointerSize "lastFreePageIndex"
		+ 6 "size"
]

{ #category : #utilities }
SoilBTreeHeaderPage >> increaseSize [
 	size := size + 1.
 	needWrite := true
]

{ #category : #initialization }
SoilBTreeHeaderPage >> initialize [ 
	super initialize.
	firstFreePageIndex := 0.
	size := 0
]

{ #category : #testing }
SoilBTreeHeaderPage >> isHeaderPage [
	^ true
]

{ #category : #accessing }
SoilBTreeHeaderPage >> lastPageIndex [
	^ lastPageIndex
]

{ #category : #accessing }
SoilBTreeHeaderPage >> lastPageIndex: anObject [
	lastPageIndex := anObject.
	needWrite := true
]

{ #category : #initialization }
SoilBTreeHeaderPage >> latestVersion [
	^ 1
]

{ #category : #accessing }
SoilBTreeHeaderPage >> nextPageOffset [
	lastPageIndex := lastPageIndex + 1.
	needWrite := true.
	^ lastPageIndex 
]

{ #category : #printing }
SoilBTreeHeaderPage >> printOn: aStream [ 
	aStream << 'header page : #' << offset asString
]

{ #category : #reading }
SoilBTreeHeaderPage >> readFrom: aStream [ 
	super readFrom: aStream.
	keySize := (aStream next: 2) asInteger.
	valueSize := (aStream next: 2) asInteger.
	lastPageIndex :=(aStream next: self pointerSize) asInteger.
	firstFreePageIndex :=(aStream next: 4) asInteger.
	size := (aStream next: 6) asInteger.
	self readItemsFrom: aStream
]

{ #category : #accessing }
SoilBTreeHeaderPage >> size [
	^size
]

{ #category : #accessing }
SoilBTreeHeaderPage >> size: anInteger [
 	size := anInteger
]

{ #category : #writing }
SoilBTreeHeaderPage >> writeHeaderOn: aStream [ 
	super writeHeaderOn: aStream.
	aStream
		nextPutAll: (keySize asByteArrayOfSize: 2);
		nextPutAll: (valueSize asByteArrayOfSize: 2);
		nextPutAll: (lastPageIndex asByteArrayOfSize: self pointerSize);
		nextPutAll: (firstFreePageIndex asByteArrayOfSize: 4);
		nextPutAll: (self size asByteArrayOfSize: 6).
]

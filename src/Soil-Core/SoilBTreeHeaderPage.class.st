"
The Header page is the first of the data pages. It knows the last page (and like all data pages the next page).

The header page is always there, even for an empty BTree.

It is easily accessible via #headerPage on the BTree index
"
Class {
	#name : #SoilBTreeHeaderPage,
	#superclass : #SoilAbstractBTreeDataPage,
	#instVars : [
		'firstFreePageIndex',
		'size',
		'lastPageOffset',
		'uniqueKeys'
	],
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #accessing }
SoilBTreeHeaderPage class >> pageCode [ 
	^ 3
]

{ #category : #testing }
SoilBTreeHeaderPage >> canBeRemoved [ 
	^ false
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
		+ 19 "keySize(2), valueSize(2), lastPageIndex(4), lastFreePageIndex(4) size(6) uniqueKeys(1)" 
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
	size := 0.
	uniqueKeys := true
]

{ #category : #testing }
SoilBTreeHeaderPage >> isHeaderPage [
	^ true
]

{ #category : #accessing }
SoilBTreeHeaderPage >> lastPageOffset [
	^ lastPageOffset
]

{ #category : #accessing }
SoilBTreeHeaderPage >> lastPageOffset: anObject [
	lastPageOffset := anObject.
	needWrite := true
]

{ #category : #initialization }
SoilBTreeHeaderPage >> latestVersion [
	^ 3
]

{ #category : #accessing }
SoilBTreeHeaderPage >> nextPageOffset [
	lastPageOffset := lastPageOffset + 1.
	needWrite := true.
	^ lastPageOffset 
]

{ #category : #printing }
SoilBTreeHeaderPage >> printOn: aStream [ 
	aStream << 'header page : #' << offset asString
]

{ #category : #reading }
SoilBTreeHeaderPage >> readFrom: aStream [ 
	super readFrom: aStream.
	self 
		readHeaderFrom: aStream;
		readItemsFrom: aStream
]

{ #category : #reading }
SoilBTreeHeaderPage >> readHeaderFrom: aStream [ 
	keySize := (aStream next: 2) asInteger.
	valueSize := (aStream next: 2) asInteger.
	lastPageOffset :=(aStream next: self pointerSize) asInteger.
	firstFreePageIndex :=(aStream next: 4) asInteger.
	size := (aStream next: 6) asInteger.
	uniqueKeys := (version > 2) 
		ifTrue: [ aStream next = 1 ]
		ifFalse: [ true ].
]

{ #category : #accessing }
SoilBTreeHeaderPage >> size [
	^size
]

{ #category : #accessing }
SoilBTreeHeaderPage >> size: anInteger [
 	size := anInteger
]

{ #category : #accessing }
SoilBTreeHeaderPage >> uniqueKeys [
	^ uniqueKeys
]

{ #category : #accessing }
SoilBTreeHeaderPage >> uniqueKeys: aBoolean [ 
	uniqueKeys := aBoolean.
	needWrite := true
]

{ #category : #writing }
SoilBTreeHeaderPage >> writeHeaderOn: aStream [ 
	super writeHeaderOn: aStream.
	aStream
		nextPutAll: (keySize asByteArrayOfSize: 2);
		nextPutAll: (valueSize asByteArrayOfSize: 2);
		nextPutAll: (lastPageOffset asByteArrayOfSize: self pointerSize);
		nextPutAll: (firstFreePageIndex asByteArrayOfSize: 4);
		nextPutAll: (self size asByteArrayOfSize: 6).
		(version > 2) ifTrue: [ 
			 (uniqueKeys isNil or: [ uniqueKeys ])
				ifTrue: [ aStream nextPut:  1 ]
				ifFalse: [ aStream nextPut: 0 ] ].
]

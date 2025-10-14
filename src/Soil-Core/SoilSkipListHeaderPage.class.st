"
The Header page is the first of the data pages.

It knows 
- the last page (and like all data pages the next page).
- the maxLevel (maximum number of levels for the skipping lists)

The header page is always there, even for an empty SkipList.

It is easily accessible via #headerPage on the BTree index.

See superclass comment for more infos.
"
Class {
	#name : #SoilSkipListHeaderPage,
	#superclass : #SoilSkipListPage,
	#instVars : [
		'maxLevel',
		'firstFreePageIndex',
		'size',
		'lastPageOffset'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #accessing }
SoilSkipListHeaderPage class >> pageCode [ 
	^ 1 
]

{ #category : #testing }
SoilSkipListHeaderPage >> canBeRemoved [ 
	^ false
]

{ #category : #utilities }
SoilSkipListHeaderPage >> decreaseSize [
	(size = -1) ifTrue: [ ^ self ].
	size := size - 1.
	needWrite := true
]

{ #category : #accessing }
SoilSkipListHeaderPage >> firstFreePageIndex [

	^ firstFreePageIndex
]

{ #category : #accessing }
SoilSkipListHeaderPage >> firstFreePageIndex: anObject [

	firstFreePageIndex := anObject.
	needWrite := true
]

{ #category : #utilities }
SoilSkipListHeaderPage >> headerSize [
	^ super headerSize 
		+ 20 "keySize(2), valueSize(2), maxLevel(2), lastPageIndex(4), lastFreePageIndex(4) size(6)" 
		+ 1 "level" 
		+ (self level * self rightSize)

]

{ #category : #utilities }
SoilSkipListHeaderPage >> increaseSize [
	(size = -1) ifTrue: [ ^ self ].
	size := size + 1.
	needWrite := true
]

{ #category : #initialization }
SoilSkipListHeaderPage >> initialize [ 
	super initialize.
	offset := 1.
	lastPageOffset := 1.
	firstFreePageIndex := 0.
	size := 0
]

{ #category : #testing }
SoilSkipListHeaderPage >> isHeaderPage [
	^ true
]

{ #category : #accessing }
SoilSkipListHeaderPage >> keySize: anInteger [
	"as long as no items have been added the key size can be changed"
	((self lastPageOffset = 1) and: [ items isEmpty ]) ifFalse: [ 
		keySize ifNotNil: [ Error signal: 'key size has been set already' ] ].
	super keySize: anInteger.
	needWrite := true
	

]

{ #category : #accessing }
SoilSkipListHeaderPage >> label [ 
	^ 'header page'
]

{ #category : #accessing }
SoilSkipListHeaderPage >> lastPageOffset [

	^ lastPageOffset
]

{ #category : #accessing }
SoilSkipListHeaderPage >> lastPageOffset: anObject [
	lastPageOffset := anObject.
	needWrite := true
]

{ #category : #initialization }
SoilSkipListHeaderPage >> latestVersion [
	^ 2
]

{ #category : #accessing }
SoilSkipListHeaderPage >> maxLevel [

	^ maxLevel
]

{ #category : #accessing }
SoilSkipListHeaderPage >> maxLevel: anInteger [
	anInteger ifNil: [^ self ].
	maxLevel := anInteger.
	right := Array new: anInteger withAll: 0.
	needWrite := true
]

{ #category : #accessing }
SoilSkipListHeaderPage >> nextPageOffset [
	lastPageOffset := lastPageOffset + 1.
	needWrite := true.
	^ lastPageOffset 
]

{ #category : #reading }
SoilSkipListHeaderPage >> readFrom: aStream [ 
	super readFrom: aStream.
	self 
		readHeaderFrom: aStream;
		readLevelsFrom: aStream;
		readItemsFrom: aStream
]

{ #category : #reading }
SoilSkipListHeaderPage >> readHeaderFrom: aStream [
	"keySize := (aStream next: 2) asInteger.
	valueSize := (aStream next: 2) asInteger.
	maxLevel := (aStream next: 2) asInteger."
	lastPageOffset :=(aStream next: 4) asInteger.
	firstFreePageIndex :=(aStream next: 4) asInteger.
	size := (version > 1) 
		ifTrue: [ (aStream next: 6) asInteger ]
		ifFalse: [ -1 ]
]

{ #category : #accessing }
SoilSkipListHeaderPage >> size [ 
	^ size
]

{ #category : #accessing }
SoilSkipListHeaderPage >> size: anInteger [ 
	size := anInteger
]

{ #category : #accessing }
SoilSkipListHeaderPage >> smallestKey [ 
	^ 0
]

{ #category : #accessing }
SoilSkipListHeaderPage >> validate [
	super validate.
	(offset >= 1) ifFalse: [ 
		Error signal: 'bogus offset' ].
	(maxLevel > 256) ifTrue: [ 
		Error signal: 'unusual hight maxLevel' ].
	(right size = maxLevel) ifFalse: [ 
		Error signal: 'right array and max level are not aligned' ].
	(firstFreePageIndex <= lastPageOffset) ifFalse: [ 
		Error signal: 'first free index is bogus' ] 
	
]

{ #category : #writing }
SoilSkipListHeaderPage >> writeHeaderOn: aStream [ 
	super writeHeaderOn: aStream.
	aStream 
		"nextPutAll: (keySize asByteArrayOfSize: 2);
		nextPutAll: (valueSize asByteArrayOfSize: 2);
		nextPutAll: (maxLevel asByteArrayOfSize: 2);"
		nextPutAll: (lastPageOffset asByteArrayOfSize: 4);
		nextPutAll: (firstFreePageIndex asByteArrayOfSize: 4).
		(version > 1) ifTrue: [ 
			aStream nextPutAll: (self size asByteArrayOfSize: 6) ].
	self 
		writeLevelsOn: aStream
]

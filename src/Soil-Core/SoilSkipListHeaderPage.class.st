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
		'lastPageIndex',
		'lastFreePageIndex'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #accessing }
SoilSkipListHeaderPage class >> pageCode [ 
	^ 1 
]

{ #category : #utilities }
SoilSkipListHeaderPage >> headerSize [
	^ super headerSize 
		+ 14 "keySize(2), valueSize(2), maxLevel(2), lastPageIndex(4), lastFreePageIndex(4)" 
		+ 1 "level" 
		+ (self level * self rightSize)
		+ 2 "items size"
]

{ #category : #initialization }
SoilSkipListHeaderPage >> initialize [ 
	super initialize.
	lastPageIndex := 1.
	lastFreePageIndex := 0
]

{ #category : #accessing }
SoilSkipListHeaderPage >> keySize: anInteger [
	"as long as no items have been added the key size can be changed"
	((self lastPageIndex = 1) and: [ items isEmpty ]) ifFalse: [ 
		keySize ifNotNil: [ Error signal: 'key size has been set already' ] ].
	super keySize: anInteger.
	dirty := true
	

]

{ #category : #accessing }
SoilSkipListHeaderPage >> lastFreePageIndex [

	^ lastFreePageIndex
]

{ #category : #accessing }
SoilSkipListHeaderPage >> lastFreePageIndex: anObject [

	lastFreePageIndex := anObject
]

{ #category : #accessing }
SoilSkipListHeaderPage >> lastPageIndex [

	^ lastPageIndex
]

{ #category : #accessing }
SoilSkipListHeaderPage >> lastPageIndex: anObject [
	lastPageIndex := anObject.
	dirty := true
]

{ #category : #accessing }
SoilSkipListHeaderPage >> maxLevel [

	^ maxLevel
]

{ #category : #accessing }
SoilSkipListHeaderPage >> maxLevel: anInteger [

	maxLevel := anInteger.
	right := Array new: anInteger withAll: 0.
	dirty := true
]

{ #category : #accessing }
SoilSkipListHeaderPage >> nextPageIndex [
	lastPageIndex := lastPageIndex + 1.
	dirty := true.
	^ lastPageIndex 
]

{ #category : #'instance creation' }
SoilSkipListHeaderPage >> readFrom: aStream [ 
	super readFrom: aStream.
	self 
		readHeaderFrom: aStream;
		readLevelsFrom: aStream;
		readItemsFrom: aStream
]

{ #category : #'instance creation' }
SoilSkipListHeaderPage >> readHeaderFrom: aStream [
	keySize := (aStream next: 2) asInteger.
	valueSize := (aStream next: 2) asInteger.
	maxLevel := (aStream next: 2) asInteger.
	lastPageIndex :=(aStream next: 4) asInteger.
	lastFreePageIndex :=(aStream next: 4) asInteger 
]

{ #category : #'instance creation' }
SoilSkipListHeaderPage >> readLegacyFrom: aStream [ 
	dirty := false.
	self 
		readLastTransactionFrom: aStream;
		readLegacyHeaderFrom: aStream;
		readLevelsFrom: aStream;
		readItemsFrom: aStream
]

{ #category : #'instance creation' }
SoilSkipListHeaderPage >> readLegacyHeaderFrom: aStream [
	keySize := (aStream next: 2) asInteger.
	valueSize := (aStream next: 2) asInteger.
	maxLevel := (aStream next: 2) asInteger.
	lastPageIndex :=(aStream next: 4) asInteger.
]

{ #category : #accessing }
SoilSkipListHeaderPage >> smallestKey [ 
	^ 0
]

{ #category : #writing }
SoilSkipListHeaderPage >> writeHeaderOn: aStream [ 
	super writeHeaderOn: aStream.
	aStream 
		nextPutAll: (keySize asByteArrayOfSize: 2);
		nextPutAll: (valueSize asByteArrayOfSize: 2);
		nextPutAll: (maxLevel asByteArrayOfSize: 2);
		nextPutAll: (lastPageIndex asByteArrayOfSize: 4);
		nextPutAll: (lastFreePageIndex asByteArrayOfSize: 4).
	self 
		writeLevelsOn: aStream.
	aStream nextPutAll: (items size asByteArrayOfSize: self itemsSizeSize).

]

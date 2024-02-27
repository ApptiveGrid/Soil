Class {
	#name : #SoilSkipListLegacyHeaderPage,
	#superclass : #SoilSkipListPage,
	#instVars : [
		'maxLevel',
		'lastPageIndex',
		'lastFreePageIndex'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #accessing }
SoilSkipListLegacyHeaderPage class >> pageCode [ 
	^ 1 
]

{ #category : #utilities }
SoilSkipListLegacyHeaderPage >> headerSize [
	^ super headerSize 
		+ 14 "keySize(2), valueSize(2), maxLevel(2), lastPageIndex(4), lastFreePageIndex(4)" 
		+ 1 "level" 
		+ (self level * self rightSize)
		+ 2 "items size"
]

{ #category : #initialization }
SoilSkipListLegacyHeaderPage >> initialize [ 
	super initialize.
	lastPageIndex := 1.
	lastFreePageIndex := 0
]

{ #category : #initialization }
SoilSkipListLegacyHeaderPage >> initializeInIndex: aSoilSkipList [ 
	
]

{ #category : #accessing }
SoilSkipListLegacyHeaderPage >> keySize: anInteger [
	"as long as no items have been added the key size can be changed"
	((self lastPageIndex = 1) and: [ items isEmpty ]) ifFalse: [ 
		keySize ifNotNil: [ Error signal: 'key size has been set already' ] ].
	super keySize: anInteger.
	dirty := true
	

]

{ #category : #accessing }
SoilSkipListLegacyHeaderPage >> lastFreePageIndex [

	^ lastFreePageIndex
]

{ #category : #accessing }
SoilSkipListLegacyHeaderPage >> lastFreePageIndex: anObject [

	lastFreePageIndex := anObject
]

{ #category : #accessing }
SoilSkipListLegacyHeaderPage >> lastPageIndex [

	^ lastPageIndex
]

{ #category : #accessing }
SoilSkipListLegacyHeaderPage >> lastPageIndex: anObject [
	lastPageIndex := anObject.
	dirty := true
]

{ #category : #accessing }
SoilSkipListLegacyHeaderPage >> maxLevel [

	^ maxLevel
]

{ #category : #accessing }
SoilSkipListLegacyHeaderPage >> maxLevel: anInteger [

	maxLevel := anInteger.
	right := Array new: anInteger withAll: 0.
	dirty := true
]

{ #category : #accessing }
SoilSkipListLegacyHeaderPage >> nextPageIndex [
	lastPageIndex := lastPageIndex + 1.
	dirty := true.
	^ lastPageIndex 
]

{ #category : #'instance creation' }
SoilSkipListLegacyHeaderPage >> readFrom: aStream [ 
	dirty := false.
	self 
		readLastTransactionFrom: aStream;
		readLegacyHeaderFrom: aStream;
		readLevelsFrom: aStream;
		readItemsFrom: aStream
]

{ #category : #'instance creation' }
SoilSkipListLegacyHeaderPage >> readHeaderFrom: aStream [
	keySize := (aStream next: 2) asInteger.
	valueSize := (aStream next: 2) asInteger.
	maxLevel := (aStream next: 2) asInteger.
	lastPageIndex :=(aStream next: 4) asInteger.
	lastFreePageIndex :=(aStream next: 4) asInteger 
]

{ #category : #'instance creation' }
SoilSkipListLegacyHeaderPage >> readLegacyFrom: aStream [ 
	dirty := false.
	self 
		readLastTransactionFrom: aStream;
		readLegacyHeaderFrom: aStream;
		readLevelsFrom: aStream;
		readItemsFrom: aStream
]

{ #category : #'instance creation' }
SoilSkipListLegacyHeaderPage >> readLegacyHeaderFrom: aStream [
	keySize := (aStream next: 2) asInteger.
	valueSize := (aStream next: 2) asInteger.
	maxLevel := (aStream next: 2) asInteger.
	lastPageIndex :=(aStream next: 4) asInteger.
]

{ #category : #accessing }
SoilSkipListLegacyHeaderPage >> smallestKey [ 
	^ 0
]

{ #category : #writing }
SoilSkipListLegacyHeaderPage >> writeHeaderOn: aStream [ 
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

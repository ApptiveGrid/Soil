Class {
	#name : #SoilSkipListHeaderPage,
	#superclass : #SoilSkipListPage,
	#instVars : [
		'maxLevel',
		'lastPageIndex'
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
		+ 8 "keySize, valueSize, maxLevel, lastPageIndex" 
		+ 1 "level" 
		+ (self level * self rightSize)
]

{ #category : #accessing }
SoilSkipListHeaderPage >> keySize: anInteger [
	keySize ifNotNil: [ Error signal: 'key size has been set alread' ].
	super keySize: anInteger.
	

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
	right := Array new: anInteger withAll: 0 
]

{ #category : #'as yet unclassified' }
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
	lastPageIndex :=(aStream next: 2) asInteger 
]

{ #category : #'as yet unclassified' }
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
		nextPutAll: (lastPageIndex asByteArrayOfSize: 2).
	self 
		writeLevelsOn: aStream
]

Class {
	#name : #SoilSkipListHeaderPage,
	#superclass : #SoilSkipListDataPage,
	#instVars : [
		'maxLevel'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #'as yet unclassified' }
SoilSkipListHeaderPage class >> pageCode [ 
	^ 1 
]

{ #category : #private }
SoilSkipListHeaderPage >> addSentinelItems [
	items 
		add: ((SoilSkipListSentinel lower keySize: keySize) numericValue -> 0);
		add: ((SoilSkipListSentinel upper keySize: keySize) numericValue -> 0)
]

{ #category : #utilities }
SoilSkipListHeaderPage >> headerSize [
	^ self indexSize + 6 + (maxLevel * self indexSize)
]

{ #category : #accessing }
SoilSkipListHeaderPage >> keySize [
	^ keySize
]

{ #category : #accessing }
SoilSkipListHeaderPage >> keySize: anInteger [ 
	keySize ifNotNil: [ Error signal: 'key size has been set alread' ].
	keySize := anInteger.
	self addSentinelItems 
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
	maxLevel := (aStream next: 2) asInteger
]

{ #category : #accessing }
SoilSkipListHeaderPage >> valueSize [
	^ valueSize
]

{ #category : #accessing }
SoilSkipListHeaderPage >> valueSize: anInteger [ 
	valueSize := anInteger
]

{ #category : #writing }
SoilSkipListHeaderPage >> writeOn: aStream [ 
	super writeOn: aStream.
	aStream 
		nextPutAll: (keySize asByteArrayOfSize: 2);
		nextPutAll: (valueSize asByteArrayOfSize: 2);
		nextPutAll: (maxLevel asByteArrayOfSize: 2).
	self 
		writeLevelsOn: aStream;
		writeItemsOn: aStream
]

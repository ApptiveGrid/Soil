Class {
	#name : #SoilSkipListHeaderPage,
	#superclass : #Object,
	#instVars : [
		'startPageIndex',
		'keySize',
		'valueSize',
		'maxLevel'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #initialization }
SoilSkipListHeaderPage >> initialize [ 
	super initialize.
	startPageIndex := 1
]

{ #category : #accessing }
SoilSkipListHeaderPage >> keySize [
	^ keySize
]

{ #category : #accessing }
SoilSkipListHeaderPage >> keySize: anInteger [ 
	keySize := anInteger
]

{ #category : #accessing }
SoilSkipListHeaderPage >> maxLevel [
	^ maxLevel
]

{ #category : #accessing }
SoilSkipListHeaderPage >> maxLevel: anInteger [ 
	maxLevel := anInteger
]

{ #category : #'instance creation' }
SoilSkipListHeaderPage >> readFrom: aStream [ 
	aStream next.
	startPageIndex := (aStream next: 8) asInteger.
	keySize := (aStream next: 2) asInteger.
	valueSize := (aStream next: 2) asInteger.
	maxLevel := (aStream next: 2) asInteger
]

{ #category : #accessing }
SoilSkipListHeaderPage >> startPageIndex [
	^ startPageIndex
]

{ #category : #accessing }
SoilSkipListHeaderPage >> startPageIndex: anInteger [ 
	startPageIndex := anInteger 
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
	aStream nextPut: 0.
	aStream 
		nextPutAll: (startPageIndex asByteArrayOfSize: 8);
		nextPutAll: (keySize asByteArrayOfSize: 2);
		nextPutAll: (valueSize asByteArrayOfSize: 2);
		nextPutAll: (maxLevel asByteArrayOfSize: 2).
]

Class {
	#name : #SoilAddKeyEntry,
	#superclass : #SoilIndexJournalEntry,
	#instVars : [
		'key',
		'value',
		'oldValue'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #'accessing - defaults' }
SoilAddKeyEntry class >> journalTypeCode [
	^ 3
]

{ #category : #accessing }
SoilAddKeyEntry >> address [
	^ key asByteArray asString
]

{ #category : #committing }
SoilAddKeyEntry >> commitIn: soil [

	| index |
	index := (soil objectRepository segmentAt: segment) indexAt: id.
	index newIterator
		at: key add: value;
		updateCurrentTransaction: transactionId
]

{ #category : #accessing }
SoilAddKeyEntry >> context [ 
	^ id 
]

{ #category : #accessing }
SoilAddKeyEntry >> key [
	^ key
]

{ #category : #accessing }
SoilAddKeyEntry >> key: aString [ 
	key := aString 
]

{ #category : #accessing }
SoilAddKeyEntry >> objectIds [
	^ { value }
]

{ #category : #accessing }
SoilAddKeyEntry >> oldValue [
	^ oldValue
]

{ #category : #accessing }
SoilAddKeyEntry >> oldValue: anObject [
	oldValue := anObject
]

{ #category : #printing }
SoilAddKeyEntry >> printOn: aStream [ 
	aStream << 'add key: ' << key printString << ' to index ' << id printString
]

{ #category : #testing }
SoilAddKeyEntry >> providesObjectIds [ 
	^ true
]

{ #category : #writing }
SoilAddKeyEntry >> readFrom: aStream [ 
	| idSize |
	super readFrom: aStream.
	idSize := aStream next.
	id := (aStream next: idSize) asString.
	key := (aStream next: aStream nextLengthEncodedInteger) asInteger.
	value := (aStream next: (aStream nextLengthEncodedInteger) asInteger) asSoilObjectId .
]

{ #category : #accessing }
SoilAddKeyEntry >> value [ 
	^ value
]

{ #category : #accessing }
SoilAddKeyEntry >> value: aString [ 
	value := aString
]

{ #category : #writing }
SoilAddKeyEntry >> writeOn: aStream [ 
	super writeOn: aStream.
	aStream 
		nextPut: id size; 
		nextPutAll: id asByteArray;
		nextPutLengthEncodedInteger: key asByteArray size;
		nextPutAll: key asByteArray;
		nextPutLengthEncodedInteger: value asByteArray size;
		nextPutAll: value asByteArray
]

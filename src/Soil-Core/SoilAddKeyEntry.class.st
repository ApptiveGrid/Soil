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

{ #category : #'as yet unclassified' }
SoilAddKeyEntry >> commitIn: transaction [ 
	| index |
	index := transaction indexAt: id segment: segment.
	index newIterator 
		at: key put: value;
		updateCurrentTransaction: transaction writeVersion 
		
]

{ #category : #accessing }
SoilAddKeyEntry >> context [ 
	^ id 
]

{ #category : #'as yet unclassified' }
SoilAddKeyEntry >> effect [
	^ key -> value 
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
SoilAddKeyEntry >> oldValue [
	^ oldValue
]

{ #category : #accessing }
SoilAddKeyEntry >> oldValue: anObject [
	oldValue := anObject
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
SoilAddKeyEntry >> segment: anInteger [ 
	segment := anInteger
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

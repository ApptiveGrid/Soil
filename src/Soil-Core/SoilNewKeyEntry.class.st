Class {
	#name : #SoilNewKeyEntry,
	#superclass : #SoilJournalEntry,
	#instVars : [
		'segment',
		'indexId',
		'key',
		'value',
		'oldValue'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #'accessing - defaults' }
SoilNewKeyEntry class >> journalTypeCode [
	^ 3
]

{ #category : #accessing }
SoilNewKeyEntry >> address [
	^ key asByteArray asString
]

{ #category : #'as yet unclassified' }
SoilNewKeyEntry >> commitIn: transaction [ 
	| index |
	index := transaction indexAt: indexId segment: segment.
	index newIterator 
		at: key put: value;
		updateCurrentTransaction: transaction writeVersion 
		
]

{ #category : #accessing }
SoilNewKeyEntry >> container [
	^ 'index: ', indexId asString
]

{ #category : #accessing }
SoilNewKeyEntry >> context [ 
	^ indexId 
]

{ #category : #'as yet unclassified' }
SoilNewKeyEntry >> effect [
	^ key -> value 
]

{ #category : #accessing }
SoilNewKeyEntry >> indexId: aString [ 
	indexId := aString
]

{ #category : #accessing }
SoilNewKeyEntry >> key [
	^ key
]

{ #category : #accessing }
SoilNewKeyEntry >> key: aString [ 
	key := aString 
]

{ #category : #accessing }
SoilNewKeyEntry >> oldValue [
	^ oldValue
]

{ #category : #accessing }
SoilNewKeyEntry >> oldValue: anObject [
	oldValue := anObject
]

{ #category : #writing }
SoilNewKeyEntry >> readFrom: aStream [ 
	| indexIdSize |
	super readFrom: aStream.
	indexIdSize := aStream next.
	indexId := (aStream next: indexIdSize) asString.
	key := (aStream next: aStream nextLengthEncodedInteger) asInteger.
	value := (aStream next: (aStream nextLengthEncodedInteger) asInteger) asSoilObjectId .
]

{ #category : #accessing }
SoilNewKeyEntry >> segment: anInteger [ 
	segment := anInteger
]

{ #category : #accessing }
SoilNewKeyEntry >> value [ 
	^ value
]

{ #category : #accessing }
SoilNewKeyEntry >> value: aString [ 
	value := aString
]

{ #category : #writing }
SoilNewKeyEntry >> writeOn: aStream [ 
	super writeOn: aStream.
	aStream 
		nextPut: indexId size; 
		nextPutAll: indexId asByteArray;
		nextPutLengthEncodedInteger: key asByteArray size;
		nextPutAll: key asByteArray;
		nextPutLengthEncodedInteger: value asByteArray size;
		nextPutAll: value asByteArray
]

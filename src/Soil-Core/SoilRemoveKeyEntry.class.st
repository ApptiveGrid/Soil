Class {
	#name : #SoilRemoveKeyEntry,
	#superclass : #SoilJournalEntry,
	#instVars : [
		'indexId',
		'key',
		'value'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #'accessing - defaults' }
SoilRemoveKeyEntry class >> journalTypeCode [
	^ 4
]

{ #category : #'as yet unclassified' }
SoilRemoveKeyEntry >> commitIn: transaction [ 
	| index |
	index := (transaction indexes associations 
		detect: [ :each | each key id = indexId ]
		ifNone: [ Error signal: 'shouldnt happen' ]) value.
	self flag: #todo.
	"ifAbsent: should not be used here"
	index newIterator 
		at: key put: (SoilObjectId segment: 0 index: 0);
		updateCurrentTransaction: transaction writeVersion 
]

{ #category : #accessing }
SoilRemoveKeyEntry >> context [ 
	^ indexId 
]

{ #category : #accessing }
SoilRemoveKeyEntry >> indexId: aString [ 
	indexId := aString
]

{ #category : #accessing }
SoilRemoveKeyEntry >> key [

	^ key
]

{ #category : #accessing }
SoilRemoveKeyEntry >> key: aString [ 
	key := aString 
]

{ #category : #'instance creation' }
SoilRemoveKeyEntry >> readFrom: aStream [
	| indexIdSize |
	super readFrom: aStream.
	indexIdSize := aStream next.
	indexId := (aStream next: indexIdSize) asString.
	key := (aStream next: (aStream next: 2) asInteger) asInteger.
	value := (aStream next: (aStream next: 2) asInteger) asSoilObjectId .
]

{ #category : #accessing }
SoilRemoveKeyEntry >> value [

	^ value
]

{ #category : #accessing }
SoilRemoveKeyEntry >> value: aString [ 
	value := aString
]

{ #category : #writing }
SoilRemoveKeyEntry >> writeOn: aStream [ 
	super writeOn: aStream.
	aStream 
		nextPut: indexId size; 
		nextPutAll: indexId asByteArray;
		nextPutAll: (key size asByteArrayOfSize: 2);
		nextPutAll: key asByteArray ;
		nextPutAll: (value asByteArray size asByteArrayOfSize: 2);
		nextPutAll: value asByteArray
		
]

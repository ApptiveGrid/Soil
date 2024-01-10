Class {
	#name : #SoilRemoveKeyEntry,
	#superclass : #SoilIndexJournalEntry,
	#instVars : [
		'key',
		'oldValue'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #'accessing - defaults' }
SoilRemoveKeyEntry class >> journalTypeCode [
	^ 4
]

{ #category : #accessing }
SoilRemoveKeyEntry >> address [
	^ key asByteArray asString
]

{ #category : #committing }
SoilRemoveKeyEntry >> commitIn: soil [ 
	((soil objectRepository segmentAt: segment) indexAt: id) newIterator 
		at: key put: SoilObjectId removed;
		updateCurrentTransaction: transactionId 
]

{ #category : #accessing }
SoilRemoveKeyEntry >> context [ 
	^ id 
]

{ #category : #accessing }
SoilRemoveKeyEntry >> key [

	^ key
]

{ #category : #accessing }
SoilRemoveKeyEntry >> key: aString [ 
	key := aString 
]

{ #category : #accessing }
SoilRemoveKeyEntry >> objectIds [
	^ { oldValue }
]

{ #category : #accessing }
SoilRemoveKeyEntry >> oldValue [

	^ oldValue
]

{ #category : #accessing }
SoilRemoveKeyEntry >> oldValue: aString [ 
	oldValue := aString
]

{ #category : #'instance creation' }
SoilRemoveKeyEntry >> readFrom: aStream [
	| idSize |
	super readFrom: aStream.
	idSize := aStream next.
	id := (aStream next: idSize) asString.
	key := (aStream next: aStream nextLengthEncodedInteger) asInteger.
	oldValue := (aStream next: aStream nextLengthEncodedInteger) asSoilObjectId .
]

{ #category : #accessing }
SoilRemoveKeyEntry >> value [ 
	^ #removed
]

{ #category : #writing }
SoilRemoveKeyEntry >> writeOn: aStream [ 
	super writeOn: aStream.
	aStream 
		nextPut: id size; 
		nextPutAll: id asByteArray;
		nextPutLengthEncodedInteger: key asByteArray size;
		nextPutAll: key asByteArray;
		nextPutLengthEncodedInteger: oldValue asByteArray size;
		nextPutAll: oldValue asByteArray
		
]

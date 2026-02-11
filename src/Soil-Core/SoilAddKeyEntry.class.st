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
SoilAddKeyEntry >> commitIn: soil recovery: aBoolean [

	| index |
	index := (soil objectRepository segmentAt: self segment) indexAt: id.
	index newIterator
		at: key add: value;
		updateCurrentTransaction: transactionId
]

{ #category : #accessing }
SoilAddKeyEntry >> context [ 
	^ id 
]

{ #category : #testing }
SoilAddKeyEntry >> isForItem: anItem [
	^ 	key = anItem key and: [value = anItem value]
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
	| keyByteArray valueByteArray |
	keyByteArray := key asByteArray.
	valueByteArray := value asByteArray.
	super writeOn: aStream.
	aStream 
		nextPut: id size; 
		nextPutAll: id asByteArray;
		nextPutLengthEncodedInteger: keyByteArray size;
		nextPutAll: keyByteArray;
		nextPutLengthEncodedInteger: valueByteArray size;
		nextPutAll: valueByteArray
]

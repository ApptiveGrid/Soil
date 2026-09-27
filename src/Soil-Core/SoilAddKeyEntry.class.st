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

{ #category : #initialization }
SoilAddKeyEntry >> initialize [
	super initialize.
	"version 2 writes the value the key held before, see #writeOn:"
	version := 2
]

{ #category : #testing }
SoilAddKeyEntry >> isForItem: anItem index: indexId [
	id = indexId ifFalse: [ ^false ].
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
	version >= 2 ifTrue: [ | oldValueSize |
		oldValueSize := aStream nextLengthEncodedInteger.
		oldValue := oldValueSize = 0
			ifTrue: [ nil ]
			ifFalse: [ (aStream next: oldValueSize) asSoilObjectId ] ]
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
	"the old value is written as well, empty when the key is new. A reader on an older
	version restores the key from it, also when this entry is read back from disk. It
	was not written up to version 1, and such an entry comes back without it; one of
	that version is still written the way it was"
	| keyByteArray valueByteArray oldValueByteArray |
	keyByteArray := key asByteArray.
	valueByteArray := value asByteArray.
	oldValueByteArray := oldValue ifNil: [ #[] ] ifNotNil: [ :old | old asByteArray ].
	super writeOn: aStream.
	aStream 
		nextPut: id size; 
		nextPutAll: id asByteArray;
		nextPutLengthEncodedInteger: keyByteArray size;
		nextPutAll: keyByteArray;
		nextPutLengthEncodedInteger: valueByteArray size;
		nextPutAll: valueByteArray.
	version >= 2 ifTrue: [
		aStream
			nextPutLengthEncodedInteger: oldValueByteArray size;
			nextPutAll: oldValueByteArray ]
]

Class {
	#name : #SoilRemoveKeyEntry,
	#superclass : #SoilIndexJournalEntry,
	#instVars : [
		'key',
		'oldValue',
		'value'
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
SoilRemoveKeyEntry >> commitIn: soil recovery: aBoolean [
	| iterator index |
	index := ((soil objectRepository segmentAt: self segment) indexAt: id).
	iterator := index newIterator.
	"on recovery we ignore a missing key because it can be removed already and the replay
	would fail always. But we still want to fail in a regular commit"
	aBoolean 
		ifTrue: [ 
			index hasUniqueKeys 
				ifTrue: [ iterator removeKey: key ifAbsent: [ "ignore missing key" ] ]
				ifFalse: [ iterator removeKey: key value: oldValue ifAbsent: [ "ignore missing key" ] ] ]
		ifFalse: [ 
			index hasUniqueKeys 
				ifTrue: [ iterator removeKey: key ]
				ifFalse: [ iterator removeKey: key value: oldValue ]
			 ].
	iterator updateCurrentTransaction: transactionId 
]

{ #category : #accessing }
SoilRemoveKeyEntry >> context [ 
	^ id 
]

{ #category : #testing }
SoilRemoveKeyEntry >> isForItem: anItem [
	| itemValue |
	key = anItem key ifFalse: [ ^false ].
	itemValue := anItem value.
	^ itemValue isRemoved 
		ifTrue: [ itemValue removedId = oldValue]
		ifFalse: [ itemValue = value ]
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

{ #category : #testing }
SoilRemoveKeyEntry >> providesObjectIds [ 
	^ true
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
SoilRemoveKeyEntry >> value: anObject [
	^ value := anObject
]

{ #category : #writing }
SoilRemoveKeyEntry >> writeOn: aStream [ 
	| keyByteArray oldValueByteArray |
	keyByteArray := key asByteArray.
	oldValueByteArray := oldValue asByteArray.
	super writeOn: aStream.
	aStream 
		nextPut: id size; 
		nextPutAll: id asByteArray;
		nextPutLengthEncodedInteger: keyByteArray size;
		nextPutAll: keyByteArray;
		nextPutLengthEncodedInteger: oldValueByteArray size;
		nextPutAll: oldValueByteArray
		
]

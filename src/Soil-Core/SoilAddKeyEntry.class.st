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

{ #category : #writing }
SoilAddKeyEntry >> hasOldValueOn: aStream [
	"version 2 writes the old value. Up to version 1 it was not written, except for a
	while it was, still as version 1: fragment files written then hold both. The byte
	after the value tells them apart. With an old value it is the old value's size, 0
	or the 8 bytes of an object id. Without one it is the type code of the next entry,
	which is never 0 and not 8 either: an add key entry is followed by an entry of the
	same transaction, never by the begin entry of the next one"
	version >= 2 ifTrue: [ ^ true ].
	^ #(0 8) includes: aStream peek
]

{ #category : #initialization }
SoilAddKeyEntry >> initialize [
	super initialize.
	"version 2 writes the value the key held before, see #writeOn:"
	version := 2
]

{ #category : #testing }
SoilAddKeyEntry >> isForItem: anItem index: indexId [
	"the value of an item on a page is the byte array the page holds. The value of
	this entry is one only while the transaction journal is in memory, as it was
	committed - one that is read back from its fragment file holds a SoilObjectId
	(#readFrom:), and a SoilObjectId is never equal to a byte array. Compared as
	they are, a reader pinned to an older version found no entry for the key it was
	to take back, and handed out an entry committed after its version"
	id = indexId ifFalse: [ ^false ].
	^ 	key = anItem key and: [ value asByteArray = anItem value asByteArray ]
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
	(self hasOldValueOn: aStream) ifTrue: [ self readOldValueFrom: aStream ]
]

{ #category : #writing }
SoilAddKeyEntry >> readOldValueFrom: aStream [
	| oldValueSize |
	oldValueSize := aStream nextLengthEncodedInteger.
	oldValue := oldValueSize = 0
		ifTrue: [ nil ]
		ifFalse: [ (aStream next: oldValueSize) asSoilObjectId ]
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
	was not written up to version 1, and one of that version is still written the way
	it was"
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
